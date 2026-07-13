import XCTest

@testable import LockCode

final class PINPolicyTests: XCTestCase {
  func testAcceptsFourToSixteenLettersAndDigits() {
    XCTAssertTrue(PINPolicy.isValid("1234"))
    XCTAssertTrue(PINPolicy.isValid("Clave2026"))
    XCTAssertTrue(PINPolicy.isValid("AbCd1234EfGh5678"))
  }

  func testRejectsInvalidLengthAndCharacters() {
    XCTAssertFalse(PINPolicy.isValid("123"))
    XCTAssertFalse(PINPolicy.isValid("12345678901234567"))
    XCTAssertFalse(PINPolicy.isValid("clave-2026"))
  }

  func testNormalizationKeepsLettersAndDigitsUpToSixteenCharacters() {
    XCTAssertEqual(PINPolicy.normalized("Mi clave-2026!Extra"), "Miclave2026Extra")
  }
}
