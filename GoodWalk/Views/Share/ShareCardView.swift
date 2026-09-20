import SwiftUI
import UIKit

/// The screenshot people post. Square so it works in Stories and feeds without cropping.
/// The dog's photo is the background; the numbers sit on a warm scrim at the bottom.
struct ShareCardView: View {
    let dogName: String
    let image: UIImage?
    /// "47 miles walked with Rex"
    let headline: String
    /// "30-day streak"
    let detail: String
    let streak: Int?

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            backdrop
            LinearGradient(colors: [.clear, .clear, Color.black.opacity(0.80)],
                           startPoint: .top, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    BrandMark()
                    Spacer()
                    if let streak, streak > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                            Text("\(streak)")
                        }
                        .font(Theme.Font.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Theme.accent)
                        .clipShape(Capsule())
                    }
                }
                Spacer()
                Text(headline)
                    .font(Theme.Font.display(26))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                Text(detail)
                    .font(Theme.Font.display(20))
                    .foregroundStyle(Color(red: 1.0, green: 0.78, blue: 0.55))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
                Text("Every dog deserves a good walk.")
                    .font(Theme.Font.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.top, 6)
            }
            .padding(18)
        }
        .frame(width: 300, height: 300)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    @ViewBuilder
    private var backdrop: some View {
        if let image {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 300, height: 300)
                .clipped()
        } else {
            ZStack {
                LinearGradient(colors: [Theme.accent, Theme.accentDeep], startPoint: .topLeading, endPoint: .bottomTrailing)
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 120, weight: .bold))
                    .foregroundStyle(.white.opacity(0.22))
                    .offset(y: -36)
            }
        }
    }

    /// Renders the card to a UIImage at 3x for sharing.
    @MainActor
    func render() -> UIImage? {
        let renderer = ImageRenderer(content: self.padding(24).background(Theme.background))
        renderer.scale = 3
        return renderer.uiImage
    }
}


/// The app icon as it appears on a card: the orange rounded square with a white paw, and the
/// name beside it. A shadow rather than a scrim, so it stays legible on a bright photo.
private struct BrandMark: View {
    var body: some View {
        HStack(spacing: 7) {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Theme.accent)
                .frame(width: 26, height: 26)
                .overlay(
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                )
            Text("Good Walk")
                .font(Theme.Font.caption)
                .foregroundStyle(.white)
        }
        .shadow(color: .black.opacity(0.45), radius: 5, y: 1)
    }
}

extension ShareCardView {

    /// The card offered at the end of a walk: "42 minutes with Rex", the distance and the day.
    /// `image` is the photo just taken, falling back to the dog's profile photo.
    static func walk(dog: DogProfile, image: UIImage?, walk: Walk, streak: Int,
                     now: Date = Date(), calendar cal: Calendar = .current) -> ShareCardView {
        ShareCardView(dogName: dog.displayName, image: image,
                      headline: headline(minutes: walk.minutes, dog: dog.displayName),
                      detail: detail(walk: walk, now: now, calendar: cal),
                      streak: streak)
    }

    /// "42 minutes with Rex" under an hour, "1h 30m with Rex" over it. The long word reads better
    /// on a card than "42 min"; past an hour the short form is the one people recognise.
    static func headline(minutes: Int, dog: String) -> String {
        let length = minutes < 60 ? "\(minutes) minute\(minutes == 1 ? "" : "s")" : Stats.duration(minutes: minutes)
        return "\(length) with \(dog)"
    }

    static func detail(walk: Walk, now: Date = Date(), calendar cal: Calendar = .current) -> String {
        let when: String
        if cal.isDateInToday(walk.start) { when = "today" }
        else if cal.isDateInYesterday(walk.start) { when = "yesterday" }
        else {
            let f = DateFormatter(); f.calendar = cal; f.locale = .current
            f.setLocalizedDateFormatFromTemplate("MMMd")
            when = f.string(from: walk.start)
        }
        return "\(Stats.milesPhrase(walk.miles)) · \(when)"
    }

    /// The totals card: "47 miles walked with Rex · 30-day streak".
    static func totals(dog: DogProfile, image: UIImage?, stats: Stats) -> ShareCardView {
        return ShareCardView(dogName: dog.displayName, image: image,
                             headline: "\(Stats.milesPhrase(stats.totalMiles)) walked with \(dog.displayName)",
                             detail: stats.streak > 0 ? "\(stats.streak)-day streak" : "\(stats.walkCount) walk\(stats.walkCount == 1 ? "" : "s") so far",
                             streak: stats.streak)
    }
}

/// UIKit share sheet bridge.
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
