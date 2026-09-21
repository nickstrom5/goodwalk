import SwiftUI

/// A day from the calendar, identified by its own date so it can drive a sheet.
struct DayKey: Identifiable, Equatable {
    let date: Date
    var id: Date { date }
}

/// One day of walks, opened from the month grid. Every walk that day with its numbers and, if
/// one was taken, the photo of the dog on that walk. Tapping a walk opens its card again, where
/// the photo can be added, changed or shared.
struct DayDetailView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    let day: Date

    @State private var openWalk: Walk?

    private var walks: [Walk] { appState.walks(on: day) }
    private var minutes: Int { walks.reduce(0) { $0 + $1.minutes } }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    header
                    ForEach(walks) { walk in
                        Button {
                            Analytics.track(.walkOpenedFromLog, ["photo": walk.hasPhoto])
                            openWalk = walk
                        } label: {
                            WalkRow(walk: walk,
                                    thumb: walk.hasPhoto ? appState.walkThumb(for: walk.id) : nil,
                                    dogs: dogNames(for: walk))
                        }
                        .buttonStyle(PressScaleStyle())
                    }
                    if walks.isEmpty {
                        Text("No walks logged on this day.")
                            .font(Theme.Font.body)
                            .foregroundStyle(Theme.textTertiary)
                            .padding(.top, 24)
                    }
                }
                .padding(.horizontal, Theme.horizontalPadding)
                .padding(.bottom, 24)
                .phoneWidthColumn()
            }
            .background(Theme.background)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
            }
            .sheet(item: $openWalk) { walk in
                WalkResultView(walk: walk, context: .fromLog)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            StatTile(value: "\(minutes)", label: "min")
            StatTile(value: "\(walks.count)", label: walks.count == 1 ? "walk" : "walks")
            StatTile(value: Stats.miles(walks.reduce(0) { $0 + $1.miles }), label: "miles")
        }
        .padding(.top, 4)
    }

    private var title: String {
        let cal = Calendar.current
        if cal.isDateInToday(day) { return "Today" }
        if cal.isDateInYesterday(day) { return "Yesterday" }
        return day.formatted(date: .abbreviated, time: .omitted)
    }

    /// Whoever was on that walk, for the row's second line.
    private func dogNames(for walk: Walk) -> String {
        let dogs = appState.dogs.filter { walk.counted(for: $0.id) }
        return DogProfile.names(dogs)
    }
}

/// One walk in the day list: its photo if it has one, the time, and what it added up to.
private struct WalkRow: View {
    let walk: Walk
    let thumb: UIImage?
    let dogs: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                if let thumb {
                    Image(uiImage: thumb)
                        .resizable()
                        .scaledToFill()
                } else {
                    Theme.surfaceRaised
                    Image(systemName: walk.source == .timer ? "stopwatch" : "pawprint.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Theme.accent.opacity(0.7))
                }
            }
            .frame(width: 64, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text("\(walk.minutes) min · \(Stats.milesPhrase(walk.miles))\(walk.distanceEstimated ? " est." : "")")
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.textPrimary)
                Text("\(walk.start.formatted(date: .omitted, time: .shortened)) · \(dogs)")
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
                if !walk.hasPhoto {
                    Text("Add a photo")
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.accent)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(Theme.textTertiary)
        }
        .padding(12)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
    }
}
