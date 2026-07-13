import Foundation
import Combine

@MainActor
final class SettingsStore: ObservableObject {
    private enum Key {
        static let protectionEnabled = "protectionEnabled"
        static let touchIDEnabled = "touchIDEnabled"
        static let unlockDuration = "unlockDuration"
        static let customUnlockMinutes = "customUnlockMinutes"
        static let protectedBundleIdentifiers = "protectedBundleIdentifiers"
    }

    private let defaults: UserDefaults

    @Published var protectionEnabled: Bool {
        didSet { defaults.set(protectionEnabled, forKey: Key.protectionEnabled) }
    }

    @Published var touchIDEnabled: Bool {
        didSet { defaults.set(touchIDEnabled, forKey: Key.touchIDEnabled) }
    }

    @Published var unlockDuration: UnlockDuration {
        didSet { defaults.set(unlockDuration.rawValue, forKey: Key.unlockDuration) }
    }

    @Published var customUnlockMinutes: Int {
        didSet {
            let clamped = min(max(customUnlockMinutes, 1), 1_440)
            if customUnlockMinutes != clamped {
                customUnlockMinutes = clamped
            } else {
                defaults.set(customUnlockMinutes, forKey: Key.customUnlockMinutes)
            }
        }
    }

    @Published private(set) var protectedBundleIdentifiers: Set<String> {
        didSet {
            defaults.set(Array(protectedBundleIdentifiers).sorted(), forKey: Key.protectedBundleIdentifiers)
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.protectionEnabled = defaults.object(forKey: Key.protectionEnabled) as? Bool ?? true
        self.touchIDEnabled = defaults.object(forKey: Key.touchIDEnabled) as? Bool ?? true
        self.unlockDuration = UnlockDuration(
            rawValue: defaults.integer(forKey: Key.unlockDuration)
        ) ?? .everyTime
        let storedCustomMinutes = defaults.integer(forKey: Key.customUnlockMinutes)
        self.customUnlockMinutes = storedCustomMinutes > 0 ? storedCustomMinutes : 10
        self.protectedBundleIdentifiers = Set(
            defaults.stringArray(forKey: Key.protectedBundleIdentifiers) ?? []
        )
    }

    func isProtected(_ bundleIdentifier: String) -> Bool {
        protectedBundleIdentifiers.contains(bundleIdentifier)
    }

    func setProtected(_ protected: Bool, bundleIdentifier: String) {
        if protected {
            protectedBundleIdentifiers.insert(bundleIdentifier)
        } else {
            protectedBundleIdentifiers.remove(bundleIdentifier)
        }
    }
}
