import UIKit

/// Dog photos live as JPEGs in the App Group container: a full one per dog for the app and the
/// share card, plus a small copy of the dog the widget is showing. Nothing is uploaded anywhere.
enum DogPhotoStore {
    static func load(for dogID: UUID) -> UIImage? {
        UIImage(contentsOfFile: AppGroup.photoURL(for: dogID).path)
    }

    static func loadForWidget() -> UIImage? {
        UIImage(contentsOfFile: AppGroup.widgetPhotoURL.path)
    }

    @discardableResult
    static func save(_ image: UIImage, for dogID: UUID) -> UIImage? {
        let full = image.squareCropped().resized(longestSide: 1_200)
        guard let fullData = full.jpegData(compressionQuality: 0.85) else { return nil }
        do {
            try fullData.write(to: AppGroup.photoURL(for: dogID), options: .atomic)
            return full
        } catch {
            return nil
        }
    }

    static func delete(for dogID: UUID) {
        try? FileManager.default.removeItem(at: AppGroup.photoURL(for: dogID))
    }

    /// Writes the small copy the widget reads, or clears it when the shown dog has no photo.
    static func mirrorToWidget(_ image: UIImage?) {
        guard let image else {
            try? FileManager.default.removeItem(at: AppGroup.widgetPhotoURL)
            return
        }
        let small = image.squareCropped().resized(longestSide: 300)
        guard let data = small.jpegData(compressionQuality: 0.8) else { return }
        try? data.write(to: AppGroup.widgetPhotoURL, options: .atomic)
    }
}

extension UIImage {
    /// Center square crop, orientation baked in. Avatars are round; a square source keeps faces centered.
    func squareCropped() -> UIImage {
        let side = min(size.width, size.height)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format)
        return renderer.image { _ in
            draw(at: CGPoint(x: (side - size.width) / 2, y: (side - size.height) / 2))
        }
    }

    func resized(longestSide: CGFloat) -> UIImage {
        let longest = max(size.width, size.height)
        guard longest > longestSide else { return self }
        let ratio = longestSide / longest
        let target = CGSize(width: (size.width * ratio).rounded(), height: (size.height * ratio).rounded())
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: target))
        }
    }
}
