import Combine
import CryptoKit
import Foundation

struct GitHubAsset: Decodable, Sendable {
    let name: String
    let browserDownloadURL: URL
    let digest: String?
    let size: Int?

    enum CodingKeys: String, CodingKey {
        case name
        case browserDownloadURL = "browser_download_url"
        case digest
        case size
    }
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
    @Published private(set) var isInstalling = false
    @Published private(set) var installationProgress: Double?

    let installedVersion: String

    init(bundle: Bundle = .main) {
        self.installedVersion = bundle.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String ?? "0.4.7"
        if let previous = UserDefaults.standard.string(forKey: "updateCompletedFrom") {
            statusMessage = "LockCode se actualizó correctamente de \(previous) a \(installedVersion)."
            UserDefaults.standard.removeObject(forKey: "updateCompletedFrom")
        }
    }

    nonisolated static func isTrustedReleaseURL(_ url: URL) -> Bool {
        url.scheme?.lowercased() == "https"
            && url.host?.lowercased() == "github.com"
            && url.path.hasPrefix("/D1abloo/LockAPP/")
    }

    nonisolated static func isTrustedAssetURL(_ url: URL) -> Bool {
        url.scheme?.lowercased() == "https"
            && url.host?.lowercased() == "github.com"
            && url.path.hasPrefix("/D1abloo/LockAPP/releases/download/")
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
            guard macOSAsset(in: release) != nil else {
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

    func installAvailableUpdate() async -> URL? {
        guard !isInstalling, updateAvailable, let release = latestRelease,
              let asset = macOSAsset(in: release),
              let expectedDigest = Self.sha256(from: asset.digest) else {
            statusMessage = "La actualización de macOS no incluye una firma SHA-256 válida."
            return nil
        }
        let currentApplication = Bundle.main.bundleURL.standardizedFileURL
        let bundleIdentifier = Bundle.main.bundleIdentifier
        guard currentApplication.pathExtension == "app",
              currentApplication.path.hasPrefix("/Applications/") else {
            statusMessage = "Para actualizar automáticamente, instala primero LockCode en /Applications."
            return nil
        }

        isInstalling = true
        installationProgress = nil
        statusMessage = "Descargando LockCode \(release.tagName)…"
        defer { isInstalling = false }

        do {
            let (archive, response) = try await URLSession.shared.download(from: asset.browserDownloadURL)
            guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                throw UpdateError.invalidDownload
            }
            installationProgress = 0.55
            statusMessage = "Verificando la descarga…"
            let installedURL = try await Task.detached(priority: .userInitiated) {
                try Self.install(
                    archive: archive,
                    expectedDigest: expectedDigest,
                    expectedVersion: release.tagName,
                    expectedBundleIdentifier: bundleIdentifier,
                    replacing: currentApplication
                )
            }.value
            installationProgress = 1
            UserDefaults.standard.set(installedVersion, forKey: "updateCompletedFrom")
            statusMessage = "Actualización instalada. Reiniciando LockCode…"
            return installedURL
        } catch {
            installationProgress = nil
            statusMessage = error.localizedDescription
            return nil
        }
    }

    private func macOSAsset(in release: GitHubRelease) -> GitHubAsset? {
        release.assets?.first {
            let name = $0.name.lowercased()
            return (name.contains("macos") || name.contains("mac-"))
                && name.hasSuffix(".zip")
                && Self.isTrustedAssetURL($0.browserDownloadURL)
        }
    }

    private nonisolated static func sha256(from value: String?) -> String? {
        guard let value, value.hasPrefix("sha256:") else { return nil }
        let digest = String(value.dropFirst("sha256:".count))
        return digest.count == 64 && digest.allSatisfy(\.isHexDigit) ? digest.lowercased() : nil
    }

    private nonisolated static func install(
        archive: URL,
        expectedDigest: String,
        expectedVersion: String,
        expectedBundleIdentifier: String?,
        replacing currentApplication: URL
    ) throws -> URL {
        let data = try Data(contentsOf: archive, options: .mappedIfSafe)
        let actualDigest = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        guard actualDigest == expectedDigest else { throw UpdateError.digestMismatch }

        let fileManager = FileManager.default
        let directory = fileManager.temporaryDirectory
            .appendingPathComponent("LockCode-update-\(UUID().uuidString)", isDirectory: true)
        defer { try? fileManager.removeItem(at: directory) }
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        try run("/usr/bin/ditto", arguments: ["-x", "-k", archive.path, directory.path])
        guard let application = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
        )?.compactMap({ $0 as? URL }).first(where: { $0.pathExtension == "app" }),
              let bundle = Bundle(url: application),
              bundle.bundleIdentifier == expectedBundleIdentifier,
              AppVersion(bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0")
                == AppVersion(expectedVersion) else {
            throw UpdateError.invalidApplication
        }
        try run("/usr/bin/codesign", arguments: ["--verify", "--deep", "--strict", application.path])

        let staged = currentApplication.deletingLastPathComponent()
            .appendingPathComponent(".LockCode-update-\(UUID().uuidString).app")
        let backup = currentApplication.deletingLastPathComponent()
            .appendingPathComponent(".LockCode-backup.app")
        try? fileManager.removeItem(at: backup)
        try fileManager.copyItem(at: application, to: staged)
        do {
            _ = try fileManager.replaceItemAt(
                currentApplication,
                withItemAt: staged,
                backupItemName: ".LockCode-backup.app",
                options: [.usingNewMetadataOnly]
            )
            try? fileManager.removeItem(at: backup)
        } catch {
            try? fileManager.removeItem(at: staged)
            throw UpdateError.cannotReplace
        }
        return currentApplication
    }

    private nonisolated static func run(_ executable: String, arguments: [String]) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { throw UpdateError.invalidApplication }
    }

    private enum UpdateError: LocalizedError {
        case invalidDownload, digestMismatch, invalidApplication, cannotReplace

        var errorDescription: String? {
            switch self {
            case .invalidDownload: "No se pudo descargar la actualización oficial."
            case .digestMismatch: "La firma SHA-256 de la actualización no coincide."
            case .invalidApplication: "El paquete descargado no contiene una copia válida y firmada de LockCode."
            case .cannotReplace: "macOS no permitió reemplazar LockCode. Comprueba que está en /Applications y pertenece a tu usuario."
            }
        }
    }
}
