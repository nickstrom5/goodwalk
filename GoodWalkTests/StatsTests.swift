import XCTest
@testable import GoodWalk

final class StatsTests: XCTestCase {
    private let cal = Calendar.current
    private var today: Date { cal.startOfDay(for: Date()) }

    private func walk(_ daysAgo: Int, minutes: Int = 30, hour: Int = 9) -> Walk {
        let day = cal.date(byAdding: .day, value: -daysAgo, to: today)!
        let start = cal.date(byAdding: .hour, value: hour, to: day)!
        return Walk(start: start, minutes: minutes, distanceMeters: WalkPlan.estimatedMeters(forMinutes: minutes),
                    distanceEstimated: true, source: .quickLog)
    }

    func testEmptyLogIsAllZeros() {
        XCTAssertEqual(Stats.compute(walks: [], goalMinutes: 60), Stats())
    }

    func testOneWalkTodayStartsStreak() {
        let stats = Stats.compute(walks: [walk(0)], goalMinutes: 60)
        XCTAssertEqual(stats.streak, 1)
        XCTAssertEqual(stats.longestStreak, 1)
        XCTAssertEqual(stats.minutesToday, 30)
        XCTAssertEqual(stats.goalDays, 0)
        XCTAssertEqual(stats.totalMiles, 1.0, accuracy: 0.0001)
    }

    func testStreakSurvivesTodayNotWalkedYet() {
        let stats = Stats.compute(walks: [walk(3), walk(2), walk(1)], goalMinutes: 60)
        XCTAssertEqual(stats.streak, 3)
        XCTAssertEqual(stats.minutesToday, 0)
    }

    func testStreakIsZeroWhenYesterdayWasMissed() {
        let stats = Stats.compute(walks: [walk(3), walk(2)], goalMinutes: 60)
        XCTAssertEqual(stats.streak, 0)
        XCTAssertEqual(stats.longestStreak, 2)
    }

    func testGapBreaksStreakButKeepsLongest() {
        let stats = Stats.compute(walks: [walk(6), walk(5), walk(4), walk(3), walk(1), walk(0)], goalMinutes: 60)
        XCTAssertEqual(stats.streak, 2)
        XCTAssertEqual(stats.longestStreak, 4)
        XCTAssertEqual(stats.daysWalked, 6)
    }

    func testTwoWalksInOneDayAddUpAndCountOneDay() {
        let stats = Stats.compute(walks: [walk(0, minutes: 25, hour: 7), walk(0, minutes: 40, hour: 18)], goalMinutes: 60)
        XCTAssertEqual(stats.minutesToday, 65)
        XCTAssertEqual(stats.daysWalked, 1)
        XCTAssertEqual(stats.walkCount, 2)
        XCTAssertEqual(stats.goalDays, 1)
        XCTAssertEqual(stats.streak, 1)
    }

    func testGoalDaysOnlyCountFullTargets() {
        let stats = Stats.compute(walks: [walk(2, minutes: 60), walk(1, minutes: 59), walk(0, minutes: 90)], goalMinutes: 60)
        XCTAssertEqual(stats.goalDays, 2)
        XCTAssertEqual(stats.streak, 3)
    }

    func testTotals() {
        let stats = Stats.compute(walks: [walk(2, minutes: 60), walk(1, minutes: 30), walk(0, minutes: 30)], goalMinutes: 60)
        XCTAssertEqual(stats.totalMinutes, 120)
        XCTAssertEqual(stats.totalHours, 2, accuracy: 0.0001)
        XCTAssertEqual(stats.totalMiles, 4, accuracy: 0.0001)
    }

    func testZeroMinuteWalksAreIgnored() {
        let stats = Stats.compute(walks: [walk(0, minutes: 0)], goalMinutes: 60)
        XCTAssertEqual(stats, Stats())
    }

