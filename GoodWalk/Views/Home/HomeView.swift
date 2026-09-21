import SwiftUI

/// The dog in a ring and one button. Everything else on this screen exists to get the leash
/// off the hook again tomorrow.
struct HomeView: View {
    enum Sheet: Identifiable, Equatable {
        case settings, paywall, quickLog, share
        case milestone(Int)

        var id: String {
            switch self {
            case .settings: return "settings"
            case .paywall: return "paywall"
            case .quickLog: return "quickLog"
            case .share: return "share"
            case .milestone(let n): return "milestone-\(n)"
            }
        }
    }

    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var store: StoreManager
    @EnvironmentObject private var reminders: ReminderManager
    @Environment(\.scenePhase) private var scenePhase

    @State private var sheet: Sheet?
    /// Stats is a full-screen presentation, not a sheet: a sheet becomes a phone-width form sheet
    /// on a wide screen, which is exactly where the stats screen has a wider layout to show.
    @State private var showStats = false
    /// Set when a timed walk ends, so its card (and the photo option) is offered once.
    @State private var finishedWalk: Walk?
    @State private var celebrate = false

    init(initialSheet: Sheet? = nil, showingStats: Bool = false, showingWalkCard: Bool = false) {
        _sheet = State(initialValue: initialSheet)
        _showStats = State(initialValue: showingStats)
        _finishedWalk = State(initialValue: showingWalkCard ? ScreenshotMode.sampleWalk : nil)
    }

