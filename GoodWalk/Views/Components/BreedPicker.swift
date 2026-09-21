import SwiftUI

/// Search for the breed instead of deciding what "medium" means. Choosing one fills in size and
/// type and closes; both remain editable underneath, because this is a shortcut, not a diagnosis.
struct BreedPicker: View {
    @Environment(\.dismiss) private var dismiss
    /// Called with the chosen breed, or nil for "not listed", which clears the label and leaves
    /// the chips as they were.
    let onChoose: (DogBreed?) -> Void

    @State private var query = ""
    @FocusState private var searchFocused: Bool

    private var results: [DogBreed] { DogBreed.search(query) }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchField
                // The rows carry minutes, so the honesty line has to be on screen with them.
                GuidelineFootnote()
                    .padding(.horizontal, Theme.horizontalPadding)
                    .padding(.bottom, 10)
                if results.isEmpty {
                    empty
                } else {
                    List {
                        ForEach(results) { breed in
                            Button { choose(breed) } label: { row(breed) }
                                .buttonStyle(.plain)
                        }
                        Section {
                            Button("My dog isn't listed") { choose(nil) }
                        } footer: {
                            Text("Then pick the closest size and type instead. Every number in Good Walk is a general guideline, not veterinary advice.")
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .scrollDismissesKeyboard(.immediately)
                }
            }
            .background(Theme.background)
            .navigationTitle("Find the breed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
            }
            .onAppear { searchFocused = true }
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").foregroundStyle(Theme.textTertiary)
            TextField("Labrador, staffy, sausage dog…", text: $query)
                .focused($searchFocused)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.words)
                .submitLabel(.search)
            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.textTertiary)
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(14)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .padding(.horizontal, Theme.horizontalPadding)
        .padding(.vertical, 12)
    }

    private func row(_ breed: DogBreed) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(breed.name)
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.textPrimary)
                Text(breed.summary)
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer(minLength: 8)
            Text("~\(breed.adultMinutes) min")
                .font(Theme.Font.caption)
                .foregroundStyle(Theme.accent)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityHint("Sets size and type, and suggests about \(breed.adultMinutes) minutes a day for an adult")
    }

    private var empty: some View {
        VStack(spacing: 10) {
            Text("No breed by that name here.")
                .font(Theme.Font.headline)
                .foregroundStyle(Theme.textPrimary)
            Text("The list covers common breeds. For anything else, pick the closest size and type and the guideline works the same way.")
                .font(Theme.Font.body)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
            SecondaryButton(title: "My dog isn't listed") { choose(nil) }
                .padding(.top, 4)
        }
        .padding(.horizontal, Theme.horizontalPadding)
        .padding(.top, 28)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private func choose(_ breed: DogBreed?) {
        onChoose(breed)
        dismiss()
    }
}

/// The line that appears once a breed is chosen: what it set, and what it means for the target.
/// Always sits next to a `GuidelineFootnote`, because it shows a guideline number.
struct BreedSummaryRow: View {
    let dog: DogProfile
    let onChange: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "pawprint.circle.fill")
                .font(.system(size: 26))
                .foregroundStyle(Theme.accent)
            VStack(alignment: .leading, spacing: 2) {
                Text(dog.breedLabel)
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.textPrimary)
                Text("A dog like this is built for about \(WalkPlan.recommendedMinutes(for: dog)) min a day.")
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            Button("Change", action: onChange)
                .font(Theme.Font.caption)
                .buttonStyle(.borderless)
        }
    }
}
