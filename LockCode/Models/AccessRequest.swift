import Foundation

struct AccessRequest: Identifiable {
    enum Trigger {
        case launch
        case activation
    }

    enum ResumeAction {
        case reopen(URL)
        case activate(processIdentifier: pid_t, fallbackURL: URL?)
    }

    let id = UUID()
    let bundleIdentifier: String
    let applicationName: String
    let bundleURL: URL?
    let trigger: Trigger
    let resumeAction: ResumeAction
}
