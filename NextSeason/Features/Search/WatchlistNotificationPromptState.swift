//
//  WatchlistNotificationPromptState.swift
//  NextSeason
//

import SwiftUI

/// Alert state for the post-track notification authorization flow.
@Observable
@MainActor
final class WatchlistNotificationPromptState {
    var shouldPromptForNotifications = false
    var shouldShowNotificationsDeniedAlert = false

    func deferPrompt(using notificationService: any NotificationManaging) {
        notificationService.deferAuthorizationPrompt()
    }

    func shouldShowNotificationsSettingsReminder() {
        shouldShowNotificationsDeniedAlert = true
    }

    func confirmPrompt(using notificationService: any NotificationManaging) async {
        await notificationService.requestAuthorizationIfNeeded()
        if await notificationService.isDenied() {
            shouldShowNotificationsSettingsReminder()
        }
    }
}

/// Presents the standard first-run notification prompts after adding to the watchlist.
struct WatchlistNotificationPromptAlerts: ViewModifier {
    @Bindable var prompt: WatchlistNotificationPromptState
    let notificationService: any NotificationManaging

    func body(content: Content) -> some View {
        content
            .alert("Stay in the Loop", isPresented: $prompt.shouldPromptForNotifications) {
                Button("Not Now", role: .cancel) {
                    prompt.deferPrompt(using: notificationService)
                }
                Button("Enable Notifications") {
                    Task { await prompt.confirmPrompt(using: notificationService) }
                }
            } message: {
                Text(FirstRunCopy.notificationPromptMessage)
            }
            .alert("Notifications Not Enabled", isPresented: $prompt.shouldShowNotificationsDeniedAlert) {
                Button("Not Now", role: .cancel) {}
                Button("Open Settings") {
                    Task { await notificationService.enableNotificationsFromSettingsEntryPoint() }
                }
            } message: {
                Text(FirstRunCopy.notificationsSettingsReminderMessage)
            }
    }
}

extension View {
    func watchlistNotificationPromptAlerts(
        prompt: WatchlistNotificationPromptState,
        notificationService: any NotificationManaging
    ) -> some View {
        modifier(
            WatchlistNotificationPromptAlerts(
                prompt: prompt,
                notificationService: notificationService
            )
        )
    }
}
