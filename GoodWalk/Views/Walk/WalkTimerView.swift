import SwiftUI

/// The walk in progress. A clock, a distance, the dog, and one button. The phone goes back in
/// the pocket; the timer runs from a stored start date, so it survives the app being killed.
struct WalkTimerView: View {
    @EnvironmentObject private var appState: AppState
    @State private var confirmDiscard = false

    private var dog: DogProfile { appState.dog }
    /// The dogs actually on this walk, in roster order.
    private var walkingDogs: [DogProfile] { appState.dogs.filter { appState.isOnActiveWalk($0.id) } }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let seconds = appState.elapsedSeconds(at: context.date)
                let minutesNow = appState.stats.minutesToday + seconds / 60
                let progress = min(1, Double(minutesNow) / Double(max(1, dog.dailyGoal)))

                VStack(spacing: 0) {
                    HStack(spacing: 8) {
                        Circle().fill(Theme.danger).frame(width: 8, height: 8)
                        Text("Walking with \(DogProfile.names(walkingDogs))")
                            .font(Theme.Font.headline)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .padding(.top, 28)

                    // Who came along can change at the door, so it stays editable mid-walk.
                    if appState.hasMultipleDogs {
                        DogToggleRow(dogs: appState.dogs,
                                     isOn: { appState.isOnActiveWalk($0) },
                                     toggle: { appState.setWalking($0, on: !appState.isOnActiveWalk($0)) },
                                     image: { appState.image(for: $0) })
                            .padding(.top, 12)
                    }

                    Spacer()

                    ProgressRing(progress: progress, lineWidth: 18) {
                        DogAvatar(image: appState.dogImage, size: 172)
                    }
                    .frame(width: 232, height: 232)

                    Text(Stats.clock(seconds: seconds))
                        .font(Theme.Font.display(76))
                        .monospacedDigit()
                        .foregroundStyle(Theme.textPrimary)
                        .padding(.top, 24)

                    HStack(spacing: 10) {
                        StatTile(value: String(format: "%.2f", appState.liveMeters(at: context.date) / WalkPlan.metersPerMile),
                                 label: appState.distanceIsMeasured ? "miles" : "miles (est.)")
                        StatTile(value: "\(minutesNow)", label: "of \(dog.dailyGoal) min today")
                    }
                    .padding(.top, 20)

                    Spacer()

                    PrimaryButton(title: "End walk", subtitle: endSubtitle) {
                        appState.finishWalk()
                    }
                    TertiaryButton(title: "Discard this walk") { confirmDiscard = true }
                        .padding(.bottom, 8)
                }
                .padding(.horizontal, Theme.horizontalPadding)
                // Presented full screen, so RootView's width cap does not reach it.
                .phoneWidthColumn()
            }
        }
        .confirmationDialog("Discard this walk?", isPresented: $confirmDiscard, titleVisibility: .visible) {
            Button("Discard", role: .destructive) { appState.cancelWalk() }
            Button("Keep walking", role: .cancel) {}
        }
    }

    /// "Logs it to Rex's streak" / "Logs it to Rex and Juno's streak".
    private var endSubtitle: String {
        let dogs = walkingDogs
        guard dogs.count != 1 else { return "Logs it to \(dogs[0].possessive) streak" }
        return "Logs it to \(DogProfile.names(dogs))'s streak"
    }
}