    private var dog: DogProfile { appState.dog }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        header
                        DogSwitcher()
                        ring
                        actions
                        WeekBars(days: appState.thisWeek, goal: dog.dailyGoal)
                        totals
                        shareRow
                    }
                    .padding(.horizontal, Theme.horizontalPadding)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
                if celebrate { ConfettiView().ignoresSafeArea() }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 6) {
                        Image(systemName: "pawprint.fill").foregroundStyle(Theme.accent)
                        Text("Good Walk")
                            .font(Theme.Font.headline)
                            .foregroundStyle(Theme.textPrimary)
                    }
                    .padding(.horizontal, 6)
                    .fixedSize()   // iOS 26 glass capsule otherwise clips the text
                }
                // One item holding both buttons: as two separate trailing items iOS stacks them
                // vertically into a single tall capsule on the iPhone Duo's inner display.
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 14) {
                        Button { showStats = true } label: {
                            Image(systemName: "chart.bar.fill").foregroundStyle(Theme.textSecondary)
                        }
                        .accessibilityLabel("Stats")
                        Button { sheet = .settings } label: {
                            Image(systemName: "gearshape.fill").foregroundStyle(Theme.textSecondary)
                        }
                        .accessibilityLabel("Settings")
                    }
                    .fixedSize()
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .fullScreenCover(isPresented: $showStats) {
            StatsView()
        }
        .sheet(item: $sheet) { sheet in
            switch sheet {
            case .settings:
                SettingsView()
            case .paywall:
                PaywallView(context: .home, onFinished: { self.sheet = nil })
            case .quickLog:
                QuickLogSheet(dogs: appState.dogs,
                              image: { appState.image(for: $0) },
                              suggested: dog.usualMinutes) { minutes, dogIDs in
                    appState.quickLog(minutes: minutes, source: .quickLog, dogIDs: dogIDs)
                }
                .presentationDetents([.height(appState.hasMultipleDogs ? 500 : 390)])
            case .share:
                ShareTotalsView()
            case .milestone(let streak):
                MilestoneView(streak: streak)
            }
        }
        .fullScreenCover(isPresented: walkingBinding) {
            WalkTimerView()
        }
        .sheet(item: $finishedWalk) { walk in
            WalkResultView(walk: walk)
        }
        .onChange(of: appState.lastWalk) { _, walk in
            // Only a walk that was actually timed; a quick log has no moment worth a photo.
            guard let walk, walk.source == .timer else { return }
            finishedWalk = walk
        }
        .onChange(of: appState.pendingMilestone) { _, milestone in
            guard let milestone else { return }
            appState.pendingMilestone = nil
            sheet = .milestone(milestone)
        }
        .onChange(of: appState.goalJustHit) { _, hit in
            guard hit else { return }
            appState.goalJustHit = false
            throwConfetti()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { startFromIntentIfAsked() }
        }
        .onAppear {
            reminders.onStartWalk = { gated { appState.startWalk(source: "notification") } }
            startFromIntentIfAsked()
        }
    }

    /// The cover follows the persisted timer, so a relaunch mid-walk lands back on it.
    private var walkingBinding: Binding<Bool> {
        Binding(get: { appState.isWalking }, set: { _ in })
    }

    // MARK: - Sections

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting)
                    .font(Theme.Font.title)
                    .foregroundStyle(Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(subline)
                    .font(Theme.Font.body)
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            if appState.household.streak > 0 {
                VStack(spacing: 0) {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                        Text("\(appState.household.streak)")
                            .contentTransition(.numericText())
                    }
                    .font(Theme.Font.display(26))
                    .foregroundStyle(Theme.accent)
                    Text(appState.household.streak == 1 ? "day" : "days")
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.textTertiary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var greeting: String {
        if appState.todayProgress >= 1 { return "\(dog.displayName.capitalizedFirst) is walked." }
        if appState.walkedToday { return "\(dog.displayName.capitalizedFirst) wants more." }
        return "\(dog.displayName.capitalizedFirst) is ready."
    }

    private var subline: String {
        let left = max(0, dog.dailyGoal - appState.stats.minutesToday)
        // With more than one dog the streak is the household's, so the nudge is about whoever
        // is still waiting by the door, not only the dog currently on screen.
        let waiting = appState.dogsNotWalkedToday
        if appState.hasMultipleDogs, !waiting.isEmpty, appState.todayProgress >= 1 {
            return "\(DogProfile.names(waiting)) hasn't been out yet."
        }
        if appState.todayProgress >= 1 {
            return appState.hasMultipleDogs
                ? "Everyone's walked. Tail up. See you tomorrow."
                : "Target hit. Tail up. See you tomorrow."
        }
        if appState.walkedToday { return "\(left) min to fill today's ring." }
        if appState.household.streak > 0 { return "Any walk today keeps the streak." }
        return "One walk starts the streak."
    }

    private var ring: some View {
        VStack(spacing: 12) {
            ProgressRing(progress: appState.todayProgress, lineWidth: 18) {
                DogAvatar(image: appState.dogImage, size: 172)
            }
            .frame(width: 232, height: 232)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(appState.stats.minutesToday)")
                    .font(Theme.Font.display(40))
                    .foregroundStyle(appState.todayProgress >= 1 ? Theme.success : Theme.accent)
                    .contentTransition(.numericText())
                Text("of \(dog.dailyGoal) min today")
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
    }

    private var actions: some View {
        VStack(spacing: 8) {
            PrimaryButton(title: "Start a walk", subtitle: "Timer and distance") {
                gated { appState.startWalk(source: "home") }
            }
            SecondaryButton(title: "Quick log a walk") { gated { sheet = .quickLog } }
        }
    }

    private var totals: some View {
        let s = appState.household
        return HStack(spacing: 10) {
            StatTile(value: Stats.miles(s.totalMiles), label: "miles")
            StatTile(value: s.totalHours >= 10 ? "\(Int(s.totalHours.rounded()))" : String(format: "%.1f", s.totalHours), label: "hours")
            StatTile(value: "\(s.walkCount)", label: s.walkCount == 1 ? "walk" : "walks")
        }
    }

    private var shareRow: some View {
        Button { sheet = .share } label: {
            HStack(spacing: 12) {
                DogAvatar(image: appState.dogImage, size: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(appState.hasMultipleDogs ? DogProfile.names(appState.dogs) + "'s" : dog.possessive.capitalizedFirst) card")
                        .font(Theme.Font.headline)
                        .foregroundStyle(Theme.textPrimary)
                    Text("\(Stats.miles(appState.household.totalMiles)) miles together. Worth a post.")
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.textTertiary)
                }
                Spacer()
                Image(systemName: "square.and.arrow.up")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.accent)
            }
            .padding(16)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
        }
        .buttonStyle(PressScaleStyle())
    }

    // MARK: - Actions

    /// The core action is behind the paywall. Nothing else is.
    private func gated(_ action: () -> Void) {
        guard store.isPro || ScreenshotMode.isActive else {
            Analytics.track(.paywallShown, ["from": "home"])
            sheet = .paywall
            return
        }
        action()
    }

    private func startFromIntentIfAsked() {
        guard appState.consumePendingStartWalk(), !appState.isWalking else { return }
        gated { appState.startWalk(source: "intent") }
    }

    private func throwConfetti() {
        celebrate = true
        Task {
            try? await Task.sleep(nanoseconds: 2_200_000_000)
            celebrate = false
        }
    }
}

struct StatTile: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(Theme.Font.mono(22))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(Theme.Font.caption)
                .foregroundStyle(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
