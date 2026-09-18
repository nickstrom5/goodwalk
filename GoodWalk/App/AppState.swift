import Foundation
import SwiftUI
import WidgetKit

/// Small, persisted app state. Everything here is local; there is no backend in v1.
@MainActor
final class AppState: ObservableObject {
    private let defaults: UserDefaults
    private let cal = Calendar.current
    private let tracker: DistanceTracker

    @Published var hasCompletedOnboarding: Bool {
        didSet { defaults.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding") }
    }

    @Published var dog: DogProfile {
        didSet {
            save(dog, forKey: "dogProfile")
            recompute()
        }
    }

    /// The dog's photo, if the user picked one. Persisted as a file by `DogPhotoStore`.
    @Published private(set) var dogImage: UIImage?

    /// Every walk, oldest first.
    @Published private(set) var walks: [Walk] {
        didSet {
            save(walks, forKey: "walks")
            recompute()
        }
    }

    @Published private(set) var stats = Stats()

    /// Start of the walk being timed right now. Persisted, so the timer survives the app being killed.
    @Published private(set) var activeWalkStart: Date? {
        didSet {
            if let activeWalkStart { defaults.set(activeWalkStart, forKey: "activeWalkStart") }
            else { defaults.removeObject(forKey: "activeWalkStart") }
        }
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

    /// Flips to true when a walk takes today over the target. Home throws the confetti.
    @Published var goalJustHit = false

    /// The most recent walk written this session, for result screens.
    @Published var lastWalk: Walk?

    init(defaults: UserDefaults = AppGroup.defaults, tracker: DistanceTracker = DistanceTrackers.makeDefault()) {
        self.defaults = defaults
        self.tracker = tracker
        hasCompletedOnboarding = defaults.bool(forKey: "hasCompletedOnboarding")
        dog = Self.load(DogProfile.self, forKey: "dogProfile", from: defaults) ?? DogProfile()
        walks = Self.load([Walk].self, forKey: "walks", from: defaults) ?? []
        reminderMinutes = (defaults.object(forKey: "reminderMinutes") as? Int) ?? (17 * 60 + 30)
        celebratedMilestones = Set(Self.load([Int].self, forKey: "celebratedMilestones", from: defaults) ?? [])
        activeWalkStart = defaults.object(forKey: "activeWalkStart") as? Date
        dogImage = DogPhotoStore.load()
        if let activeWalkStart { tracker.begin(from: activeWalkStart) }
        recompute()
    }

    // MARK: - The walk timer

    var isWalking: Bool { activeWalkStart != nil }

    func startWalk(source: String, at date: Date = Date()) {
        guard activeWalkStart == nil else { return }
        activeWalkStart = date
        tracker.begin(from: date)
        Analytics.track(.walkStarted, ["source": source])
    }

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
        tracker.end()
        activeWalkStart = nil
        guard seconds >= 30 else { return nil }
        let minutes = max(1, Int((Double(seconds) / 60).rounded()))
        let walk = Walk(start: start, minutes: minutes,
                        distanceMeters: measured ?? WalkPlan.estimatedMeters(forMinutes: minutes),
                        distanceEstimated: measured == nil || !tracker.isMeasured, source: .timer)
        add(walk)
        Analytics.track(.walkFinished, ["minutes": minutes, "measured": !walk.distanceEstimated])
        return walk
    }

    func cancelWalk() {
        tracker.end()
        activeWalkStart = nil
    }

    // MARK: - Logging

    /// Logs a walk that already happened. Distance is a pace-based estimate.
    @discardableResult
    func quickLog(minutes: Int, source: Walk.Source, at date: Date = Date()) -> Walk {
        let clamped = min(600, max(1, minutes))
        let walk = Walk(start: date, minutes: clamped,
                        distanceMeters: WalkPlan.estimatedMeters(forMinutes: clamped),
                        distanceEstimated: true, source: source)
        add(walk)
        Analytics.track(.walkQuickLogged, ["minutes": clamped, "source": source.rawValue])
        return walk
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
        if Stats.milestones.contains(stats.streak), !celebratedMilestones.contains(stats.streak) {
            celebratedMilestones.insert(stats.streak)
            pendingMilestone = stats.streak
            Analytics.track(.milestoneReached, ["streak": stats.streak])
        }
    }

    var todaysWalks: [Walk] { walks.filter { cal.isDateInToday($0.start) } }

    var walkedToday: Bool { stats.minutesToday > 0 }

    /// 0...1 for the ring. Never more than full; the number under it can keep going.
    var todayProgress: Double {
        let goal = max(1, dog.dailyGoal)
        return min(1, Double(stats.minutesToday) / Double(goal))
    }

    /// The current calendar week, in the user's locale, with minutes per day.
    var thisWeek: [WeekDay] {
        let today = cal.startOfDay(for: Date())
        guard let start = cal.dateInterval(of: .weekOfYear, for: today)?.start else { return [] }
        var minutesByDay: [Date: Int] = [:]
        for walk in walks { minutesByDay[cal.startOfDay(for: walk.start), default: 0] += walk.minutes }
        return (0..<7).compactMap { offset in
            guard let date = cal.date(byAdding: .day, value: offset, to: start) else { return nil }
            return WeekDay(date: date, minutes: minutesByDay[date] ?? 0,
                           isToday: cal.isDate(date, inSameDayAs: today), isFuture: date > today)
        }
    }

    // MARK: - Photo

    func setDogPhoto(_ image: UIImage) {
        dogImage = DogPhotoStore.save(image) ?? image
        Analytics.track(.photoAdded)
        WidgetCenter.shared.reloadAllTimelines()
    }

    func removeDogPhoto() {
        DogPhotoStore.delete()
        dogImage = nil
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
        stats = Stats.compute(walks: walks, goalMinutes: dog.dailyGoal)
        mirrorToWidget()
    }

    private func mirrorToWidget() {
        defaults.set(dog.displayName, forKey: AppGroup.Key.dogName)
        defaults.set(dog.dailyGoal, forKey: AppGroup.Key.goalMinutes)
        defaults.set(stats.minutesToday, forKey: AppGroup.Key.minutesToday)
        defaults.set(AppGroup.dayFormatter.string(from: Date()), forKey: AppGroup.Key.minutesDay)
        defaults.set(stats.streak, forKey: AppGroup.Key.streak)
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

    func seedPhoto(_ image: UIImage?) { dogImage = image }

    func seedActiveWalk(start: Date) {
        activeWalkStart = start
        tracker.begin(from: start)
    }
}
