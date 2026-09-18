import SwiftUI

/// A number that counts up from zero when it appears. Used on the reveal, the result and the
/// milestone card; the animation is the screenshot people take.
struct CountUpText: View {
    let target: Int
    var prefix: String = ""
    var suffix: String = ""
    var duration: Double = 1.2
    var delay: Double = 0

    @State private var start = Date()

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { context in
            let elapsed = context.date.timeIntervalSince(start) - delay
            let t = max(0, min(1, elapsed / duration))
            let eased = 1 - pow(1 - t, 3)
            let value = Int((Double(target) * eased).rounded())
            Text(prefix + value.formatted(.number.grouping(.automatic)) + suffix)
                .monospacedDigit()
        }
    }
}
