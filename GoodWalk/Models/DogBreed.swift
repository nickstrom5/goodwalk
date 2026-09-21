import Foundation

/// A breed the owner can search for, so nobody has to decide whether a Beagle counts as small or
/// medium. Choosing one fills in size and type; both stay editable afterwards, because the breed
/// is a shortcut, not an authority. The guideline itself is still `WalkPlan` and nothing else.
///
/// **Provenance.** `size` is this app's own weight band (see `DogProfile.Size.detail`) for the
/// breed's standard adult weight, and `type` is the closest of our eight types to the breed's
/// kennel-club group. Where a breed straddles a band, the band chosen is the one whose result
/// lands nearest the Royal Kennel Club exercise label for that breed: a Pembroke Welsh Corgi is
/// filed small, not medium, because the Kennel Club says "up to 1 hour" and small gets there.
/// `playbook/12-sources.md` §5 carries the full note, including what still needs checking.
struct DogBreed: Identifiable, Equatable, Hashable {
    let name: String
    let size: DogProfile.Size
    let type: DogProfile.BreedType
    /// What people actually type: nicknames, old names, common misspellings.
    let aliases: [String]

    var id: String { name }

    init(_ name: String, _ size: DogProfile.Size, _ type: DogProfile.BreedType, _ aliases: [String] = []) {
        self.name = name
        self.size = size
        self.type = type
        self.aliases = aliases
    }

    /// What an adult of this breed would be offered. Shown next to the name so the choice is
    /// visible before it is made.
    var adultMinutes: Int {
        var dog = DogProfile()
        dog.size = size
        dog.breedType = type
        dog.age = .adult
        return WalkPlan.recommendedMinutes(for: dog)
    }

    /// "Small hound" / "Large sporting dog" / "Giant breed". The line under the name.
    var summary: String {
        switch type {
        case .mixed: return "\(size.label) dog"
        case .companion: return "\(size.label) companion dog"
        case .flatFaced: return "\(size.label), flat-faced"
        case .sporting, .herding, .working: return "\(size.label) \(type.label.lowercased()) dog"
        case .terrier, .hound: return "\(size.label) \(type.label.lowercased())"
        }
    }
}

