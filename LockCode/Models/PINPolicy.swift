import Foundation

enum PINPolicy {
    static let validLength = 4...64

    static func normalized(_ candidate: String) -> String {
        String(candidate.filter { character in
            !character.unicodeScalars.contains { CharacterSet.controlCharacters.contains($0) }
        }.prefix(validLength.upperBound))
    }

    static func isValid(_ candidate: String) -> Bool {
        validLength.contains(candidate.count)
            && normalized(candidate) == candidate
    }
}
