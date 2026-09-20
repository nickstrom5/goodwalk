import ActivityKit
import Foundation

/// Starts and ends the walk Live Activity. Best-effort: a walk works exactly the same when Live
/// Activities are switched off or unavailable.
@MainActor
enum WalkActivityController {
    /// Longest a walk timer is shown for. The timer text needs an end date; nobody walks 8 hours.
    static let maximumDuration: TimeInterval = 8 * 60 * 60

    static func start(dogName: String, startDate: Date, minutesBeforeThisWalk: Int, goalMinutes: Int) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled, !ScreenshotMode.isActive, !isUnitTesting else { return }
        // One walk at a time. If the app was killed mid-walk the old activity is still running; keep it.
        if Activity<WalkActivityAttributes>.activities.contains(where: { $0.attributes.startDate == startDate }) { return }
        endAll()
        let attributes = WalkActivityAttributes(dogName: dogName.isEmpty ? "your dog" : dogName, startDate: startDate)
        let state = WalkActivityAttributes.ContentState(minutesBeforeThisWalk: minutesBeforeThisWalk, goalMinutes: goalMinutes)
        do {
            _ = try Activity.request(
                attributes: attributes,
                content: ActivityContent(state: state, staleDate: startDate.addingTimeInterval(maximumDuration)),
                pushType: nil
            )
        } catch {
            Analytics.track(.liveActivityFailed, ["error": String(describing: error)])
        }
    }

    /// Unit tests start and finish walks constantly; they must not spawn real activities.
    private static var isUnitTesting: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    static func endAll() {
        let running = Activity<WalkActivityAttributes>.activities
        guard !running.isEmpty else { return }
        Task {
            for activity in running {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }
}
