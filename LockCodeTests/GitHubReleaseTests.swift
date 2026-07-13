import Foundation
import XCTest

@testable import LockCode

final class GitHubReleaseTests: XCTestCase {
    func testDecodesLatestReleaseResponse() throws {
        let payload = Data(#"""
        {
            "tag_name": "v0.2.0",
            "name": "LockCode 0.2.0",
            "body": "Mejoras de seguridad",
            "html_url": "https://github.com/D1abloo/LockAPP/releases/tag/v0.2.0",
            "published_at": "2026-07-14T12:00:00Z"
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
    }
}
