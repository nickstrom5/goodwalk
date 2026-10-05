import XCTest
@testable import GoodWalk

/// Bugs found in the October QA pass, pinned so they stay fixed.
@MainActor
final class QAFixTests: XCTestCase {
    private var defaults: UserDefaults!
    private let suite = "goodwalk.tests.qafixes"

    override func setUp() {
        super.setUp()
        UserDefaults().removePersistentDomain(forName: suite)
        defaults = UserDefaults(suiteName: suite)
    }

    private func twoDogs() -> (AppState, rex: DogProfile, juno: DogProfile) {
        let state = AppState(defaults: defaults, tracker: MockDistanceTracker())
        var rex = DogProfile(); rex.name = "Rex"; rex.goalMinutes = 60
        var juno = DogProfile(); juno.name = "Juno"; juno.goalMinutes = 30
        state.replaceDogs([rex, juno])
        return (state, rex, juno)
    }

    // MARK: - The timer fills the ring of a dog who is on the walk

    func testTheRingIsTheDogOnScreenWhenTheyCameAlong() {
        let (state, rex, juno) = twoDogs()
        state.select(rex.id)
        state.seedActiveWalk(start: Date().addingTimeInterval(-600), dogIDs: [rex.id, juno.id])
        XCTAssertEqual(state.ringDog().id, rex.id)
    }

    func testTheRingMovesToADogOnTheWalkWhenTheOneOnScreenStayedHome() {
        let (state, rex, juno) = twoDogs()
        state.select(rex.id)
        state.seedActiveWalk(start: Date().addingTimeInterval(-600), dogIDs: [juno.id])
        XCTAssertEqual(state.ringDog().id, juno.id)
        XCTAssertEqual(state.ringDog().dailyGoal, 30)
    }

    // MARK: - A day that starts at 01:00 doesn't break the streak

    /// Chile moves its clocks at midnight: on 6 Sep 2026 Santiago goes from 23:59:59 to 01:00.
    func testAStreakRunsThroughAMidnightClockChange() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "America/Santiago")!
        func noon(_ day: Int) -> Date {
            cal.date(from: DateComponents(year: 2026, month: 9, day: day, hour: 12))!
        }
        let walks = (4...7).map { day in
            Walk(start: noon(day), minutes: 30, distanceMeters: 1600, distanceEstimated: true, source: .quickLog)
        }
        let stats = Stats.compute(walks: walks, goalMinutes: 30, today: noon(7), calendar: cal)
        XCTAssertEqual(stats.streak, 4)

        var dog = DogProfile(); dog.addedOn = noon(1)
        let household = Stats.Household.compute(dogs: [dog], walks: walks, today: noon(7), calendar: cal)
        XCTAssertEqual(household.streak, 4)
    }

    // MARK: - Settings and copy

    func testRefreshingForTodayKeepsTheNumbersTheLogGives() {
        let (state, rex, _) = twoDogs()
        state.select(rex.id)
        state.quickLog(minutes: 25, source: .quickLog, dogIDs: [rex.id])
        state.refreshForToday()
        XCTAssertEqual(state.stats.minutesToday, 25)
    }
}
