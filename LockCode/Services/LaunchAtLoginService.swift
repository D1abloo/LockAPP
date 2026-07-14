import Foundation
import Combine
import ServiceManagement

@MainActor
final class LaunchAtLoginService: ObservableObject {
    private static let registeredBuildKey = "launchAtLoginRegisteredBuild"

    enum State {
        case enabled
        case notRegistered
        case requiresApproval
        case unavailable
    }

    @Published private(set) var state: State = .notRegistered
    @Published var lastError: String?

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
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

    func setEnabled(_ enabled: Bool, repairAfterUpdate: Bool = false) async {
        do {
            if enabled {
                var status = SMAppService.mainApp.status
                if repairAfterUpdate,
                   status == .enabled,
                   defaults.string(forKey: Self.registeredBuildKey) != currentBuildIdentifier {
                    try await SMAppService.mainApp.unregister()
                    status = SMAppService.mainApp.status
                }
                if status != .enabled && status != .requiresApproval {
                    try SMAppService.mainApp.register()
                }
                defaults.set(currentBuildIdentifier, forKey: Self.registeredBuildKey)
            } else {
                let status = SMAppService.mainApp.status
                if status == .enabled || status == .requiresApproval {
                    try await SMAppService.mainApp.unregister()
                }
                defaults.removeObject(forKey: Self.registeredBuildKey)
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

    private var currentBuildIdentifier: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "0"
        let build = info?["CFBundleVersion"] as? String ?? "0"
        return "\(version)-\(build)"
    }
}
