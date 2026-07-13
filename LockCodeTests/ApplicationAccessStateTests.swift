import Foundation
import XCTest

@testable import LockCode

final class ApplicationAccessStateTests: XCTestCase {
    private let bundleIdentifier = "com.example.PrivateApp"
    private let now = Date(timeIntervalSince1970: 10_000)

    func testProtectedApplicationCreatesOnlyOnePendingRequest() {
        var state = ApplicationAccessState()

        XCTAssertTrue(beginRequest(in: &state, at: now))
        XCTAssertFalse(beginRequest(in: &state, at: now))

        state.deny(bundleIdentifier: bundleIdentifier)
        XCTAssertTrue(beginRequest(in: &state, at: now))
    }

    func testApprovedApplicationRemainsUnlockedUntilGracePeriodExpires() {
        var state = ApplicationAccessState()
        XCTAssertTrue(beginRequest(in: &state, at: now))

        state.approve(bundleIdentifier: bundleIdentifier, graceInterval: 60, at: now)

        XCTAssertFalse(beginRequest(in: &state, at: now.addingTimeInterval(59)))
        XCTAssertTrue(beginRequest(in: &state, at: now.addingTimeInterval(60)))
    }

    func testImmediateModeStaysUnlockedUntilApplicationTerminates() {
        var state = ApplicationAccessState()
        XCTAssertTrue(beginRequest(in: &state, at: now))

        state.approveUntilApplicationTerminates(bundleIdentifier: bundleIdentifier)

        XCTAssertFalse(beginRequest(in: &state, at: now.addingTimeInterval(3_600)))
        state.applicationDidTerminate(bundleIdentifier: bundleIdentifier)
        XCTAssertTrue(beginRequest(in: &state, at: now.addingTimeInterval(3_601)))
    }

    func testInvalidatingAccessEndsGracePeriodImmediately() {
        var state = ApplicationAccessState()
        XCTAssertTrue(beginRequest(in: &state, at: now))
        state.approve(bundleIdentifier: bundleIdentifier, graceInterval: 300, at: now)

        state.invalidateAll()

        XCTAssertTrue(beginRequest(in: &state, at: now.addingTimeInterval(1)))
    }

    func testTimedAccessSurvivesApplicationTerminationUntilItExpires() {
        var state = ApplicationAccessState()
        XCTAssertTrue(beginRequest(in: &state, at: now))
        state.approve(bundleIdentifier: bundleIdentifier, graceInterval: 60, at: now)

        state.applicationDidTerminate(bundleIdentifier: bundleIdentifier)

        XCTAssertFalse(beginRequest(in: &state, at: now.addingTimeInterval(59)))
        XCTAssertTrue(beginRequest(in: &state, at: now.addingTimeInterval(60)))
    }

    func testUnprotectedAndExcludedApplicationsNeverCreateRequests() {
        var state = ApplicationAccessState()

        XCTAssertFalse(state.beginRequest(
            for: bundleIdentifier,
            isProtected: false,
            excludedBundleIdentifiers: [],
            at: now
        ))
        XCTAssertFalse(state.beginRequest(
            for: "com.apple.finder",
            isProtected: true,
            excludedBundleIdentifiers: ["com.apple.finder"],
            at: now
        ))
        XCTAssertFalse(state.beginRequest(
            for: "com.example.LockCode",
            isProtected: true,
            excludedBundleIdentifiers: ["com.example.LockCode"],
            at: now
        ))
    }

    private func beginRequest(in state: inout ApplicationAccessState, at date: Date) -> Bool {
        state.beginRequest(
            for: bundleIdentifier,
            isProtected: true,
            excludedBundleIdentifiers: [],
            at: date
        )
    }
}
