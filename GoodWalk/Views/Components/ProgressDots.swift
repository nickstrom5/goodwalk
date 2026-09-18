import SwiftUI

/// Thin progress bar for onboarding. Shows how close the end is; people finish what they can see.
struct OnboardingProgress: View {
    let current: Int
    let total: Int

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.surfaceRaised)
                Capsule()
                    .fill(Theme.accent)
                    .frame(width: geo.size.width * CGFloat(current + 1) / CGFloat(total))
                    .animation(.easeInOut(duration: 0.3), value: current)
            }
        }
        .frame(height: 4)
    }
}
