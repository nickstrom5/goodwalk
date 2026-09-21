import Foundation
import os

/// Every funnel event the business is judged on. Names are stable so the backend can change.
enum AnalyticsEvent: String {
    case appOpen = "app_open"
    case onboardingStarted = "onboarding_started"
    case onboardingStep = "onboarding_step"
    case onboardingCompleted = "onboarding_completed"
    case photoAdded = "photo_added"
    case remindersAuthorized = "reminders_authorized"
    case remindersDenied = "reminders_denied"
    case firstWalkLogged = "first_walk_logged"
    case firstWalkSkipped = "first_walk_skipped"
    case paywallShown = "paywall_shown"
    case paywallDismissed = "paywall_dismissed"
    case planSelected = "plan_selected"
    case trialStarted = "trial_started"
    case paid = "paid"
    case purchaseCancelled = "purchase_cancelled"
    case purchaseFailed = "purchase_failed"
    case restoreTapped = "restore_tapped"
    case storeLoadFailed = "store_load_failed"
    case walkStarted = "walk_started"
    case walkFinished = "walk_finished"
    case walkQuickLogged = "walk_quick_logged"
    case walkDeleted = "walk_deleted"
    case goalHit = "goal_hit"
    case milestoneReached = "milestone_reached"
    case shareTapped = "share_tapped"
    case supportTapped = "support_tapped"
    case liveActivityFailed = "live_activity_failed"
    case reminderTimeChanged = "reminder_time_changed"
    case dogAdded = "dog_added"
    case dogRemoved = "dog_removed"
    case dogSwitched = "dog_switched"
}

protocol AnalyticsSink {
    func track(_ event: AnalyticsEvent, _ properties: [String: Any])
}

/// `GoodWalkApp.init` installs the console sink plus PostHog when `Config.postHogKey` is set.
enum Analytics {
    static var sink: AnalyticsSink = ConsoleAnalytics()

    static func track(_ event: AnalyticsEvent, _ properties: [String: Any] = [:]) {
        sink.track(event, properties)
    }
}

struct ConsoleAnalytics: AnalyticsSink {
    private let log = Logger(subsystem: "app.getgoodwalk.goodwalk", category: "analytics")

    func track(_ event: AnalyticsEvent, _ properties: [String: Any]) {
        let props = properties.isEmpty ? "" : " \(properties)"
        log.info("\(event.rawValue, privacy: .public)\(props, privacy: .public)")
    }
}
