import Foundation

/// Pure state machine used by the workspace observer. Keeping this state free of
/// AppKit makes grace periods and request deduplication deterministic to test.
struct ApplicationAccessState {
    private var unlockedUntil: [String: Date] = [:]
    private var unlockedUntilTermination: Set<String> = []
    private var pendingBundleIdentifiers: Set<String> = []

    mutating func beginRequest(
        for bundleIdentifier: String,
        isProtected: Bool,
        excludedBundleIdentifiers: Set<String>,
        at date: Date = Date()
    ) -> Bool {
        guard isProtected,
              !excludedBundleIdentifiers.contains(bundleIdentifier),
              !pendingBundleIdentifiers.contains(bundleIdentifier),
              !unlockedUntilTermination.contains(bundleIdentifier) else {
            return false
        }

        if let expiry = unlockedUntil[bundleIdentifier] {
            guard expiry <= date else { return false }
            unlockedUntil.removeValue(forKey: bundleIdentifier)
        }

        pendingBundleIdentifiers.insert(bundleIdentifier)
        return true
    }

    func hasPendingRequest(for bundleIdentifier: String) -> Bool {
        pendingBundleIdentifiers.contains(bundleIdentifier)
    }

    mutating func approve(
        bundleIdentifier: String,
        graceInterval: TimeInterval,
        at date: Date = Date()
    ) {
        pendingBundleIdentifiers.remove(bundleIdentifier)
        unlockedUntil[bundleIdentifier] = date.addingTimeInterval(graceInterval)
    }

    mutating func approveUntilApplicationTerminates(bundleIdentifier: String) {
        pendingBundleIdentifiers.remove(bundleIdentifier)
        unlockedUntil.removeValue(forKey: bundleIdentifier)
        unlockedUntilTermination.insert(bundleIdentifier)
    }

    mutating func applicationDidTerminate(bundleIdentifier: String) {
        unlockedUntilTermination.remove(bundleIdentifier)
    }

    mutating func deny(bundleIdentifier: String) {
        pendingBundleIdentifiers.remove(bundleIdentifier)
    }

    mutating func invalidateAll() {
        unlockedUntil.removeAll()
        unlockedUntilTermination.removeAll()
    }

    mutating func invalidate(bundleIdentifier: String) {
        unlockedUntil.removeValue(forKey: bundleIdentifier)
        unlockedUntilTermination.remove(bundleIdentifier)
    }
}
