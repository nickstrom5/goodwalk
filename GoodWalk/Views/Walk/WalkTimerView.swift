import SwiftUI

/// The walk in progress. A clock, a distance, the dog, and one button. The phone goes back in
/// the pocket; the timer runs from a stored start date, so it survives the app being killed.
struct WalkTimerView: View {
    @EnvironmentObject private var appState: AppState
    @State private var confirmDiscard = false
    /// Tapping the tip moves it on. The clock moves it on too, once a minute.
    @State private var tipNudge = 0

    private var dog: DogProfile { appState.dog }
    /// The dogs actually on this walk, in roster order.
    private var walkingDogs: [DogProfile] { appState.dogs.filter { appState.isOnActiveWalk($0.id) } }
    /// Where today's walks start in the tip deck. Fixed in screenshot mode so the capture is stable.
    private var tipOffset: Int { ScreenshotMode.isActive ? 0 : DogTips.dailyOffset() }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let seconds = appState.elapsedSeconds(at: context.date)
                let tip = DogTips.tip(for: dog, householdSize: appState.dogs.count,
                                      at: tipOffset + tipNudge + seconds / 60)
                // The tip only goes where there is room for it. On a small phone the clock, the
                // ring and the button come first, and the walk looks exactly as it did before.
                ViewThatFits(in: .vertical) {
                    walk(at: context.date, seconds: seconds, tip: tip)
                    walk(at: context.date, seconds: seconds, tip: nil)
                }
            }
        }
        .confirmationDialog("Discard this walk?", isPresented: $confirmDiscard, titleVisibility: .visible) {
            Button("Discard", role: .destructive) { appState.cancelWalk() }
            Button("Keep walking", role: .cancel) {}
        }
    }

    private func walk(at date: Date, seconds: Int, tip: DogTip?) -> some View {
        let minutesNow = appState.stats.minutesToday + seconds / 60
        let progress = min(1, Double(minutesNow) / Double(max(1, dog.dailyGoal)))

        return VStack(spacing: 0) {
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
                StatTile(value: String(format: "%.2f", appState.liveMeters(at: date) / WalkPlan.metersPerMile),
                         label: appState.distanceIsMeasured ? "miles" : "miles (est.)")
                StatTile(value: "\(minutesNow)", label: "of \(dog.dailyGoal) min today")
            }
            .padding(.top, 20)

            if let tip {
                Button { tipNudge += 1 } label: { TipCard(tip: tip, dog: dog) }
                    .buttonStyle(.plain)
                    .accessibilityHint("Shows another tip")
                    .id(tip.id)
                    .transition(.opacity)
                    .padding(.top, 16)
            }

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
        .animation(.easeInOut(duration: 0.3), value: tip?.id)
    }

    /// "Logs it to Rex's streak" / "Logs it to Rex and Juno's streak".
    private var endSubtitle: String {
        let dogs = walkingDogs
        guard dogs.count != 1 else { return "Logs it to \(dogs[0].possessive) streak" }
        return "Logs it to \(DogProfile.names(dogs))'s streak"
    }
}
