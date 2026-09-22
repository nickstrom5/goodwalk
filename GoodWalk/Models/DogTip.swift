import Foundation

/// A short thing worth knowing, shown where the app makes someone wait: under the walk timer, and
/// on the paywall while plans load. Two kinds, held to two different rules:
///
/// - A **fact** carries a figure or a position from a published source, and the source goes on the
///   card. Every fact has a row in `playbook/12-sources.md` §7, and reuses a figure §1 or §2 already
///   sources; none is new.
/// - A **tip** is practical or about the app. It carries no figure and no claim about a dog's health.
///
/// Neither kind ever promises a health outcome (weight, lifespan, behaviour) or tells an owner what
/// their dog "needs". `GoodWalkTests/DogTipTests.swift` holds the whole list to both rules, so a line
/// that breaks one fails the build instead of reaching the App Store.
struct DogTip: Identifiable, Equatable {
    enum Kind: Equatable { case fact, tip }

    let id: String
    let kind: Kind
    /// May contain `{name}`, `{Name}` (starting a sentence), `{name's}` and `{Name's}`.
    let template: String
    /// The line under a fact. Required whenever the text carries a figure.
    let source: String?
    /// Who it is written for. An empty set means everyone.
    var ages: Set<DogProfile.Age> = []
    var sizes: Set<DogProfile.Size> = []
    var types: Set<DogProfile.BreedType> = []
    /// `true`: households with more than one dog only. `false`: one-dog households only.
    var multipleDogs: Bool? = nil

    /// Written for a particular kind of dog rather than for everyone.
    var isPersonal: Bool { !ages.isEmpty || !sizes.isEmpty || !types.isEmpty }

    func applies(to dog: DogProfile, householdSize: Int) -> Bool {
        if !ages.isEmpty && !ages.contains(dog.age) { return false }
        if !sizes.isEmpty && !sizes.contains(dog.size) { return false }
        if !types.isEmpty && !types.contains(dog.breedType) { return false }
        if let multipleDogs, multipleDogs != (householdSize > 1) { return false }
        return true
    }

    /// The line with the dog's name in it. An unnamed dog reads "your dog", and "Your dog" where
    /// it starts a sentence.
    func text(for dog: DogProfile) -> String {
        template
            .replacingOccurrences(of: "{Name's}", with: Self.capitalizingFirst(dog.possessive))
            .replacingOccurrences(of: "{name's}", with: dog.possessive)
            .replacingOccurrences(of: "{Name}", with: Self.capitalizingFirst(dog.displayName))
            .replacingOccurrences(of: "{name}", with: dog.displayName)
    }

    private static func capitalizingFirst(_ text: String) -> String {
        guard let first = text.first else { return text }
        return first.uppercased() + text.dropFirst()
    }
}

enum DogTips {
    // Source lines as they appear on a card. Kennel Club and PDSA figures are breed guidance, so
    // their line says so, the same way `GuidelineFootnote` does wherever a target is shown.
    private static let kennelClub = "Royal Kennel Club breed guidance. A general guideline, not veterinary advice."
    private static let pdsa = "PDSA. A general guideline, not veterinary advice."
    private static let pdsaAndRSPCA = "PDSA and RSPCA. A general guideline, not veterinary advice."
    private static let kennelClubAndPDSA = "Royal Kennel Club and PDSA. Not veterinary advice."
    private static let christian = "Christian et al., 2013: a review of 29 studies."

