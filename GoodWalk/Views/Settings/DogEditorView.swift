import PhotosUI
import SwiftUI

/// The fields that describe one dog. Used inline in Settings when there is a single dog, and
/// pushed from the roster when there are several, so the one-dog screen never gains a tap.
struct DogFields: View {
    @Binding var dog: DogProfile
    let image: UIImage?
    let onPickPhoto: (UIImage) -> Void
    let onRemovePhoto: () -> Void

    @State private var pickerItem: PhotosPickerItem?
    @State private var showBreedSearch = false

    var body: some View {
        Section {
            HStack(spacing: 14) {
                DogAvatar(image: image, size: 56)
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Dog's name", text: $dog.name)
                        .font(Theme.Font.headline)
                    PhotosPicker(image == nil ? "Add a photo" : "Change photo", selection: $pickerItem, matching: .images)
                        .font(Theme.Font.caption)
                }
                Spacer(minLength: 0)
                if image != nil {
                    Button("Remove", role: .destructive, action: onRemovePhoto)
                        .font(Theme.Font.caption)
                        .buttonStyle(.borderless)
                }
            }
            if dog.breedName.isEmpty {
                Button("Find the breed") { showBreedSearch = true }
            } else {
                BreedSummaryRow(dog: dog) { showBreedSearch = true }
            }
            Picker("Size", selection: $dog.size) {
                ForEach(DogProfile.Size.allCases) { Text($0.label).tag($0) }
            }
            Picker("Type", selection: $dog.breedType) {
                ForEach(DogProfile.BreedType.allCases) { Text($0.label).tag($0) }
            }
            Picker("Age", selection: $dog.age) {
                ForEach(DogProfile.Age.allCases) { Text($0.label).tag($0) }
            }
        } header: {
            Text(dog.displayName == "your dog" ? "Your dog" : dog.displayName)
        }

        Section {
            Stepper("Daily target: \(dog.dailyGoal) min",
                    value: Binding(get: { dog.dailyGoal }, set: { dog.goalMinutes = $0 }),
                    in: WalkPlan.minimumMinutes...180, step: 5)
            Stepper("\"Walked\" logs: \(dog.usualMinutes) min", value: $dog.usualMinutes, in: 5...120, step: 5)
        } header: {
            Text("Target")
        } footer: {
            Text("Guideline for a dog like \(dog.displayName): about \(WalkPlan.recommendedMinutes(for: dog)) min a day. General guidance, not veterinary advice.")
        }
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self), let picked = UIImage(data: data) {
                    onPickPhoto(picked)
                }
            }
        }
        .sheet(isPresented: $showBreedSearch) {
            BreedPicker { breed in dog.apply(breed) }
        }
    }
}

/// One dog's own screen, pushed from the roster. Everything about them, plus the way out.
struct DogEditorView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    let dogID: UUID

    @State private var confirmRemove = false

    var body: some View {
        List {
            if let binding = appState.binding(for: dogID) {
                DogFields(dog: binding,
                          image: appState.image(for: dogID),
                          onPickPhoto: { appState.setDogPhoto($0, for: dogID) },
                          onRemovePhoto: { appState.removeDogPhoto(for: dogID) })
            }

            if appState.hasMultipleDogs {
                Section {
                    Button("Remove this dog", role: .destructive) { confirmRemove = true }
                } footer: {
                    Text("Walks they shared with another dog stay in the log. Walks that were only theirs go with them.")
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle(appState.dog(withID: dogID)?.displayName ?? "Dog")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Remove \(appState.dog(withID: dogID)?.displayName ?? "this dog")?",
                            isPresented: $confirmRemove, titleVisibility: .visible) {
            Button("Remove", role: .destructive) {
                appState.removeDog(dogID)
                dismiss()
            }
            Button("Keep", role: .cancel) {}
        } message: {
            Text("Their photo and their own walks are deleted from this phone. This can't be undone.")
        }
    }
}

/// Adding the second dog. Short on purpose: name, size, type, age. The photo can come later,
/// and onboarding stays untouched, so the funnel before the paywall never gets longer.
struct AddDogView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var reminders: ReminderManager
    @Environment(\.dismiss) private var dismiss

    @State private var dog = DogProfile()
    @State private var pickerItem: PhotosPickerItem?
    @State private var photo: UIImage?
    @State private var showBreedSearch = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 14) {
                        DogAvatar(image: photo, size: 56)
                        VStack(alignment: .leading, spacing: 4) {
                            TextField("Their name", text: $dog.name)
                                .font(Theme.Font.headline)
                            PhotosPicker(photo == nil ? "Add a photo" : "Change photo", selection: $pickerItem, matching: .images)
                                .font(Theme.Font.caption)
                        }
                    }
                    if dog.breedName.isEmpty {
                        Button("Find the breed") { showBreedSearch = true }
                    } else {
                        BreedSummaryRow(dog: dog) { showBreedSearch = true }
                    }
                    Picker("Size", selection: $dog.size) {
                        ForEach(DogProfile.Size.allCases) { Text($0.label).tag($0) }
                    }
                    Picker("Type", selection: $dog.breedType) {
                        ForEach(DogProfile.BreedType.allCases) { Text($0.label).tag($0) }
                    }
                    Picker("Age", selection: $dog.age) {
                        ForEach(DogProfile.Age.allCases) { Text($0.label).tag($0) }
                    }
                } header: {
                    Text("Another dog")
                } footer: {
                    Text("Their guideline: about \(WalkPlan.recommendedMinutes(for: dog)) min a day. General guidance, not veterinary advice. Their streak starts today, so the days before they arrived stay yours.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("Add a dog")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") { add() }
                        .disabled(dog.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onChange(of: pickerItem) { _, item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self), let picked = UIImage(data: data) {
                        photo = picked
                    }
                }
            }
            .sheet(isPresented: $showBreedSearch) {
                BreedPicker { breed in dog.apply(breed) }
            }
        }
    }

    private func add() {
        let added = appState.addDog(dog)
        if let photo { appState.setDogPhoto(photo, for: added.id) }
        // The notification names everyone, and its text is fixed when it's scheduled.
        if reminders.isAuthorized {
            reminders.schedule(minutesAfterMidnight: appState.reminderMinutes, dogNames: appState.dogNames)
        }
        dismiss()
    }
}
