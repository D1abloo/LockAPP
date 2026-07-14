import Foundation
import XCTest

@testable import LockCode

@MainActor
final class AuditLogStoreTests: XCTestCase {
    func testEventsPersistWithoutApplicationData() throws {
        let suiteName = "LockCodeTests.AuditLog.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            return XCTFail("No se pudo crear UserDefaults aislado")
        }
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let date = Date(timeIntervalSince1970: 12_345)
        let first = AuditLogStore(defaults: defaults)
        first.record(.unlocked, at: date)
        first.record(.failedAttempt, at: date.addingTimeInterval(1))

        let restored = AuditLogStore(defaults: defaults)
        XCTAssertEqual(restored.events.map(\.kind), [.failedAttempt, .unlocked])
        XCTAssertEqual(restored.events.map(\.timestamp), [date.addingTimeInterval(1), date])

        let encoded = try XCTUnwrap(defaults.data(forKey: "auditEvents"))
        XCTAssertNil(String(data: encoded, encoding: .utf8)?.range(of: "bundleIdentifier"))
    }

    func testClearRemovesPersistedEvents() {
        let suiteName = "LockCodeTests.AuditLog.Clear.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            return XCTFail("No se pudo crear UserDefaults aislado")
        }
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = AuditLogStore(defaults: defaults)
        store.record(.failedAttempt)
        store.clear()

        XCTAssertTrue(store.events.isEmpty)
        XCTAssertTrue(AuditLogStore(defaults: defaults).events.isEmpty)
    }

    func testHistoryIsLimitedToTwoHundredEvents() {
        let suiteName = "LockCodeTests.AuditLog.Limit.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            return XCTFail("No se pudo crear UserDefaults aislado")
        }
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = AuditLogStore(defaults: defaults)
        for offset in 0..<250 {
            store.record(.failedAttempt, at: Date(timeIntervalSince1970: Double(offset)))
        }

        XCTAssertEqual(store.events.count, 200)
        XCTAssertEqual(store.events.first?.timestamp, Date(timeIntervalSince1970: 249))
    }
}
