import PhotosUI
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: StoreManager
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var reminders: ReminderManager
    @Environment(\.dismiss) private var dismiss
    @State private var showPaywall = false
    @State private var showAddDog = false

    var body: some View {
        NavigationStack {
            List {
                // One dog: the fields sit right here, exactly as they always have. Several:
                // a roster, and each dog gets their own screen.
                if appState.hasMultipleDogs {
                    Section {
                        ForEach(appState.dogs) { dog in
                            NavigationLink {
                                DogEditorView(dogID: dog.id)
                            } label: {
                                HStack(spacing: 12) {
                                    DogAvatar(image: appState.image(for: dog.id), size: 40)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(dog.displayName).font(Theme.Font.headline)
                                        Text("\(appState.minutesToday(for: dog.id)) of \(dog.dailyGoal) min today")
                                            .font(Theme.Font.caption)
                                            .foregroundStyle(Theme.textTertiary)
                                    }
                                }
                            }
                        }
                        Button("Add another dog") { showAddDog = true }
                    } header: {
                        Text("Your dogs")
                    } footer: {
                        Text("Walking them together is one walk on every ring. Tap a dog to change their target or remove them.")
                    }
                } else {
                    if let binding = appState.binding(for: appState.selectedDogID) {
                        DogFields(dog: binding,
                                  image: appState.dogImage,
                                  onPickPhoto: { appState.setDogPhoto($0) },
                                  onRemovePhoto: { appState.removeDogPhoto() })
                    }
                    Section {
                        Button("Add another dog") { showAddDog = true }
                    } footer: {
                        Text("Two or three dogs in the house? Add them and one walk counts for everyone who came along.")
                    }
                }

                Section {
                    DatePicker("Reminder time", selection: ReminderTime.binding(appState), displayedComponents: .hourAndMinute)
                    if !reminders.isAuthorized {
                        Button("Turn on notifications") {
                            Task {
                                let granted = await reminders.requestAuthorization()
                                if granted { reminders.schedule(minutesAfterMidnight: appState.reminderMinutes, dogNames: appState.dogNames) }
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

                Section {
                    LabeledContent("Current streak", value: "\(appState.household.streak) days")
                    LabeledContent("Longest streak", value: "\(appState.household.longestStreak) days")
                    LabeledContent("Full-target days", value: "\(appState.stats.goalDays) of \(appState.stats.daysWalked) walked")
                    LabeledContent("Distance", value: "\(Stats.miles(appState.household.totalMiles)) miles")
                    LabeledContent("Time together", value: Stats.duration(minutes: appState.household.totalMinutes))
                } header: {
                    Text("So far")
                } footer: {
                    if appState.hasMultipleDogs {
                        Text("The streak is the whole household's: a day counts once every dog has had their walk. Full-target days are \(appState.dog.possessive).")
                    }
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
            .sheet(isPresented: $showAddDog) {
                AddDogView()
            }
            .onChange(of: appState.reminderMinutes) { _, minutes in
                Analytics.track(.reminderTimeChanged, ["minutes": minutes])
                if reminders.isAuthorized { reminders.schedule(minutesAfterMidnight: minutes, dogNames: appState.dogNames) }
            }
            .onChange(of: appState.dog.name) { _, _ in
                if reminders.isAuthorized { reminders.schedule(minutesAfterMidnight: appState.reminderMinutes, dogNames: appState.dogNames) }
            }
            .onChange(of: appState.dogs.count) { _, _ in
                if reminders.isAuthorized {
                    reminders.schedule(minutesAfterMidnight: appState.reminderMinutes, dogNames: appState.dogNames)
                }
            }
        }
    }
}