    func testSeededScreenshotDataIsThePitch() {
        // "47 miles walked with Rex · 30-day streak"
        var walks = ScreenshotMode.seededMinutes.enumerated().map { walk($0.offset + 1, minutes: $0.element) }
        walks.append(walk(0, minutes: 25))
        let stats = Stats.compute(walks: walks, goalMinutes: 60)
        XCTAssertEqual(stats.streak, 30)
        XCTAssertEqual(Stats.miles(stats.totalMiles), "47")
    }

    func testFormatting() {
        XCTAssertEqual(Stats.miles(4.66), "4.7")
        XCTAssertEqual(Stats.miles(47.2), "47")
        XCTAssertEqual(Stats.duration(minutes: 42), "42 min")
        XCTAssertEqual(Stats.duration(minutes: 65), "1h 05m")
        XCTAssertEqual(Stats.duration(minutes: 420), "7h")
        XCTAssertEqual(Stats.clock(seconds: 727), "12:07")
        XCTAssertEqual(Stats.clock(seconds: 3_727), "1:02:07")
    }
}

@MainActor
final class AppStateTests: XCTestCase {
    private var defaults: UserDefaults!
    private let suite = "goodwalk.tests"

    override func setUp() {
        super.setUp()
        UserDefaults().removePersistentDomain(forName: suite)
        defaults = UserDefaults(suiteName: suite)
    }

    private func makeState() -> AppState {
        let state = AppState(defaults: defaults, tracker: MockDistanceTracker())
        var dog = DogProfile()
        dog.name = "Rex"
        dog.goalMinutes = 60
        state.dog = dog
        return state
    }

    func testQuickLogEstimatesDistanceAndStartsStreak() {
        let state = makeState()
        let walk = state.quickLog(minutes: 30, source: .quickLog)
        XCTAssertTrue(walk.distanceEstimated)
        XCTAssertEqual(walk.miles, 1.0, accuracy: 0.0001)
        XCTAssertEqual(state.stats.streak, 1)
        XCTAssertEqual(state.pendingMilestone, 1)
        XCTAssertFalse(state.goalJustHit)
    }

    func testCrossingTheTargetFlagsGoalHitOnce() {
        let state = makeState()
        state.quickLog(minutes: 40, source: .quickLog)
        XCTAssertFalse(state.goalJustHit)
        state.quickLog(minutes: 20, source: .quickLog)
        XCTAssertTrue(state.goalJustHit)
        state.goalJustHit = false
        state.quickLog(minutes: 10, source: .quickLog)
        XCTAssertFalse(state.goalJustHit)
        XCTAssertEqual(state.todayProgress, 1)
    }

    func testTimerLogsAWalkAndSurvivesRelaunch() {
        let state = makeState()
        let start = Date().addingTimeInterval(-20 * 60)
        state.startWalk(source: "test", at: start)
        XCTAssertTrue(state.isWalking)

        // A second AppState on the same defaults is a relaunch mid-walk.
        let relaunched = AppState(defaults: defaults, tracker: MockDistanceTracker())
        XCTAssertTrue(relaunched.isWalking)
        let walk = relaunched.finishWalk()
        XCTAssertEqual(walk?.minutes, 20)
        XCTAssertEqual(walk?.source, .timer)
        XCTAssertFalse(relaunched.isWalking)
        XCTAssertEqual(relaunched.stats.totalMinutes, 20)
    }

    func testMisTapUnderThirtySecondsIsDropped() {
        let state = makeState()
        state.startWalk(source: "test", at: Date().addingTimeInterval(-10))
        XCTAssertNil(state.finishWalk())
        XCTAssertFalse(state.isWalking)
        XCTAssertTrue(state.walks.isEmpty)
    }

    func testDeleteRemovesTheWalk() {
        let state = makeState()
        let walk = state.quickLog(minutes: 30, source: .quickLog)
        state.delete(walk)
        XCTAssertEqual(state.stats, Stats())
    }

    func testStartWalkIntentFlagIsConsumedOnce() {
        let state = makeState()
        state.hasCompletedOnboarding = true
        defaults.set(true, forKey: AppGroup.Key.pendingStartWalk)
        XCTAssertTrue(state.consumePendingStartWalk())
        XCTAssertFalse(state.consumePendingStartWalk())
    }
}
