import AppIntents
import SwiftUI
import WidgetKit

/// Small Home Screen widget: the dog's face in today's ring, minutes against the target, and a
/// one-tap "Start a walk" button. The button runs the same intent Siri and the Action Button use.
struct TodayWalkWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TodayWalkWidget", provider: TodayProvider()) { entry in
            TodayWalkWidgetView(entry: entry)
                .containerBackground(WidgetPalette.background, for: .widget)
        }
        .configurationDisplayName("Today's walk")
        .description("Your dog, today's ring, and one tap to start a walk.")
        .supportedFamilies([.systemSmall])
    }
}

/// Mirrors the tokens in GoodWalk/Design/Theme.swift (the widget target doesn't compile the app's sources).
enum WidgetPalette {
    static let background = Color(red: 0.980, green: 0.961, blue: 0.925)
    static let track = Color(red: 0.949, green: 0.918, blue: 0.867)
    static let accent = Color(red: 0.929, green: 0.455, blue: 0.200)
    static let success = Color(red: 0.298, green: 0.624, blue: 0.439)
    static let text = Color(red: 0.180, green: 0.133, blue: 0.098)
}

struct TodayEntry: TimelineEntry {
    let date: Date
    let dogName: String
    let minutes: Int
    let goal: Int
    let streak: Int
    let photo: UIImage?

    var progress: Double { min(1, Double(minutes) / Double(max(1, goal))) }
}

struct TodayProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodayEntry {
        TodayEntry(date: Date(), dogName: "Rex", minutes: 25, goal: 60, streak: 30, photo: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayEntry) -> Void) {
        completion(current())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayEntry>) -> Void) {
        // Refresh just after midnight so "today" resets, or in an hour, whichever is sooner.
        let cal = Calendar.current
        let midnight = cal.startOfDay(for: cal.date(byAdding: .day, value: 1, to: Date())!).addingTimeInterval(60)
        let next = min(midnight, Date().addingTimeInterval(3600))
        completion(Timeline(entries: [current()], policy: .after(next)))
    }

    private func current() -> TodayEntry {
        let defaults = AppGroup.defaults
        let today = AppGroup.dayFormatter.string(from: Date())
        let isToday = defaults.string(forKey: AppGroup.Key.minutesDay) == today
        let goal = defaults.integer(forKey: AppGroup.Key.goalMinutes)
        return TodayEntry(date: Date(),
                          dogName: defaults.string(forKey: AppGroup.Key.dogName) ?? "Your dog",
                          minutes: isToday ? defaults.integer(forKey: AppGroup.Key.minutesToday) : 0,
                          goal: goal > 0 ? goal : 60,
                          streak: defaults.integer(forKey: AppGroup.Key.streak),
                          photo: DogPhotoStore.loadForWidget())
    }
}

private struct TodayWalkWidgetView: View {
    let entry: TodayEntry

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                ZStack {
                    Circle().stroke(WidgetPalette.track, lineWidth: 5)
                    Circle()
                        .trim(from: 0, to: entry.progress)
                        .stroke(entry.progress >= 1 ? WidgetPalette.success : WidgetPalette.accent,
                                style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .opacity(entry.progress > 0 ? 1 : 0)
                    avatar.padding(7)
                }
                .frame(width: 58, height: 58)
                VStack(alignment: .leading, spacing: 1) {
                    Text(entry.dogName)
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundStyle(WidgetPalette.text)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text("\(entry.minutes)/\(entry.goal) min")
                        .font(.system(.caption, design: .rounded).weight(.medium))
                        .foregroundStyle(WidgetPalette.text.opacity(0.62))
                    if entry.streak > 0 {
                        Label("\(entry.streak)", systemImage: "flame.fill")
                            .font(.system(.caption, design: .rounded).weight(.bold))
                            .foregroundStyle(WidgetPalette.accent)
                            .labelStyle(.titleAndIcon)
                    }
                }
                Spacer(minLength: 0)
            }
            Spacer(minLength: 0)
            if entry.progress >= 1 {
                Label("Walked today", systemImage: "checkmark.circle.fill")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(WidgetPalette.success)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            } else {
                Button(intent: StartWalkIntent()) {
                    Text("Start a walk")
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(WidgetPalette.accent)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var avatar: some View {
        if let photo = entry.photo {
            Image(uiImage: photo).resizable().scaledToFill().clipShape(Circle())
        } else {
            ZStack {
                Circle().fill(WidgetPalette.accent.opacity(0.14))
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(WidgetPalette.accent)
            }
        }
    }
}
