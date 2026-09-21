import Foundation
import UIKit

/// Launch the app with `-screenshot <screen>` to open one screen with seeded data.
/// Used by `.github/workflows/screenshots.yml` to capture every screen in the simulator, and
/// handy for App Store screenshots. Never active in a normal launch.
enum ScreenshotMode {
    enum Screen: String, CaseIterable {
        case hook, dog, size, breed, usual, reveal, plan, first, result, paywall
        case home, walking, log, milestone, stats, walkcard, settings, share
        /// The home screen for a two-dog household.
        case dogs
        /// A day opened from the calendar, with a walk that has a photo.
        case day
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

        var rex = DogProfile()
        rex.name = "Rex"
        rex.size = .medium
        rex.breedType = .mixed
        rex.age = .adult
        rex.usualMinutes = 20
        rex.goalMinutes = 60
        // Days before a dog arrived are not theirs to miss, so a sample second dog has to have
        // been here all along or the seeded 30-day streak would read as 0.
        rex.addedOn = Date().addingTimeInterval(-400 * 24 * 3600)

        var roster = [rex]
        if screen == .dogs {
            var juno = DogProfile()
            juno.name = "Juno"
            juno.size = .small
            juno.breedType = .terrier
            juno.age = .adult
            juno.usualMinutes = 20
            juno.goalMinutes = 40
            juno.addedOn = rex.addedOn
            roster.append(juno)
        }
        appState.replaceDogs(roster)
        for dog in roster { appState.seedPhoto(UIImage(named: "SampleDog"), for: dog.id) }

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
        // One walk with a photo kept against it, so the calendar shows its marker and the day
        // sheet has something to open.
        if let sample = UIImage(named: "SampleDog"), let index = walks.indices.last {
            WalkPhotoStore.save(sample, for: walks[index].id)
            walks[index].hasPhoto = true
        }
        appState.replaceWalks(walks, celebrated: [1, 3, 7, 14, 30])

        if screen == .walking {
            // 18 minutes and 24 seconds in.
            appState.seedActiveWalk(start: Date().addingTimeInterval(-(18 * 60 + 24)))
        }
        appState.hasCompletedOnboarding = {
            switch screen {
            case .home, .walking, .log, .milestone, .stats, .walkcard, .settings, .share, .dogs, .day: return true
            default: return false
            }
        }()
    }
}
