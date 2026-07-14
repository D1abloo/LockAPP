import AppKit

@MainActor
final class LockCodeApplicationDelegate: NSObject, NSApplicationDelegate {
    weak var model: AppModel?
    private var powerOffObserver: NSObjectProtocol?
    private var isSystemTerminationInProgress = false

    func applicationWillFinishLaunching(_ notification: Notification) {
        powerOffObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.willPowerOffNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.isSystemTerminationInProgress = true
            }
        }
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        // Shutdown, restart and logout must never be delayed by LockCode's
        // authentication prompt. Manual Cmd-Q remains protected below.
        if isSystemTerminationInProgress { return .terminateNow }
        guard let model else { return .terminateNow }
        guard !model.isConfigurationLoading else { return .terminateCancel }
        guard model.isConfigured else { return .terminateNow }
        if model.consumeQuitAuthorization() {
            return .terminateNow
        }
        model.requestQuit()
        return .terminateCancel
    }
}
