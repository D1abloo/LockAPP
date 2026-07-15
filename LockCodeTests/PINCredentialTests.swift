import Foundation
import XCTest

@testable import LockCode

final class PINCredentialTests: XCTestCase {
    func testKeychainUsesBrandedServiceName() {
        XCTAssertEqual(KeychainPINStore.defaultService, "LockCode")
    }

    func testCredentialVerifiesOnlyOriginalPIN() throws {
        let hasher = PINCredentialHasher(rounds: 1_000)
        let credential = try hasher.makeCredential(for: "1234")

        XCTAssertTrue(hasher.verify("1234", against: credential))
        XCTAssertFalse(hasher.verify("1235", against: credential))
    }

    func testEncodedCredentialDoesNotContainPlaintextPIN() throws {
        let pin = "8675309"
        let credential = try PINCredentialHasher(rounds: 1_000).makeCredential(for: pin)
        let encoded = try PropertyListEncoder().encode(credential)

        XCTAssertNotEqual(encoded, Data(pin.utf8))
        XCTAssertNil(encoded.range(of: Data(pin.utf8)))
    }
}
