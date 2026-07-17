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

extension View {
    /// Refreshes a notifications-enabled flag when the scene becomes active.
    func refreshNotificationDeliveryStatus(_ enabled: Binding<Bool>) -> some View {
        modifier(NotificationDeliveryStatusRefreshModifier(notificationsEnabled: enabled))
    }
}

private struct NotificationDeliveryStatusRefreshModifier: ViewModifier {
    @Environment(\.notificationService) private var notificationService
    @Environment(\.scenePhase) private var scenePhase
    @Binding var notificationsEnabled: Bool

    func body(content: Content) -> some View {
        content
            .onChange(of: scenePhase) { _, phase in
                guard phase == .active else { return }
                Task { await refresh() }
            }
    }

    private func refresh() async {
        notificationsEnabled = await notificationService.canDeliverVisibleAlerts()
    }
}
