import Foundation

struct AppCatalogService: Sendable {
    func loadInstalledApplications(excluding excludedBundleIdentifiers: Set<String>) async -> [InstalledApplication] {
        await Task.detached(priority: .utility) {
            Self.scanInstalledApplications(excluding: excludedBundleIdentifiers)
        }.value
    }

    private static func scanInstalledApplications(
        excluding excludedBundleIdentifiers: Set<String>
    ) -> [InstalledApplication] {
        let fileManager = FileManager.default
        let homeApplications = fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Applications")
        let roots = [
            URL(fileURLWithPath: "/Applications", isDirectory: true),
            URL(fileURLWithPath: "/System/Applications", isDirectory: true),
            homeApplications
        ]

        var applicationsByBundleIdentifier: [String: InstalledApplication] = [:]
        let resourceKeys: [URLResourceKey] = [.isDirectoryKey, .isPackageKey]

        for root in roots where fileManager.fileExists(atPath: root.path) {
            guard let enumerator = fileManager.enumerator(
                at: root,
                includingPropertiesForKeys: resourceKeys,
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) else { continue }

            for case let url as URL in enumerator where url.pathExtension.lowercased() == "app" {
                guard let bundle = Bundle(url: url),
                      let identifier = bundle.bundleIdentifier,
                      !excludedBundleIdentifiers.contains(identifier) else {
                    continue
                }

                let displayName = (bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
                    ?? (bundle.object(forInfoDictionaryKey: "CFBundleName") as? String)
                    ?? url.deletingPathExtension().lastPathComponent

                applicationsByBundleIdentifier[identifier] = InstalledApplication(
                    bundleIdentifier: identifier,
                    displayName: displayName,
                    bundleURL: url
                )
            }
        }

        return applicationsByBundleIdentifier.values.sorted {
            $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
        }
    }
}
