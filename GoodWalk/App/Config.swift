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

    static let site = "https://goodwalk.app"
    static let privacyURL = URL(string: "\(site)/privacy.html")!
    static let termsURL = URL(string: "\(site)/terms.html")!
    static let supportEmail = "support@goodwalk.app"
}
