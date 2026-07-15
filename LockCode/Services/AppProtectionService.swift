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
    private var lastTerminationRequest: [pid_t: Date] = [:]
    private var enforcementTimer: DispatchSourceTimer?
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

        // macOS may restore applications before login items have finished
        // starting. Hide and normally terminate protected restored apps before
        // beginning the continuous frontmost-app safety check.
        secureRestoredApplications()
        startContinuousEnforcement()
    }

    func stop() {
        let center = NSWorkspace.shared.notificationCenter
        observers.forEach(center.removeObserver)
        observers.removeAll()
        enforcementTimer?.cancel()
        enforcementTimer = nil
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
        terminateRequestTarget(request)
    }

    func unlockPolicyDidChange() {
        accessState.invalidateAll()
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
            concealAndRequestNormalTermination(application)
        }
    }

    func protectionDidBecomeEnabled() {
        concealRunningProtectedApplications()
    }

    private func handle(_ notification: Notification, trigger: AccessRequest.Trigger) {
        guard let application = notification.userInfo?[NSWorkspace.applicationUserInfoKey]
                as? NSRunningApplication else {
            return
        }
        handle(application, trigger: trigger)
    }

    private func handle(_ application: NSRunningApplication, trigger: AccessRequest.Trigger) {
        guard settings.protectionEnabled,
              let bundleIdentifier = application.bundleIdentifier,
              !excludedBundleIdentifiers.contains(bundleIdentifier),
              settings.isProtected(bundleIdentifier) else {
            return
        }

        // A protected app may emit activation events while its first request is
        // still on screen. It must remain hidden even though no second request
        // should be enqueued.
        if accessState.hasPendingRequest(for: bundleIdentifier) {
            conceal(application)
            return
        }

        guard accessState.beginRequest(
                  for: bundleIdentifier,
                  isProtected: true,
                  excludedBundleIdentifiers: excludedBundleIdentifiers
              ) else {
            return
        }

        conceal(application)

        let bundleURL = application.bundleURL
        let resumeAction: AccessRequest.ResumeAction
        resumeAction = .activate(
            processIdentifier: application.processIdentifier,
            fallbackURL: bundleURL
        )

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
        lastTerminationRequest.removeValue(forKey: application.processIdentifier)
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
            concealAndRequestNormalTermination(application)
        }
    }

    private func secureRestoredApplications() {
        guard settings.protectionEnabled else { return }
        for application in NSWorkspace.shared.runningApplications {
            guard let bundleIdentifier = application.bundleIdentifier,
                  settings.isProtected(bundleIdentifier),
                  !excludedBundleIdentifiers.contains(bundleIdentifier),
                  !application.isTerminated else {
                continue
            }
            concealAndRequestNormalTermination(application)
            // A normal termination lets the target save state or refuse. Never
            // force-terminate because privacy protection must not lose data.
        }
    }

    private func startContinuousEnforcement() {
        enforcementTimer?.cancel()
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(
            deadline: .now() + .milliseconds(50),
            repeating: .milliseconds(50),
            leeway: .milliseconds(10)
        )
        timer.setEventHandler { [weak self] in
            MainActor.assumeIsolated {
                self?.enforceProtectedApplications()
            }
        }
        timer.resume()
        enforcementTimer = timer
    }

    private func enforceProtectedApplications() {
        guard settings.protectionEnabled else { return }
        let now = Date()
        for bundleIdentifier in settings.protectedBundleIdentifiers {
            guard !excludedBundleIdentifiers.contains(bundleIdentifier),
                  !accessState.isAccessGranted(for: bundleIdentifier, at: now) else {
                continue
            }
            for application in NSRunningApplication.runningApplications(
                withBundleIdentifier: bundleIdentifier
            ) where !application.isTerminated {
                if accessState.hasPendingRequest(for: bundleIdentifier) {
                    conceal(application)
                } else if application.isActive {
                    handle(application, trigger: .activation)
                } else {
                    concealAndRequestNormalTermination(application)
                }
            }
        }
    }

    private func concealAndRequestNormalTermination(
        _ application: NSRunningApplication
    ) {
        guard !application.isTerminated else { return }
        conceal(application)
        requestNormalTermination(application)
    }

    private func conceal(_ application: NSRunningApplication) {
        guard !application.isTerminated, !application.isHidden else { return }
        _ = application.hide()
    }

    private func terminateRequestTarget(_ request: AccessRequest) {
        switch request.resumeAction {
        case .activate(let processIdentifier, _):
            if let application = NSRunningApplication(processIdentifier: processIdentifier) {
                requestNormalTermination(application)
            }
        case .reopen:
            for application in NSRunningApplication.runningApplications(
                withBundleIdentifier: request.bundleIdentifier
            ) where !application.isTerminated {
                requestNormalTermination(application)
            }
        }
    }

    private func requestNormalTermination(_ application: NSRunningApplication) {
        let processIdentifier = application.processIdentifier
        let now = Date()
        if let previousRequest = lastTerminationRequest[processIdentifier],
           now.timeIntervalSince(previousRequest) < 1 {
            return
        }
        lastTerminationRequest[processIdentifier] = now
        _ = application.terminate()
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
