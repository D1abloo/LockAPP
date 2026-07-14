import XCTest

@testable import LockCode

final class PINPolicyTests: XCTestCase {
  func testAcceptsLettersNumbersSpacesAndSymbols() {
    XCTAssertTrue(PINPolicy.isValid("1234"))
    XCTAssertTrue(PINPolicy.isValid("Clave2026"))
    XCTAssertTrue(PINPolicy.isValid("Mi clave: #2026!"))
    XCTAssertTrue(PINPolicy.isValid("🔐-€-@-✓"))
  }

  func testRejectsInvalidLengthAndControlCharacters() {
    XCTAssertFalse(PINPolicy.isValid("123"))
    XCTAssertFalse(PINPolicy.isValid(String(repeating: "a", count: 65)))
    XCTAssertFalse(PINPolicy.isValid("clave\n2026"))
  }

  func testNormalizationKeepsSymbolsAndLimitsToSixtyFourCharacters() {
    XCTAssertEqual(PINPolicy.normalized("Mi clave-2026!"), "Mi clave-2026!")
    XCTAssertEqual(PINPolicy.normalized("abc\ndef"), "abcdef")
    XCTAssertEqual(
      PINPolicy.normalized(String(repeating: "x", count: 80)).count,
      64
    )
  }
}
