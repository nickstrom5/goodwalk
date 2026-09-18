import Foundation

/// What the user told us about their dog during onboarding. Drives every personalized number.
struct DogProfile: Codable, Equatable {
    var name: String = ""
    var size: Size = .medium
    var breedType: BreedType = .mixed
    var age: Age = .adult
    /// Minutes of walking on a normal day right now, as stated in onboarding.
    var usualMinutes: Int = 20
    /// Daily target the user committed to. 0 = not chosen yet, use the recommendation.
    var goalMinutes: Int = 0

    /// Name for copy. Never empty, so sentences always read.
    var displayName: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "your dog" : trimmed
    }

    /// "Rex's" / "Gus'" is a fight nobody wins; always 's.
    var possessive: String { displayName == "your dog" ? "your dog's" : displayName + "'s" }

    /// The target every screen uses.
    var dailyGoal: Int { goalMinutes > 0 ? goalMinutes : WalkPlan.recommendedMinutes(for: self) }

    enum Size: String, Codable, CaseIterable, Identifiable {
        case toy, small, medium, large, giant
        var id: String { rawValue }

        var label: String { rawValue.capitalized }

        var detail: String {
            switch self {
            case .toy: return "Under 10 lb"
            case .small: return "10–25 lb"
            case .medium: return "25–55 lb"
            case .large: return "55–90 lb"
            case .giant: return "Over 90 lb"
            }
        }

        var example: String {
            switch self {
            case .toy: return "Chihuahua, Yorkie"
            case .small: return "Dachshund, Pug"
            case .medium: return "Beagle, Border Collie"
            case .large: return "Labrador, Shepherd"
            case .giant: return "Great Dane, Mastiff"
            }
        }
    }

    enum BreedType: String, Codable, CaseIterable, Identifiable {
        case companion, terrier, hound, sporting, herding, working, flatFaced, mixed
        var id: String { rawValue }

        var label: String {
            switch self {
            case .companion: return "Companion"
            case .terrier: return "Terrier"
            case .hound: return "Hound"
            case .sporting: return "Sporting"
            case .herding: return "Herding"
            case .working: return "Working"
            case .flatFaced: return "Flat-faced"
            case .mixed: return "Mixed / not sure"
            }
        }

        var symbol: String {
            switch self {
            case .companion: return "heart.fill"
            case .terrier: return "bolt.fill"
            case .hound: return "nose.fill"
            case .sporting: return "figure.run"
            case .herding: return "hare.fill"
            case .working: return "shield.fill"
            case .flatFaced: return "wind"
            case .mixed: return "pawprint.fill"
            }
        }
    }

    enum Age: String, Codable, CaseIterable, Identifiable {
        case puppy, adult, senior
        var id: String { rawValue }

        var label: String { rawValue.capitalized }

        var detail: String {
            switch self {
            case .puppy: return "Under 1 year"
            case .adult: return "1–7 years"
            case .senior: return "8 and up"
            }
        }
    }
}