    static let all: [DogTip] = [
        // MARK: Facts for everyone (playbook/12-sources.md §7, drawing on §1 and §2)
        DogTip(id: "fact.kc-top-band", kind: .fact,
               template: "Of the 227 breeds on the Kennel Club's list, 85 sit in its top exercise band: more than 2 hours a day.",
               source: kennelClub),
        DogTip(id: "fact.pdsa-walks", kind: .fact,
               template: "The PDSA's guidance: most dogs need at least 1–2 walks a day.",
               source: pdsa),
        DogTip(id: "fact.typical-week", kind: .fact,
               template: "Across 29 studies, a dog who got walked typically got 4 walks and 160 minutes a week. That's about 23 minutes a day.",
               source: christian),
        DogTip(id: "fact.owners-who-walk", kind: .fact,
               template: "In those same 29 studies, about 60% of dog owners walked their dog. You're one of them.",
               source: christian),

        // MARK: Facts for one kind of dog
        DogTip(id: "fact.toy-band", kind: .fact,
               template: "18 of the Kennel Club's 24 Toy breeds sit in its \u{201C}up to 30 minutes a day\u{201D} band.",
               source: kennelClub, sizes: [.toy]),
        DogTip(id: "fact.small-band", kind: .fact,
               template: "47 of the 49 small breeds outside the Kennel Club's Toy group sit in its \u{201C}up to 1 hour a day\u{201D} band.",
               source: kennelClub, sizes: [.small]),
        DogTip(id: "fact.medium-band", kind: .fact,
               template: "37 of the Kennel Club's 55 medium breeds sit in its \u{201C}up to 1 hour a day\u{201D} band. 17 sit in the top one, more than 2 hours.",
               source: kennelClub, sizes: [.medium]),
        DogTip(id: "fact.large-band", kind: .fact,
               template: "56 of the Kennel Club's 79 large breeds sit in its top band: more than 2 hours a day.",
               source: kennelClub, sizes: [.large]),
        DogTip(id: "fact.giant-band", kind: .fact,
               template: "The Kennel Club puts St Bernards, Mastiffs and Newfoundlands at up to 1 hour a day, and Great Danes at more than 2 hours.",
               source: kennelClub, sizes: [.giant]),
        DogTip(id: "fact.terrier-band", kind: .fact,
               template: "All 27 terrier breeds on the Kennel Club's list sit in the same band: up to 1 hour a day.",
               source: kennelClub, types: [.terrier]),
        DogTip(id: "fact.hound-band", kind: .fact,
               template: "Most small and medium hounds sit in the Kennel Club's \u{201C}up to 1 hour\u{201D} band. Large hounds mostly sit in the top one: 14 of 17 are more than 2 hours a day.",
               source: kennelClub, types: [.hound]),
        DogTip(id: "fact.gundog-band", kind: .fact,
               template: "21 of the Kennel Club's 24 large gundog breeds sit in its top band: more than 2 hours a day.",
               source: kennelClub, types: [.sporting]),
        DogTip(id: "fact.herding-pdsa", kind: .fact,
               template: "The PDSA suggests a minimum of 2 hours a day for Border Collies and German Shepherds.",
               source: pdsa, types: [.herding]),
        DogTip(id: "fact.flat-faced-band", kind: .fact,
               template: "The Kennel Club puts Pugs, French Bulldogs and Bulldogs at up to 1 hour a day, which is why Good Walk's suggestion for flat-faced dogs sits on the cautious side.",
               source: kennelClub, types: [.flatFaced]),
        DogTip(id: "fact.puppy-short", kind: .fact,
               template: "For puppies, the PDSA's advice is to keep exercise sessions short.",
               source: pdsa, ages: [.puppy]),
        DogTip(id: "fact.puppy-rule", kind: .fact,
               template: "\u{201C}5 minutes per month of age\u{201D} is a common puppy rule. The Kennel Club calls it a good rule of thumb; the PDSA says there's no scientific evidence behind it. Your vet can tell you what suits {name}.",
               source: kennelClubAndPDSA, ages: [.puppy]),
        DogTip(id: "fact.senior-routes", kind: .fact,
               template: "For older dogs, the PDSA suggests shorter, flatter routes, and the RSPCA says little and often.",
               source: pdsaAndRSPCA, ages: [.senior]),

        // MARK: Getting the most out of the app (true of the app, no claim about dogs)
        DogTip(id: "app.walked-from-reminder", kind: .tip,
               template: "Press and hold the daily reminder, tap Walked \u{2713}, and the walk logs without opening the app.",
               source: nil),
        DogTip(id: "app.walks-add-up", kind: .tip,
               template: "Two short walks count the same as one long one. Every walk today adds to {name's} ring.",
               source: nil),
        // One dog only: with two or more, the streak on screen is the household's, and a day
        // counts once every dog has walked.
        DogTip(id: "app.any-walk-counts", kind: .tip,
               template: "Rain or shine, a short walk still counts. Any day with a walk keeps {name's} streak going.",
               source: nil, multipleDogs: false),
        DogTip(id: "app.add-a-dog", kind: .tip,
               template: "Walk more than one dog? Add them in Settings, and one walk fills every ring.",
               source: nil, multipleDogs: false),
        DogTip(id: "app.log-once", kind: .tip,
               template: "Out with everyone? Log it once. One walk counts for every dog on it.",
               source: nil, multipleDogs: true),
        DogTip(id: "app.walk-photo", kind: .tip,
               template: "Add a photo on the walk card. It stays with that day on your calendar, on your phone.",
               source: nil),
        DogTip(id: "app.target-editable", kind: .tip,
               template: "{Name's} target is a general guideline. You can change it any time in Settings.",
               source: nil),
        DogTip(id: "app.no-location", kind: .tip,
               template: "Distance comes from your phone's step counter, not GPS. Good Walk never asks for your location.",
               source: nil),
        DogTip(id: "app.widget", kind: .tip,
               template: "Add the Good Walk widget to your home screen to see {name's} streak without opening the app.",
               source: nil),
        DogTip(id: "app.siri", kind: .tip,
               template: "Say \u{201C}Start a walk in Good Walk\u{201D} to Siri and the timer starts.",
               source: nil),

        // MARK: Practical (no figure, no health outcome)
        DogTip(id: "walk.sniff", kind: .tip,
               template: "Let {name} sniff. A slow walk still fills the ring.",
               source: nil),
        DogTip(id: "walk.water-bags", kind: .tip,
               template: "Heading out for a long one? Bring water and bags.",
               source: nil),
        DogTip(id: "walk.after-dark", kind: .tip,
               template: "Walking after dark? A light or something reflective helps drivers see you both.",
               source: nil),
        DogTip(id: "walk.hot-days", kind: .tip,
               template: "On hot days, save the walk for the cooler part of the day.",
               source: nil),
        DogTip(id: "walk.leash", kind: .tip,
               template: "Near roads or livestock, keep {name} on the leash.",
               source: nil),
        DogTip(id: "walk.tag", kind: .tip,
               template: "Is the phone number on {name's} tag still current? Worth a check.",
               source: nil),
        DogTip(id: "walk.new-route", kind: .tip,
               template: "Try a new route this week. The ring doesn't mind where you go.",
               source: nil),
        DogTip(id: "walk.paws", kind: .tip,
               template: "Muddy, wet or salted streets? A quick paw wipe when you get home.",
               source: nil),
    ]

