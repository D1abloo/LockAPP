import Combine
import Foundation

struct GitHubAsset: Decodable, Sendable {
    let name: String
}

struct GitHubRelease: Decodable, Sendable {
    let tagName: String
    let name: String?
    let body: String?
    let htmlURL: URL
    let publishedAt: Date?
    let assets: [GitHubAsset]?

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name
        case body
        case htmlURL = "html_url"
        case publishedAt = "published_at"
        case assets
    }
}

@MainActor
final class UpdateService: ObservableObject {
    @Published private(set) var isChecking = false
    @Published private(set) var latestRelease: GitHubRelease?
    @Published private(set) var statusMessage = "Comprueba si hay una nueva versión disponible."
    @Published private(set) var updateAvailable = false

    let installedVersion: String

    init(bundle: Bundle = .main) {
        self.installedVersion = bundle.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String ?? "0.3.1"
    }

    nonisolated static func isTrustedReleaseURL(_ url: URL) -> Bool {
        url.scheme?.lowercased() == "https"
            && url.host?.lowercased() == "github.com"
            && url.path.hasPrefix("/D1abloo/LockAPP/")
    }

    func checkForUpdates() async {
        guard !isChecking else { return }
        isChecking = true
        defer { isChecking = false }

        guard let url = URL(
            string: "https://api.github.com/repos/D1abloo/LockAPP/releases/latest"
        ) else {
            statusMessage = "No se pudo preparar la consulta de actualizaciones."
            return
        }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.setValue("LockCode/\(installedVersion)", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else {
                statusMessage = "GitHub devolvió una respuesta no válida."
                return
            }

            if response.statusCode == 404 {
                latestRelease = nil
                updateAvailable = false
                statusMessage = "Todavía no hay versiones publicadas en GitHub."
                return
            }

            guard response.statusCode == 200 else {
                statusMessage = "No se pudo consultar GitHub (HTTP \(response.statusCode))."
                return
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let release = try decoder.decode(GitHubRelease.self, from: data)
            guard Self.isTrustedReleaseURL(release.htmlURL) else {
                latestRelease = nil
                updateAvailable = false
                statusMessage = "GitHub devolvió un enlace de actualización no válido."
                return
            }
            guard release.assets?.contains(where: {
                let name = $0.name.lowercased()
                return (name.contains("macos") || name.contains("mac-"))
                    && (name.hasSuffix(".zip") || name.hasSuffix(".dmg"))
            }) == true else {
                latestRelease = nil
                updateAvailable = false
                statusMessage = "La versión publicada todavía no incluye LockCode para macOS."
                return
            }
            latestRelease = release
            updateAvailable = AppVersion(installedVersion) < AppVersion(release.tagName)
            statusMessage = updateAvailable
                ? "LockCode \(installedVersion) puede actualizarse a \(release.tagName)."
                : "LockCode está actualizado."
        } catch {
            statusMessage = "No se pudo comprobar la actualización. Revisa tu conexión."
        }
    }
}
