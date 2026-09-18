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
                    HStack(spacing: 6) {
                        Image(systemName: "pawprint.fill")
                        Text("Good Walk")
                    }
                    .font(Theme.Font.caption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.35))
                    .clipShape(Capsule())
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

extension ShareCardView {
    /// The totals card: "47 miles walked with Rex · 30-day streak".
    static func totals(dog: DogProfile, image: UIImage?, stats: Stats) -> ShareCardView {
        let miles = Stats.miles(stats.totalMiles)
        let unit = miles == "1" || miles == "1.0" ? "mile" : "miles"
        return ShareCardView(dogName: dog.displayName, image: image,
                             headline: "\(miles) \(unit) walked with \(dog.displayName)",
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
