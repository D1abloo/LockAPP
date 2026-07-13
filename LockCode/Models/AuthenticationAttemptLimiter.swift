import Foundation

struct AuthenticationAttemptLimiter {
    private(set) var failedAttempts = 0
    private(set) var lockedUntil: Date?

    mutating func canAttempt(at date: Date = Date()) -> Bool {
        guard let lockedUntil else { return true }
        if date >= lockedUntil {
            self.lockedUntil = nil
            return true
        }
        return false
    }

    mutating func recordFailure(at date: Date = Date()) {
        failedAttempts += 1
        guard let delay = lockoutDelay else { return }
        lockedUntil = date.addingTimeInterval(delay)
    }

    mutating func recordSuccess() {
        failedAttempts = 0
        lockedUntil = nil
    }

    func retryAfter(at date: Date = Date()) -> TimeInterval? {
        guard let lockedUntil, lockedUntil > date else { return nil }
        return lockedUntil.timeIntervalSince(date)
    }

    private var lockoutDelay: TimeInterval? {
        switch failedAttempts {
        case 0...2: return nil
        case 3...4: return 5
        case 5...6: return 30
        default: return 300
        }
    }
}
