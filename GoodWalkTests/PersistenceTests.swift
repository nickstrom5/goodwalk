import XCTest
@testable import GoodWalk

/// An update must never cost anyone their log. Every field added to a walk or a dog since the
/// first TestFlight build is missing from data saved before it; these load that data back.
@MainActor
final class PersistenceTests: XCTestCase {
    private var defaults: UserDefaults!
    private let suite = "goodwalk.tests.persistence"

    override func setUp() {
        super.setUp()
        UserDefaults().removePersistentDomain(forName: suite)
        defaults = UserDefaults(suiteName: suite)
    }

    // Dates as the default JSONEncoder writes them: seconds since 1 Jan 2001.
    private let oldWalks = """
    [{"id":"6F1C2B9E-6D6A-4F3E-9D1A-1B2C3D4E5F60","start":780000000,"minutes":32,
      "distanceMeters":1700,"distanceEstimated":false,"source":"timer"},
     {"id":"6F1C2B9E-6D6A-4F3E-9D1A-1B2C3D4E5F61","start":780090000,"minutes":20,
      "distanceMeters":1100,"distanceEstimated":true,"source":"quickLog"}]
    """

    private let oldDogs = """
    [{"id":"0A1B2C3D-4E5F-4061-8293-A4B5C6D7E8F9","name":"Rex","size":"medium",
      "breedType":"hound","age":"adult","usualMinutes":25,"goalMinutes":60}]
    """

    func testWalksSavedBeforeDogsAndPhotosStillLoad() throws {
        let walks = try JSONDecoder().decode([Walk].self, from: Data(oldWalks.utf8))
        XCTAssertEqual(walks.count, 2)
        XCTAssertEqual(walks[0].minutes, 32)
        XCTAssertEqual(walks[0].dogIDs, [], "no dogs recorded means the walk counted for everyone")
        XCTAssertFalse(walks[0].hasPhoto)
        XCTAssertFalse(walks[0].distanceEstimated)
    }

    func testADogSavedBeforeBreedsStillLoadsWithTheirIdentity() throws {
        let dogs = try JSONDecoder().decode([DogProfile].self, from: Data(oldDogs.utf8))
        XCTAssertEqual(dogs.count, 1)
        XCTAssertEqual(dogs[0].id, UUID(uuidString: "0A1B2C3D-4E5F-4061-8293-A4B5C6D7E8F9"))
        XCTAssertEqual(dogs[0].name, "Rex")
        XCTAssertEqual(dogs[0].breedType, .hound)
        XCTAssertEqual(dogs[0].breedName, "")
        XCTAssertEqual(dogs[0].goalMinutes, 60)
        XCTAssertEqual(dogs[0].addedOn, .distantPast, "a dog with no arrival date has always lived here")
    }

    func testTheFirstSingleDogFormatStillLoads() throws {
        let dog = try JSONDecoder().decode(DogProfile.self, from: Data("""
        {"name":"Juno","size":"small","breedType":"terrier","age":"puppy","usualMinutes":15,"goalMinutes":0}
        """.utf8))
        XCTAssertEqual(dog.name, "Juno")
        XCTAssertEqual(dog.size, .small)
        XCTAssertEqual(dog.age, .puppy)
    }

    func testAnUnknownChoiceFallsBackRatherThanLosingTheDog() throws {
        let dog = try JSONDecoder().decode(DogProfile.self, from: Data("""
        {"name":"Pip","size":"enormous","breedType":"hound","age":"adult"}
        """.utf8))
        XCTAssertEqual(dog.name, "Pip")
        XCTAssertEqual(dog.size, .medium)
    }

    func testAppStateKeepsAnOldLogAndItsStreak() {
        defaults.set(Data(oldDogs.utf8), forKey: "dogs")
        defaults.set(Data(oldWalks.utf8), forKey: "walks")
        defaults.set(true, forKey: "hasCompletedOnboarding")

        let state = AppState(defaults: defaults, tracker: MockDistanceTracker())
        XCTAssertEqual(state.walks(forDog: state.dog.id).count, 2)
        XCTAssertEqual(state.dog.name, "Rex")
        XCTAssertEqual(state.household.walkCount, 2)
        XCTAssertEqual(state.household.longestStreak, 2, "the two days in a row still count for Rex")
    }

    func testANewSaveRoundTrips() throws {
        var dog = DogProfile()
        dog.name = "Rex"
        dog.breedName = "Beagle"
        let walk = Walk(start: Date(timeIntervalSinceReferenceDate: 780_000_000), minutes: 30,
                        distanceMeters: 1600, distanceEstimated: false, source: .timer,
                        dogIDs: [dog.id], hasPhoto: true)
        let decodedDog = try JSONDecoder().decode(DogProfile.self, from: JSONEncoder().encode(dog))
        let decodedWalk = try JSONDecoder().decode(Walk.self, from: JSONEncoder().encode(walk))
        XCTAssertEqual(decodedDog, dog)
        XCTAssertEqual(decodedWalk, walk)
    }
}
