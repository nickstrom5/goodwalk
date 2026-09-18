import Foundation

/// Everything derived from the walk log. Recomputed whenever the log or the goal changes; never
/// stored, so it can't drift from the source of truth.
struct Stats: Equatable {
    /// Consecutive days with at least one walk.
    var streak = 0
    var longestStreak = 0
    var minutesToday = 0
    var walkCount = 0
    var daysWalked = 0
    /// Days the full target was hit.
    var goalDays = 0
    var totalMinutes = 0
    var totalMeters: Double = 0

    var totalMiles: Double { totalMeters / WalkPlan.metersPerMile }
    var totalHours: Double { Double(totalMinutes) / 60 }

    /// Streak lengths worth a card. Reached once each.
    static let milestones = [1, 3, 7, 14, 30, 60, 100, 365]

    static func compute(walks: [Walk], goalMinutes: Int, today: Date = Date(), calendar cal: Calendar = .current) -> Stats {
        var minutesByDay: [Date: Int] = [:]
        var stats = Stats()
        for walk in walks where walk.minutes > 0 {
            minutesByDay[cal.startOfDay(for: walk.start), default: 0] += walk.minutes
            stats.walkCount += 1
            stats.totalMinutes += walk.minutes
            stats.totalMeters += max(0, walk.distanceMeters)
        }
        let days = minutesByDay.keys.sorted()
        stats.daysWalked = days.count
        stats.goalDays = goalMinutes > 0 ? minutesByDay.values.filter { $0 >= goalMinutes }.count : 0

        let todayStart = cal.startOfDay(for: today)
        stats.minutesToday = minutesByDay[todayStart] ?? 0

        // Longest run of consecutive walked days anywhere in the log.
        var run = 0
        var previous: Date?
        for day in days {
            if let previous, let next = cal.date(byAdding: .day, value: 1, to: previous), cal.isDate(next, inSameDayAs: day) {
                run += 1
            } else {
                run = 1
            }
            stats.longestStreak = max(stats.longestStreak, run)
            previous = day
        }

        // Current streak: counts back from today if there's a walk today, else from yesterday,
        // so a morning with no walk yet doesn't zero the number before the evening walk.
        var cursor = todayStart
        if minutesByDay[cursor] == nil, let yesterday = cal.date(byAdding: .day, value: -1, to: cursor) {
            cursor = yesterday
        }
        while minutesByDay[cursor] != nil, let earlier = cal.date(byAdding: .day, value: -1, to: cursor) {
            stats.streak += 1
            cursor = earlier
        }
        return stats
    }

    // MARK: - Formatting

    /// "47" above 10 miles, "4.7" below. Nobody brags in decimals.
    static func miles(_ value: Double) -> String {
        value >= 10 ? String(Int(value.rounded())) : String(format: "%.1f", value)
    }

    /// "1h 05m" / "42 min".
    static func duration(minutes: Int) -> String {
        guard minutes >= 60 else { return "\(minutes) min" }
        return minutes % 60 == 0 ? "\(minutes / 60)h" : "\(minutes / 60)h \(String(format: "%02d", minutes % 60))m"
    }

    /// "12:07" / "1:02:07" for the live timer.
    static func clock(seconds: Int) -> String {
        let s = max(0, seconds)
        return s >= 3600
            ? String(format: "%d:%02d:%02d", s / 3600, (s % 3600) / 60, s % 60)
            : String(format: "%d:%02d", s / 60, s % 60)
    }
}
