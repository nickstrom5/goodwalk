import PhotosUI
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: StoreManager
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var reminders: ReminderManager
    @Environment(\.dismiss) private var dismiss
    @State private var showPaywall = false
    @State private var pickerItem: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 14) {
                        DogAvatar(image: appState.dogImage, size: 56)
                        VStack(alignment: .leading, spacing: 4) {
                            TextField("Dog's name", text: $appState.dog.name)
                                .font(Theme.Font.headline)
                            PhotosPicker(appState.dogImage == nil ? "Add a photo" : "Change photo", selection: $pickerItem, matching: .images)
                                .font(Theme.Font.caption)
                        }
                    }
                    Picker("Size", selection: $appState.dog.size) {
                        ForEach(DogProfile.Size.allCases) { Text($0.label).tag($0) }
                    }
                    Picker("Type", selection: $appState.dog.breedType) {
                        ForEach(DogProfile.BreedType.allCases) { Text($0.label).tag($0) }
                    }
                    Picker("Age", selection: $appState.dog.age) {
                        ForEach(DogProfile.Age.allCases) { Text($0.label).tag($0) }
                    }
                } header: {
                    Text("Your dog")
                }

                Section {
                    Stepper("Daily target: \(appState.dog.dailyGoal) min",
                            value: Binding(get: { appState.dog.dailyGoal }, set: { appState.dog.goalMinutes = $0 }),
                            in: WalkPlan.minimumMinutes...180, step: 5)
                    Stepper("\"Walked\" logs: \(appState.dog.usualMinutes) min", value: $appState.dog.usualMinutes, in: 5...120, step: 5)
                } header: {
                    Text("Target")
                } footer: {
                    Text("Guideline for a dog like \(appState.dog.displayName): about \(WalkPlan.recommendedMinutes(for: appState.dog)) min a day. General guidance, not veterinary advice.")
                }

                Section {
                    DatePicker("Reminder time", selection: ReminderTime.binding(appState), displayedComponents: .hourAndMinute)
                    if !reminders.isAuthorized {
                        Button("Turn on notifications") {
                            Task {
                                let granted = await reminders.requestAuthorization()
                                if granted { reminders.schedule(minutesAfterMidnight: appState.reminderMinutes, dogName: appState.dog.displayName) }
                                else if let url = URL(string: UIApplication.openSettingsURLString) { await UIApplication.shared.open(url) }
                            }
                        }
                    }
                } header: {
                    Text("Daily nudge")
                } footer: {
                    Text(reminders.isAuthorized
                         ? "One notification at \(ReminderManager.label(forMinutes: appState.reminderMinutes)). Tap Walked or Start a walk right from it."
                         : "Notifications are off, so the nudge can't reach you. The widget and Siri still work.")
                }

                Section("So far") {
                    LabeledContent("Current streak", value: "\(appState.stats.streak) days")
                    LabeledContent("Longest streak", value: "\(appState.stats.longestStreak) days")
                    LabeledContent("Full-target days", value: "\(appState.stats.goalDays) of \(appState.stats.daysWalked) walked")
                    LabeledContent("Distance", value: "\(Stats.miles(appState.stats.totalMiles)) miles")
                    LabeledContent("Time together", value: Stats.duration(minutes: appState.stats.totalMinutes))
                }

                if !appState.todaysWalks.isEmpty {
                    Section {
                        ForEach(appState.todaysWalks.reversed()) { walk in
                            LabeledContent(walk.start.formatted(date: .omitted, time: .shortened),
                                           value: "\(walk.minutes) min · \(String(format: "%.2f", walk.miles)) mi\(walk.distanceEstimated ? " est." : "")")
                        }
                        .onDelete { offsets in
                            let shown = Array(appState.todaysWalks.reversed())
                            offsets.map { shown[$0] }.forEach(appState.delete)
                        }
                    } header: {
                        Text("Today's walks")
                    } footer: {
                        Text("Swipe to delete a walk logged by mistake.")
                    }
                }

                Section("Plan") {
                    if store.isPro {
                        LabeledContent("Good Walk Pro", value: "Active")
                        Button("Manage subscription") {
                            if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                                UIApplication.shared.open(url)
                            }
                        }
                    } else {
                        Button("Upgrade to Good Walk Pro") { showPaywall = true }
                    }
                    Button("Restore purchases") { Task { await store.restore() } }
                }

                HelpSection()

                Section {
                    Link("Privacy policy", destination: Config.privacyURL)
                    Link("Terms", destination: Config.termsURL)
                } footer: {
                    Text("Good Walk \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "") · Everything stays on your phone, including the photo. Walk targets are general guidelines, not veterinary advice. Ask your vet what's right for your dog, especially puppies, seniors, flat-faced breeds and dogs with health conditions.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(context: .home, onFinished: { showPaywall = false })
            }
            .onChange(of: appState.reminderMinutes) { _, minutes in
                Analytics.track(.reminderTimeChanged, ["minutes": minutes])
                if reminders.isAuthorized { reminders.schedule(minutesAfterMidnight: minutes, dogName: appState.dog.displayName) }
            }
            .onChange(of: appState.dog.name) { _, _ in
                if reminders.isAuthorized { reminders.schedule(minutesAfterMidnight: appState.reminderMinutes, dogName: appState.dog.displayName) }
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
}
