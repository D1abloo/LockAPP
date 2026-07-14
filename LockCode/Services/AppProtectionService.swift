import AppKit
import Foundation

@MainActor
final class AppProtectionService {
    var onBlocked: ((AccessRequest) -> Void)?
    var onSessionInvalidated: (() -> Void)?

    private let settings: SettingsStore
    private let ownBundleIdentifier: String
    private var observers: [NSObjectProtocol] = []
    private var accessState = ApplicationAccessState()
    private var isStarted = false

    private let criticalBundleIdentifiers: Set<String> = [
        "com.apple.finder",
        "com.apple.dock",
        "com.apple.SystemUIServer",
        "com.apple.loginwindow",
        "com.apple.WindowManager",
        "com.apple.controlcenter",
        "com.apple.notificationcenterui",
        "com.apple.SecurityAgent",
        "com.apple.CoreServicesUIAgent"
    ]

    init(settings: SettingsStore, ownBundleIdentifier: String) {
        self.settings = settings
        self.ownBundleIdentifier = ownBundleIdentifier
    }

    var excludedBundleIdentifiers: Set<String> {
        criticalBundleIdentifiers.union([ownBundleIdentifier])
    }

    func start() {
        guard !isStarted else { return }
        isStarted = true

        let center = NSWorkspace.shared.notificationCenter
        observers.append(center.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let notification = MainQueueWorkspaceNotification(value: notification)
            MainActor.assumeIsolated {
                self?.handle(notification.value, trigger: .launch)
            }
        })

