import Foundation

struct InstalledApplication: Identifiable, Hashable, Codable, Sendable {
    let bundleIdentifier: String
    let displayName: String
    let bundleURL: URL

    var id: String { bundleIdentifier }
}
