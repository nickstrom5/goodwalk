import Foundation

/// The recommendation math behind the reveal. A general guideline, not veterinary advice; the
/// UI says so wherever these numbers appear.
///
/// Assumptions are documented in docs/01-strategy.md ("Where the numbers come from"). Cite
/// sources for them before submission.
enum WalkPlan {
    static let minimumMinutes = 15
    static let maximumMinutes = 120

    /// Pace used to estimate distance for quick-logged walks. Slower than a person alone:
    /// dogs stop to read the news.
    static let dogPaceMilesPerHour = 2.0
    static let metersPerMile = 1609.344

    static func baseMinutes(for size: DogProfile.Size) -> Double {
        switch size {
        case .toy: return 30
        case .small: return 40
        case .medium: return 60
        case .large: return 75
        case .giant: return 45   // big frames, easy does it
        }
    }

    static func breedFactor(for type: DogProfile.BreedType) -> Double {
        switch type {
        case .flatFaced: return 0.6
        case .companion: return 0.75
        case .terrier, .hound, .mixed: return 1.0
        case .working: return 1.15
        case .sporting: return 1.25
        case .herding: return 1.35
        }
    }

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

    /// What a typical dog of this size gets per day. Placeholder survey figures; cite or replace.
    static func typicalMinutes(for size: DogProfile.Size) -> Int {
        switch size {
        case .toy: return 17
        case .small: return 19
        case .medium: return 22
        case .large: return 24
        case .giant: return 21
        }
    }

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
