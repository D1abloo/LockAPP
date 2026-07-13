import Foundation

enum PINPolicy {
    static let validLength = 4...16

    static func normalized(_ candidate: String) -> String {
        String(candidate.filter { $0.isLetter || $0.isNumber }.prefix(validLength.upperBound))
    }

    static func isValid(_ candidate: String) -> Bool {
        validLength.contains(candidate.count)
            && candidate.allSatisfy { $0.isLetter || $0.isNumber }
    }
}
