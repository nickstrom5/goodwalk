import PhotosUI
import SwiftUI

// MARK: - 1. Hook

struct HookScreen: View {
    let onNext: () -> Void
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
            Text("The typical dog gets about")
                .font(Theme.Font.headline)
                .foregroundStyle(Theme.textSecondary)
            HStack(alignment: .lastTextBaseline, spacing: 10) {
                Text("\(WalkPlan.typicalMinutes)")
                    .font(Theme.Font.display(104))
                    .foregroundStyle(Theme.accent)
                Text("minutes\na day.")
                    .font(Theme.Font.title)
                    .foregroundStyle(Theme.textPrimary)
            }
            .padding(.vertical, -6)
            Text("Many are built for more.")
                .font(Theme.Font.title)
                .foregroundStyle(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
            Text("\(WalkPlan.typicalMinutesPerWeek) minutes a week: the median across 29 studies of owners who walk their dog (Christian et al., 2013).")
                .font(Theme.Font.caption)
                .foregroundStyle(Theme.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 14)
            Spacer()
            PrimaryButton(title: "What does my dog need?", action: onNext)
            Text("Good Walk turns the daily walk into a streak. Their name on it, not yours.")
                .font(Theme.Font.caption)
                .foregroundStyle(Theme.textTertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, 12)
                .padding(.bottom, 16)
        }
        .padding(.horizontal, Theme.horizontalPadding)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
        .onAppear { withAnimation(.easeOut(duration: 0.6)) { appeared = true } }
    }
}

// MARK: - 2. Name + photo

struct DogScreen: View {
    @EnvironmentObject private var appState: AppState
    let onNext: () -> Void
    @State private var pickerItem: PhotosPickerItem?
    @FocusState private var nameFocused: Bool

    private var hasName: Bool { !appState.dog.name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        let photo = appState.dogImage   // read on the main actor; the picker's label closure isn't
        return OnboardingScreen(
            title: "Who are we walking?",
            subtitle: "Their name and face go on everything: the streak, the widget, the card you'll post.",
            ctaEnabled: hasName,
            onCTA: onNext
        ) {
            VStack(spacing: 20) {
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    ZStack(alignment: .bottomTrailing) {
                        DogAvatar(image: photo, size: 148)
                            .overlay(Circle().stroke(Theme.accent, lineWidth: 3))
                        Image(systemName: photo == nil ? "camera.fill" : "pencil")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Theme.onAccent)
                            .frame(width: 40, height: 40)
                            .background(Theme.accent)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Theme.background, lineWidth: 3))
                    }
                }
                .buttonStyle(PressScaleStyle())
                .frame(maxWidth: .infinity)

                Text(appState.dogImage == nil ? "Add a photo (optional). It never leaves your phone." : "Looking good.")
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.textTertiary)

                TextField("Dog's name", text: $appState.dog.name)
                    .font(Theme.Font.display(28))
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .focused($nameFocused)
                    .padding(.vertical, 16)
                    .background(Theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .onChange(of: appState.dog.name) { _, new in
                        if new.count > 20 { appState.dog.name = String(new.prefix(20)) }
                    }
            }
        }
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                    appState.setDogPhoto(image)
                }
            }
        }
    }
}

// MARK: - 3. Size

struct SizeScreen: View {
    @EnvironmentObject private var appState: AppState
    let onNext: () -> Void

    var body: some View {
        OnboardingScreen(
            title: "How big is \(appState.dog.displayName)?",
            subtitle: "Size sets the starting point. A Yorkie and a Lab don't need the same day.",
            onCTA: onNext
        ) {
            VStack(spacing: 10) {
                ForEach(DogProfile.Size.allCases) { size in
                    SizeRow(size: size, selected: appState.dog.size == size) {
                        appState.dog.size = size
                        appState.dog.goalMinutes = 0
                    }
                }
            }
        }
    }
}

private struct SizeRow: View {
    let size: DogProfile.Size
    let selected: Bool
    let action: () -> Void

    private var pawSize: CGFloat {
        switch size {
        case .toy: return 14
        case .small: return 18
        case .medium: return 22
        case .large: return 27
        case .giant: return 32
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: pawSize))
                    .frame(width: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text(size.label).font(Theme.Font.headline)
                    Text(size.example).font(Theme.Font.caption).opacity(0.75)
                }
                Spacer()
                Text(size.detail).font(Theme.Font.caption).opacity(0.75)
            }
            .foregroundStyle(selected ? Theme.onAccent : Theme.textPrimary)
            .padding(.horizontal, 16)
            .frame(height: 64)
            .background(selected ? Theme.accent : Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(PressScaleStyle())
    }
}

