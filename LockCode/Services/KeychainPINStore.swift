import Foundation
import LocalAuthentication
import Security

enum KeychainPINStoreError: LocalizedError {
    case invalidEncoding
    case unexpectedStatus(OSStatus)

    var errorDescription: String? {
        switch self {
        case .invalidEncoding:
            return "No se pudo codificar el código."
        case .unexpectedStatus(let status):
            return "Keychain devolvió el error \(status)."
        }
    }
}

final class KeychainPINStore {
    static let defaultService = "LockCode"

    private let service: String
    private let legacyServices: [String]
    private let account = "primary-pin"
    private let encoder = PropertyListEncoder()
    private let decoder = PropertyListDecoder()
    private let hasher: PINCredentialHasher

    init(
        service: String = KeychainPINStore.defaultService,
        legacyServices: [String] = ["com.example.LockCode"],
        hasher: PINCredentialHasher = PINCredentialHasher()
    ) {
        self.service = service
        self.legacyServices = legacyServices
        self.hasher = hasher
    }

    var hasPIN: Bool {
        (try? readPINData()) != nil
    }

    func save(pin: String) throws {
        let credential = try hasher.makeCredential(for: pin)
        let data = try encoder.encode(credential)
        try save(data: data, service: service)
    }

    private func save(data: Data, service: String) throws {
        let baseQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrLabel as String: "LockCode",
            kSecAttrDescription as String: "Código de acceso de LockCode",
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let updateStatus = SecItemUpdate(baseQuery as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess {
            return
        }

        guard updateStatus == errSecItemNotFound else {
            throw KeychainPINStoreError.unexpectedStatus(updateStatus)
        }

        var addQuery = baseQuery
        attributes.forEach { addQuery[$0.key] = $0.value }
        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw KeychainPINStoreError.unexpectedStatus(addStatus)
        }
    }

    func validate(pin: String) -> Bool {
        guard let stored = try? readPINData() else {
            return false
        }

        if let credential = try? decoder.decode(PINCredential.self, from: stored) {
            return hasher.verify(pin, against: credential)
        }

        // Migrate credentials produced by the earliest MVP builds. The legacy
        // value is replaced immediately after the first successful validation.
        guard let candidate = pin.data(using: .utf8),
              hasher.constantTimeEqual(candidate, stored) else {
            return false
        }
        do {
            try save(pin: pin)
            return true
        } catch {
            return false
        }
    }

    func delete() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainPINStoreError.unexpectedStatus(status)
        }
    }

    private func readPINData() throws -> Data {
        do {
            return try readPINData(service: service)
        } catch KeychainPINStoreError.unexpectedStatus(let status)
            where status == errSecItemNotFound {
            for legacyService in legacyServices where legacyService != service {
                guard let data = try? readPINData(
                    service: legacyService,
                    allowAuthenticationUI: false
                ) else { continue }
                try save(data: data, service: service)
                let legacyQuery: [String: Any] = [
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrService as String: legacyService,
                    kSecAttrAccount as String: account
                ]
                _ = SecItemDelete(legacyQuery as CFDictionary)
                return data
            }
            throw KeychainPINStoreError.unexpectedStatus(status)
        }
    }

    private func readPINData(
        service: String,
        allowAuthenticationUI: Bool = true
    ) throws -> Data {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        if !allowAuthenticationUI {
            let context = LAContext()
            context.interactionNotAllowed = true
            query[kSecUseAuthenticationContext as String] = context
        }

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else {
            throw KeychainPINStoreError.unexpectedStatus(status)
        }
        guard let data = result as? Data else {
            throw KeychainPINStoreError.invalidEncoding
        }
        return data
    }
}
