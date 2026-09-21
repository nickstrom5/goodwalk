import SwiftUI

/// Everything the log adds up to: total walks, the streak now, the best streak ever, and a month
/// grid you can page back through.
///
/// Laid out for the iPhone Duo. The inner display reports a regular width class, so the numbers
/// move into a column beside the calendar instead of stacking above it, and the month grid gets
/// the width it wants. On a folded Duo and on every other iPhone it is the usual single column.
struct StatsView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    /// First of the month being shown. Paged with the arrows, never stored.
    @State private var month = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date())) ?? Date()

    /// Two panes once there is genuinely room for them. Measured, not guessed from the size class:
    /// on a wide screen this screen is presented full width, but a form sheet would report regular
    /// while only being phone-wide, and the layout should follow the pixels either way.
    private static let twoPaneWidth: CGFloat = 620

    /// The grid is one dog's month; the switcher above it flips between them.
    private var summary: MonthSummary {
        MonthSummary.build(walks: appState.walks(forDog: appState.selectedDogID),
                           goalMinutes: appState.dog.dailyGoal, month: month)
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let isWide = geo.size.width >= Self.twoPaneWidth
                ScrollView(showsIndicators: false) {
                    Group {
                        if isWide {
                            HStack(alignment: .top, spacing: 20) {
                                VStack(spacing: 12) { numbers(wide: true) }
                                    .frame(width: 260)
                                VStack(spacing: 16) {
                                    DogSwitcher()
                                    MonthCard(summary: summary, canGoForward: !summary.isCurrentMonth(),
                                              onBack: { step(-1) }, onForward: { step(1) })
                                    totals
                                }
                            }
                        } else {
                            VStack(spacing: 16) {
                                HStack(spacing: 10) { numbers(wide: false) }
                                DogSwitcher()
                                MonthCard(summary: summary, canGoForward: !summary.isCurrentMonth(),
                                          onBack: { step(-1) }, onForward: { step(1) })
                                totals
                            }
                        }
                    }
                    .frame(maxWidth: isWide ? 860 : .infinity)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, Theme.horizontalPadding)
                    .padding(.top, 12)
                    .padding(.bottom, 28)
                }
            }
            .background(Theme.background)
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Pieces

    /// The streak here is the same household streak the home screen shows, so the two can never
    /// disagree. The month grid below is the one place a single dog's own days are read.
    @ViewBuilder
    private func numbers(wide: Bool) -> some View {
        let stats = appState.household
        let name = appState.hasMultipleDogs ? DogProfile.names(appState.dogs) : appState.dog.displayName
        StatBlock(value: "\(stats.walkCount)", label: stats.walkCount == 1 ? "walk with \(name)" : "walks with \(name)",
                  symbol: "figure.walk", tint: Theme.accent, wide: wide)
        StatBlock(value: "\(stats.streak)", label: stats.streak == 1 ? "day streak" : "day streak",
                  symbol: "flame.fill", tint: Theme.accentDeep, wide: wide)
        StatBlock(value: "\(stats.longestStreak)", label: "longest streak",
                  symbol: "trophy.fill", tint: Theme.success, wide: wide)
    }

    private var totals: some View {
        let household = appState.household
        return HStack(spacing: 10) {
            SmallTotal(value: Stats.miles(household.totalMiles), label: "miles")
            SmallTotal(value: Stats.duration(minutes: household.totalMinutes), label: "together")
            // Hitting the full target is one dog's business, so this one stays per dog, next to
            // the month grid it belongs to.
            SmallTotal(value: "\(appState.stats.goalDays)", label: "full days")
        }
    }

    private func step(_ months: Int) {
        guard let next = Calendar.current.date(byAdding: .month, value: months, to: month) else { return }
        withAnimation(.easeInOut(duration: 0.2)) { month = next }
    }
}