// MARK: - 4. Breed type + age

struct BreedScreen: View {
    @EnvironmentObject private var appState: AppState
    let onNext: () -> Void

    private let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    var body: some View {
        OnboardingScreen(
            title: "What kind of dog?",
            subtitle: "Closest match is fine. A herding dog and a lap dog of the same size want very different days.",
            onCTA: onNext
        ) {
            VStack(alignment: .leading, spacing: 20) {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(DogProfile.BreedType.allCases) { type in
                        Chip(label: type.label, symbol: type.symbol, selected: appState.dog.breedType == type) {
                            appState.dog.breedType = type
                            appState.dog.goalMinutes = 0
                        }
                    }
                }
                Text("And how old?")
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.top, 4)
                HStack(spacing: 8) {
                    ForEach(DogProfile.Age.allCases) { age in
                        Chip(label: age.label, detail: age.detail, selected: appState.dog.age == age) {
                            appState.dog.age = age
                            appState.dog.goalMinutes = 0
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 5. Usual walking right now

struct UsualScreen: View {
    @EnvironmentObject private var appState: AppState
    let onNext: () -> Void

    private let options = [10, 20, 30, 45, 60]

    var body: some View {
        OnboardingScreen(
            title: "Honestly, how much does \(appState.dog.displayName) walk on a normal day?",
            subtitle: "All walks added up. Not the best day, the normal one. No judgement.",
            onCTA: onNext
        ) {
            VStack(spacing: 24) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(appState.dog.usualMinutes)")
                        .font(Theme.Font.display(72))
                        .foregroundStyle(Theme.accent)
                        .contentTransition(.numericText())
                    Text("min a day")
                        .font(Theme.Font.title)
                        .foregroundStyle(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                HStack(spacing: 8) {
                    ForEach(options, id: \.self) { minutes in
                        Chip(label: minutes == 60 ? "60+" : "\(minutes)", selected: appState.dog.usualMinutes == minutes) {
                            appState.dog.usualMinutes = minutes
                        }
                    }
                }
                NoteCard(text: LocalizedStringKey(comparison))
            }
        }
    }

    private var comparison: String {
        switch appState.dog.usualMinutes {
        case ..<15: return "A lap of the block. Plenty of dogs live here; it's the easiest number to move."
        case 15..<30: return "Right around the typical dog. Let's see what \(appState.dog.displayName) is built for."
        case 30..<60: return "Better than most. Let's see how close that is to what \(appState.dog.displayName) is built for."
        default: return "That's a well-walked dog. Good Walk keeps it that way, and keeps the receipts."
        }
    }
}

// MARK: - 6. Reveal

struct RevealScreen: View {
    @EnvironmentObject private var appState: AppState
    let onNext: () -> Void
    @State private var showSecond = false
    @State private var showThird = false

    private var dog: DogProfile { appState.dog }
    private var recommended: Int { WalkPlan.recommendedMinutes(for: dog) }
    private var gapHours: Int { WalkPlan.yearlyGapHours(for: dog) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 26) {
                    HStack(spacing: 12) {
                        DogAvatar(image: appState.dogImage, size: 52)
                        Text("\(dog.size.label) · \(dog.breedType.label) · \(dog.age.label)")
                            .font(Theme.Font.caption)
                            .foregroundStyle(Theme.textTertiary)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("A dog like \(dog.displayName) needs about")
                            .font(Theme.Font.headline)
                            .foregroundStyle(Theme.textSecondary)
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            CountUpText(target: recommended)
                                .font(Theme.Font.display(80))
                                .foregroundStyle(Theme.accent)
                            Text("min a day.")
                                .font(Theme.Font.title)
                                .foregroundStyle(Theme.textPrimary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("The typical dog gets about")
                            .font(Theme.Font.headline)
                            .foregroundStyle(Theme.textSecondary)
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            CountUpText(target: WalkPlan.typicalMinutes, delay: 0.9)
                                .font(Theme.Font.display(56))
                                .foregroundStyle(Theme.warning)
                            Text("min. You said \(dog.usualMinutes).")
                                .font(Theme.Font.title)
                                .foregroundStyle(Theme.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .opacity(showSecond ? 1 : 0)
                    .offset(y: showSecond ? 0 : 10)

                    VStack(alignment: .leading, spacing: 2) {
                        if gapHours > 0 {
                            Text("Over a year, the gap is")
                                .font(Theme.Font.headline)
                                .foregroundStyle(Theme.textSecondary)
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                CountUpText(target: gapHours, delay: 1.8)
                                    .font(Theme.Font.display(72))
                                    .foregroundStyle(Theme.danger)
                                    .lineLimit(1)
                                Text("hours")
                                    .font(Theme.Font.title)
                                    .foregroundStyle(Theme.textPrimary)
                            }
                            Text("of sniffing, trotting and tail up that \(dog.displayName) isn't getting. It closes one walk at a time.")
                                .font(Theme.Font.body)
                                .foregroundStyle(Theme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        } else {
                            Text("\(dog.displayName) is already there.")
                                .font(Theme.Font.title)
                                .foregroundStyle(Theme.success)
                            Text("The hard part now is every day. That's what a streak is for.")
                                .font(Theme.Font.body)
                                .foregroundStyle(Theme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .opacity(showThird ? 1 : 0)
                    .offset(y: showThird ? 0 : 10)

                    GuidelineFootnote()
                        .opacity(showThird ? 1 : 0)
                }
                .padding(.horizontal, Theme.horizontalPadding)
                .padding(.top, 28)
                .padding(.bottom, 24)
            }
            PrimaryButton(title: "Make \(dog.possessive) plan", action: onNext)
                .padding(.horizontal, Theme.horizontalPadding)
                .padding(.bottom, 16)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.9)) { showSecond = true }
            withAnimation(.easeOut(duration: 0.5).delay(1.8)) { showThird = true }
        }
    }
}

// MARK: - 7. Plan: target + reminder

struct PlanScreen: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var reminders: ReminderManager
    let onNext: () -> Void
    @State private var requesting = false

    private var recommended: Int { WalkPlan.recommendedMinutes(for: appState.dog) }

    var body: some View {
        OnboardingScreen(
            title: "\(appState.dog.possessive.capitalizedFirst) daily target",
            subtitle: "Start where you'll actually win. Any walk keeps the streak; the target fills the ring.",
            cta: "Set my reminder",
            ctaLoading: requesting,
            onCTA: setReminder
        ) {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 8) {
                    ForEach(WalkPlan.goalOptions(for: appState.dog), id: \.self) { minutes in
                        Chip(label: "\(minutes)", detail: minutes == recommended ? "guideline" : "min",
                             selected: appState.dog.dailyGoal == minutes) {
                            appState.dog.goalMinutes = minutes
                        }
                    }
                }
                NoteCard(text: "That's **\(Stats.duration(minutes: appState.dog.dailyGoal * 7))** a week with \(appState.dog.displayName), and about **\(Int((Double(appState.dog.dailyGoal) * 365 / 60).rounded())) hours** a year.")

                VStack(alignment: .leading, spacing: 10) {
                    Text("The daily nudge")
                        .font(Theme.Font.headline)
                        .foregroundStyle(Theme.textPrimary)
                    Text("One notification a day: \"\(ReminderManager.title(dogNames: appState.dogNames))\" Tap Walked or Start a walk right from it.")
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    DatePicker("Reminder time", selection: ReminderTime.binding(appState), displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                        .font(Theme.Font.body)
                        .foregroundStyle(Theme.textPrimary)
                        .tint(Theme.accent)
                }
                .padding(16)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .onAppear {
            if appState.dog.goalMinutes == 0 { appState.dog.goalMinutes = recommended }
        }
    }

    private func setReminder() {
        requesting = true
        Task {
            let granted = await reminders.requestAuthorization()
            if granted { reminders.schedule(minutesAfterMidnight: appState.reminderMinutes, dogNames: appState.dogNames) }
            requesting = false
            onNext()
        }
    }
}

enum ReminderTime {
    @MainActor
    static func binding(_ appState: AppState) -> Binding<Date> {
        Binding(
            get: {
                var components = DateComponents()
                components.hour = appState.reminderMinutes / 60
                components.minute = appState.reminderMinutes % 60
                return Calendar.current.date(from: components) ?? Date()
            },
            set: { date in
                let c = Calendar.current.dateComponents([.hour, .minute], from: date)
                appState.reminderMinutes = (c.hour ?? 17) * 60 + (c.minute ?? 30)
            }
        )
    }
}

extension String {
    var capitalizedFirst: String { prefix(1).uppercased() + dropFirst() }
}

// MARK: - 8. First walk (the taste)

struct FirstWalkScreen: View {
    @EnvironmentObject private var appState: AppState
    let onNext: () -> Void
    @State private var minutes = 20
    @State private var logged = false

    private let options = [10, 20, 30, 45, 60]

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Has \(appState.dog.displayName) walked today?")
                        .font(Theme.Font.title)
                        .foregroundStyle(Theme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Log it and day 1 starts now: the ring, the streak and the first card.")
                        .font(Theme.Font.body)
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, Theme.horizontalPadding)
                .padding(.top, 36)

                Spacer()

                ProgressRing(progress: logged ? min(1, Double(minutes) / Double(max(1, appState.dog.dailyGoal))) : 0) {
                    DogAvatar(image: appState.dogImage, size: 150)
                }
                .frame(width: 200, height: 200)
                .frame(maxWidth: .infinity)

                HStack(spacing: 8) {
                    ForEach(options, id: \.self) { option in
                        Chip(label: "\(option)", detail: "min", selected: minutes == option) { minutes = option }
                    }
                }
                .padding(.horizontal, Theme.horizontalPadding)
                .padding(.top, 28)
                .disabled(logged)

                Spacer()

                PrimaryButton(title: logged ? "Logged ✓" : "Log \(minutes) min with \(appState.dog.displayName)", action: logWalk)
                    .padding(.horizontal, Theme.horizontalPadding)
                TertiaryButton(title: "Not yet. We'll start with the next walk.") {
                    Analytics.track(.firstWalkSkipped)
                    onNext()
                }
                .padding(.horizontal, Theme.horizontalPadding)
                .padding(.bottom, 8)
                .opacity(logged ? 0 : 1)
            }
            if logged { ConfettiView().ignoresSafeArea() }
        }
        .onAppear {
            // Re-entry after a kill mid-onboarding: today is already logged, don't ask twice.
            if appState.walkedToday { onNext() }
        }
    }

    private func logWalk() {
        guard !logged else { return }
        appState.quickLog(minutes: minutes, source: .onboarding)
        Analytics.track(.firstWalkLogged, ["minutes": minutes])
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { logged = true }
        Task {
            try? await Task.sleep(nanoseconds: 1_400_000_000)
            onNext()
        }
    }
}

// MARK: - 9. First result

struct FirstResultScreen: View {
    @EnvironmentObject private var appState: AppState
    let onNext: () -> Void
    @State private var shareImage: UIImage?

    private var dog: DogProfile { appState.dog }
    private var walked: Bool { appState.walkedToday }
    private var left: Int { max(0, dog.dailyGoal - appState.stats.minutesToday) }

    private var card: ShareCardView {
        ShareCardView(dogName: dog.displayName, image: appState.dogImage,
                      headline: "Day 1 with \(dog.displayName)",
                      detail: "\(appState.stats.minutesToday) min walked today", streak: 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(walked ? "Day 1 with \(dog.displayName)." : "The next walk is day 1.")
                        .font(Theme.Font.title)
                        .foregroundStyle(Theme.textPrimary)
                    if walked {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            CountUpText(target: appState.stats.minutesToday)
                                .font(Theme.Font.display(72))
                                .foregroundStyle(Theme.accent)
                            Text("of \(dog.dailyGoal) min today.")
                                .font(Theme.Font.title)
                                .foregroundStyle(Theme.textPrimary)
                        }
                    }
                    Text(summary)
                        .font(Theme.Font.body)
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 4)

                    if walked {
                        card
                            .frame(maxWidth: .infinity)
                            .padding(.top, 20)
                        SecondaryButton(title: "Share it") {
                            Analytics.track(.shareTapped, ["from": "onboarding"])
                            shareImage = card.render()
                        }
                        .padding(.top, 12)
                    }
                }
                .padding(.horizontal, Theme.horizontalPadding)
                .padding(.top, 36)
                .padding(.bottom, 24)
            }
            PrimaryButton(title: "Keep it going", action: onNext)
                .padding(.horizontal, Theme.horizontalPadding)
                .padding(.bottom, 16)
        }
        .sheet(item: $shareImage) { image in
            ShareSheet(items: [image, "Day 1 of daily walks with \(dog.displayName). getgoodwalk.app"])
        }
    }

    private var summary: String {
        if !walked {
            return "Good Walk will nudge you at \(ReminderManager.label(forMinutes: appState.reminderMinutes)). One tap logs it, and \(dog.possessive) streak begins."
        }
        if left == 0 { return "Target hit on day one. Good Walk counts every day, and gives \(dog.displayName) a card at every milestone." }
        return "\(left) more minutes fills the ring. Good Walk counts every day, and gives \(dog.displayName) a card at every milestone."
    }
}

extension UIImage: @retroactive Identifiable {
    public var id: ObjectIdentifier { ObjectIdentifier(self) }
}
