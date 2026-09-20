import ActivityKit
import SwiftUI
import WidgetKit

/// The walk timer on the Lock Screen and in the Dynamic Island. On iPhone Duo the compact form
/// sits in the outer display's status bar while the phone is folded in a pocket.
struct WalkLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WalkActivityAttributes.self) { context in
            WalkLockScreenView(context: context)
                .activityBackgroundTint(WidgetPalette.background)
                .activitySystemActionForegroundColor(WidgetPalette.text)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label("Walking", systemImage: "pawprint.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(WidgetPalette.accent)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    WalkTimerText(start: context.attributes.startDate)
                        .font(.title3.monospacedDigit().weight(.semibold))
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(WalkLiveActivity.subtitle(for: context))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } compactLeading: {
                Image(systemName: "pawprint.fill")
                    .foregroundStyle(WidgetPalette.accent)
            } compactTrailing: {
                WalkTimerText(start: context.attributes.startDate)
                    .font(.caption.monospacedDigit())
                    .frame(width: 44)
            } minimal: {
                Image(systemName: "pawprint.fill")
                    .foregroundStyle(WidgetPalette.accent)
            }
        }
    }

    static func subtitle(for context: ActivityViewContext<WalkActivityAttributes>) -> String {
        let state = context.state
        if state.minutesBeforeThisWalk >= state.goalMinutes {
            return "\(context.attributes.dogName)'s \(state.goalMinutes) min target is already done today"
        }
        if state.minutesBeforeThisWalk > 0 {
            return "\(state.minutesBeforeThisWalk) of \(state.goalMinutes) min done before this walk"
        }
        return "Today's target: \(state.goalMinutes) min"
    }
}

/// Counts up from the walk's start. `Text(timerInterval:)` needs an end, so it gets a far one.
private struct WalkTimerText: View {
    let start: Date

    var body: some View {
        Text(timerInterval: start...start.addingTimeInterval(8 * 60 * 60), countsDown: false)
    }
}

private struct WalkLockScreenView: View {
    let context: ActivityViewContext<WalkActivityAttributes>

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "pawprint.fill")
                .font(.title2)
                .foregroundStyle(WidgetPalette.accent)
            VStack(alignment: .leading, spacing: 2) {
                Text("Walking \(context.attributes.dogName)")
                    .font(.headline)
                    .foregroundStyle(WidgetPalette.text)
                    .lineLimit(1)
                Text(WalkLiveActivity.subtitle(for: context))
                    .font(.caption)
                    .foregroundStyle(WidgetPalette.text.opacity(0.7))
                    .lineLimit(2)
            }
            Spacer()
            WalkTimerText(start: context.attributes.startDate)
                .font(.system(size: 28, weight: .semibold, design: .rounded).monospacedDigit())
                .foregroundStyle(WidgetPalette.text)
                .multilineTextAlignment(.trailing)
                .frame(width: 96)
        }
        .padding(16)
    }
}
