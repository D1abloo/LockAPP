import AppKit
import SwiftUI

@MainActor
final class UnlockPanelController: NSObject, NSWindowDelegate {
    private var panel: NSPanel?
    private var cancellationHandler: (() -> Void)?
    private var presentationID: UUID?

    var isPresented: Bool { panel != nil }

    func present(
        applicationName: String,
        bundleURL: URL?,
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
                self.dismiss()
                onCancelled()
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
        panel?.orderOut(nil)
        panel?.contentViewController = nil
        panel = nil
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        let handler = cancellationHandler
        cancellationHandler = nil
        dismiss()
        handler?()
        return false
    }
}