/// One big number. Sits in a row on a phone and in a column on the Duo's inner display.
private struct StatBlock: View {
    let value: String
    let label: String
    let symbol: String
    let tint: Color
    let wide: Bool

    var body: some View {
        Group {
            if wide {
                HStack(spacing: 14) {
                    Image(systemName: symbol)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(tint)
                        .frame(width: 44, height: 44)
                        .background(tint.opacity(0.14))
                        .clipShape(Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text(value)
                            .font(Theme.Font.display(34))
                            .foregroundStyle(Theme.textPrimary)
                            .contentTransition(.numericText())
                        Text(label)
                            .font(Theme.Font.caption)
                            .foregroundStyle(Theme.textSecondary)
                            .lineLimit(2)
                    }
                    Spacer(minLength: 0)
                }
            } else {
                VStack(spacing: 4) {
                    Image(systemName: symbol)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(tint)
                    Text(value)
                        .font(Theme.Font.display(30))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .contentTransition(.numericText())
                    Text(label)
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        // Always two lines' worth, so a one-line label like "day streak" does not
                        // make its card shorter and drop its number below the other two.
                        .lineLimit(2, reservesSpace: true)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(16)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
    }
}

private struct SmallTotal: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(Theme.Font.mono(20))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(Theme.Font.caption)
                .foregroundStyle(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

/// The month grid: a filled dot for a day that hit the target, a ring for a shorter walk,
/// nothing for a day with no walk.
private struct MonthCard: View {
    let summary: MonthSummary
    let canGoForward: Bool
    let onBack: () -> Void
    let onForward: () -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left").font(.headline)
                }
                .accessibilityLabel("Previous month")
                Spacer()
                Text(summary.title())
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Button(action: onForward) {
                    Image(systemName: "chevron.right").font(.headline)
                }
                .disabled(!canGoForward)
                .opacity(canGoForward ? 1 : 0.25)
                .accessibilityLabel("Next month")
            }
            .foregroundStyle(Theme.accent)

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(Array(MonthSummary.weekdayInitials().enumerated()), id: \.offset) { index, day in
                    Text(day)
                        .id("weekday-\(index)")
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.textTertiary)
                }
                ForEach(summary.days) { day in
                    DayCell(day: day)
                }
            }

            HStack(spacing: 16) {
                Legend(filled: true, text: "Target met")
                Legend(filled: false, text: "Shorter walk")
                Spacer()
                Text("\(summary.walkedDays) of \(summary.days.filter { $0.date != nil }.count) days")
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(18)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
    }
}

private struct DayCell: View {
    let day: MonthDay

    var body: some View {
        ZStack {
            if day.date != nil {
                if day.hitGoal {
                    Circle().fill(Theme.accent)
                } else if day.walked {
                    Circle().stroke(Theme.accent, lineWidth: 2)
                } else {
                    Circle().fill(Theme.surfaceRaised.opacity(day.isFuture ? 0.4 : 1))
                }
                if day.isToday {
                    Circle().stroke(Theme.textPrimary.opacity(0.55), lineWidth: 2).padding(-3)
                }
                Text("\(day.dayNumber ?? 0)")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(day.hitGoal ? Theme.onAccent : Theme.textSecondary)
            }
        }
        .frame(height: 34)
        .accessibilityElement()
        .accessibilityLabel(label)
    }

    private var label: String {
        guard let number = day.dayNumber else { return "" }
        if day.hitGoal { return "\(number): target met, \(day.minutes) minutes" }
        if day.walked { return "\(number): \(day.minutes) minutes" }
        return day.isFuture ? "\(number): still to come" : "\(number): no walk"
    }
}

private struct Legend: View {
    let filled: Bool
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Group {
                if filled { Circle().fill(Theme.accent) } else { Circle().stroke(Theme.accent, lineWidth: 2) }
            }
            .frame(width: 12, height: 12)
            Text(text)
                .font(Theme.Font.caption)
                .foregroundStyle(Theme.textSecondary)
        }
    }
}
