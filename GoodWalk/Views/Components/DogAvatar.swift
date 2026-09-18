import SwiftUI

/// The dog, round. Their photo when there is one, a paw on terracotta when there isn't.
/// The dog's face is on every screen that matters: the streak belongs to them.
struct DogAvatar: View {
    let image: UIImage?
    var size: CGFloat = 56

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Theme.accentSoft
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: size * 0.42, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

/// Today's minutes against the target, drawn around whatever is inside (usually the dog).
struct ProgressRing<Content: View>: View {
    let progress: Double
    var lineWidth: CGFloat = 16
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack {
            Circle().stroke(Theme.surfaceRaised, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(progress >= 1 ? Theme.success : Theme.accent,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .opacity(progress > 0 ? 1 : 0)
                .animation(.easeOut(duration: 0.6), value: progress)
            content().padding(lineWidth + 6)
        }
    }
}
