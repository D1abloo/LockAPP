import Foundation

enum UnlockDuration: Int, CaseIterable, Codable, Identifiable {
    case everyTime = 0
    case oneMinute = 60
    case fiveMinutes = 300
    case fifteenMinutes = 900
    case thirtyMinutes = 1_800
    case custom = -1

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .everyTime: return "Al cerrar la aplicación"
        case .oneMinute: return "1 minuto"
        case .fiveMinutes: return "5 minutos"
        case .fifteenMinutes: return "15 minutos"
        case .thirtyMinutes: return "30 minutos"
        case .custom: return "Minutos personalizados"
        }
    }

    var keepsAccessUntilApplicationCloses: Bool {
        self == .everyTime
    }

    func graceInterval(customMinutes: Int) -> TimeInterval? {
        switch self {
        case .everyTime:
            return nil
        case .custom:
            return TimeInterval(min(max(customMinutes, 1), 1_440) * 60)
        default:
            return TimeInterval(rawValue)
        }
    }
}
