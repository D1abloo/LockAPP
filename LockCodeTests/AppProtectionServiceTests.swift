import Foundation
import XCTest

@testable import LockCode

@MainActor
final class AppProtectionServiceTests: XCTestCase {
    func testServiceExcludesLockCodeAndCriticalProcesses() {
        let suiteName = "LockCodeTests.AppProtectionService.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            return XCTFail("No se pudo crear UserDefaults aislado")
        }
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let service = AppProtectionService(
            settings: SettingsStore(defaults: defaults),
            ownBundleIdentifier: "com.example.LockCode"
        )

        XCTAssertTrue(service.excludedBundleIdentifiers.contains("com.example.LockCode"))
        XCTAssertTrue(service.excludedBundleIdentifiers.contains("com.apple.finder"))
        XCTAssertTrue(service.excludedBundleIdentifiers.contains("com.apple.dock"))
        XCTAssertTrue(service.excludedBundleIdentifiers.contains("com.apple.loginwindow"))
    }
}