        observers.append(center.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let notification = MainQueueWorkspaceNotification(value: notification)
            MainActor.assumeIsolated {
                self?.handle(notification.value, trigger: .activation)
            }
        })

        observers.append(center.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let notification = MainQueueWorkspaceNotification(value: notification)
            MainActor.assumeIsolated {
                self?.handleTermination(notification.value)
            }
        })

        observers.append(center.addObserver(
            forName: NSWorkspace.sessionDidResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.invalidateAllAccess()
            }
        })

        observers.append(center.addObserver(
            forName: NSWorkspace.screensDidSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.invalidateAllAccess()
            }
        })

        // A protected application may already be running when LockCode starts.
        // Register every observer first so a concurrent activation cannot escape.
        concealRunningProtectedApplications()
    }

    func stop() {
        let center = NSWorkspace.shared.notificationCenter
        observers.forEach(center.removeObserver)
        observers.removeAll()
        isStarted = false
    }

    func approve(_ request: AccessRequest) {
        if settings.unlockDuration.keepsAccessUntilApplicationCloses {
            accessState.approveUntilApplicationTerminates(
                bundleIdentifier: request.bundleIdentifier
            )
        } else if let interval = settings.unlockDuration.graceInterval(
            customMinutes: settings.customUnlockMinutes
        ) {
            accessState.approve(
                bundleIdentifier: request.bundleIdentifier,
                graceInterval: interval
            )
        }
        resume(request)
    }

    func deny(_ request: AccessRequest) {
        accessState.deny(bundleIdentifier: request.bundleIdentifier)
    }

    func invalidateAllAccess() {
        accessState.invalidateAll()
        concealRunningProtectedApplications(force: true)
        onSessionInvalidated?()
    }

    func invalidateAccess(for bundleIdentifier: String) {
        accessState.invalidate(bundleIdentifier: bundleIdentifier)
    }

    func concealRunningApplication(bundleIdentifier: String) {
        guard settings.protectionEnabled else { return }
        for application in NSRunningApplication.runningApplications(
            withBundleIdentifier: bundleIdentifier
        ) where !application.isTerminated {
            _ = application.hide()
        }
    }

    func protectionDidBecomeEnabled() {
        concealRunningProtectedApplications()
    }

    private func handle(_ notification: Notification, trigger: AccessRequest.Trigger) {
        guard settings.protectionEnabled,
              let application = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              let bundleIdentifier = application.bundleIdentifier,
              !excludedBundleIdentifiers.contains(bundleIdentifier),
              settings.isProtected(bundleIdentifier) else {
            return
        }

        // A protected app may emit activation events while its first request is
        // still on screen. It must remain hidden even though no second request
        // should be enqueued.
        if accessState.hasPendingRequest(for: bundleIdentifier) {
            _ = application.hide()
            return
        }

        guard accessState.beginRequest(
                  for: bundleIdentifier,
                  isProtected: true,
                  excludedBundleIdentifiers: excludedBundleIdentifiers
              ) else {
            return
        }

        _ = application.hide()

        let bundleURL = application.bundleURL
        let resumeAction: AccessRequest.ResumeAction
        switch trigger {
        case .launch:
            // Request a normal termination. Never force-terminate by default because the app
            // may be restoring documents or performing another data-sensitive operation.
            if let bundleURL {
                _ = application.terminate()
                resumeAction = .reopen(bundleURL)
            } else {
                resumeAction = .activate(
                    processIdentifier: application.processIdentifier,
                    fallbackURL: nil
                )
            }
        case .activation:
            resumeAction = .activate(
                processIdentifier: application.processIdentifier,
                fallbackURL: bundleURL
            )
        }

        let request = AccessRequest(
            bundleIdentifier: bundleIdentifier,
            applicationName: application.localizedName
                ?? bundleURL?.deletingPathExtension().lastPathComponent
                ?? bundleIdentifier,
            bundleURL: bundleURL,
            trigger: trigger,
            resumeAction: resumeAction
        )
        onBlocked?(request)
    }

    private func handleTermination(_ notification: Notification) {
        guard let application = notification.userInfo?[NSWorkspace.applicationUserInfoKey]
                as? NSRunningApplication,
              let bundleIdentifier = application.bundleIdentifier else {
            return
        }
        accessState.applicationDidTerminate(bundleIdentifier: bundleIdentifier)
    }

    private func concealRunningProtectedApplications(force: Bool = false) {
        guard force || settings.protectionEnabled else { return }
        for application in NSWorkspace.shared.runningApplications {
            guard let bundleIdentifier = application.bundleIdentifier,
                  settings.isProtected(bundleIdentifier),
                  !excludedBundleIdentifiers.contains(bundleIdentifier),
                  !application.isTerminated else {
                continue
            }
            _ = application.hide()
        }
    }

    private func resume(_ request: AccessRequest) {
        switch request.resumeAction {
        case .reopen(let url):
            let resolvedURL: URL?
            if FileManager.default.fileExists(atPath: url.path) {
                resolvedURL = url
            } else {
                resolvedURL = NSWorkspace.shared.urlForApplication(
                    withBundleIdentifier: request.bundleIdentifier
                )
            }
            guard let resolvedURL else { return }
            let configuration = NSWorkspace.OpenConfiguration()
            configuration.activates = true
            NSWorkspace.shared.openApplication(at: resolvedURL, configuration: configuration) { _, _ in }

        case .activate(let processIdentifier, let fallbackURL):
            if let application = NSRunningApplication(processIdentifier: processIdentifier),
               !application.isTerminated {
                _ = application.activate(options: [.activateAllWindows])
            } else if let fallbackURL = fallbackURL
                ?? NSWorkspace.shared.urlForApplication(withBundleIdentifier: request.bundleIdentifier) {
                let configuration = NSWorkspace.OpenConfiguration()
                configuration.activates = true
                NSWorkspace.shared.openApplication(at: fallbackURL, configuration: configuration) { _, _ in }
            }
        }
    }
}

/// NotificationCenter does not express that a `.main` observer invokes its
/// closure synchronously on the main queue. This wrapper records that local
/// guarantee for Swift's sendability checker; it is never sent to another task.
private struct MainQueueWorkspaceNotification: @unchecked Sendable {
    let value: Notification
}
