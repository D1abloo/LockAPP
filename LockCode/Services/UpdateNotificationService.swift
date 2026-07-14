import AppKit
import Foundation
@preconcurrency import UserNotifications

@MainActor
final class UpdateNotificationService: NSObject, UNUserNotificationCenterDelegate {
    private enum Identifier {
        static let category = "LOCKCODE_UPDATE_AVAILABLE"
        static let open = "LOCKCODE_UPDATE_YES"
        static let dismiss = "LOCKCODE_UPDATE_NO"
        static let releaseURL = "releaseURL"
        static let lastNotifiedTag = "lastNotifiedUpdateTag"
        static let lastNotifiedAt = "lastNotifiedUpdateDate"
    }

    private let center: UNUserNotificationCenter
    private let defaults: UserDefaults

    init(
        center: UNUserNotificationCenter = .current(),
        defaults: UserDefaults = .standard
    ) {
        self.center = center
        self.defaults = defaults
        super.init()
        center.delegate = self

        let open = UNNotificationAction(
            identifier: Identifier.open,
            title: "Sí, actualizar",
            options: [.foreground]
        )
        let dismiss = UNNotificationAction(
            identifier: Identifier.dismiss,
            title: "No ahora",
            options: []
        )
        center.setNotificationCategories([
            UNNotificationCategory(
                identifier: Identifier.category,
                actions: [open, dismiss],
                intentIdentifiers: [],
                options: [.customDismissAction]
            )
        ])
    }

    func notifyIfNeeded(for release: GitHubRelease) async {
        guard UpdateService.isTrustedReleaseURL(release.htmlURL) else {
            return
        }
        if defaults.string(forKey: Identifier.lastNotifiedTag) == release.tagName,
           let lastNotifiedAt = defaults.object(forKey: Identifier.lastNotifiedAt) as? Date,
           Date().timeIntervalSince(lastNotifiedAt) < 86_400 {
            return
        }

        do {
            let authorized = try await center.requestAuthorization(options: [.alert, .sound])
            guard authorized else { return }

            let content = UNMutableNotificationContent()
            content.title = "Actualización de LockCode disponible"
            content.body = "Está disponible la versión \(release.tagName). ¿Quieres abrir la página para actualizar?"
            content.sound = .default
            content.categoryIdentifier = Identifier.category
            content.userInfo = [Identifier.releaseURL: release.htmlURL.absoluteString]

            try await center.add(UNNotificationRequest(
                identifier: "lockcode-update-\(release.tagName)",
                content: content,
                trigger: nil
            ))
            defaults.set(release.tagName, forKey: Identifier.lastNotifiedTag)
            defaults.set(Date(), forKey: Identifier.lastNotifiedAt)
        } catch {
            // A denied or unavailable notification must never interrupt protection.
        }
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let actionIdentifier = response.actionIdentifier
        let urlString = response.notification.request.content.userInfo[Identifier.releaseURL]
            as? String
        completionHandler()

        guard actionIdentifier == Identifier.open,
              let urlString,
              let url = URL(string: urlString),
              UpdateService.isTrustedReleaseURL(url) else {
            return
        }
        Task { @MainActor in
            NSWorkspace.shared.open(url)
        }
    }
}