    /// The tips that fit this dog. The ones written for them come first and alternate with the
    /// rest, so the first card is about their dog and a run of cards never turns into one topic.
    static func deck(for dog: DogProfile, householdSize: Int) -> [DogTip] {
        let fitting = all.filter { $0.applies(to: dog, householdSize: householdSize) }
        let personal = fitting.filter(\.isPersonal)
        let general = fitting.filter { !$0.isPersonal }
        var deck: [DogTip] = []
        for index in 0..<max(personal.count, general.count) {
            if index < personal.count { deck.append(personal[index]) }
            if index < general.count { deck.append(general[index]) }
        }
        return deck
    }

    /// The tip at a position in the deck. Any integer works; it wraps, negatives included.
    static func tip(for dog: DogProfile, householdSize: Int, at index: Int) -> DogTip? {
        let deck = deck(for: dog, householdSize: householdSize)
        guard !deck.isEmpty else { return nil }
        let wrapped = ((index % deck.count) + deck.count) % deck.count
        return deck[wrapped]
    }

    /// Moves on once a day, so a new walk or the paywall doesn't open on the same card every time.
    static func dailyOffset(_ date: Date = Date(), calendar: Calendar = .current) -> Int {
        calendar.ordinality(of: .day, in: .era, for: date) ?? 0
    }
}
