import StoreKit
import SwiftUI
import UserNotifications

/// Hard paywall. Trial-first framing, yearly preselected, reminder toggle that really schedules
/// a notification. Design notes in playbook/02-onboarding-and-paywall.md.
struct PaywallView: View {
    enum Context { case onboarding, home }

    @EnvironmentObject private var store: StoreManager
    @EnvironmentObject private var appState: AppState
    let context: Context
    let onFinished: () -> Void

    @State private var selectedID: StoreManager.ProductID = .yearly
    @State private var remindBeforeTrialEnds = true
    @State private var showClose = false
    @State private var purchasing = false
    @State private var availableHeight: CGFloat = 900

    var body: some View {
        ZStack(alignment: .topLeading) {
            Theme.background.ignoresSafeArea()
            // The folded Duo's outer display is 678pt tall. Measure rather than guess: the
            // three-step timeline only fits above roughly 720pt, and below that it pushed the
            // plan rows behind the pinned button.
            GeometryReader { geo in
                Color.clear.onAppear { availableHeight = geo.size.height }
                    .onChange(of: geo.size.height) { _, h in availableHeight = h }
            }

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    timeline
                    plans
                    if selectedProduct.map(store.hasTrial) == true || (ScreenshotMode.isActive && selectedID == .yearly) { reminderToggle }
                    if let error = store.purchaseError, !ScreenshotMode.isActive {
                        Text(error).font(Theme.Font.caption).foregroundStyle(Theme.danger)
                    }
                }
                .padding(.horizontal, Theme.horizontalPadding)
                .padding(.top, 56)
                .padding(.bottom, 140)
            }

            VStack(spacing: 10) {
                PrimaryButton(title: ctaTitle, subtitle: ctaSubtitle, isEnabled: selectedProduct != nil || ScreenshotMode.isActive, isLoading: purchasing, action: purchase)
                footer
            }
            .padding(.horizontal, Theme.horizontalPadding)
            .padding(.top, 12)
            .padding(.bottom, 12)
            .background(Theme.background.ignoresSafeArea(edges: .bottom))
            .frame(maxHeight: .infinity, alignment: .bottom)

