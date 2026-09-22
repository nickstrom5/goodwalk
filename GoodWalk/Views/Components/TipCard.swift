import SwiftUI

/// One `DogTip` as a card: what kind it is, the line, and for a fact, where it comes from.
struct TipCard: View {
    let tip: DogTip
    let dog: DogProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(tip.kind == .fact ? "Did you know?" : "Tip",
                  systemImage: tip.kind == .fact ? "lightbulb.fill" : "pawprint.fill")
                .font(Theme.Font.caption)
                .foregroundStyle(Theme.accent)
            Text(tip.text(for: dog))
                .font(Theme.Font.body)
                .foregroundStyle(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            if let source = tip.source {
                Text(source)
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

/// A spinner that, if the wait drags on, turns into something worth reading. A quick load never
/// sees the card, so it can't flash up and vanish.
struct LoadingTip: View {
    let dog: DogProfile
    let householdSize: Int
    var delay: TimeInterval = 1

    @State private var showTip = false

    var body: some View {
        VStack(spacing: 14) {
            ProgressView()
            if showTip, let tip = DogTips.tip(for: dog, householdSize: householdSize, at: DogTips.dailyOffset()) {
                TipCard(tip: tip, dog: dog)
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity)
        .task {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.3)) { showTip = true }
        }
    }
}
