import Foundation
import XCTest

@testable import LockCode

final class GitHubReleaseTests: XCTestCase {
    func testOnlyOfficialRepositoryReleaseURLsAreTrusted() {
        XCTAssertTrue(UpdateService.isTrustedReleaseURL(
            URL(string: "https://github.com/D1abloo/LockAPP/releases/tag/v0.3.0")!
        ))
        XCTAssertFalse(UpdateService.isTrustedReleaseURL(
            URL(string: "http://github.com/D1abloo/LockAPP/releases/tag/v0.3.0")!
        ))
        XCTAssertFalse(UpdateService.isTrustedReleaseURL(
            URL(string: "https://example.com/D1abloo/LockAPP/releases/tag/v0.3.0")!
        ))
        XCTAssertTrue(UpdateService.isTrustedAssetURL(
            URL(string: "https://github.com/D1abloo/LockAPP/releases/download/v0.4.4/LockCode-macOS-0.4.4.zip")!
        ))
        XCTAssertFalse(UpdateService.isTrustedAssetURL(
            URL(string: "https://example.com/D1abloo/LockAPP/releases/download/v0.4.4/LockCode.zip")!
        ))
    }

    func testDecodesLatestReleaseResponse() throws {
        let payload = Data(#"""
        {
            "tag_name": "v0.2.0",
            "name": "LockCode 0.2.0",
            "body": "Mejoras de seguridad",
            "html_url": "https://github.com/D1abloo/LockAPP/releases/tag/v0.2.0",
            "published_at": "2026-07-14T12:00:00Z",
            "assets": [{
                "name": "LockCode-macOS-0.2.0.zip",
                "browser_download_url": "https://github.com/D1abloo/LockAPP/releases/download/v0.2.0/LockCode-macOS-0.2.0.zip",
                "digest": "sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
                "size": 1234
            }]
        }
        """#.utf8)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let release = try decoder.decode(GitHubRelease.self, from: payload)

        XCTAssertEqual(release.tagName, "v0.2.0")
        XCTAssertEqual(release.name, "LockCode 0.2.0")
        XCTAssertEqual(
            release.htmlURL.absoluteString,
            "https://github.com/D1abloo/LockAPP/releases/tag/v0.2.0"
        )
        XCTAssertNotNil(release.publishedAt)
        XCTAssertEqual(release.assets?.first?.name, "LockCode-macOS-0.2.0.zip")
    }
}
