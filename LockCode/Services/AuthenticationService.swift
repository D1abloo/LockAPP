import Foundation
import LocalAuthentication

enum AuthenticationError: LocalizedError {
    case invalidPINFormat
    case biometricsUnavailable
    case authenticationFailed

    var errorDescription: String? {
        switch self {
        case .invalidPINFormat:
            return "El código debe contener entre 4 y 64 caracteres. Puedes usar letras, números, espacios y símbolos."
        case .biometricsUnavailable:
            return "Touch ID no está disponible."
        case .authenticationFailed:
            return "No se pudo verificar tu identidad."
        }
    }
}

@MainActor
final class AuthenticationService {
    private let pinStore: KeychainPINStore
    private var attemptLimiter = AuthenticationAttemptLimiter()

    init(pinStore: KeychainPINStore) {
        self.pinStore = pinStore
    }

    var hasPIN: Bool { pinStore.hasPIN }

    func setPIN(_ pin: String) throws {
        guard PINPolicy.isValid(pin) else {
            throw AuthenticationError.invalidPINFormat
        }
        try pinStore.save(pin: pin)
        attemptLimiter.recordSuccess()
    }

    func validatePIN(_ pin: String) -> Bool {
        let now = Date()
        guard attemptLimiter.canAttempt(at: now), PINPolicy.isValid(pin) else {
            return false
        }

        let valid = pinStore.validate(pin: pin)
        if valid {
            attemptLimiter.recordSuccess()
        } else {
            attemptLimiter.recordFailure(at: now)
        }
        return valid
    }

    func pinFailureMessage() -> String {
        if let retryAfter = attemptLimiter.retryAfter() {
            return "Demasiados intentos. Espera \(Int(ceil(retryAfter))) segundos."
        }
        return "Código incorrecto."
    }

    func canUseBiometrics() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    func authenticateWithBiometrics(reason: String) async throws {
        let context = LAContext()
        context.localizedCancelTitle = "Usar código"
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw AuthenticationError.biometricsUnavailable
        }

        let success = try await context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: reason
        )
        guard success else {
            throw AuthenticationError.authenticationFailed
        }
        attemptLimiter.recordSuccess()
    }
}
