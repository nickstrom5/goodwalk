import Foundation
import UIKit

/// Launch the app with `-screenshot <screen>` to open one screen with seeded data.
/// Used by `.github/workflows/screenshots.yml` to capture every screen in the simulator, and
/// handy for App Store screenshots. Never active in a normal launch.
enum ScreenshotMode {
    enum Screen: String, CaseIterable {
        case hook, dog, size, breed, usual, reveal, plan, first, result, paywall
        case home, walking, log, milestone, stats, walkcard, settings, share
    }

    static let screen: Screen? = {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-screenshot"), i + 1 < args.count else { return nil }
        return Screen(rawValue: args[i + 1])
    }()


    /// A finished 42-minute walk, for the `-screenshot walkcard` route.
    static var sampleWalk: Walk {
        Walk(start: Date().addingTimeInterval(-42 * 60), minutes: 42,
             distanceMeters: WalkPlan.estimatedMeters(forMinutes: 42),
             distanceEstimated: false, source: .timer)
    }

    static var isActive: Bool { screen != nil }

    /// Minutes walked on each of the 29 days before today, newest first. With today's 25 this is
    /// 1,410 minutes: 47.0 miles at dog pace, on a 30-day streak. The numbers on the share card.
    static let seededMinutes: [Int] = {
        let week = [45, 60, 40, 50, 35, 65, 45]
        return (0..<28).map { week[$0 % 7] } + [25]
    }()

    /// Fills the app with believable data so screens don't look empty.
    @MainActor
    static func seed(_ appState: AppState) {
        UIView.setAnimationsEnabled(false)
        appState.cancelWalk()

        var dog = DogProfile()
        dog.name = "Rex"
        dog.size = .medium
        dog.breedType = .mixed
        dog.age = .adult
        dog.usualMinutes = 20
        dog.goalMinutes = 60
        appState.dog = dog
        appState.seedPhoto(UIImage(named: "SampleDog"))

        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        func walk(daysAgo: Int, hour: Int, minutes: Int) -> Walk {
            let day = cal.date(byAdding: .day, value: -daysAgo, to: today)!
            let start = cal.date(byAdding: .hour, value: hour, to: day)!
            return Walk(start: start, minutes: minutes, distanceMeters: WalkPlan.estimatedMeters(forMinutes: minutes),
                        distanceEstimated: false, source: .timer)
        }

        var walks = seededMinutes.enumerated().map { index, minutes in
            walk(daysAgo: index + 1, hour: 17, minutes: minutes)
        }
        // This morning's walk. Today is not at the target yet, so home shows a ring in progress.
        walks.append(walk(daysAgo: 0, hour: 7, minutes: 25))

        switch screen {
        case .first:
            walks = []
        case .result:
            walks = [Walk(start: Date(), minutes: 30, distanceMeters: WalkPlan.estimatedMeters(forMinutes: 30),
                          distanceEstimated: true, source: .onboarding)]
        default:
            break
        }
        appState.replaceWalks(walks, celebrated: [1, 3, 7, 14, 30])

        if screen == .walking {
            // 18 minutes and 24 seconds in.
            appState.seedActiveWalk(start: Date().addingTimeInterval(-(18 * 60 + 24)))
        }
        appState.hasCompletedOnboarding = {
            switch screen {
            case .home, .walking, .log, .milestone, .stats, .walkcard, .settings, .share: return true
            default: return false
            }
        }()
    }
}
