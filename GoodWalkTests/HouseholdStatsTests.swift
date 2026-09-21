import XCTest
@testable import GoodWalk

/// The household streak is the number on the home screen once a second dog exists, so these are
/// the rules the whole feature stands on: one dog missed is a day missed, a walk shared by two
/// dogs is one walk, and a dog who wasn't here yet can't have missed anything.
final class HouseholdStatsTests: XCTestCase {
    private let cal = Calendar.current
    private var today: Date { cal.startOfDay(for: Date()) }

    private func day(_ daysAgo: Int) -> Date {
        cal.date(byAdding: .day, value: -daysAgo, to: today)!
    }

    private func dog(_ name: String, addedDaysAgo: Int = 400, goal: Int = 60) -> DogProfile {
        var d = DogProfile()
        d.name = name
        d.goalMinutes = goal
        d.addedOn = day(addedDaysAgo)
        return d
    }

    private func walk(_ daysAgo: Int, minutes: Int = 30, dogIDs: [UUID] = [], hour: Int = 9) -> Walk {
        let start = cal.date(byAdding: .hour, value: hour, to: day(daysAgo))!
        return Walk(start: start, minutes: minutes,
                    distanceMeters: WalkPlan.estimatedMeters(forMinutes: minutes),
                    distanceEstimated: true, source: .quickLog, dogIDs: dogIDs)
    }

    func testNoDogsIsAllZeros() {
        XCTAssertEqual(Stats.Household.compute(dogs: [], walks: [walk(0)]), Stats.Household())
    }

    func testOneDogBehavesExactlyLikeTheSingleDogStreak() {
        let rex = dog("Rex")
        let walks = [walk(2, dogIDs: [rex.id]), walk(1, dogIDs: [rex.id]), walk(0, dogIDs: [rex.id])]
        let household = Stats.Household.compute(dogs: [rex], walks: walks)
        let single = Stats.compute(walks: walks, goalMinutes: 60)
        XCTAssertEqual(household.streak, single.streak)
        XCTAssertEqual(household.longestStreak, single.longestStreak)
        XCTAssertEqual(household.walkCount, single.walkCount)
    }

    func testADayCountsOnlyWhenEveryDogWalked() {
        let rex = dog("Rex")
        let juno = dog("Juno")
        // Yesterday only Rex went out, so yesterday is not a complete day.
        let walks = [walk(2, dogIDs: [rex.id, juno.id]),
                     walk(1, dogIDs: [rex.id]),
                     walk(0, dogIDs: [rex.id, juno.id])]
        let household = Stats.Household.compute(dogs: [rex, juno], walks: walks)
        XCTAssertEqual(household.streak, 1, "the streak restarts at today, because yesterday Juno was skipped")
        XCTAssertEqual(household.longestStreak, 1)
        XCTAssertEqual(household.completeDays, 2)
    }

    func testOneWalkWithTwoDogsCountsForBothAndIsCountedOnce() {
        let rex = dog("Rex")
        let juno = dog("Juno")
        let household = Stats.Household.compute(dogs: [rex, juno], walks: [walk(0, minutes: 40, dogIDs: [rex.id, juno.id])])
        XCTAssertEqual(household.streak, 1)
        XCTAssertEqual(household.walkCount, 1, "walking two dogs around the block is one walk")
        XCTAssertEqual(household.totalMinutes, 40, "and forty minutes, not eighty")
        XCTAssertEqual(household.dogsWalkedToday, 2)
    }

    func testAWalkWithNoDogsNamedCountsForEveryone() {
        let rex = dog("Rex")
        let juno = dog("Juno")
        let household = Stats.Household.compute(dogs: [rex, juno], walks: [walk(0)])
        XCTAssertEqual(household.dogsWalkedToday, 2)
        XCTAssertEqual(household.streak, 1)
    }

    func testANewDogDoesNotBreakTheStreakThatCameBeforeThem() {
        let rex = dog("Rex")
        let juno = dog("Juno", addedDaysAgo: 0)   // arrived today
        var walks = (1...10).map { walk($0, dogIDs: [rex.id]) }
        walks.append(walk(0, dogIDs: [rex.id, juno.id]))
        let household = Stats.Household.compute(dogs: [rex, juno], walks: walks)
        XCTAssertEqual(household.streak, 11, "Juno cannot have missed the days before she arrived")
    }

    func testTodayStillShortADogDoesNotBreakYesterdaysStreak() {
        let rex = dog("Rex")
        let juno = dog("Juno")
        // Three complete days, then today only Rex has been out so far.
        var walks = (1...3).map { walk($0, dogIDs: [rex.id, juno.id]) }
        walks.append(walk(0, dogIDs: [rex.id]))
        let household = Stats.Household.compute(dogs: [rex, juno], walks: walks)
        XCTAssertEqual(household.streak, 3, "an unfinished day never zeroes the number before the evening walk")
        XCTAssertFalse(household.everyoneWalkedToday)
        XCTAssertEqual(household.dogsWalkedToday, 1)
    }

