import Foundation

struct AuditEvent: Codable, Equatable, Identifiable {
    enum Kind: String, Codable {
        case unlocked
        case failedAttempt

        var title: String {
            switch self {
            case .unlocked: return "Aplicación desbloqueada"
            case .failedAttempt: return "Intento fallido"
            }
        }

        var systemImage: String {
            switch self {
            case .unlocked: return "lock.open.fill"
            case .failedAttempt: return "exclamationmark.lock.fill"
            }
        }
    }

    let id: UUID
    let kind: Kind
    let timestamp: Date

    init(id: UUID = UUID(), kind: Kind, timestamp: Date = Date()) {
        self.id = id
        self.kind = kind
        self.timestamp = timestamp
    }
}
