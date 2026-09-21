import UIKit

/// A photo of one particular walk: the dog on the trail that evening, not the profile picture.
/// Stored as JPEGs in the App Group container, one pair per walk, and deleted with the walk.
/// Nothing is uploaded; a card leaves the phone only when the user shares it.
enum WalkPhotoStore {
    /// Longest side of the stored photo. Big enough for a share card at 3x, small enough that a
    /// year of daily walks is tens of megabytes rather than hundreds.
    private static let fullSide: CGFloat = 1_200
    /// Longest side of the copy the day list and the month grid read.
    private static let thumbSide: CGFloat = 300

    static func url(for walkID: UUID) -> URL {
        AppGroup.photoDirectory.appendingPathComponent("walk-\(walkID.uuidString).jpg")
    }

    static func thumbURL(for walkID: UUID) -> URL {
        AppGroup.photoDirectory.appendingPathComponent("walk-\(walkID.uuidString)-thumb.jpg")
    }

    static func load(for walkID: UUID) -> UIImage? {
        UIImage(contentsOfFile: url(for: walkID).path)
    }

    static func loadThumb(for walkID: UUID) -> UIImage? {
        UIImage(contentsOfFile: thumbURL(for: walkID).path) ?? load(for: walkID)
    }

    /// Writes both sizes. Returns the stored full-size image, or nil if it could not be written.
    @discardableResult
    static func save(_ image: UIImage, for walkID: UUID) -> UIImage? {
        let full = image.resized(longestSide: fullSide)
        let thumb = full.squareCropped().resized(longestSide: thumbSide)
        guard let fullData = full.jpegData(compressionQuality: 0.85),
              let thumbData = thumb.jpegData(compressionQuality: 0.8) else { return nil }
        do {
            try fullData.write(to: url(for: walkID), options: .atomic)
            try thumbData.write(to: thumbURL(for: walkID), options: .atomic)
            return full
        } catch {
            return nil
        }
    }

    static func delete(for walkID: UUID) {
        try? FileManager.default.removeItem(at: url(for: walkID))
        try? FileManager.default.removeItem(at: thumbURL(for: walkID))
    }

    static func exists(for walkID: UUID) -> Bool {
        FileManager.default.fileExists(atPath: url(for: walkID).path)
    }
}
