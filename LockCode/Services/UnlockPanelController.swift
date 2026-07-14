import AppKit
import SwiftUI

@MainActor
final class UnlockPanelController: NSObject, NSWindowDelegate {
    private var panel: NSPanel?
    private var privacyShields: [NSPanel] = []
    private var cancellationHandler: (() -> Void)?
    private var presentationID: UUID?
    private var shieldedBundleIdentifier: String?
    private var shieldCleanupID: UUID?

    var isPresented: Bool { panel != nil }

    func present(
        applicationName: String,
        bundleURL: URL?,
        protectedBundleIdentifier: String? = nil,
        promptMessage: String? = nil,
        touchIDEnabled: Bool,
        touchIDAvailable: Bool,
        verifyPIN: @escaping (String) async -> Bool,
        pinFailureMessage: @escaping () -> String,
        verifyBiometrics: @escaping () async -> Bool,
        onApproved: @escaping () -> Void,
        onCancelled: @escaping () -> Void
    ) {
        dismiss()
        let presentationID = UUID()
        self.presentationID = presentationID
        cancellationHandler = onCancelled
        shieldedBundleIdentifier = protectedBundleIdentifier
        if protectedBundleIdentifier != nil {
            presentPrivacyShields()
        }

        let rootView = UnlockPromptView(
            applicationName: applicationName,
            bundleURL: bundleURL,
            promptMessage: promptMessage ?? "Autentícate para abrir \(applicationName).",
            touchIDEnabled: touchIDEnabled,
            touchIDAvailable: touchIDAvailable,
            verifyPIN: verifyPIN,
            pinFailureMessage: pinFailureMessage,
            verifyBiometrics: verifyBiometrics,
            onApproved: { [weak self] in
                guard let self, self.presentationID == presentationID else { return }
                self.cancellationHandler = nil
                self.dismiss()
                onApproved()
            },
            onCancelled: { [weak self] in
                guard let self, self.presentationID == presentationID else { return }
                self.cancellationHandler = nil
                onCancelled()
                self.removeShieldsWhenApplicationIsConcealed(
                    bundleIdentifier: protectedBundleIdentifier
                )
            }
        )

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 390, height: 320),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.title = "LockCode"
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isFloatingPanel = true
        panel.level = .modalPanel
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.delegate = self
        panel.contentViewController = NSHostingController(rootView: rootView)
        panel.center()

        self.panel = panel
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }

    func dismiss() {
        presentationID = nil
        shieldCleanupID = nil
        shieldedBundleIdentifier = nil
        cancellationHandler = nil
        dismissPanelKeepingShields()
        removePrivacyShields()
    }

    private func dismissPanelKeepingShields() {
        panel?.orderOut(nil)
        panel?.contentViewController = nil
        panel = nil
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        let handler = cancellationHandler
        let bundleIdentifier = shieldedBundleIdentifier
        cancellationHandler = nil
        handler?()
        removeShieldsWhenApplicationIsConcealed(bundleIdentifier: bundleIdentifier)
        return false
    }

    private func presentPrivacyShields() {
        removePrivacyShields()
        privacyShields = NSScreen.screens.map { screen in
            let shield = NSPanel(
                contentRect: screen.frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false,
                screen: screen
            )
            shield.level = NSWindow.Level(rawValue: NSWindow.Level.modalPanel.rawValue - 1)
            shield.collectionBehavior = [
                .canJoinAllSpaces,
                .fullScreenAuxiliary,
                .stationary,
                .ignoresCycle
            ]
            shield.backgroundColor = .windowBackgroundColor
            shield.isOpaque = true
            shield.hasShadow = false
            shield.hidesOnDeactivate = false
            shield.isReleasedWhenClosed = false
            shield.contentView = NSHostingView(rootView: PrivacyShieldView())
            shield.orderFrontRegardless()
            return shield
        }
    }

    private func removePrivacyShields() {
        privacyShields.forEach {
            $0.orderOut(nil)
            $0.contentView = nil
            $0.close()
        }
        privacyShields.removeAll()
    }

    private func removeShieldsWhenApplicationIsConcealed(bundleIdentifier: String?) {
        guard let bundleIdentifier else {
            dismiss()
            return
        }
        let cleanupID = UUID()
        shieldCleanupID = cleanupID
        Task { @MainActor [weak self] in
            while self?.shieldCleanupID == cleanupID {
                let applications = NSRunningApplication.runningApplications(
                    withBundleIdentifier: bundleIdentifier
                )
                if applications.allSatisfy({ $0.isTerminated || $0.isHidden }) {
                    self?.dismiss()
                    return
                }
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
        }
    }
}

private struct PrivacyShieldView: View {
    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)
                .ignoresSafeArea()
            VStack(spacing: 16) {
                BrandLogoView(size: 88)
                Text("Contenido protegido")
                    .font(.largeTitle.bold())
                Text("Completa la autenticación de LockCode para continuar.")
                    .foregroundStyle(.secondary)
            }
        }
    }
}
