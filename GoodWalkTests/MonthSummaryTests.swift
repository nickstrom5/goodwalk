import XCTest
@testable import GoodWalk

final class MonthSummaryTests: XCTestCase {
    private var cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        c.firstWeekday = 1            // Sunday, so the leading-blank maths is deterministic
        return c
    }()

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        cal.date(from: DateComponents(year: y, month: m, day: d, hour: 9))!
    }

    private func walk(_ y: Int, _ m: Int, _ d: Int, minutes: Int) -> Walk {
        Walk(start: date(y, m, d), minutes: minutes, distanceMeters: 0, distanceEstimated: true, source: .quickLog)
    }

    func testSeptember2026StartsOnTuesdayWithTwoBlanks() {
        let s = MonthSummary.build(walks: [], goalMinutes: 60, month: date(2026, 9, 15),
                                   today: date(2026, 9, 20), calendar: cal)
        // 1 Sep 2026 is a Tuesday: Sunday and Monday are blank.
        XCTAssertEqual(s.days.prefix(2).filter { $0.date == nil }.count, 2)
        XCTAssertEqual(s.days.count, 2 + 30)
        XCTAssertEqual(s.days[2].dayNumber, 1)
    }

    func testCountsWalkedAndGoalDays() {
        let walks = [walk(2026, 9, 1, minutes: 60), walk(2026, 9, 2, minutes: 20),
                     walk(2026, 9, 2, minutes: 45), walk(2026, 9, 3, minutes: 10)]
        let s = MonthSummary.build(walks: walks, goalMinutes: 60, month: date(2026, 9, 10),
                                   today: date(2026, 9, 20), calendar: cal)
        XCTAssertEqual(s.walkedDays, 3)
        XCTAssertEqual(s.goalDays, 2)          // 1st (60) and 2nd (20+45=65)
        XCTAssertEqual(s.totalMinutes, 135)
    }

    func testIgnoresWalksInOtherMonths() {
        let walks = [walk(2026, 8, 31, minutes: 90), walk(2026, 9, 1, minutes: 30)]
        let s = MonthSummary.build(walks: walks, goalMinutes: 60, month: date(2026, 9, 10),
                                   today: date(2026, 9, 20), calendar: cal)
        XCTAssertEqual(s.walkedDays, 1)
        XCTAssertEqual(s.totalMinutes, 30)
    }

    func testMarksTodayAndFutureDays() {
        let s = MonthSummary.build(walks: [], goalMinutes: 60, month: date(2026, 9, 1),
                                   today: date(2026, 9, 20), calendar: cal)
        let dated = s.days.compactMap { $0.date == nil ? nil : $0 }
        XCTAssertEqual(dated.filter(\.isToday).count, 1)
        XCTAssertEqual(dated.first(where: \.isToday)?.dayNumber, 20)
        XCTAssertEqual(dated.filter(\.isFuture).count, 10)   // 21st to 30th
    }

    func testZeroGoalNeverCountsGoalDays() {
        let s = MonthSummary.build(walks: [walk(2026, 9, 1, minutes: 90)], goalMinutes: 0,
                                   month: date(2026, 9, 1), today: date(2026, 9, 20), calendar: cal)
        XCTAssertEqual(s.goalDays, 0)
        XCTAssertEqual(s.walkedDays, 1)
    }

    func testCurrentMonthFlag() {
        let sep = MonthSummary.build(walks: [], goalMinutes: 60, month: date(2026, 9, 1),
                                     today: date(2026, 9, 20), calendar: cal)
        let aug = MonthSummary.build(walks: [], goalMinutes: 60, month: date(2026, 8, 1),
                                     today: date(2026, 9, 20), calendar: cal)
        XCTAssertTrue(sep.isCurrentMonth(today: date(2026, 9, 20), calendar: cal))
        XCTAssertFalse(aug.isCurrentMonth(today: date(2026, 9, 20), calendar: cal))
    }

    func testWeekdayInitialsFollowFirstWeekday() {
        var monday = cal; monday.firstWeekday = 2
        XCTAssertEqual(MonthSummary.weekdayInitials(cal).count, 7)
        XCTAssertNotEqual(MonthSummary.weekdayInitials(cal), MonthSummary.weekdayInitials(monday))
    }
}
