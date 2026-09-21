import Foundation

/// Build-time configuration. Nothing here is secret: PostHog project keys are write-only and
/// ship inside every mobile app that uses them.
enum Config {
    /// PostHog project API key (starts with "phc_"). Empty = analytics logs to the console only.
    /// Get one at https://posthog.com (free tier is plenty for launch), paste it here.
    static let postHogKey = ""

    /// PostHog ingestion host. US cloud by default; use "https://eu.i.posthog.com" for the EU cloud.
    static let postHogHost = "https://us.i.posthog.com"

    static var analyticsEnabled: Bool { !postHogKey.isEmpty }

    static let site = "https://getgoodwalk.app"
    static let privacyURL = URL(string: "\(site)/privacy.html")!
    static let termsURL = URL(string: "\(site)/terms.html")!
    static let supportEmail = "support@getgoodwalk.app"

    // MARK: - The wall of dogs

    /// Instagram handle, without the @. Empty until the account exists, which keeps every mention
    /// of it out of the app: a share sheet must never point at a handle that isn't there.
    /// Set it to "goodwalkapp" (see `playbook/11-social-kit.md`) once the account is claimed.
    static let instagramHandle = ""

    /// The tag that collects shared walks. Short enough to type after a walk, and ours: the
    /// generic dog tags are for reach, this one is for finding the dogs that use the app.
    static let shareTag = "#agoodwalk"

    static var socialEnabled: Bool { !instagramHandle.isEmpty }

    static var instagramURL: URL? {
        guard socialEnabled else { return nil }
        return URL(string: "https://instagram.com/\(instagramHandle)")
    }

    /// Appended to every share sheet's text, so a card posted anywhere carries the tag home.
    /// Empty string until the account exists, so the copy simply ends where it did before.
    static var shareCredit: String {
        socialEnabled ? " \(shareTag) @\(instagramHandle)" : ""
    }
}
