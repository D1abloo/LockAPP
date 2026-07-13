import XCTest

@testable import LockCode

final class AppVersionTests: XCTestCase {
    func testComparesSemanticVersionsAndOptionalVPrefix() {
        XCTAssertLessThan(AppVersion("0.1.0"), AppVersion("v0.2.0"))
        XCTAssertLessThan(AppVersion("1.9"), AppVersion("1.10.0"))
        XCTAssertEqual(AppVersion("v1.2.0"), AppVersion("1.2"))
    }
}
