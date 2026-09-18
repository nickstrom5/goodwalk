import Foundation

/// One walk, timed or quick-logged. Days with no walk don't exist; we only count what happened.
struct Walk: Codable, Equatable, Identifiable {
    enum Source: String, Codable {
        case timer, quickLog, notification, onboarding
    }

    var id = UUID()
    /// When the walk started (quick logs use the moment they were logged).
    var start: Date
    var minutes: Int
    var distanceMeters: Double
    /// True when the distance is a pace-based guess rather than a pedometer reading.
    var distanceEstimated: Bool
    var source: Source

    var miles: Double { distanceMeters / WalkPlan.metersPerMile }
}

/// One bar in the week chart on the home screen.
struct WeekDay: Identifiable, Equatable {
    let date: Date
    let minutes: Int
    let isToday: Bool
    let isFuture: Bool
    var id: Date { date }
}
