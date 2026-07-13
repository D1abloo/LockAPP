import CommonCrypto
import Foundation
import Security

struct PINCredential: Codable, Equatable {
    static let currentVersion = 1

    let version: Int
    let salt: Data
    let derivedKey: Data
    let rounds: UInt32
}

enum PINCredentialError: LocalizedError {
    case randomGenerationFailed(OSStatus)
    case keyDerivationFailed(Int32)

    var errorDescription: String? {
        switch self {
        case .randomGenerationFailed:
            return "No se pudo generar una credencial segura para el código."
        case .keyDerivationFailed:
            return "No se pudo proteger el código."
        }
    }
}

/// Produces a salted, deliberately expensive representation of the PIN. The
/// Keychain stores this record, never the PIN itself.
struct PINCredentialHasher {
    static let defaultRounds: UInt32 = 210_000

    private let rounds: UInt32
    private let saltByteCount = 16
    private let derivedKeyByteCount = 32

    init(rounds: UInt32 = defaultRounds) {
        self.rounds = rounds
    }

    func makeCredential(for pin: String) throws -> PINCredential {
        var salt = Data(count: saltByteCount)
        let status = salt.withUnsafeMutableBytes { bytes in
            SecRandomCopyBytes(kSecRandomDefault, saltByteCount, bytes.baseAddress!)
        }
        guard status == errSecSuccess else {
            throw PINCredentialError.randomGenerationFailed(status)
        }

        return PINCredential(
            version: PINCredential.currentVersion,
            salt: salt,
            derivedKey: try deriveKey(pin: pin, salt: salt, rounds: rounds),
            rounds: rounds
        )
    }

    func verify(_ pin: String, against credential: PINCredential) -> Bool {
        guard credential.version == PINCredential.currentVersion,
              credential.rounds > 0,
              let candidate = try? deriveKey(
                  pin: pin,
                  salt: credential.salt,
                  rounds: credential.rounds
              ) else {
            return false
        }
        return constantTimeEqual(candidate, credential.derivedKey)
    }

    private func deriveKey(pin: String, salt: Data, rounds: UInt32) throws -> Data {
        var derivedKey = Data(count: derivedKeyByteCount)
        let result = pin.withCString { password in
            salt.withUnsafeBytes { saltBytes in
                derivedKey.withUnsafeMutableBytes { derivedKeyBytes in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        password,
                        pin.utf8.count,
                        saltBytes.bindMemory(to: UInt8.self).baseAddress,
                        salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                        rounds,
                        derivedKeyBytes.bindMemory(to: UInt8.self).baseAddress,
                        derivedKeyByteCount
                    )
                }
            }
        }
        guard result == kCCSuccess else {
            throw PINCredentialError.keyDerivationFailed(result)
        }
        return derivedKey
    }

    func constantTimeEqual(_ lhs: Data, _ rhs: Data) -> Bool {
        guard lhs.count == rhs.count else { return false }
        var difference: UInt8 = 0
        for (left, right) in zip(lhs, rhs) {
            difference |= left ^ right
        }
        return difference == 0
    }
}
