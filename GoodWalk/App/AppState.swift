import Foundation
import SwiftUI
import WidgetKit

/// Small, persisted app state. Everything here is local; there is no backend in v1.
///
/// A household can have more than one dog. `dogs` is the roster, `dog` is the one the screens are
/// showing, and every walk records the dogs it counted for. Walking two dogs at once is one walk
/// on both their rings, not two walks, which is what keeps "Walked ✓" a single tap.
@MainActor
final class AppState: ObservableObject {
    private let defaults: UserDefaults
    private let cal = Calendar.current
    private let tracker: DistanceTracker

    @Published var hasCompletedOnboarding: Bool {
        didSet { defaults.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding") }
    }

    /// Every dog in the house, in the order they were added. Never empty.
    @Published var dogs: [DogProfile] {
        didSet {
            save(dogs, forKey: "dogs")
            recompute()
        }
    }

    /// The dog the screens are showing. With one dog this is simply that dog.
    @Published var selectedDogID: UUID {
        didSet {
            defaults.set(selectedDogID.uuidString, forKey: "selectedDogID")
            recompute()
        }
    }

    /// Each dog's photo, if the user picked one. Persisted as files by `DogPhotoStore`.
    @Published private(set) var dogImages: [UUID: UIImage]

    /// Every walk, oldest first.
    @Published private(set) var walks: [Walk] {
        didSet {
            save(walks, forKey: "walks")
            recompute()
        }
    }

    /// Today's numbers for the dog on screen.
    @Published private(set) var stats = Stats()

    /// The streak and the totals for the whole house.
    @Published private(set) var household = Stats.Household()

    /// Start of the walk being timed right now. Persisted, so the timer survives the app being killed.
    @Published private(set) var activeWalkStart: Date? {
        didSet {
            if let activeWalkStart { defaults.set(activeWalkStart, forKey: "activeWalkStart") }
            else { defaults.removeObject(forKey: "activeWalkStart") }
        }
    }

    /// Who is on the walk being timed. Persisted with the start date for the same reason.
    @Published private(set) var activeWalkDogIDs: [UUID] {
        didSet { defaults.set(activeWalkDogIDs.map(\.uuidString), forKey: "activeWalkDogIDs") }
    }

    /// Daily reminder time as minutes after midnight. Default 5:30 PM.
    @Published var reminderMinutes: Int {
        didSet { defaults.set(reminderMinutes, forKey: "reminderMinutes") }
    }

    /// Streak milestones already shown as a card, so each one fires once.
    @Published private(set) var celebratedMilestones: Set<Int> {
        didSet { save(Array(celebratedMilestones), forKey: "celebratedMilestones") }
    }

    /// Set when a walk pushes the streak onto a milestone. Home presents the card.
    @Published var pendingMilestone: Int?

    /// Flips to true when a walk takes the shown dog over their target. Home throws the confetti.
    @Published var goalJustHit = false

    /// The most recent walk written this session, for result screens.
    @Published var lastWalk: Walk?

    init(defaults: UserDefaults = AppGroup.defaults, tracker: DistanceTracker = DistanceTrackers.makeDefault()) {
        self.defaults = defaults
        self.tracker = tracker
        hasCompletedOnboarding = defaults.bool(forKey: "hasCompletedOnboarding")

        // The roster, falling back to the single dog older dev builds stored, then to a new one.
        var roster = Self.load([DogProfile].self, forKey: "dogs", from: defaults) ?? []
        if roster.isEmpty {
            roster = [Self.load(DogProfile.self, forKey: "dogProfile", from: defaults) ?? DogProfile()]
        }
        dogs = roster
        let storedSelection = (defaults.string(forKey: "selectedDogID")).flatMap(UUID.init(uuidString:))
        selectedDogID = roster.contains(where: { $0.id == storedSelection }) ? (storedSelection ?? roster[0].id) : roster[0].id

        walks = Self.load([Walk].self, forKey: "walks", from: defaults) ?? []
        reminderMinutes = (defaults.object(forKey: "reminderMinutes") as? Int) ?? (17 * 60 + 30)
        celebratedMilestones = Set(Self.load([Int].self, forKey: "celebratedMilestones", from: defaults) ?? [])
        activeWalkStart = defaults.object(forKey: "activeWalkStart") as? Date
        activeWalkDogIDs = (defaults.stringArray(forKey: "activeWalkDogIDs") ?? []).compactMap(UUID.init(uuidString:))
        dogImages = Dictionary(uniqueKeysWithValues: roster.compactMap { dog in
            DogPhotoStore.load(for: dog.id).map { (dog.id, $0) }
        })
        if let activeWalkStart { tracker.begin(from: activeWalkStart) }
        recompute()
    }

    // MARK: - The roster

    /// The dog every screen is showing. Setting it writes back into the roster.
    var dog: DogProfile {
        get { dogs.first { $0.id == selectedDogID } ?? dogs.first ?? DogProfile() }
        set {
            if let index = dogs.firstIndex(where: { $0.id == newValue.id }) {
                dogs[index] = newValue
            } else if let index = dogs.firstIndex(where: { $0.id == selectedDogID }) {
                // A profile built from scratch replaces the dog on screen rather than silently
                // doing nothing, but keeps their identity and arrival date so the walks already
                // logged against them stay theirs.
                var replacement = newValue
                replacement.id = dogs[index].id
                replacement.addedOn = dogs[index].addedOn
                dogs[index] = replacement
            }
        }
    }

    var hasMultipleDogs: Bool { dogs.count > 1 }

    /// Every dog's name, for the reminder text and anywhere copy lists them.
    var dogNames: [String] { dogs.map(\.displayName) }

    /// Adds a dog and shows them. Their streak starts today; earlier days are not their fault.
    @discardableResult
    func addDog(_ dog: DogProfile) -> DogProfile {
        var added = dog
        added.addedOn = Date()
        dogs.append(added)
        selectedDogID = added.id
        Analytics.track(.dogAdded, ["count": dogs.count])
        return added
    }

    /// Removes a dog, their photo, and their claim on past walks. The last dog can't be removed:
    /// an app with no dog has nothing to show.
    func removeDog(_ dogID: UUID) {
        guard dogs.count > 1, let index = dogs.firstIndex(where: { $0.id == dogID }) else { return }
        dogs.remove(at: index)
        dogImages[dogID] = nil
        DogPhotoStore.delete(for: dogID)
        // A walk that was only ever theirs goes with them; a shared walk stays, minus their name.
        var updated = walks.compactMap { walk -> Walk? in
            guard walk.dogIDs.contains(dogID) else { return walk }
            var trimmed = walk
            trimmed.dogIDs.removeAll { $0 == dogID }
            return trimmed.dogIDs.isEmpty ? nil : trimmed
        }
        updated.sort { $0.start < $1.start }
        walks = updated
        if selectedDogID == dogID { selectedDogID = dogs[0].id }
        activeWalkDogIDs.removeAll { $0 == dogID }
        Analytics.track(.dogRemoved, ["count": dogs.count])
    }

    func select(_ dogID: UUID) {
        guard dogs.contains(where: { $0.id == dogID }) else { return }
        selectedDogID = dogID
    }

    func dog(withID dogID: UUID) -> DogProfile? { dogs.first { $0.id == dogID } }

    /// A writable handle on one dog, for the editor screens.
    func binding(for dogID: UUID) -> Binding<DogProfile>? {
        guard dogs.contains(where: { $0.id == dogID }) else { return nil }
        return Binding(
            get: { [weak self] in self?.dogs.first { $0.id == dogID } ?? DogProfile() },
            set: { [weak self] newValue in
                guard let self, let index = self.dogs.firstIndex(where: { $0.id == dogID }) else { return }
                self.dogs[index] = newValue
            }
        )
    }

    /// The photo of the dog on screen.
    var dogImage: UIImage? { dogImages[selectedDogID] }

    func image(for dogID: UUID) -> UIImage? { dogImages[dogID] }

    /// Dogs with nothing logged today. What the reminder is really asking about.
    var dogsNotWalkedToday: [DogProfile] {
        dogs.filter { minutesToday(for: $0.id) == 0 }
    }

    // MARK: - The walk timer

    var isWalking: Bool { activeWalkStart != nil }

    /// `dogIDs` empty means everyone: the common case is the whole household on one leash walk.
    func startWalk(source: String, dogIDs: [UUID]? = nil, at date: Date = Date()) {
        guard activeWalkStart == nil else { return }
        let walking = resolve(dogIDs)
        activeWalkDogIDs = walking
        activeWalkStart = date
        tracker.begin(from: date)
        WalkActivityController.start(dogName: DogProfile.names(dogs.filter { walking.contains($0.id) }),
                                     startDate: date,
                                     minutesBeforeThisWalk: stats.minutesToday, goalMinutes: dog.dailyGoal)
        Analytics.track(.walkStarted, ["source": source, "dogs": walking.count])
    }

    /// Adds or removes a dog from the walk already running, for the dog who joined at the door.
    func setWalking(_ dogID: UUID, on: Bool) {
        var walking = activeWalkDogIDs
        if on {
            guard !walking.contains(dogID) else { return }
            walking.append(dogID)
        } else {
            guard walking.count > 1 else { return }   // a walk with nobody on it is not a walk
            walking.removeAll { $0 == dogID }
        }
        activeWalkDogIDs = walking
    }

    func isOnActiveWalk(_ dogID: UUID) -> Bool { activeWalkDogIDs.contains(dogID) }

    func elapsedSeconds(at now: Date = Date()) -> Int {
        guard let activeWalkStart else { return 0 }
        return max(0, Int(now.timeIntervalSince(activeWalkStart)))
    }

    /// Live distance for the timer screen, measured or estimated.
    func liveMeters(at now: Date = Date()) -> Double {
        tracker.currentMeters(at: now) ?? WalkPlan.estimatedMeters(forMinutes: elapsedSeconds(at: now) / 60)
    }

    var distanceIsMeasured: Bool { tracker.isMeasured }

    /// Stops the timer and logs the walk. Anything under 30 seconds is a mis-tap and is dropped.
    @discardableResult
    func finishWalk(at now: Date = Date()) -> Walk? {
        guard let start = activeWalkStart else { return nil }
        let seconds = elapsedSeconds(at: now)
        let measured = tracker.currentMeters(at: now)
        let walking = resolve(activeWalkDogIDs)
        tracker.end()
        activeWalkStart = nil
        activeWalkDogIDs = []
        WalkActivityController.endAll()
        guard seconds >= 30 else { return nil }
        let minutes = max(1, Int((Double(seconds) / 60).rounded()))
        let walk = Walk(start: start, minutes: minutes,
                        distanceMeters: measured ?? WalkPlan.estimatedMeters(forMinutes: minutes),
                        distanceEstimated: measured == nil || !tracker.isMeasured, source: .timer,
                        dogIDs: walking)
        add(walk)
        Analytics.track(.walkFinished, ["minutes": minutes, "measured": !walk.distanceEstimated, "dogs": walking.count])
        return walk
    }

    func cancelWalk() {
        tracker.end()
        activeWalkStart = nil
        activeWalkDogIDs = []
        WalkActivityController.endAll()
    }

    // MARK: - Logging

    /// Logs a walk that already happened. Distance is a pace-based estimate.
    @discardableResult
    func quickLog(minutes: Int, source: Walk.Source, dogIDs: [UUID]? = nil, at date: Date = Date()) -> Walk {
        let clamped = min(600, max(1, minutes))
        let walked = resolve(dogIDs)
        let walk = Walk(start: date, minutes: clamped,
                        distanceMeters: WalkPlan.estimatedMeters(forMinutes: clamped),
                        distanceEstimated: true, source: source, dogIDs: walked)
        add(walk)
        Analytics.track(.walkQuickLogged, ["minutes": clamped, "source": source.rawValue, "dogs": walked.count])
        return walk
    }

    /// What "Walked ✓" on the notification does: logs the usual walk for whoever still hasn't
    /// been out. One tap, however many dogs, and it never double-logs the one already walked.
    @discardableResult
    func logUsualWalkForDogsNotWalkedToday(at date: Date = Date()) -> Walk? {
        let waiting = dogsNotWalkedToday
        guard !waiting.isEmpty else { return nil }
        let minutes = waiting.map { max(5, $0.usualMinutes) }.max() ?? 20
        return quickLog(minutes: minutes, source: .notification, dogIDs: waiting.map(\.id), at: date)
    }

    func delete(_ walk: Walk) {
        walks.removeAll { $0.id == walk.id }
        Analytics.track(.walkDeleted)
    }

    private func add(_ walk: Walk) {
        let goal = dog.dailyGoal
        let before = stats.minutesToday
        var updated = walks
        updated.append(walk)
        updated.sort { $0.start < $1.start }
        if updated.count > 5_000 { updated.removeFirst(updated.count - 5_000) }
        walks = updated
        lastWalk = walk

        if cal.isDateInToday(walk.start), before < goal, stats.minutesToday >= goal {
            goalJustHit = true
            Analytics.track(.goalHit, ["minutes": stats.minutesToday, "goal": goal])
        }
        // Milestones belong to the household: the streak on the home screen is the one being
        // celebrated, so the card can't fire off a number nobody is looking at.
        if Stats.milestones.contains(household.streak), !celebratedMilestones.contains(household.streak) {
            celebratedMilestones.insert(household.streak)
            pendingMilestone = household.streak
            Analytics.track(.milestoneReached, ["streak": household.streak])
        }
    }

    /// Everyone, when the caller didn't say. Walking the whole house is the normal case.
    private func resolve(_ dogIDs: [UUID]?) -> [UUID] {
        let requested = (dogIDs ?? []).filter { id in dogs.contains { $0.id == id } }
        return requested.isEmpty ? dogs.map(\.id) : requested
    }

    // MARK: - Derived

    /// Every walk that counted for a dog.
    func walks(forDog dogID: UUID) -> [Walk] {
        walks.filter { $0.counted(for: dogID) }
    }

    func minutesToday(for dogID: UUID) -> Int {
        walks.filter { $0.counted(for: dogID) && cal.isDateInToday($0.start) }
            .reduce(0) { $0 + $1.minutes }
    }

    /// Today's progress for any dog, 0...1.
    func progressToday(for dogID: UUID) -> Double {
        guard let dog = dog(withID: dogID) else { return 0 }
        return min(1, Double(minutesToday(for: dogID)) / Double(max(1, dog.dailyGoal)))
    }

    /// Every walk logged today, whoever it was for. The log, not one dog's ring.
    var todaysWalks: [Walk] { walks.filter { cal.isDateInToday($0.start) } }

    var walkedToday: Bool { stats.minutesToday > 0 }

    /// 0...1 for the ring. Never more than full; the number under it can keep going.
    var todayProgress: Double {
        let goal = max(1, dog.dailyGoal)
        return min(1, Double(stats.minutesToday) / Double(goal))
    }

    /// The current calendar week for the dog on screen, in the user's locale, with minutes per day.
    var thisWeek: [WeekDay] {
        let today = cal.startOfDay(for: Date())
        guard let start = cal.dateInterval(of: .weekOfYear, for: today)?.start else { return [] }
        var minutesByDay: [Date: Int] = [:]
        for walk in walks(forDog: selectedDogID) {
            minutesByDay[cal.startOfDay(for: walk.start), default: 0] += walk.minutes
        }
        return (0..<7).compactMap { offset in
            guard let date = cal.date(byAdding: .day, value: offset, to: start) else { return nil }
            return WeekDay(date: date, minutes: minutesByDay[date] ?? 0,
                           isToday: cal.isDate(date, inSameDayAs: today), isFuture: date > today)
        }
    }

    // MARK: - Photo

    func setDogPhoto(_ image: UIImage, for dogID: UUID? = nil) {
        let id = dogID ?? selectedDogID
        dogImages[id] = DogPhotoStore.save(image, for: id) ?? image
        if id == selectedDogID { DogPhotoStore.mirrorToWidget(dogImages[id]) }
        Analytics.track(.photoAdded)
        WidgetCenter.shared.reloadAllTimelines()
    }

    func removeDogPhoto(for dogID: UUID? = nil) {
        let id = dogID ?? selectedDogID
        DogPhotoStore.delete(for: id)
        dogImages[id] = nil
        if id == selectedDogID { DogPhotoStore.mirrorToWidget(nil) }
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Intent

    /// Reads and clears the flag left behind by the widget / Siri intent. Returns true when the
    /// caller should start (or is allowed to start) the walk timer.
    func consumePendingStartWalk() -> Bool {
        guard defaults.bool(forKey: AppGroup.Key.pendingStartWalk) else { return false }
        defaults.removeObject(forKey: AppGroup.Key.pendingStartWalk)
        return hasCompletedOnboarding
    }

    // MARK: - Derived

    private func recompute() {
        stats = Stats.compute(walks: walks(forDog: selectedDogID), goalMinutes: dog.dailyGoal)
        household = Stats.Household.compute(dogs: dogs, walks: walks)
        mirrorToWidget()
    }

    private func mirrorToWidget() {
        defaults.set(dog.displayName, forKey: AppGroup.Key.dogName)
        defaults.set(dog.dailyGoal, forKey: AppGroup.Key.goalMinutes)
        defaults.set(stats.minutesToday, forKey: AppGroup.Key.minutesToday)
        defaults.set(AppGroup.dayFormatter.string(from: Date()), forKey: AppGroup.Key.minutesDay)
        defaults.set(household.streak, forKey: AppGroup.Key.streak)
        defaults.set(dogs.count, forKey: AppGroup.Key.dogCount)
        DogPhotoStore.mirrorToWidget(dogImages[selectedDogID])
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Persistence helpers

    private func save<T: Encodable>(_ value: T, forKey key: String) {
        if let data = try? JSONEncoder().encode(value) {
            defaults.set(data, forKey: key)
        }
    }

    private static func load<T: Decodable>(_ type: T.Type, forKey key: String, from defaults: UserDefaults) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    // MARK: - Test / screenshot seeding

    func replaceWalks(_ newWalks: [Walk], celebrated: Set<Int> = []) {
        celebratedMilestones = celebrated
        walks = newWalks.sorted { $0.start < $1.start }
        pendingMilestone = nil
        goalJustHit = false
    }

    /// Replaces the whole roster, for tests and `-screenshot` launches.
    func replaceDogs(_ newDogs: [DogProfile]) {
        guard !newDogs.isEmpty else { return }
        dogs = newDogs
        selectedDogID = newDogs[0].id
    }

    func seedPhoto(_ image: UIImage?, for dogID: UUID? = nil) {
        let id = dogID ?? selectedDogID
        dogImages[id] = image
    }

    func seedActiveWalk(start: Date, dogIDs: [UUID]? = nil) {
        activeWalkDogIDs = resolve(dogIDs)
        activeWalkStart = start
        tracker.begin(from: start)
    }
}
