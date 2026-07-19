//
//  BetaAppInfoSection.swift
//  NextSeason
//

import SwiftUI

/// Shared “App” list section used by About and Diagnostics.
struct BetaAppInfoSection: View {
    let channelDisplayName: String
    var themeDisplayName: String?
    var notificationsEnabledLabel: String?

    var body: some View {
        Section("App") {
            LabeledContent("Version", value: AppVersionInfo.displayString)
            LabeledContent("Build channel", value: channelDisplayName)
            if let themeDisplayName {
                LabeledContent("Current theme", value: themeDisplayName)
            }
            if let notificationsEnabledLabel {
                LabeledContent("Notifications enabled", value: notificationsEnabledLabel)
            }
        }
    }
}
