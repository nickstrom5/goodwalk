import XCTest
@testable import GoodWalk

final class WalkPlanTests: XCTestCase {
    private func dog(_ size: DogProfile.Size, _ type: DogProfile.BreedType = .mixed, _ age: DogProfile.Age = .adult, usual: Int = 20) -> DogProfile {
        var d = DogProfile()
        d.name = "Rex"
        d.size = size
        d.breedType = type
        d.age = age
        d.usualMinutes = usual
        return d
    }

    func testDefaultDogMatchesThePitch() {
        // "Rex needs about 60 min a day; the typical dog gets about 23."
        let rex = dog(.medium)
        XCTAssertEqual(WalkPlan.recommendedMinutes(for: rex), 60)
        // 160 min a week (Christian et al., 2013) / 7 = 22.9.
        XCTAssertEqual(WalkPlan.typicalMinutesPerWeek, 160)
        XCTAssertEqual(WalkPlan.typicalMinutes, 23)
    }

    /// Named breeds against the Royal Kennel Club's Breeds A to Z exercise bands and PDSA's breed
    /// pages, accessed 18 Sep 2026 (docs/12-sources.md). "More than 2 hours" means the 120 cap
    /// or close to it; "Up to 1 hour" / "Up to 30 minutes" are ceilings.
    func testNamedBreedsSitInTheirPublishedBands() {
        // KC "Up to 30 minutes per day"; PDSA "a minimum of half an hour".
        XCTAssertEqual(WalkPlan.recommendedMinutes(for: dog(.toy, .companion)), 30)          // Chihuahua
        XCTAssertLessThanOrEqual(WalkPlan.recommendedMinutes(for: dog(.toy, .terrier)), 30)  // Yorkshire Terrier
        // KC "Up to 1 hour per day"; PDSA "up to an hour".
        XCTAssertLessThanOrEqual(WalkPlan.recommendedMinutes(for: dog(.small, .flatFaced)), 60)   // Pug, French Bulldog
        XCTAssertLessThanOrEqual(WalkPlan.recommendedMinutes(for: dog(.medium, .flatFaced)), 60)  // Bulldog
        XCTAssertLessThanOrEqual(WalkPlan.recommendedMinutes(for: dog(.small, .terrier)), 60)     // Jack Russell
        XCTAssertLessThanOrEqual(WalkPlan.recommendedMinutes(for: dog(.small, .hound)), 60)       // Dachshund
        XCTAssertLessThanOrEqual(WalkPlan.recommendedMinutes(for: dog(.giant, .mixed)), 60)       // St. Bernard, Mastiff
        // KC "More than 2 hours per day"; PDSA "a minimum of two hours".
        XCTAssertEqual(WalkPlan.recommendedMinutes(for: dog(.large, .sporting)), 120)   // Labrador, Golden Retriever
        XCTAssertEqual(WalkPlan.recommendedMinutes(for: dog(.large, .herding)), 120)    // German Shepherd
        XCTAssertGreaterThanOrEqual(WalkPlan.recommendedMinutes(for: dog(.medium, .herding)), 90)  // Border Collie
    }

    func testBreedTypeMovesTheNumber() {
        XCTAssertEqual(WalkPlan.recommendedMinutes(for: dog(.medium, .herding)), 90)
        XCTAssertEqual(WalkPlan.recommendedMinutes(for: dog(.medium, .sporting)), 80)   // 81 → 80
        XCTAssertEqual(WalkPlan.recommendedMinutes(for: dog(.medium, .flatFaced)), 35)  // 36 → 35
        XCTAssertEqual(WalkPlan.recommendedMinutes(for: dog(.large, .working)), 105)    // 103.5 → 105
        XCTAssertEqual(WalkPlan.recommendedMinutes(for: dog(.giant, .working)), 70)     // 69 → 70
    }

    func testPuppiesAndSeniorsGetLess() {
        let adult = WalkPlan.recommendedMinutes(for: dog(.large, .sporting))
        XCTAssertLessThan(WalkPlan.recommendedMinutes(for: dog(.large, .sporting, .puppy)), adult)
        XCTAssertLessThan(WalkPlan.recommendedMinutes(for: dog(.large, .sporting, .senior)), adult)
    }

