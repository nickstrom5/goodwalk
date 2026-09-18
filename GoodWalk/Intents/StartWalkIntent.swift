import AppIntents
import Foundation

/// Lets the Home Screen widget, Siri, Shortcuts and the Action Button start the walk timer.
/// Compiled into both the app and the widget extension.
struct StartWalkIntent: AppIntent {
    static var title: LocalizedStringResource = "Start a walk"
    static var description = IntentDescription("Opens Good Walk and starts the walk timer.")
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        AppGroup.defaults.set(true, forKey: AppGroup.Key.pendingStartWalk)
        return .result()
    }
}
