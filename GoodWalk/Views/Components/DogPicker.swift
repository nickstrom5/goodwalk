import SwiftUI

/// The row of faces that appears only when more than one dog lives here. With a single dog every
/// screen looks exactly as it did before: one dog should never pay for the second one's feature.

/// Taps switch which dog the screen is about. Each face carries its own ring, so you can see at a
/// glance who is still short today without switching to them.
struct DogSwitcher: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        if appState.hasMultipleDogs {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(appState.dogs) { dog in
                        Button {
                            guard dog.id != appState.selectedDogID else { return }
                            appState.select(dog.id)
                            Analytics.track(.dogSwitched)
                        } label: {
                            DogRingLabel(dog: dog,
                                         image: appState.image(for: dog.id),
                                         progress: appState.progressToday(for: dog.id),
                                         selected: dog.id == appState.selectedDogID)
                        }
                        .buttonStyle(PressScaleStyle())
                        .accessibilityLabel("\(dog.displayName), \(appState.minutesToday(for: dog.id)) of \(dog.dailyGoal) minutes today")
                        .accessibilityAddTraits(dog.id == appState.selectedDogID ? [.isSelected] : [])
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 4)
            }
        }
    }
}

/// One face with its ring and name. Used by the switcher and the "who's on this walk" row.
struct DogRingLabel: View {
    let dog: DogProfile
    let image: UIImage?
    let progress: Double
    var selected: Bool = true
    var size: CGFloat = 52

    var body: some View {
        VStack(spacing: 5) {
            ProgressRing(progress: progress, lineWidth: 4) {
                DogAvatar(image: image, size: size)
            }
            .frame(width: size + 20, height: size + 20)
            Text(dog.displayName)
                .font(Theme.Font.caption)
                .foregroundStyle(selected ? Theme.textPrimary : Theme.textTertiary)
                .lineLimit(1)
                .frame(maxWidth: size + 20)
        }
        .opacity(selected ? 1 : 0.5)
        .animation(.easeOut(duration: 0.2), value: selected)
    }
}

/// "Who's on this walk?" Tapping a face includes or excludes that dog. Everyone starts included,
/// because the whole point is that walking two dogs is one walk and one tap.
struct DogToggleRow: View {
    let dogs: [DogProfile]
    let isOn: (UUID) -> Bool
    let toggle: (UUID) -> Void
    var image: (UUID) -> UIImage?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(dogs) { dog in
                    Button { toggle(dog.id) } label: {
                        VStack(spacing: 5) {
                            ZStack(alignment: .bottomTrailing) {
                                DogAvatar(image: image(dog.id), size: 52)
                                    .overlay(
                                        Circle().strokeBorder(isOn(dog.id) ? Theme.accent : .clear, lineWidth: 3)
                                    )
                                if isOn(dog.id) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundStyle(.white, Theme.accent)
                                        .offset(x: 2, y: 2)
                                }
                            }
                            .frame(width: 58, height: 58)
                            Text(dog.displayName)
                                .font(Theme.Font.caption)
                                .foregroundStyle(isOn(dog.id) ? Theme.textPrimary : Theme.textTertiary)
                                .lineLimit(1)
                                .frame(maxWidth: 72)
                        }
                        .opacity(isOn(dog.id) ? 1 : 0.5)
                    }
                    .buttonStyle(PressScaleStyle())
                    .accessibilityLabel(dog.displayName)
                    .accessibilityValue(isOn(dog.id) ? "on this walk" : "not on this walk")
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 4)
        }
        .animation(.easeOut(duration: 0.2), value: dogs.map { isOn($0.id) })
    }
}
