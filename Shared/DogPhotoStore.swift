import UIKit

/// The dog's photo lives in two JPEGs in the App Group container: a full one for the app and the
/// share card, and a small one the widget can afford to decode. Nothing is uploaded anywhere.
enum DogPhotoStore {
    static func load() -> UIImage? {
        UIImage(contentsOfFile: AppGroup.photoURL.path)
    }

    static func loadForWidget() -> UIImage? {
        UIImage(contentsOfFile: AppGroup.widgetPhotoURL.path)
    }

    @discardableResult
    static func save(_ image: UIImage) -> UIImage? {
        let full = image.squareCropped().resized(longestSide: 1_200)
        let small = full.resized(longestSide: 300)
        guard let fullData = full.jpegData(compressionQuality: 0.85),
              let smallData = small.jpegData(compressionQuality: 0.8) else { return nil }
        do {
            try fullData.write(to: AppGroup.photoURL, options: .atomic)
            try smallData.write(to: AppGroup.widgetPhotoURL, options: .atomic)
            return full
        } catch {
            return nil
        }
    }

    static func delete() {
        try? FileManager.default.removeItem(at: AppGroup.photoURL)
        try? FileManager.default.removeItem(at: AppGroup.widgetPhotoURL)
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
