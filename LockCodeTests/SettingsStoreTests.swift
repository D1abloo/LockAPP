import Foundation
import XCTest

@testable import LockCode

@MainActor
final class SettingsStoreTests: XCTestCase {
    func testProtectedApplicationsPersistAcrossStoreInstances() {
        let suiteName = "LockCodeTests.SettingsStore.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            return XCTFail("No se pudo crear UserDefaults aislado")
        }
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let firstStore = SettingsStore(defaults: defaults)
        firstStore.setProtected(true, bundleIdentifier: "com.example.First")
        firstStore.setProtected(true, bundleIdentifier: "com.example.Second")
        firstStore.setProtected(false, bundleIdentifier: "com.example.First")
        firstStore.unlockDuration = .custom
        firstStore.customUnlockMinutes = 42

        let restoredStore = SettingsStore(defaults: defaults)

        XCTAssertFalse(restoredStore.isProtected("com.example.First"))
        XCTAssertTrue(restoredStore.isProtected("com.example.Second"))
        XCTAssertEqual(restoredStore.protectedBundleIdentifiers, Set(["com.example.Second"]))
        XCTAssertEqual(restoredStore.unlockDuration, .custom)
        XCTAssertEqual(restoredStore.customUnlockMinutes, 42)
    }
}
