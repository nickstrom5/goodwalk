import Foundation

/// One cell in the month grid. `date` is nil for the blanks that pad the first week.
struct MonthDay: Identifiable, Equatable {
    let index: Int
    let date: Date?
    /// Day of the month, resolved with the same calendar the grid was built with. Reading it back
    /// off `date` with `Calendar.current` would shift the number whenever the two disagree.
    let dayNumber: Int?
    let minutes: Int
    let hitGoal: Bool
    let isToday: Bool
    let isFuture: Bool

    /// Namespaced so it cannot collide with the weekday-header cells that share the grid.
    var id: String { "day-\(index)" }
    var walked: Bool { minutes > 0 }
}

/// A calendar month of walking, derived from the log. Like `Stats`, nothing here is stored:
/// it is rebuilt from `walks` so it can never drift from what actually happened.
struct MonthSummary: Equatable {
    var monthStart: Date
    var days: [MonthDay]
    var walkedDays = 0
    var goalDays = 0
    var totalMinutes = 0

    /// Weekday initials in the user's own order, e.g. S M T W T F S.
    static func weekdayInitials(_ cal: Calendar = .current) -> [String] {
        let symbols = cal.veryShortStandaloneWeekdaySymbols
        let first = cal.firstWeekday - 1
        return Array(symbols[first...] + symbols[..<first])
    }

    func title(_ cal: Calendar = .current) -> String {
        let f = DateFormatter()
        f.calendar = cal
        f.locale = .current
        f.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        return f.string(from: monthStart)
    }

    /// True when `monthStart` is the month containing `today`, so the next arrow can be hidden.
    func isCurrentMonth(today: Date = Date(), calendar cal: Calendar = .current) -> Bool {
        cal.isDate(monthStart, equalTo: today, toGranularity: .month)
    }

    static func build(walks: [Walk], goalMinutes: Int, month: Date = Date(),
                      today: Date = Date(), calendar cal: Calendar = .current) -> MonthSummary {
        var minutesByDay: [Date: Int] = [:]
        for walk in walks where walk.minutes > 0 {
            minutesByDay[cal.startOfDay(for: walk.start), default: 0] += walk.minutes
        }

        let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: month)) ?? cal.startOfDay(for: month)
        let dayCount = cal.range(of: .day, in: .month, for: monthStart)?.count ?? 30
        // How many blanks before the 1st, given the user's first day of the week.
        let leading = (cal.component(.weekday, from: monthStart) - cal.firstWeekday + 7) % 7
        let todayStart = cal.startOfDay(for: today)

        var summary = MonthSummary(monthStart: monthStart, days: [])
        var cells: [MonthDay] = (0..<leading).map {
            MonthDay(index: $0, date: nil, dayNumber: nil, minutes: 0, hitGoal: false, isToday: false, isFuture: false)
        }
        for offset in 0..<dayCount {
            guard let date = cal.date(byAdding: .day, value: offset, to: monthStart) else { continue }
            let minutes = minutesByDay[date] ?? 0
            let hitGoal = goalMinutes > 0 && minutes >= goalMinutes
            cells.append(MonthDay(index: leading + offset, date: date,
                                  dayNumber: cal.component(.day, from: date), minutes: minutes,
                                  hitGoal: hitGoal, isToday: cal.isDate(date, inSameDayAs: todayStart),
                                  isFuture: date > todayStart))
            if minutes > 0 { summary.walkedDays += 1; summary.totalMinutes += minutes }
            if hitGoal { summary.goalDays += 1 }
        }
        summary.days = cells
        return summary
    }
}
