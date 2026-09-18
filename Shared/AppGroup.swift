import Foundation

/// Constants shared between the app and the widget extension.
enum AppGroup {
    static let identifier = "group.app.goodwalk.goodwalk"

    /// UserDefaults suite shared across the app and its extensions.
    static var defaults: UserDefaults {
        UserDefaults(suiteName: identifier) ?? .standard
    }

    enum Key {
        /// The dog's name, mirrored for the widget.
        static let dogName = "dogName"
        /// Daily walk target in minutes.
        static let goalMinutes = "goalMinutes"
        /// Minutes walked on `minutesDay`.
        static let minutesToday = "minutesToday"
        /// "yyyy-MM-dd" the `minutesToday` value belongs to, so the widget resets after midnight.
        static let minutesDay = "minutesDay"
        /// Current walk streak in days. Mirrored by the app for the widget.
        static let streak = "streak"
        /// Set by the widget / Siri intent; the app starts the walk timer on next foreground.
        static let pendingStartWalk = "pendingStartWalk"
    }

    /// Day formatter shared by app and widget. Calendar-local, no time.
    static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar.current
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    // MARK: - Dog photo (a file, not defaults: images are too big for a plist)

    /// Shared container when the App Group is provisioned, the app's own Documents otherwise
    /// (unsigned simulator builds). The widget falls back to the paw when it can't see the file.
    static var photoDirectory: URL {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    /// Full-size photo for the app and the share card (longest side 1,200 px).
    static var photoURL: URL { photoDirectory.appendingPathComponent("dog.jpg") }
    /// Small copy for the widget, which has a tight memory budget (longest side 300 px).
    static var widgetPhotoURL: URL { photoDirectory.appendingPathComponent("dog-widget.jpg") }
}
