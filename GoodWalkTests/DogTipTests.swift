import XCTest
@testable import GoodWalk

/// The tips are copy, and CLAUDE.md holds copy to two rules that this file enforces: a figure about
/// dogs or owners has a published source (and a row in `playbook/12-sources.md` §7), and nothing
/// promises a health outcome or tells an owner what their dog needs.
final class DogTipTests: XCTestCase {

    private func dog(_ name: String = "Rex", size: DogProfile.Size = .medium,
                     type: DogProfile.BreedType = .mixed, age: DogProfile.Age = .adult) -> DogProfile {
        var dog = DogProfile()
        dog.name = name
        dog.size = size
        dog.breedType = type
        dog.age = age
        return dog
    }

    private func ids(_ tips: [DogTip]) -> Set<String> { Set(tips.map(\.id)) }

    private func tip(_ id: String) -> DogTip? { DogTips.all.first { $0.id == id } }

    // MARK: - The rules

    func testIDsAreUniqueAndNothingIsBlank() {
        let all = DogTips.all.map(\.id)
        XCTAssertEqual(Set(all).count, all.count, "a tip id is used twice")
        for tip in DogTips.all {
            XCTAssertFalse(tip.template.trimmingCharacters(in: .whitespaces).isEmpty, tip.id)
        }
    }

    func testEveryFigureHasASourceAndOnlyFactsCarryOne() {
        for tip in DogTips.all {
            let hasFigure = tip.template.rangeOfCharacter(from: .decimalDigits) != nil || tip.template.contains("%")
            switch tip.kind {
            case .fact:
                XCTAssertNotNil(tip.source, "\(tip.id): a fact names its source")
            case .tip:
                XCTAssertNil(tip.source, "\(tip.id): a tip has nothing to cite")
                XCTAssertFalse(hasFigure, "\(tip.id): a figure makes it a fact, with a source and a row in 12-sources.md §7")
            }
        }
    }

    func testGuidanceFiguresSayTheyAreNotVeterinaryAdvice() {
        for tip in DogTips.all where tip.kind == .fact {
            guard let source = tip.source,
                  ["Kennel Club", "PDSA", "RSPCA"].contains(where: { source.contains($0) }) else { continue }
            XCTAssertTrue(source.lowercased().contains("not veterinary advice"), tip.id)
        }
    }

    func testNoHealthOutcomesAndNoTellingOwnersWhatTheirDogNeeds() {
        let banned = ["weight", "obes", "lifespan", "live longer", "longer life", "healthier",
                      "health benefit", "cure", "prevent", "anxiety", "arthritis", "disease",
                      "behaviour problem", "behavior problem", "calmer", "calorie", "fitter",
                      "your dog needs", "{name} needs", "{name} must"]
        for tip in DogTips.all {
            let text = (tip.template + " " + (tip.source ?? "")).lowercased()
            for word in banned {
                XCTAssertFalse(text.contains(word), "\(tip.id) says \"\(word)\"")
            }
        }
    }

    // MARK: - Names

    func testTheDogsNameGoesIn() {
        let rex = dog()
        for tip in DogTips.all {
            let text = tip.text(for: rex)
            XCTAssertFalse(text.contains("{") || text.contains("}"), "\(tip.id): \(text)")
            if tip.template.lowercased().contains("{name") {
                XCTAssertTrue(text.contains("Rex"), "\(tip.id): \(text)")
            }
        }
    }

    func testAnUnnamedDogReadsNaturally() {
        let unnamed = dog("")
        let target = tip("app.target-editable")?.text(for: unnamed) ?? ""
        XCTAssertTrue(target.hasPrefix("Your dog's target"), target)
        XCTAssertEqual(tip("walk.sniff")?.text(for: unnamed), "Let your dog sniff. A slow walk still fills the ring.")
    }

    // MARK: - Who sees what

    func testPuppyAndSeniorFactsOnlyReachPuppiesAndSeniors() {
        let adult = ids(DogTips.deck(for: dog(age: .adult), householdSize: 1))
        let puppy = ids(DogTips.deck(for: dog(age: .puppy), householdSize: 1))
        let senior = ids(DogTips.deck(for: dog(age: .senior), householdSize: 1))
        XCTAssertTrue(puppy.contains("fact.puppy-rule"))
        XCTAssertFalse(adult.contains("fact.puppy-rule"))
        XCTAssertFalse(senior.contains("fact.puppy-rule"))
        XCTAssertTrue(senior.contains("fact.senior-routes"))
        XCTAssertFalse(puppy.contains("fact.senior-routes"))
    }

    func testBreedTypeFactsFollowTheType() {
        let terrier = ids(DogTips.deck(for: dog(size: .small, type: .terrier), householdSize: 1))
        XCTAssertTrue(terrier.contains("fact.terrier-band"))
        XCTAssertFalse(terrier.contains("fact.hound-band"))
        let pug = ids(DogTips.deck(for: dog(size: .small, type: .flatFaced), householdSize: 1))
        XCTAssertTrue(pug.contains("fact.flat-faced-band"))
        XCTAssertFalse(pug.contains("fact.terrier-band"))
    }

    func testHouseholdTipsMatchTheHousehold() {
        let one = ids(DogTips.deck(for: dog(), householdSize: 1))
        let two = ids(DogTips.deck(for: dog(), householdSize: 2))
        XCTAssertTrue(one.contains("app.add-a-dog"))
        XCTAssertFalse(one.contains("app.log-once"))
        XCTAssertTrue(two.contains("app.log-once"))
        XCTAssertFalse(two.contains("app.add-a-dog"))
        XCTAssertFalse(two.contains("app.any-walk-counts"), "with two dogs the streak on screen is the household's")
    }

    func testEveryDogOpensOnSomethingWrittenForThem() {
        for size in DogProfile.Size.allCases {
            for type in DogProfile.BreedType.allCases {
                for age in DogProfile.Age.allCases {
                    let deck = DogTips.deck(for: dog(size: size, type: type, age: age), householdSize: 1)
                    XCTAssertFalse(deck.isEmpty)
                    XCTAssertTrue(deck.first?.isPersonal ?? false, "\(size) \(type) \(age)")
                }
            }
        }
    }

    // MARK: - Rotation

    func testTheDeckCyclesThroughEveryTipBeforeRepeating() {
        let rex = dog(size: .small, type: .terrier, age: .puppy)
        let deck = DogTips.deck(for: rex, householdSize: 1)
        let shown = (0..<deck.count).compactMap { DogTips.tip(for: rex, householdSize: 1, at: $0)?.id }
        XCTAssertEqual(Set(shown).count, deck.count)
        XCTAssertEqual(DogTips.tip(for: rex, householdSize: 1, at: deck.count)?.id, deck.first?.id)
        XCTAssertEqual(DogTips.tip(for: rex, householdSize: 1, at: -1)?.id, deck.last?.id)
    }

    func testTheDeckAlternatesPersonalAndGeneral() {
        let deck = DogTips.deck(for: dog(size: .small, type: .terrier, age: .puppy), householdSize: 1)
        XCTAssertTrue(deck[0].isPersonal)
        XCTAssertFalse(deck[1].isPersonal)
        XCTAssertTrue(deck[2].isPersonal)
    }
}
