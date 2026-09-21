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
    /// The dogs this walk counted for. Two dogs on one leash walk is one walk, not two, so the
    /// miles are never double counted. Empty means "whoever lives here", which is what seeded
    /// and single-dog walks are.
    var dogIDs: [UUID] = []
    /// True when a photo of this walk is stored on the phone (`WalkPhotoStore`). Kept on the walk
    /// so the month grid can mark the days that have one without hitting the filesystem 31 times.
    var hasPhoto: Bool = false

    var miles: Double { distanceMeters / WalkPlan.metersPerMile }

    /// Did this walk count for that dog?
    func counted(for dogID: UUID) -> Bool {
        dogIDs.isEmpty || dogIDs.contains(dogID)
    }
}

/// One bar in the week chart on the home screen.
struct WeekDay: Identifiable, Equatable {
    let date: Date
    let minutes: Int
    let isToday: Bool
    let isFuture: Bool
    var id: Date { date }
}
