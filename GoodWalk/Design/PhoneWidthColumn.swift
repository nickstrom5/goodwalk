import SwiftUI

/// Keeps a single-column layout phone-width on a regular-width screen: the iPhone Duo's inner
/// display and iPad. Without it a column of buttons and body text stretches the full width and
/// stops being readable.
///
/// `RootView` applies this to the app's own content, but anything presented over it
/// (`fullScreenCover`, and a `sheet` that is not a form sheet) is outside that frame and has to
/// opt in for itself.
private struct PhoneWidthColumn: ViewModifier {
    @Environment(\.horizontalSizeClass) private var sizeClass

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: sizeClass == .regular ? Theme.regularWidthMax : .infinity)
            .frame(maxWidth: .infinity)
    }
}

extension View {
    func phoneWidthColumn() -> some View { modifier(PhoneWidthColumn()) }
}
