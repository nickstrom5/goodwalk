import PhotosUI
import SwiftUI

/// Shown when a timed walk ends. The walk's numbers on a card, and the option to put a photo of
/// the dog behind them. The photo is never saved: it lives here until the card is shared or the
/// screen is closed, which is what lets the app keep saying nothing leaves your phone.
struct WalkResultView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    let walk: Walk

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
                        Text("Nice walk.")
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
                            TertiaryButton(title: "Remove the photo") { photo = nil }
                        }
                        PrimaryButton(title: "Share the card") {
                            Analytics.track(.shareTapped, ["from": "walk_result", "photo": photo != nil])
                            shareImage = card.render()
                        }
                        TertiaryButton(title: "Done") { dismiss() }
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
            CameraPicker { image in photo = image }
                .ignoresSafeArea()
        }
        .photosPicker(isPresented: $showLibrary, selection: $pickerItem, matching: .images)
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                    photo = image
                }
            }
        }
        .sheet(item: $shareImage) { image in
            ShareSheet(items: [image, "\(ShareCardView.headline(minutes: walk.minutes, dog: walkedWith)). Every dog deserves a good walk."])
        }
    }

    private var summary: String {
        let measured = walk.distanceEstimated ? " (est.)" : ""
        let length = walk.minutes < 60 ? "\(walk.minutes) minute\(walk.minutes == 1 ? "" : "s")" : Stats.duration(minutes: walk.minutes)
        return "\(length) and \(Stats.milesPhrase(walk.miles))\(measured) with \(walkedWith)."
    }
}