    func testEveryCombinationIsClampedAndAMultipleOfFive() {
        for size in DogProfile.Size.allCases {
            for type in DogProfile.BreedType.allCases {
                for age in DogProfile.Age.allCases {
                    let minutes = WalkPlan.recommendedMinutes(for: dog(size, type, age))
                    XCTAssertGreaterThanOrEqual(minutes, WalkPlan.minimumMinutes)
                    XCTAssertLessThanOrEqual(minutes, WalkPlan.maximumMinutes)
                    XCTAssertEqual(minutes % 5, 0, "\(size) \(type) \(age)")
                }
            }
        }
    }

    func testSmallestDogHitsTheFloor() {
        // 30 × 0.6 × 0.6 = 10.8 → 10 → clamped to 15.
        XCTAssertEqual(WalkPlan.recommendedMinutes(for: dog(.toy, .flatFaced, .puppy)), 15)
    }

    func testYearlyGap() {
        // 60 needed, 20 now: 40 min × 365 / 60 = 243 hours.
        XCTAssertEqual(WalkPlan.dailyGap(for: dog(.medium, usual: 20)), 40)
        XCTAssertEqual(WalkPlan.yearlyGapHours(for: dog(.medium, usual: 20)), 243)
    }

    func testGapNeverGoesNegative() {
        XCTAssertEqual(WalkPlan.dailyGap(for: dog(.toy, .companion, usual: 60)), 0)
        XCTAssertEqual(WalkPlan.yearlyGapHours(for: dog(.toy, .companion, usual: 60)), 0)
    }

    func testGoalOptionsIncludeTheRecommendationAndStayInRange() {
        let rex = dog(.medium)
        XCTAssertEqual(WalkPlan.goalOptions(for: rex), [30, 45, 60, 75])
        let tiny = dog(.toy, .flatFaced, .puppy)
        XCTAssertEqual(WalkPlan.goalOptions(for: tiny), [15, 30])
        let max = dog(.large, .herding)   // 135 → capped at 120
        XCTAssertEqual(WalkPlan.goalOptions(for: max), [90, 105, 120])
        XCTAssertTrue(WalkPlan.goalOptions(for: max).allSatisfy { $0 <= WalkPlan.maximumMinutes })
    }

    func testDailyGoalFallsBackToRecommendation() {
        var rex = dog(.medium)
        XCTAssertEqual(rex.dailyGoal, 60)
        rex.goalMinutes = 45
        XCTAssertEqual(rex.dailyGoal, 45)
    }

    func testNamesAlwaysRead() {
        var d = DogProfile()
        XCTAssertEqual(d.displayName, "your dog")
        XCTAssertEqual(d.possessive, "your dog's")
        d.name = "  Rex "
        XCTAssertEqual(d.displayName, "Rex")
        XCTAssertEqual(d.possessive, "Rex's")
    }

    func testEstimatedDistanceAtDogPace() {
        // 60 minutes at 2 mph is 2 miles.
        XCTAssertEqual(WalkPlan.estimatedMeters(forMinutes: 60) / WalkPlan.metersPerMile, 2.0, accuracy: 0.0001)
    }

    func testMockTrackerIsDeterministic() {
        let start = Date(timeIntervalSince1970: 1_000_000)
        let a = MockDistanceTracker(seed: 7)
        let b = MockDistanceTracker(seed: 7)
        XCTAssertNil(a.currentMeters(at: start))
        a.begin(from: start)
        b.begin(from: start)
        let later = start.addingTimeInterval(1_800)
        XCTAssertEqual(a.currentMeters(at: later), b.currentMeters(at: later))
        // Half an hour at ~2 mph is about a mile, within the ±4% wobble.
        XCTAssertEqual(a.currentMeters(at: later)! / WalkPlan.metersPerMile, 1.0, accuracy: 0.05)
        XCTAssertFalse(a.isMeasured)
        a.end()
        XCTAssertNil(a.currentMeters(at: later))
    }
}
