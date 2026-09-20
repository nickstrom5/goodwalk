import Foundation
import UIKit

/// Where users reach a person. One address, two subjects, and enough device detail in the draft
/// that a bug report is useful without a back-and-forth. The app sends nothing itself: these
/// only open the user's own mail app with a draft they can read and edit before sending.
enum Support {
    static let appName = "Good Walk"
    static let email = "support@getgoodwalk.app"
    static let helpURL = URL(string: "https://getgoodwalk.app/support.html")!

    /// Numeric App Store ID (App Store Connect → App Information → Apple ID). Empty until the
    /// listing exists; the "Rate" row stays hidden until it is set.
    static let appStoreID = ""

    static var reviewURL: URL? {
        appStoreID.isEmpty ? nil : URL(string: "https://apps.apple.com/app/id\(appStoreID)?action=write-review")
    }

    enum Kind: String {
        case help, feedback

        var subject: String {
            switch self {
            case .help: return "\(Support.appName) help"
            case .feedback: return "\(Support.appName) feedback"
            }
        }

        var opener: String {
            switch self {
            case .help: return "What happened, and what did you expect instead?"
            case .feedback: return "What would make \(Support.appName) better for you?"
            }
        }
    }

    /// A `mailto:` URL with the subject and a short body already filled in.
    static func mailURL(_ kind: Kind) -> URL {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = email
        components.queryItems = [
            URLQueryItem(name: "subject", value: kind.subject),
            URLQueryItem(name: "body", value: "\(kind.opener)\n\n\n—\n\(diagnostics)")
        ]
        return components.url ?? URL(string: "mailto:\(email)")!
    }

    /// App version, iOS version and device model. No identifiers, nothing personal.
    static var diagnostics: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "\(appName) \(version) (\(build)) · iOS \(UIDevice.current.systemVersion) · \(deviceModel)"
    }

    private static var deviceModel: String {
        var system = utsname()
        uname(&system)
        return withUnsafePointer(to: &system.machine) { pointer in
            pointer.withMemoryRebound(to: CChar.self, capacity: Int(_SYS_NAMELEN)) { String(cString: $0) }
        }
    }
}
