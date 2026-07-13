import AppKit

@MainActor
final class LockCodeApplicationDelegate: NSObject, NSApplicationDelegate {
    weak var model: AppModel?

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard let model else { return .terminateNow }
        guard model.isConfigured else { return .terminateNow }
        if model.consumeQuitAuthorization() {
            return .terminateNow
        }
        model.requestQuit()
        return .terminateCancel
    }
}
