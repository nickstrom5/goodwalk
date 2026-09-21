import Combine
import Foundation
import UserNotifications

/// The daily walk reminder. One repeating local notification with two actions: "Walked" logs the
/// usual walk without opening the app; "Start a walk" opens the app on the timer.
///
/// One notification however many dogs live here. The content is fixed when it's scheduled, so it
/// names the whole household and "Walked" sorts out at tap time who still hadn't been out. A
/// notification per dog would turn the one tap that makes this app work into a queue of them.
@MainActor
final class ReminderManager: NSObject, ObservableObject {
    static let categoryID = "goodwalk.reminder"
    static let walkedActionID = "goodwalk.reminder.walked"
    static let startActionID = "goodwalk.reminder.start"
    static let requestID = "goodwalk.reminder.daily"

    @Published private(set) var isAuthorized = false

    /// Set by the app. Called on the main actor when the user taps "Walked" on the notification.
    var onWalked: (() -> Void)?
    /// Called when the user taps "Start a walk"; the app opens and starts the timer.
    var onStartWalk: (() -> Void)?

    override init() {
        super.init()
        let walked = UNNotificationAction(identifier: Self.walkedActionID, title: "Walked ✓", options: [])
        let start = UNNotificationAction(identifier: Self.startActionID, title: "Start a walk", options: [.foreground])
        let category = UNNotificationCategory(identifier: Self.categoryID, actions: [walked, start], intentIdentifiers: [])
        let center = UNUserNotificationCenter.current()
        center.setNotificationCategories([category])
        center.delegate = self
    }

    func refreshStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
    }

    /// Asks once. Returns true when granted.
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted
            Analytics.track(granted ? .remindersAuthorized : .remindersDenied)
            return granted
        } catch {
            isAuthorized = false
            Analytics.track(.remindersDenied, ["error": String(describing: error)])
            return false
        }
    }

    /// (Re)schedules the daily reminder at `minutesAfterMidnight` local time. Call it again when
    /// a dog is added, removed or renamed: the text is baked in when the request is made.
    func schedule(minutesAfterMidnight: Int, dogNames: [String]) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.requestID])

        let content = UNMutableNotificationContent()
        content.title = Self.title(dogNames: dogNames)
        content.body = dogNames.count > 1
            ? "One tap logs everyone who hasn't been out. Or grab the leash and start the timer."
            : "One tap keeps the streak. Or grab the leash and start the timer."
        content.sound = .default
        content.categoryIdentifier = Self.categoryID

        var components = DateComponents()
        components.hour = minutesAfterMidnight / 60
        components.minute = minutesAfterMidnight % 60
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        center.add(UNNotificationRequest(identifier: Self.requestID, content: content, trigger: trigger))
    }

    /// "Has Rex had a walk today?" / "Have Rex and Juno had a walk today?"
    static func title(dogNames: [String]) -> String {
        let names = dogNames.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard !names.isEmpty else { return "Has your dog had a walk today?" }
        let subject: String
        switch names.count {
        case 1: subject = names[0]
        case 2: subject = "\(names[0]) and \(names[1])"
        default: subject = names.dropLast().joined(separator: ", ") + " and " + (names.last ?? "")
        }
        return "\(names.count == 1 ? "Has" : "Have") \(subject) had a walk today?"
    }

    static func label(forMinutes minutes: Int) -> String {
        var components = DateComponents()
        components.hour = minutes / 60
        components.minute = minutes % 60
        let date = Calendar.current.date(from: components) ?? Date()
        return date.formatted(date: .omitted, time: .shortened)
    }
}

extension ReminderManager: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            didReceive response: UNNotificationResponse,
                                            withCompletionHandler completionHandler: @escaping () -> Void) {
        let action = response.actionIdentifier
        Task { @MainActor in
            switch action {
            case Self.walkedActionID:
                onWalked?()
            case Self.startActionID:
                onStartWalk?()
            default:
                break
            }
            completionHandler()
        }
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            willPresent notification: UNNotification,
                                            withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}
