import ActivityKit
import Foundation

/// Live Activity payload for a walk in progress. Shown on the Lock Screen and in the Dynamic
/// Island, and on iPhone Duo in the outer display's status bar while the phone is folded in a
/// pocket. The system renders the running time from `startDate`, so no updates are needed.
struct WalkActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        /// Minutes already walked today before this walk started.
        var minutesBeforeThisWalk: Int
        /// Today's target in minutes.
        var goalMinutes: Int
    }

    var dogName: String
    var startDate: Date
}
