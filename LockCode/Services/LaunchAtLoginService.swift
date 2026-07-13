import Foundation
import Combine
import ServiceManagement

@MainActor
final class LaunchAtLoginService: ObservableObject {
    enum State {
        case enabled
        case notRegistered
        case requiresApproval
        case unavailable
    }

    @Published private(set) var state: State = .notRegistered
    @Published var lastError: String?

    init() {
        refresh()
    }

    func refresh() {
        switch SMAppService.mainApp.status {
        case .enabled:
            state = .enabled
        case .requiresApproval:
            state = .requiresApproval
        case .notRegistered:
            state = .notRegistered
        case .notFound:
            state = .unavailable
        @unknown default:
            state = .unavailable
        }
    }

    func setEnabled(_ enabled: Bool) async {
        do {
            if enabled {
                let status = SMAppService.mainApp.status
                if status != .enabled && status != .requiresApproval {
                    try SMAppService.mainApp.register()
                }
            } else {
                let status = SMAppService.mainApp.status
                if status == .enabled || status == .requiresApproval {
                    try await SMAppService.mainApp.unregister()
                }
            }
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
        refresh()
    }

    func openSystemSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }
}
