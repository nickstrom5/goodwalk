import AppIntents

/// Exposes the intent to Siri, Spotlight and the Shortcuts app. App target only.
struct GoodWalkShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartWalkIntent(),
            phrases: [
                "Start a walk in \(.applicationName)",
                "Start a dog walk with \(.applicationName)",
                "Walk the dog with \(.applicationName)"
            ],
            shortTitle: "Start a walk",
            systemImageName: "pawprint.fill"
        )
    }
}
