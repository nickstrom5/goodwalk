import CoreMotion
import Foundation

/// Measures how far a walk went. Behind a protocol so the simulator (no motion hardware), the
/// tests and screenshots get a deterministic mock, and so GPS could replace the pedometer later
/// without touching the views.
protocol DistanceTracker: AnyObject {
    /// True when readings are real measurements. False means the app should label the number "est."
    var isMeasured: Bool { get }
    /// Begins counting from `start`. Safe to call again for the same walk after a relaunch.
    func begin(from start: Date)
    /// Best current reading in meters, or nil when nothing has been measured yet.
    func currentMeters(at now: Date) -> Double?
    func end()
}

enum DistanceTrackers {
    /// Pedometer on a phone that has one; the seeded mock everywhere else.
    static func makeDefault() -> DistanceTracker {
        #if targetEnvironment(simulator)
        return MockDistanceTracker()
        #else
        return CMPedometer.isDistanceAvailable() ? PedometerDistanceTracker() : MockDistanceTracker()
        #endif
    }
}

/// CoreMotion pedometer. No location permission, works with the phone in a pocket, and the
/// system keeps step history, so a walk survives the app being killed mid-way.
final class PedometerDistanceTracker: DistanceTracker {
    private let pedometer = CMPedometer()
    private var meters: Double?

    let isMeasured = true

    func begin(from start: Date) {
        meters = nil
        pedometer.startUpdates(from: start) { [weak self] data, _ in
            guard let distance = data?.distance?.doubleValue else { return }
            DispatchQueue.main.async { self?.meters = distance }
        }
    }

    func currentMeters(at now: Date) -> Double? { meters }

    func end() { pedometer.stopUpdates() }
}

/// Deterministic stand-in: a steady dog pace from the start time, with a seeded wobble so the
/// number doesn't look fake on screen. Same seed + same elapsed time = same distance.
final class MockDistanceTracker: DistanceTracker {
    private let seed: UInt64
    private let metersPerSecond: Double
    private var start: Date?

    let isMeasured = false

    init(seed: UInt64 = 7, milesPerHour: Double = WalkPlan.dogPaceMilesPerHour) {
        self.seed = seed
        self.metersPerSecond = milesPerHour * WalkPlan.metersPerMile / 3600
    }

    func begin(from start: Date) { self.start = start }

    func currentMeters(at now: Date) -> Double? {
        guard let start else { return nil }
        let elapsed = max(0, now.timeIntervalSince(start))
        // ±4% pace variation, fixed by the seed.
        let wobble = 1 + (Double(seed % 9) - 4) / 100
        return elapsed * metersPerSecond * wobble
    }

    func end() { start = nil }
}