            if showClose {
                Button {
                    Analytics.track(.paywallDismissed, ["context": String(describing: context)])
                    onFinished()
                } label: {
                    Image(systemName: "xmark")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Theme.textTertiary)
                        .frame(width: 32, height: 32)
                        .background(Theme.surface)
                        .clipShape(Circle())
                }
                .padding(.leading, 16)
                .padding(.top, 12)
                .transition(.opacity)
            }
        }
        .task {
            if store.isPro { onFinished(); return }
            Analytics.track(.paywallShown, ["context": String(describing: context)])
            if store.products.isEmpty { await store.load() }
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            withAnimation { showClose = true }
        }
        .onChange(of: store.isPro) { _, pro in if pro { onFinished() } }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Try Good Walk free for 7 days")
                .font(Theme.Font.title)
                .foregroundStyle(Theme.textPrimary)
            Text("**\(appState.dog.dailyGoal) minutes a day** for \(appState.dog.displayName). A timer, a nudge that shows up, a streak with their face on it and a card at every milestone.")
                .font(Theme.Font.body)
                .foregroundStyle(Theme.textSecondary)
        }
    }

    /// The trial explained. On a short screen (the folded iPhone Duo's outer display) the
    /// three-step version pushes the plans below the fold, so it collapses to one line there.
    private var isShortScreen: Bool { availableHeight < 720 }

    @ViewBuilder
    private var timeline: some View {
        if isShortScreen {
            HStack(spacing: 10) {
                Image(systemName: "bell.fill").foregroundStyle(Theme.accent)
                Text("Full access today. We remind you on day 5. Cancel any time before day 7.")
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
        } else {
            VStack(alignment: .leading, spacing: 0) {
                TimelineRow(symbol: "pawprint.fill", title: "Today", detail: "Full access. Walk, log, watch the ring fill.", isFirst: true)
                TimelineRow(symbol: "bell.fill", title: "Day 5", detail: "We remind you the trial is ending.")
                TimelineRow(symbol: "star.fill", title: "Day 7", detail: "Trial ends. Cancel any time before.", isLast: true)
            }
            .padding(18)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
        }
    }

    private var plans: some View {
        VStack(spacing: 10) {
            if ScreenshotMode.isActive {
                ForEach(StoreManager.ProductID.allCases, id: \.self) { id in
                    PlanRow(title: sampleTitle(id), badge: badge(for: id), detail: sampleDetail(id),
                            isSelected: selectedID == id) { selectedID = id }
                }
            } else {
                if store.products.isEmpty {
                    if store.hasLoaded && !store.isLoading {
                        Button("Try again") { Task { await store.load() } }
                            .font(Theme.Font.body)
                            .foregroundStyle(Theme.accent)
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        ProgressView().frame(maxWidth: .infinity).padding()
                    }
                }
                ForEach(store.products, id: \.id) { product in
                    if let id = StoreManager.ProductID(rawValue: product.id) {
                        PlanRow(
                            title: product.displayName.replacingOccurrences(of: "Good Walk ", with: ""),
                            badge: badge(for: id),
                            detail: planDetail(product, id: id),
                            isSelected: selectedID == id
                        ) {
                            selectedID = id
                            Analytics.track(.planSelected, ["product": product.id])
                        }
                    }
                }
            }
        }
    }

    private func badge(for id: StoreManager.ProductID) -> String? {
        switch id {
        case .yearly: return "BEST VALUE"
        case .lifetime: return "ONE-TIME"
        case .monthly: return nil
        }
    }

    private func sampleTitle(_ id: StoreManager.ProductID) -> String {
        switch id { case .yearly: return "Yearly"; case .monthly: return "Monthly"; case .lifetime: return "Lifetime" }
    }

    private func sampleDetail(_ id: StoreManager.ProductID) -> String {
        switch id {
        case .yearly: return "$1.67/mo · billed $19.99/yr after 7-day free trial"
        case .monthly: return "$3.99/mo · cancel anytime"
        case .lifetime: return "$29.99 once · no subscription"
        }
    }

    private var reminderToggle: some View {
        Toggle(isOn: $remindBeforeTrialEnds) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Remind me before the trial ends")
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.textPrimary)
                Text("A notification on day 5. No surprises.")
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .tint(Theme.accent)
        .padding(16)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var footer: some View {
        HStack(spacing: 18) {
            Button("Restore") { Task { await store.restore() } }
            Link("Terms", destination: Config.termsURL)
            Link("Privacy", destination: Config.privacyURL)
        }
        .font(Theme.Font.caption)
        .foregroundStyle(Theme.textTertiary)
    }

    // MARK: - Helpers

    private var selectedProduct: Product? { store.product(selectedID) }

    private var ctaTitle: String {
        if ScreenshotMode.isActive { return selectedID == .yearly ? "Start my free trial" : "Continue" }
        guard let product = selectedProduct else {
            return store.hasLoaded && !store.isLoading ? "Plans unavailable" : "Loading plans…"
        }
        return store.hasTrial(product) ? "Start my free trial" : "Continue"
    }

    private var ctaSubtitle: String? {
        if ScreenshotMode.isActive {
            switch selectedID {
            case .yearly: return "7 days free, then $19.99/year. Cancel anytime."
            case .monthly: return "$3.99/month. Cancel anytime."
            case .lifetime: return "$29.99 once. Yours forever."
            }
        }
        guard let product = selectedProduct else { return nil }
        if store.hasTrial(product) {
            return "7 days free, then \(product.displayPrice)/year. Cancel anytime."
        }
        if product.type == .nonConsumable { return "\(product.displayPrice) once. Yours forever." }
        return "\(product.displayPrice)/month. Cancel anytime."
    }

    private func planDetail(_ product: Product, id: StoreManager.ProductID) -> String {
        switch id {
        case .yearly:
            let perMonth = store.perMonthEquivalent(product) ?? ""
            return "\(perMonth) · billed \(product.displayPrice)/yr after 7-day free trial"
        case .monthly:
            return "\(product.displayPrice)/mo · cancel anytime"
        case .lifetime:
            return "\(product.displayPrice) once · no subscription"
        }
    }

    private func purchase() {
        guard let product = selectedProduct else { return }
        purchasing = true
        Task {
            let ok = await store.purchase(product)
            purchasing = false
            if ok, store.hasTrial(product), remindBeforeTrialEnds {
                scheduleTrialReminder()
            }
            if ok { onFinished() }
        }
    }

    private func scheduleTrialReminder() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = "Your Good Walk trial ends in 2 days"
            content.body = "Keep the streak going, or cancel in Settings. No hard feelings."
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5 * 24 * 60 * 60, repeats: false)
            center.add(UNNotificationRequest(identifier: "goodwalk.trialReminder", content: content, trigger: trigger))
        }
    }
}

// MARK: - Rows

private struct TimelineRow: View {
    let symbol: String
    let title: String
    let detail: String
    var isFirst = false
    var isLast = false

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                Image(systemName: symbol)
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(isFirst ? Theme.onAccent : Theme.textSecondary)
                    .frame(width: 30, height: 30)
                    .background(isFirst ? Theme.accent : Theme.surfaceRaised)
                    .clipShape(Circle())
                if !isLast {
                    Rectangle().fill(Theme.surfaceRaised).frame(width: 2, height: 28)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(Theme.Font.headline).foregroundStyle(Theme.textPrimary)
                Text(detail).font(Theme.Font.caption).foregroundStyle(Theme.textSecondary)
            }
            .padding(.top, 4)
            Spacer()
        }
    }
}

private struct PlanRow: View {
    let title: String
    let badge: String?
    let detail: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Theme.accent : Theme.textTertiary)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(Theme.Font.headline)
                            .foregroundStyle(Theme.textPrimary)
                        if let badge {
                            Text(badge)
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(Theme.onAccent)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Theme.accent)
                                .clipShape(Capsule())
                        }
                    }
                    Text(detail)
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
            }
            .padding(16)
            .background(isSelected ? Theme.accentSoft : Theme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? Theme.accent : .clear, lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(PressScaleStyle())
    }
}
