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

    // MARK: - The household

    /// Stats for the whole house when there is more than one dog. The streak is the household's:
    /// a day counts when every dog who lived here that day got a walk. One dog missed is a day
    /// missed, which is the only reading that keeps the promise honest; "any dog walked" would
    /// let a dog be skipped for a month behind a healthy-looking number.
    ///
    /// Totals count each walk once, however many dogs were on it. Walking two dogs around the
    /// block is one mile, not two.
    struct Household: Equatable {
        var streak = 0
        var longestStreak = 0
        var walkCount = 0
        var daysWalked = 0
        var completeDays = 0
        var totalMinutes = 0
        var totalMeters: Double = 0
        /// Dogs with at least one walk today, out of the dogs who live here.
        var dogsWalkedToday = 0
        var dogCount = 0

        var totalMiles: Double { totalMeters / WalkPlan.metersPerMile }
        var totalHours: Double { Double(totalMinutes) / 60 }
        /// True when every dog has walked today.
        var everyoneWalkedToday: Bool { dogCount > 0 && dogsWalkedToday >= dogCount }

        static func compute(dogs: [DogProfile], walks: [Walk],
                            today: Date = Date(), calendar cal: Calendar = .current) -> Household {
            var household = Household()
            household.dogCount = dogs.count
            guard !dogs.isEmpty else { return household }

            // Which dogs walked on each day, and the totals, in one pass.
            var dogsByDay: [Date: Set<UUID>] = [:]
            for walk in walks where walk.minutes > 0 {
                let day = cal.startOfDay(for: walk.start)
                let walked = walk.dogIDs.isEmpty ? dogs.map(\.id) : walk.dogIDs
                dogsByDay[day, default: []].formUnion(walked)
                household.walkCount += 1
                household.totalMinutes += walk.minutes
                household.totalMeters += max(0, walk.distanceMeters)
            }
            household.daysWalked = dogsByDay.count

            let todayStart = cal.startOfDay(for: today)
            let walkedToday = dogsByDay[todayStart] ?? []
            household.dogsWalkedToday = dogs.filter { walkedToday.contains($0.id) }.count

            /// Every dog who already lived here that day got a walk.
            func complete(_ day: Date) -> Bool {
                let expected = dogs.filter { $0.existed(on: day, calendar: cal) }
                guard !expected.isEmpty else { return false }
                let walked = dogsByDay[day] ?? []
                return expected.allSatisfy { walked.contains($0.id) }
            }

            let completeDays = dogsByDay.keys.filter(complete).sorted()
            household.completeDays = completeDays.count

            // Longest run of consecutive complete days anywhere in the log.
            var run = 0
            var previous: Date?
            for day in completeDays {
                if let previous, let next = cal.date(byAdding: .day, value: 1, to: previous),
                   cal.isDate(next, inSameDayAs: day) {
                    run += 1
                } else {
                    run = 1
                }
                household.longestStreak = max(household.longestStreak, run)
                previous = day
            }

            // Current streak, counting back. A day that isn't finished yet doesn't break it:
            // if today is still short a dog, start from yesterday, same as the single-dog rule.
            let completeSet = Set(completeDays)
            var cursor = todayStart
            if !completeSet.contains(cursor), let yesterday = cal.date(byAdding: .day, value: -1, to: cursor) {
                cursor = yesterday
            }
            while completeSet.contains(cursor), let earlier = cal.date(byAdding: .day, value: -1, to: cursor) {
                household.streak += 1
                cursor = earlier
            }
            return household
        }
    }

    // MARK: - Formatting

    /// "47" above 10 miles, "4.7" below. Nobody brags in decimals.
    static func miles(_ value: Double) -> String {
        value >= 10 ? String(Int(value.rounded())) : String(format: "%.1f", value)
    }

    /// "1 mile", "1.8 miles", "12 miles". Exactly one mile drops the decimal, because
    /// "1.0 mile" reads like a machine wrote it.
    static func milesPhrase(_ value: Double) -> String {
        let text = miles(value)
        if text == "1.0" || text == "1" { return "1 mile" }
        return "\(text) miles"
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