    func testEveryoneWalkedTodayOnlyWhenNobodyIsLeft() {
        let rex = dog("Rex")
        let juno = dog("Juno")
        let one = Stats.Household.compute(dogs: [rex, juno], walks: [walk(0, dogIDs: [rex.id])])
        XCTAssertFalse(one.everyoneWalkedToday)
        let both = Stats.Household.compute(dogs: [rex, juno], walks: [walk(0, dogIDs: [rex.id]), walk(0, dogIDs: [juno.id], hour: 18)])
        XCTAssertTrue(both.everyoneWalkedToday)
        XCTAssertEqual(both.walkCount, 2, "two separate walks are two walks")
    }
}

/// The parts of `AppState` that only exist once there is more than one dog.
@MainActor
final class MultiDogStateTests: XCTestCase {
    private var defaults: UserDefaults!
    private let suite = "goodwalk.tests.multidog"

    override func setUp() {
        super.setUp()
        UserDefaults().removePersistentDomain(forName: suite)
        defaults = UserDefaults(suiteName: suite)
    }

    private func makeState() -> AppState {
        let state = AppState(defaults: defaults, tracker: MockDistanceTracker())
        state.dog.name = "Rex"
        state.dog.goalMinutes = 60
        return state
    }

    func testAddingADogSelectsThemAndLeavesTheFirstOneAlone() {
        let state = makeState()
        let rexID = state.selectedDogID
        var juno = DogProfile()
        juno.name = "Juno"
        let added = state.addDog(juno)
        XCTAssertEqual(state.dogs.count, 2)
        XCTAssertEqual(state.selectedDogID, added.id)
        XCTAssertTrue(state.hasMultipleDogs)
        XCTAssertEqual(state.dog(withID: rexID)?.name, "Rex")
    }

    func testAWalkWithNoDogsNamedCountsForEveryone() {
        let state = makeState()
        var juno = DogProfile()
        juno.name = "Juno"
        let added = state.addDog(juno)
        state.quickLog(minutes: 30, source: .quickLog)
        XCTAssertEqual(state.minutesToday(for: added.id), 30)
        XCTAssertEqual(state.household.dogsWalkedToday, 2)
    }

    func testLoggingForOneDogLeavesTheOtherWaiting() {
        let state = makeState()
        let rexID = state.selectedDogID
        var juno = DogProfile()
        juno.name = "Juno"
        let junoID = state.addDog(juno).id
        state.quickLog(minutes: 30, source: .quickLog, dogIDs: [rexID])
        XCTAssertEqual(state.minutesToday(for: rexID), 30)
        XCTAssertEqual(state.minutesToday(for: junoID), 0)
        XCTAssertEqual(state.dogsNotWalkedToday.map(\.id), [junoID])
        XCTAssertEqual(state.household.streak, 0, "the day isn't done until Juno has been out")
    }

    func testTheNotificationLogsOnlyTheDogsStillWaiting() {
        let state = makeState()
        let rexID = state.selectedDogID
        var juno = DogProfile()
        juno.name = "Juno"
        let junoID = state.addDog(juno).id
        state.quickLog(minutes: 30, source: .quickLog, dogIDs: [rexID])
        let logged = state.logUsualWalkForDogsNotWalkedToday()
        XCTAssertEqual(logged?.dogIDs, [junoID], "Rex already went out; one tap must not log him twice")
        XCTAssertEqual(state.minutesToday(for: rexID), 30)
        XCTAssertTrue(state.household.everyoneWalkedToday)
        XCTAssertEqual(state.household.streak, 1)
    }

    func testNothingIsLoggedWhenEveryoneHasAlreadyWalked() {
        let state = makeState()
        state.quickLog(minutes: 30, source: .quickLog)
        XCTAssertNil(state.logUsualWalkForDogsNotWalkedToday())
        XCTAssertEqual(state.walks.count, 1)
    }

    func testRemovingADogKeepsSharedWalksAndDropsTheirOwn() {
        let state = makeState()
        let rexID = state.selectedDogID
        var juno = DogProfile()
        juno.name = "Juno"
        let junoID = state.addDog(juno).id
        state.quickLog(minutes: 30, source: .quickLog, dogIDs: [rexID, junoID])
        state.quickLog(minutes: 20, source: .quickLog, dogIDs: [junoID])
        XCTAssertEqual(state.walks.count, 2)

        state.removeDog(junoID)
        XCTAssertEqual(state.dogs.count, 1)
        XCTAssertEqual(state.walks.count, 1, "the walk that was only Juno's goes with her")
        XCTAssertEqual(state.walks.first?.dogIDs, [rexID])
        XCTAssertEqual(state.selectedDogID, rexID)
    }

    func testTheLastDogCannotBeRemoved() {
        let state = makeState()
        state.removeDog(state.selectedDogID)
        XCTAssertEqual(state.dogs.count, 1, "an app with no dog has nothing to show")
    }

    func testEachDogKeepsTheirOwnTargetAndRing() {
        let state = makeState()
        let rexID = state.selectedDogID
        var juno = DogProfile()
        juno.name = "Juno"
        juno.goalMinutes = 30
        let junoID = state.addDog(juno).id
        state.quickLog(minutes: 30, source: .quickLog)

        XCTAssertEqual(state.progressToday(for: junoID), 1.0, accuracy: 0.0001, "30 of 30 fills Juno's ring")
        XCTAssertEqual(state.progressToday(for: rexID), 0.5, accuracy: 0.0001, "the same walk is half of Rex's 60")
    }
}
