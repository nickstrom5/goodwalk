import PhotosUI
import SwiftUI

/// One walk: its numbers on a card, and a photo of the dog taken on that walk. Shown when a
/// timed walk ends, and again whenever the walk is opened from the calendar.
///
/// The photo is kept with the walk on this phone, so the day can be looked back at months later.
/// It is never uploaded: a card leaves the phone only when the user shares it.
struct WalkResultView: View {
    /// Why this screen is open. Only the heading differs; a walk from last March deserves the
    /// same card as the one that just ended.
    enum Context {
        case justFinished, fromLog
    }

    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    let walk: Walk
    var context: Context = .justFinished

    @State private var photo: UIImage?
    @State private var pickerItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var showSourceChoice = false
    @State private var showLibrary = false
    @State private var shareImage: UIImage?

    private var dog: DogProfile { appState.dog }
    /// Whoever was actually on this walk, so a walk with both dogs says both names.
    private var walkedWith: String {
        let dogs = appState.dogs.filter { walk.counted(for: $0.id) }
        return dogs.isEmpty ? dog.displayName : DogProfile.names(dogs)
    }
    private var card: ShareCardView {
        ShareCardView.walk(dogName: walkedWith, image: photo ?? appState.dogImage, walk: walk,
                           streak: appState.household.streak)
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    VStack(spacing: 4) {
                        Text(heading)
                            .font(Theme.Font.title)
                            .foregroundStyle(Theme.textPrimary)
                        Text(summary)
                            .font(Theme.Font.body)
                            .foregroundStyle(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 8)

                    card.frame(maxWidth: .infinity)

                    VStack(spacing: 10) {
                        SecondaryButton(title: photo == nil ? "Add a photo of \(walkedWith)" : "Use a different photo") {
                            if CameraPicker.isAvailable { showSourceChoice = true } else { showLibrary = true }
                        }
                        if photo != nil {
                            TertiaryButton(title: "Remove the photo") { removePhoto() }
                        }
                        PrimaryButton(title: "Share the card") {
                            Analytics.track(.shareTapped, ["from": "walk_result", "photo": photo != nil])
                            shareImage = card.render()
                        }
                        TertiaryButton(title: "Done") { dismiss() }
                        Text(photo == nil
                             ? "A photo you add is kept with this walk on your phone, and you can find it again on the calendar."
                             : "Saved to this walk. It stays on your phone; the card leaves only when you share it.")
                            .font(Theme.Font.caption)
                            .foregroundStyle(Theme.textTertiary)
                            .multilineTextAlignment(.center)
                            .padding(.top, 2)
                    }
                    .padding(.horizontal, Theme.horizontalPadding)
                }
                .padding(.bottom, 24)
                .phoneWidthColumn()
            }
            .background(Theme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
            }
        }
        .confirmationDialog("Add a photo", isPresented: $showSourceChoice, titleVisibility: .hidden) {
            Button("Take a photo") { showCamera = true }
            Button("Choose from library") { showLibrary = true }
            Button("Cancel", role: .cancel) {}
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { image in keep(image) }
                .ignoresSafeArea()
        }
        .photosPicker(isPresented: $showLibrary, selection: $pickerItem, matching: .images)
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                    keep(image)
                }
            }
        }
        .onAppear { photo = appState.walkPhoto(for: walk.id) }
        .sheet(item: $shareImage) { image in
            ShareSheet(items: [image, "\(ShareCardView.headline(minutes: walk.minutes, dog: walkedWith)). Every dog deserves a good walk.\(Config.shareCredit)"])
        }
    }

    private func keep(_ image: UIImage) {
        photo = image
        appState.setWalkPhoto(image, for: walk.id)
    }

    private func removePhoto() {
        photo = nil
        appState.removeWalkPhoto(for: walk.id)
    }

    private var heading: String {
        guard context == .fromLog else { return "Nice walk." }
        let cal = Calendar.current
        if cal.isDateInToday(walk.start) { return "Today's walk." }
        if cal.isDateInYesterday(walk.start) { return "Yesterday's walk." }
        return walk.start.formatted(date: .abbreviated, time: .omitted)
    }

    private var summary: String {
        let measured = walk.distanceEstimated ? " (est.)" : ""
        let length = walk.minutes < 60 ? "\(walk.minutes) minute\(walk.minutes == 1 ? "" : "s")" : Stats.duration(minutes: walk.minutes)
        return "\(length) and \(Stats.milesPhrase(walk.miles))\(measured) with \(walkedWith)."
    }
}