extension DogBreed {
    /// Common breeds, not every breed. A dog that isn't here is served by the size and type
    /// chips, which is what every dog used before this list existed.
    static let all: [DogBreed] = [
        // Toy: under 10 lb
        DogBreed("Chihuahua", .toy, .companion, ["chiuaua", "chiwawa"]),
        DogBreed("Pomeranian", .toy, .companion, ["pom"]),
        DogBreed("Yorkshire Terrier", .toy, .terrier, ["yorkie"]),
        DogBreed("Maltese", .toy, .companion),
        DogBreed("Papillon", .toy, .companion),
        DogBreed("Toy Poodle", .toy, .companion),
        DogBreed("Pekingese", .toy, .flatFaced, ["pekinese"]),
        DogBreed("Italian Greyhound", .toy, .hound, ["iggy"]),

        // Small: 10–25 lb
        DogBreed("Dachshund", .small, .hound, ["sausage dog", "weiner dog", "wiener dog", "doxie"]),
        DogBreed("Jack Russell Terrier", .small, .terrier, ["jrt"]),
        DogBreed("Pug", .small, .flatFaced),
        DogBreed("French Bulldog", .small, .flatFaced, ["frenchie"]),
        DogBreed("Boston Terrier", .small, .flatFaced),
        DogBreed("Shih Tzu", .small, .flatFaced, ["shitzu", "shih-tzu"]),
        DogBreed("Cavalier King Charles Spaniel", .small, .companion, ["cavalier", "king charles"]),
        DogBreed("Miniature Schnauzer", .small, .terrier, ["mini schnauzer"]),
        DogBreed("West Highland White Terrier", .small, .terrier, ["westie"]),
        DogBreed("Scottish Terrier", .small, .terrier, ["scottie"]),
        DogBreed("Cairn Terrier", .small, .terrier),
        DogBreed("Border Terrier", .small, .terrier),
        DogBreed("Cockapoo", .small, .sporting, ["cocka poo", "cockerpoo"]),
        DogBreed("Bichon Frise", .small, .companion),
        DogBreed("Miniature Poodle", .small, .companion),
        DogBreed("Pembroke Welsh Corgi", .small, .herding, ["corgi", "welsh corgi"]),
        DogBreed("Shetland Sheepdog", .small, .herding, ["sheltie"]),
        DogBreed("Shiba Inu", .small, .working, ["shiba"]),
        DogBreed("Lhasa Apso", .small, .companion),
        DogBreed("Havanese", .small, .companion),

        // Medium: 25–55 lb
        DogBreed("Beagle", .medium, .hound),
        DogBreed("Cocker Spaniel", .medium, .sporting, ["cocker"]),
        DogBreed("English Springer Spaniel", .medium, .sporting, ["springer", "springer spaniel"]),
        DogBreed("Brittany", .medium, .sporting, ["brittany spaniel"]),
        DogBreed("Border Collie", .medium, .herding, ["collie"]),
        DogBreed("Australian Shepherd", .medium, .herding, ["aussie", "aussie shepherd"]),
        DogBreed("Australian Cattle Dog", .medium, .herding, ["blue heeler", "heeler", "red heeler"]),
        DogBreed("Staffordshire Bull Terrier", .medium, .terrier, ["staffy", "staffie", "staff"]),
        DogBreed("American Pit Bull Terrier", .medium, .terrier, ["pitbull", "pit bull", "pittie"]),
        DogBreed("Whippet", .medium, .hound),
        DogBreed("Basset Hound", .medium, .hound, ["basset"]),
        DogBreed("Bulldog", .medium, .flatFaced, ["english bulldog", "british bulldog"]),
        DogBreed("Schnauzer", .medium, .terrier, ["standard schnauzer"]),
        DogBreed("Bull Terrier", .medium, .terrier),
        DogBreed("Chow Chow", .medium, .working, ["chow"]),

        // Large: 55–90 lb
        DogBreed("Labrador Retriever", .large, .sporting, ["lab", "labrador"]),
        DogBreed("Golden Retriever", .large, .sporting, ["golden", "goldie"]),
        DogBreed("German Shepherd", .large, .herding, ["gsd", "alsatian", "german shepard"]),
        DogBreed("Belgian Malinois", .large, .herding, ["malinois", "mal"]),
        DogBreed("German Shorthaired Pointer", .large, .sporting, ["gsp", "pointer"]),
        DogBreed("Vizsla", .large, .sporting),
        DogBreed("Weimaraner", .large, .sporting),
        DogBreed("Dalmatian", .large, .sporting, ["dalmation"]),
        DogBreed("Boxer", .large, .working),
        DogBreed("Doberman Pinscher", .large, .working, ["doberman", "dobermann", "dobie"]),
        DogBreed("Rottweiler", .large, .working, ["rottie", "rotweiler"]),
        DogBreed("Siberian Husky", .large, .working, ["husky"]),
        DogBreed("Alaskan Malamute", .large, .working, ["malamute"]),
        DogBreed("Standard Poodle", .large, .working, ["poodle"]),
        DogBreed("Labradoodle", .large, .sporting, ["labra doodle"]),
        DogBreed("Goldendoodle", .large, .sporting, ["golden doodle"]),
        DogBreed("Greyhound", .large, .hound),
        DogBreed("Rhodesian Ridgeback", .large, .hound, ["ridgeback"]),
        DogBreed("Airedale Terrier", .large, .terrier, ["airedale"]),
        DogBreed("Old English Sheepdog", .large, .herding),

        // Giant: over 90 lb
        DogBreed("Bernese Mountain Dog", .giant, .working, ["bernese", "berner"]),
        DogBreed("Great Dane", .giant, .working, ["dane"]),
        DogBreed("Saint Bernard", .giant, .mixed, ["st bernard", "st. bernard"]),
        DogBreed("Newfoundland", .giant, .mixed, ["newfie"]),
        DogBreed("Mastiff", .giant, .mixed, ["english mastiff"]),
        DogBreed("Irish Wolfhound", .giant, .working, ["wolfhound"]),
        DogBreed("Leonberger", .giant, .working),
        DogBreed("Great Pyrenees", .giant, .working, ["pyrenean mountain dog", "pyrenees"]),
    ]

    /// Matches on any word of the name or an alias, so "collie" finds Border Collie and "shepherd"
    /// finds both shepherds. Exact and prefix matches come first; nothing fuzzy, because a wrong
    /// guess here quietly changes the dog's target.
    static func search(_ query: String, in breeds: [DogBreed] = DogBreed.all) -> [DogBreed] {
        let needle = normalise(query)
        guard !needle.isEmpty else { return breeds }

        return breeds.compactMap { breed -> (DogBreed, Int)? in
            guard let rank = rank(breed, needle) else { return nil }
            return (breed, rank)
        }
        .sorted { left, right in
            left.1 == right.1 ? left.0.name < right.0.name : left.1 < right.1
        }
        .map(\.0)
    }

    /// Lower wins. An exact hit comes first so that "lab" finds the Labrador before the
    /// Labradoodle, which a plain prefix sort would put on top for being alphabetically earlier.
    /// 0 = the name or a nickname is exactly this, 1 = the name starts with it, 2 = a later word
    /// does, 3 = a nickname starts with it.
    private static func rank(_ breed: DogBreed, _ needle: String) -> Int? {
        let name = normalise(breed.name)
        let aliases = breed.aliases.map(normalise)
        if name == needle || aliases.contains(needle) { return 0 }
        if name.hasPrefix(needle) { return 1 }
        if name.split(separator: " ").contains(where: { $0.hasPrefix(needle) }) { return 2 }
        if aliases.contains(where: { alias in
            alias.hasPrefix(needle) || alias.split(separator: " ").contains { $0.hasPrefix(needle) }
        }) { return 3 }
        return nil
    }

    /// Lowercased, accent-folded, punctuation dropped: "Shih-Tzu" and "shih tzu" are one search.
    private static func normalise(_ text: String) -> String {
        text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .replacingOccurrences(of: "[^a-z0-9 ]", with: " ", options: .regularExpression)
            .split(separator: " ")
            .joined(separator: " ")
    }
}
