import XCTest

@testable import LockCode

final class AuthenticationAttemptLimiterTests: XCTestCase {
  func testFirstTwoFailuresDoNotLock() {
    let now = Date(timeIntervalSince1970: 1_000)
    var limiter = AuthenticationAttemptLimiter()

    limiter.recordFailure(at: now)
    limiter.recordFailure(at: now)

    XCTAssertTrue(limiter.canAttempt(at: now))
    XCTAssertNil(limiter.retryAfter(at: now))
  }

  func testThirdFailureLocksForFiveSeconds() {
    let now = Date(timeIntervalSince1970: 1_000)
    var limiter = AuthenticationAttemptLimiter()

    for _ in 0..<3 { limiter.recordFailure(at: now) }

    XCTAssertFalse(limiter.canAttempt(at: now.addingTimeInterval(4)))
    XCTAssertTrue(limiter.canAttempt(at: now.addingTimeInterval(5)))
  }

  func testSuccessClearsFailuresAndLockout() {
    let now = Date(timeIntervalSince1970: 1_000)
    var limiter = AuthenticationAttemptLimiter()

    for _ in 0..<5 { limiter.recordFailure(at: now) }
    limiter.recordSuccess()

    XCTAssertEqual(limiter.failedAttempts, 0)
    XCTAssertNil(limiter.lockedUntil)
    XCTAssertTrue(limiter.canAttempt(at: now))
  }

  func testFifthFailureLocksForThirtySeconds() {
    let now = Date(timeIntervalSince1970: 1_000)
    var limiter = AuthenticationAttemptLimiter()

    for _ in 0..<5 { limiter.recordFailure(at: now) }

    XCTAssertFalse(limiter.canAttempt(at: now.addingTimeInterval(29)))
    XCTAssertTrue(limiter.canAttempt(at: now.addingTimeInterval(30)))
  }

  func testSeventhFailureLocksForFiveMinutes() {
    let now = Date(timeIntervalSince1970: 1_000)
    var limiter = AuthenticationAttemptLimiter()

    for _ in 0..<7 { limiter.recordFailure(at: now) }

    XCTAssertEqual(limiter.retryAfter(at: now), 300)
  }
}
