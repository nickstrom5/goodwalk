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
    /// The time zone the walk was logged in, so it stays on the day it was walked after the phone
    /// changes zone. Nil on walks logged before it was kept; those follow the phone's zone.
    var timeZoneID: String?

    var miles: Double { distanceMeters / WalkPlan.metersPerMile }

    /// Did this walk count for that dog?
    func counted(for dogID: UUID) -> Bool {
        dogIDs.isEmpty || dogIDs.contains(dogID)
    }

    /// The day this walk belongs to, as the start of that day in `cal`: the calendar day where it
    /// was walked, not the one the phone is in now.
    func day(in cal: Calendar) -> Date {
        guard let timeZoneID, timeZoneID != cal.timeZone.identifier,
              let zone = TimeZone(identifier: timeZoneID) else { return cal.startOfDay(for: start) }
        let walked = cal.dateComponents(in: zone, from: start)
        var day = DateComponents(era: walked.era, year: walked.year, month: walked.month, day: walked.day)
        day.isLeapMonth = walked.isLeapMonth   // Chinese and Korean years can repeat a month; keep which one
        return cal.date(from: day).map(cal.startOfDay(for:)) ?? cal.startOfDay(for: start)
    }

    /// The start time as the clock read where the walk was logged, so after a flight it agrees
    /// with the day the walk is filed under. Walks with no stored zone show the phone's time.
    var startTime: String {
        let zone = timeZoneID.flatMap(TimeZone.init(identifier:)) ?? .autoupdatingCurrent
        return start.formatted(Date.FormatStyle(date: .omitted, time: .shortened, timeZone: zone))
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

// Decoded by hand so walks saved by an older build still load. The synthesized decoder throws
// on a missing key even when the property has a default, and one bad walk fails the whole log.
extension Walk {
    enum CodingKeys: String, CodingKey {
        case id, start, minutes, distanceMeters, distanceEstimated, source, dogIDs, hasPhoto
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let minutes = try c.decode(Int.self, forKey: .minutes)
        self.init(id: try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID(),
                  start: try c.decode(Date.self, forKey: .start),
                  minutes: minutes,
                  distanceMeters: try c.decodeIfPresent(Double.self, forKey: .distanceMeters)
                      ?? WalkPlan.estimatedMeters(forMinutes: minutes),
                  distanceEstimated: try c.decodeIfPresent(Bool.self, forKey: .distanceEstimated) ?? true,
                  source: (try? c.decodeIfPresent(Source.self, forKey: .source)) ?? .quickLog,
                  dogIDs: try c.decodeIfPresent([UUID].self, forKey: .dogIDs) ?? [],
                  hasPhoto: try c.decodeIfPresent(Bool.self, forKey: .hasPhoto) ?? false)
    }
}
