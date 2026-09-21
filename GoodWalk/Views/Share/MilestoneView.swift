import SwiftUI

/// Shown once per milestone streak. The number, what it added up to, and the card to post.
struct MilestoneView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    let streak: Int
    @State private var shareImage: UIImage?

    private var dog: DogProfile { appState.dog }
    /// The milestone belongs to the household, so the card names everyone.
    private var names: String { DogProfile.names(appState.dogs) }

    private var card: ShareCardView {
        ShareCardView(dogName: names, image: appState.dogImage,
                      headline: "\(streak) day\(streak == 1 ? "" : "s") in a row with \(names)",
                      detail: "\(Stats.miles(appState.household.totalMiles)) miles so far", streak: streak)
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(headline)
                        .font(Theme.Font.headline)
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.top, 8)
                    HStack(alignment: .lastTextBaseline, spacing: 10) {
                        CountUpText(target: streak)
                            .font(Theme.Font.display(88))
                            .foregroundStyle(Theme.accent)
                        Text(streak == 1 ? "day." : "days\nin a row.")
                            .font(Theme.Font.title)
                            .foregroundStyle(Theme.textPrimary)
                    }
                    Text("\(names) \(appState.hasMultipleDogs ? "don't" : "doesn't") know what a streak is. \(appState.hasMultipleDogs ? "They know" : "\(dog.displayName) knows") the leash came out \(streak) day\(streak == 1 ? "" : "s") running: \(Stats.miles(appState.household.totalMiles)) miles and \(Stats.duration(minutes: appState.household.totalMinutes)) together so far.")
                        .font(Theme.Font.body)
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 4)

                    card
                        .frame(maxWidth: .infinity)
                        .padding(.top, 20)

                    SecondaryButton(title: "Share the card") {
                        Analytics.track(.shareTapped, ["from": "milestone", "streak": streak])
                        shareImage = card.render()
                    }
                    .padding(.top, 12)
                    PrimaryButton(title: "Keep going") { dismiss() }
                        .padding(.top, 4)
                }
                .padding(.horizontal, Theme.horizontalPadding)
                .padding(.top, 36)
                .padding(.bottom, 24)
            }
            ConfettiView().ignoresSafeArea()
        }
        .sheet(item: $shareImage) { image in
            ShareSheet(items: [image, "\(streak) days of walks in a row with \(names). getgoodwalk.app\(Config.shareCredit)"])
        }
    }

    private var headline: String {
        switch streak {
        case 1: return "First one down."
        case 3: return "Three's a pattern."
        case 7: return "A whole week."
        case 14: return "Two weeks. This is a routine now."
        case 30: return "A month. Most people never get here."
        case 60: return "Two months."
        case 100: return "Triple digits."
        case 365: return "A year. Every single day."
        default: return "Milestone."
        }
    }
}

/// The totals card on demand, from the home screen.
struct ShareTotalsView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var shareImage: UIImage?

    private var card: ShareCardView {
        ShareCardView.totals(dogName: DogProfile.names(appState.dogs), image: appState.dogImage,
                             miles: appState.household.totalMiles,
                             streak: appState.household.streak,
                             walkCount: appState.household.walkCount)
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 8) {
                Text("\(appState.hasMultipleDogs ? DogProfile.names(appState.dogs) + "'s" : appState.dog.possessive.capitalizedFirst) card")
                    .font(Theme.Font.title)
                    .foregroundStyle(Theme.textPrimary)
                Text("Every mile you've walked together, on one square. Made for Stories, group chats and the fridge.")
                    .font(Theme.Font.body)
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                card.frame(maxWidth: .infinity)
                    .shadow(color: Theme.textPrimary.opacity(0.18), radius: 24, y: 12)
                Spacer()
                PrimaryButton(title: "Share the card") {
                    Analytics.track(.shareTapped, ["from": "home"])
                    shareImage = card.render()
                }
                TertiaryButton(title: "Done") { dismiss() }
            }
            .padding(.horizontal, Theme.horizontalPadding)
            .padding(.top, 36)
            .padding(.bottom, 8)
        }
        .sheet(item: $shareImage) { image in
            ShareSheet(items: [image, "\(card.headline). \(card.detail). getgoodwalk.app\(Config.shareCredit)"])
        }
    }
}
