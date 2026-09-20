import SwiftUI

/// One place for the look. Warm cream, terracotta accent, rounded type. A sunny pavement and a
/// wagging tail, not a fitness dashboard and not a vet's waiting room.
enum Theme {
    static let background = Color(red: 0.980, green: 0.961, blue: 0.925)      // cream
    static let surface = Color.white
    static let surfaceRaised = Color(red: 0.949, green: 0.918, blue: 0.867)   // oat
    static let accent = Color(red: 0.929, green: 0.455, blue: 0.200)          // terracotta
    static let accentDeep = Color(red: 0.788, green: 0.333, blue: 0.106)
    static let accentSoft = accent.opacity(0.14)
    static let onAccent = Color.white
    static let textPrimary = Color(red: 0.180, green: 0.133, blue: 0.098)     // dark brown
    static let textSecondary = textPrimary.opacity(0.66)
    static let textTertiary = textPrimary.opacity(0.42)
    static let danger = Color(red: 0.800, green: 0.250, blue: 0.220)
    static let warning = Color(red: 0.870, green: 0.600, blue: 0.130)
    static let success = Color(red: 0.298, green: 0.624, blue: 0.439)         // leaf green

    static let cornerRadius: CGFloat = 20
    static let horizontalPadding: CGFloat = 24
    /// Content width on regular-width screens (iPhone Duo open). Keeps lines and buttons phone-sized.
    static let regularWidthMax: CGFloat = 560

    enum Font {
        static func display(_ size: CGFloat = 40) -> SwiftUI.Font {
            .system(size: size, weight: .bold, design: .rounded)
        }
        static let title = SwiftUI.Font.system(size: 28, weight: .bold, design: .rounded)
        static let headline = SwiftUI.Font.system(size: 18, weight: .semibold, design: .rounded)
        static let body = SwiftUI.Font.system(size: 17, weight: .regular, design: .rounded)
        static let caption = SwiftUI.Font.system(size: 13, weight: .medium, design: .rounded)
        static func mono(_ size: CGFloat) -> SwiftUI.Font {
            .system(size: size, weight: .semibold, design: .rounded).monospacedDigit()
        }
    }
}
