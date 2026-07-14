import Combine
import Foundation

@MainActor
final class AuditLogStore: ObservableObject {
    private static let storageKey = "auditEvents"
    private static let maximumEventCount = 200

    @Published private(set) var events: [AuditEvent]

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.storageKey),
           let storedEvents = try? PropertyListDecoder().decode([AuditEvent].self, from: data) {
            self.events = Array(storedEvents.prefix(Self.maximumEventCount))
        } else {
            self.events = []
        }
    }

    func record(_ kind: AuditEvent.Kind, at timestamp: Date = Date()) {
        events.insert(AuditEvent(kind: kind, timestamp: timestamp), at: 0)
        if events.count > Self.maximumEventCount {
            events.removeLast(events.count - Self.maximumEventCount)
        }
        persist()
    }

    func clear() {
        events.removeAll()
        defaults.removeObject(forKey: Self.storageKey)
    }

    private func persist() {
        guard let data = try? PropertyListEncoder().encode(events) else { return }
        defaults.set(data, forKey: Self.storageKey)
    }
}
