import SwiftUI

struct PrimaryButton: View {
    let title: String
    var subtitle: String? = nil
    var isEnabled: Bool = true
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                VStack(spacing: 2) {
                    Text(title)
                        .font(Theme.Font.headline)
                    if let subtitle {
                        Text(subtitle)
                            .font(Theme.Font.caption)
                            .opacity(0.85)
                    }
                }
                .opacity(isLoading ? 0 : 1)
                if isLoading {
                    ProgressView().tint(Theme.onAccent)
                }
            }
            .foregroundStyle(Theme.onAccent)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(isEnabled ? Theme.accent : Theme.accent.opacity(0.35))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .disabled(!isEnabled || isLoading)
        .buttonStyle(PressScaleStyle())
    }
}

struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.Font.headline)
                .foregroundStyle(Theme.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Theme.surfaceRaised)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(PressScaleStyle())
    }
}

/// Low-key text button for the "no thanks" path.
struct TertiaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.Font.body)
                .foregroundStyle(Theme.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
        }
    }
}

struct PressScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Selectable pill used for prices, goals and reasons.
struct Chip: View {
    let label: String
    var symbol: String? = nil
    var detail: String? = nil
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let symbol {
                    Image(systemName: symbol)
                        .font(.subheadline.weight(.semibold))
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(label)
                        .font(Theme.Font.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    if let detail {
                        Text(detail)
                            .font(Theme.Font.caption)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .opacity(0.85)
                    }
                }
            }
            .foregroundStyle(selected ? Theme.onAccent : Theme.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, detail == nil ? 14 : 10)
            .padding(.horizontal, 12)
            .background(selected ? Theme.accent : Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(PressScaleStyle())
    }
}
