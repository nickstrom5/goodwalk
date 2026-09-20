import SwiftUI

@main
@MainActor
struct GoodWalkApp: App {
    @StateObject private var appState: AppState
    @StateObject private var store: StoreManager
    @StateObject private var reminders: ReminderManager

    init() {
        var sinks: [AnalyticsSink] = [ConsoleAnalytics()]
        if let postHog = PostHogAnalytics.start() { sinks.append(postHog) }
        Analytics.sink = CompositeAnalytics(sinks: sinks)

        let state = AppState()
        if ScreenshotMode.isActive { ScreenshotMode.seed(state) }
        let reminders = ReminderManager()
        reminders.onWalked = { [weak state] in
            guard let state, state.hasCompletedOnboarding else { return }
            state.quickLog(minutes: max(5, state.dog.usualMinutes), source: .notification)
        }
        _appState = StateObject(wrappedValue: state)
        _store = StateObject(wrappedValue: StoreManager())
        _reminders = StateObject(wrappedValue: reminders)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(store)
                .environmentObject(reminders)
                .preferredColorScheme(.light)
                .tint(Theme.accent)
                .task {
                    Analytics.track(.appOpen)
                    await reminders.refreshStatus()
                    await store.load()
                }
        }
    }
}

/// Routes between onboarding and the main app.
struct RootView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            Group {
                if let screen = ScreenshotMode.screen {
                    ScreenshotRouter(screen: screen)
                } else if appState.hasCompletedOnboarding {
                    HomeView()
                        .transition(.opacity)
                } else {
                    OnboardingFlow()
                        .transition(.opacity)
                }
            }
            // iPhone Duo's inner display reports a regular width class. Keep the one-column
            // layout readable there by capping its width, per Apple's Duo guidance.
            .frame(maxWidth: sizeClass == .regular ? Theme.regularWidthMax : .infinity)
            .frame(maxWidth: .infinity)
        }
        .animation(.easeInOut(duration: 0.35), value: appState.hasCompletedOnboarding)
    }
}

/// Renders exactly one screen for `-screenshot <name>` launches.
private struct ScreenshotRouter: View {
    let screen: ScreenshotMode.Screen

    var body: some View {
        switch screen {
        case .hook:      OnboardingFlow(initialStep: .hook)
        case .dog:       OnboardingFlow(initialStep: .dog)
        case .size:      OnboardingFlow(initialStep: .size)
        case .breed:     OnboardingFlow(initialStep: .breed)
        case .usual:     OnboardingFlow(initialStep: .usual)
        case .reveal:    OnboardingFlow(initialStep: .reveal)
        case .plan:      OnboardingFlow(initialStep: .plan)
        case .first:     OnboardingFlow(initialStep: .first)
        case .result:    OnboardingFlow(initialStep: .result)
        case .paywall:   PaywallView(context: .onboarding, onFinished: {})
        case .home:      HomeView()
        case .walking:   HomeView()
        case .log:       HomeView(initialSheet: .quickLog)
        case .milestone: HomeView(initialSheet: .milestone(7))
        case .stats:     HomeView(showingStats: true)
        case .settings:  SettingsView()
        case .share:     HomeView(initialSheet: .share)
        }
    }
}
