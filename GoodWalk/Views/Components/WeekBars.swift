import SwiftUI

/// Seven bars, minutes per day against the target line. Full bars turn green.
struct WeekBars: View {
    let days: [WeekDay]
    let goal: Int

    private var goalDays: Int { days.filter { $0.minutes >= goal }.count }
    private let barHeight: CGFloat = 72

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("This week")
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.textTertiary)
                Spacer()
                Text("\(goalDays) full day\(goalDays == 1 ? "" : "s") · target \(goal) min")
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(days) { day in
                    VStack(spacing: 6) {
                        ZStack(alignment: .bottom) {
                            Capsule().fill(Theme.surfaceRaised).frame(height: barHeight)
                            if day.minutes > 0 {
                                Capsule()
                                    .fill(day.minutes >= goal ? Theme.success : Theme.accent)
                                    .frame(height: max(14, barHeight * min(1, CGFloat(day.minutes) / CGFloat(max(1, goal)))))
                            }
                        }
                        .frame(width: 14)
                        Text(day.date, format: .dateTime.weekday(.narrow))
                            .font(Theme.Font.caption)
                            .foregroundStyle(day.isToday ? Theme.textPrimary : Theme.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .opacity(day.isFuture ? 0.45 : 1)
                }
            }
        }
        .padding(16)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
    }
}
