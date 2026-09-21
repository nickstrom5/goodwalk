import SwiftUI

/// "How long?" A stepper, five quick chips, one button. Logging a walk after the fact has to be
/// as easy as timing one, or the days without the phone in hand go missing.
struct QuickLogSheet: View {
    /// Every dog in the house. With one, the picker never appears.
    let dogs: [DogProfile]
    let image: (UUID) -> UIImage?
    let suggested: Int
    let onLog: (Int, [UUID]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var minutes: Int = 20
    /// Who this walk was for. Everyone, until you say otherwise.
    @State private var walked: Set<UUID> = []

    private var walkedDogs: [DogProfile] { dogs.filter { walked.contains($0.id) } }

    var body: some View {
        VStack(spacing: 20) {
            Text("How long did \(DogProfile.names(walkedDogs)) walk?")
                .font(Theme.Font.title)
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.top, 28)
                .padding(.horizontal, Theme.horizontalPadding)

            if dogs.count > 1 {
                DogToggleRow(dogs: dogs,
                             isOn: { walked.contains($0) },
                             toggle: { toggle($0) },
                             image: image)
                    .padding(.horizontal, Theme.horizontalPadding)
            }

            HStack(spacing: 24) {
                StepButton(symbol: "minus") { minutes = max(5, minutes - 5) }
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(minutes)")
                        .font(Theme.Font.display(72))
                        .foregroundStyle(Theme.accent)
                        .contentTransition(.numericText())
                    Text("min")
                        .font(Theme.Font.headline)
                        .foregroundStyle(Theme.textSecondary)
                }
                .frame(minWidth: 150)
                StepButton(symbol: "plus") { minutes = min(300, minutes + 5) }
            }

            HStack(spacing: 8) {
                ForEach([10, 20, 30, 45, 60], id: \.self) { n in
                    Chip(label: "\(n)", selected: minutes == n) { minutes = n }
                }
            }
            .padding(.horizontal, Theme.horizontalPadding)

            VStack(spacing: 6) {
                PrimaryButton(title: "Log \(minutes) min") {
                    onLog(minutes, Array(walked))
                    dismiss()
                }
                .disabled(walked.isEmpty)
                Text("Distance is estimated at an easy dog pace. Use the timer to measure it.")
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
            .padding(.horizontal, Theme.horizontalPadding)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
        .onAppear {
            minutes = min(300, max(5, suggested))
            if walked.isEmpty { walked = Set(dogs.map(\.id)) }
        }
        .animation(.easeInOut(duration: 0.15), value: minutes)
    }

    /// The last dog can't be switched off: a walk nobody was on isn't a walk.
    private func toggle(_ dogID: UUID) {
        if walked.contains(dogID) {
            guard walked.count > 1 else { return }
            walked.remove(dogID)
        } else {
            walked.insert(dogID)
        }
    }
}

private struct StepButton: View {
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.title2.weight(.bold))
                .foregroundStyle(Theme.textPrimary)
                .frame(width: 56, height: 56)
                .background(Theme.surfaceRaised)
                .clipShape(Circle())
        }
        .buttonStyle(PressScaleStyle())
    }
}
