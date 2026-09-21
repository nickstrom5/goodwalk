import XCTest
@testable import GoodWalk

/// The breed list is a shortcut that fills in size and type. These tests hold it to the breeds
/// already sourced in `playbook/12-sources.md` §1, so a change to `WalkPlan` or to a row fails
/// here rather than quietly moving somebody's dog's target.
final class BreedTests: XCTestCase {

    // MARK: - The catalogue agrees with the sourced numbers

    private func breed(_ name: String) -> DogBreed? {
        DogBreed.all.first { $0.name == name }
    }

    func testThePinnedBreedsMatchTheSourcedTargets() {
        XCTAssertEqual(breed("Labrador Retriever")?.adultMinutes, 120)
        XCTAssertEqual(breed("Golden Retriever")?.adultMinutes, 120)
        XCTAssertEqual(breed("German Shepherd")?.adultMinutes, 120)
        XCTAssertEqual(breed("Chihuahua")?.adultMinutes, 30)
        XCTAssertGreaterThanOrEqual(breed("Border Collie")?.adultMinutes ?? 0, 90)
        XCTAssertLessThanOrEqual(breed("Pug")?.adultMinutes ?? 999, 60)
        XCTAssertLessThanOrEqual(breed("Dachshund")?.adultMinutes ?? 999, 60)
        XCTAssertLessThanOrEqual(breed("Saint Bernard")?.adultMinutes ?? 999, 60)
    }

    func testEveryBreedLandsInsideTheAllowedRange() {
        for breed in DogBreed.all {
            XCTAssertGreaterThanOrEqual(breed.adultMinutes, WalkPlan.minimumMinutes, breed.name)
            XCTAssertLessThanOrEqual(breed.adultMinutes, WalkPlan.maximumMinutes, breed.name)
            XCTAssertFalse(breed.summary.isEmpty, breed.name)
        }
    }

    func testNoDuplicateNames() {
        let names = DogBreed.all.map(\.name)
        XCTAssertEqual(Set(names).count, names.count, "a breed is listed twice")
    }

    /// A corgi filed medium would be offered 90 minutes, well past the Kennel Club's "up to 1
    /// hour"; filed small it lands on 60. The reasoning is in §6 of the sources file.
    func testCorgiStaysWithinItsPublishedBand() {
        XCTAssertEqual(breed("Pembroke Welsh Corgi")?.adultMinutes, 60)
    }

    // MARK: - Search

    func testEmptyQueryReturnsEverything() {
        XCTAssertEqual(DogBreed.search("").count, DogBreed.all.count)
        XCTAssertEqual(DogBreed.search("   ").count, DogBreed.all.count)
    }

    func testPrefixOfTheNameWinsOverAnAlias() {
        let results = DogBreed.search("lab")
        XCTAssertEqual(results.first?.name, "Labrador Retriever")
        XCTAssertTrue(results.contains { $0.name == "Labradoodle" })
    }

    func testALaterWordInTheNameMatches() {
        let results = DogBreed.search("collie")
        XCTAssertTrue(results.contains { $0.name == "Border Collie" })
    }

    func testNicknamesFindTheBreed() {
        XCTAssertEqual(DogBreed.search("staffy").first?.name, "Staffordshire Bull Terrier")
        XCTAssertEqual(DogBreed.search("frenchie").first?.name, "French Bulldog")
        XCTAssertEqual(DogBreed.search("sausage dog").first?.name, "Dachshund")
        XCTAssertEqual(DogBreed.search("alsatian").first?.name, "German Shepherd")
        XCTAssertEqual(DogBreed.search("westie").first?.name, "West Highland White Terrier")
    }

    func testPunctuationAndCaseDoNotMatter() {
        XCTAssertEqual(DogBreed.search("shih-tzu").first?.name, "Shih Tzu")
        XCTAssertEqual(DogBreed.search("SHIH TZU").first?.name, "Shih Tzu")
        XCTAssertEqual(DogBreed.search("st. bernard").first?.name, "Saint Bernard")
    }

    func testAnUnknownBreedFindsNothingRatherThanGuessing() {
        XCTAssertTrue(DogBreed.search("velociraptor").isEmpty, "a wrong guess here changes a dog's target")
    }

    // MARK: - Applying a breed

    func testChoosingABreedFillsInSizeAndTypeAndResetsTheTarget() {
        var dog = DogProfile()
        dog.size = .toy
        dog.breedType = .companion
        dog.goalMinutes = 25

        dog.apply(breed("Border Collie"))
        XCTAssertEqual(dog.breedName, "Border Collie")
        XCTAssertEqual(dog.size, .medium)
        XCTAssertEqual(dog.breedType, .herding)
        XCTAssertEqual(dog.goalMinutes, 0, "a target set for a toy companion cannot survive becoming a collie")
        XCTAssertEqual(dog.dailyGoal, 90)
        XCTAssertEqual(dog.breedLabel, "Border Collie")
    }

    func testNotListedClearsOnlyTheLabel() {
        var dog = DogProfile()
        dog.apply(breed("Beagle"))
        XCTAssertEqual(dog.size, .medium)

        dog.apply(nil)
        XCTAssertEqual(dog.breedName, "")
        XCTAssertEqual(dog.size, .medium, "their size and type stay; only the label goes")
        XCTAssertEqual(dog.breedLabel, "Medium hound")
    }

    func testTheSizeAndTypeStayEditableAfterABreedIsChosen() {
        var dog = DogProfile()
        dog.apply(breed("Labrador Retriever"))
        XCTAssertEqual(dog.dailyGoal, 120)

        // The owner knows their dog is a small one; the breed was only a shortcut.
        dog.size = .medium
        XCTAssertEqual(dog.dailyGoal, 80)
        XCTAssertEqual(dog.breedName, "Labrador Retriever", "it is still a Labrador")
    }
}
