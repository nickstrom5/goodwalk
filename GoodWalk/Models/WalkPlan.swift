import Foundation

/// The recommendation math behind the reveal. A general guideline, not veterinary advice; the
/// UI says so wherever these numbers appear.
///
/// The size bases and breed-type factors are calibrated to the Royal Kennel Club's Breeds A to Z
/// exercise bands ("Up to 30 minutes", "Up to 1 hour", "More than 2 hours per day") and PDSA's
/// breed pages. Every figure, source and date is in docs/12-sources.md; the tables are mirrored in
/// docs/01-strategy.md. Change a number here and change it there.
enum WalkPlan {
    static let minimumMinutes = 15
    static let maximumMinutes = 120

    /// Pace used to estimate distance for quick-logged walks. Slower than a person alone:
    /// dogs stop to read the news.
    static let dogPaceMilesPerHour = 2.0
    static let metersPerMile = 1609.344

    static func baseMinutes(for size: DogProfile.Size) -> Double {
        switch size {
        case .toy: return 30     // KC: 18 of 24 Toy-group breeds are "Up to 30 minutes per day"
        case .small: return 40   // KC: small terrier, utility and hound breeds are "Up to 1 hour"
        case .medium: return 60  // KC: most medium breeds are "Up to 1 hour"
        case .large: return 90   // KC: 56 of 79 large breeds are "More than 2 hours"; halfway up
        case .giant: return 60   // KC: St. Bernard, Mastiff, Newfoundland "Up to 1 hour"; Great Dane more
        }
    }

    static func breedFactor(for type: DogProfile.BreedType) -> Double {
        switch type {
        case .flatFaced: return 0.6   // KC + PDSA: Pug, French Bulldog, Bulldog "up to an hour"; stay low
        case .companion, .terrier, .hound, .mixed: return 1.0   // KC: these sit in the band their size gives
        case .working: return 1.15    // KC: large Working breeds split between "Up to 1 hour" and "More than 2"
        case .sporting: return 1.35   // KC: 21 of 24 large Gundogs "More than 2 hours" → large hits the cap
        case .herding: return 1.5     // KC + PDSA: Border Collie, German Shepherd "minimum of two hours"
        }
    }

    /// PDSA, the Kennel Club and the RSPCA all say puppies and older dogs want shorter walks, but
    /// none gives a ratio. The direction is sourced; 0.6 and 0.7 are our judgment (docs/12-sources.md).
    static func ageFactor(for age: DogProfile.Age) -> Double {
        switch age {
        case .puppy: return 0.6
        case .adult: return 1.0
        case .senior: return 0.7
        }
    }

    /// Minutes a day for this dog, rounded to the nearest 5 and clamped to 15...120.
    static func recommendedMinutes(for dog: DogProfile) -> Int {
        let raw = baseMinutes(for: dog.size) * breedFactor(for: dog.breedType) * ageFactor(for: dog.age)
        let rounded = Int((raw / 5).rounded()) * 5
        return min(maximumMinutes, max(minimumMinutes, rounded))
    }

    /// Median dog walking among owners who walk their dog: 160 minutes a week across 29 studies
    /// (Christian et al., J Phys Act Health 2013;10(5):750-9). No source splits this by dog size,
    /// so neither do we.
    static let typicalMinutesPerWeek = 160

    /// The same figure per day, rounded: 160 / 7 = 22.9 → 23.
    static var typicalMinutes: Int { Int((Double(typicalMinutesPerWeek) / 7).rounded()) }

    /// Minutes a day between what the dog gets now and the guideline. Never negative.
    static func dailyGap(for dog: DogProfile) -> Int {
        max(0, recommendedMinutes(for: dog) - dog.usualMinutes)
    }

    /// The gap over a year, in whole hours. The number on the reveal.
    static func yearlyGapHours(for dog: DogProfile) -> Int {
        Int((Double(dailyGap(for: dog)) * 365 / 60).rounded())
    }

    /// Distance guess for a quick-logged walk, in meters.
    static func estimatedMeters(forMinutes minutes: Int) -> Double {
        Double(minutes) / 60 * dogPaceMilesPerHour * metersPerMile
    }

    /// Targets offered on the plan screen: the recommendation and sensible steps around it.
    static func goalOptions(for dog: DogProfile) -> [Int] {
        let rec = recommendedMinutes(for: dog)
        let options = [rec - 30, rec - 15, rec, rec + 15].filter { $0 >= minimumMinutes && $0 <= maximumMinutes }
        return Array(Set(options)).sorted()
    }
}
