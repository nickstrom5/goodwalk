import SwiftUI
import UIKit

/// Settings → Help. Every way to reach a person, in one place.
struct HelpSection: View {
    @Environment(\.openURL) private var openURL
    @State private var copied = false

    var body: some View {
        Section {
            Button("Get help") { compose(.help) }
            Button("Send feedback or an idea") { compose(.feedback) }
            Link("Help & FAQ", destination: Support.helpURL)
            if let reviewURL = Support.reviewURL {
                Link("Rate \(Support.appName)", destination: reviewURL)
            }
            Button(copied ? "Address copied" : "Copy support address") { copyAddress() }
        } header: {
            Text("Help")
        } footer: {
            Text("\(Support.email) · A person reads every message.")
        }
    }

    private func compose(_ kind: Support.Kind) {
        Analytics.track(.supportTapped, ["kind": kind.rawValue])
        openURL(Support.mailURL(kind)) { accepted in
            // No mail app set up: put the address on the clipboard instead of doing nothing.
            if !accepted { copyAddress() }
        }
    }

    private func copyAddress() {
        UIPasteboard.general.string = Support.email
        copied = true
    }
}
