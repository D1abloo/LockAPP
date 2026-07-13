import XCTest

@testable import LockCode

final class UnlockDurationTests: XCTestCase {
  func testImmediateModeKeepsAccessUntilApplicationCloses() {
    XCTAssertTrue(UnlockDuration.everyTime.keepsAccessUntilApplicationCloses)
    XCTAssertNil(UnlockDuration.everyTime.graceInterval(customMinutes: 10))
  }

  func testConfiguredDurationsUseTheirRawValue() {
    XCTAssertEqual(UnlockDuration.fiveMinutes.graceInterval(customMinutes: 10), 300)
    XCTAssertEqual(UnlockDuration.thirtyMinutes.graceInterval(customMinutes: 10), 1_800)
  }

  func testCustomDurationUsesSelectedMinutesAndClampsRange() {
    XCTAssertEqual(UnlockDuration.custom.graceInterval(customMinutes: 42), 2_520)
    XCTAssertEqual(UnlockDuration.custom.graceInterval(customMinutes: 0), 60)
    XCTAssertEqual(UnlockDuration.custom.graceInterval(customMinutes: 2_000), 86_400)
  }
}
