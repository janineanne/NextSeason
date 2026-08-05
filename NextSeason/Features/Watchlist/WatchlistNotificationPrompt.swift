//
//  WatchlistNotificationPrompt.swift
//  NextSeason
//

import SwiftUI

/// Alert flags for the post-track notification authorization flow (shared by
/// Search and Show Detail via `watchlistNotificationPromptAlerts`).
///
/// After the user adds a show, callers set `shouldPromptForNotifications` when
/// `NotificationService` says a prompt is still appropriate; "Not Now" defers
/// via UserDefaults, and a denial surfaces the Settings reminder alert.
@Observable
@MainActor
final class WatchlistNotificationPromptState {
    var shouldPromptForNotifications = false
    var shouldShowNotificationsDeniedAlert = false

    /// Honors "Not Now" by recording deferral in `NotificationService`.
    func deferPrompt(using notificationService: any NotificationManaging) {
        notificationService.deferAuthorizationPrompt()
    }

    func shouldShowNotificationsSettingsReminder() {
        shouldShowNotificationsDeniedAlert = true
    }

    /// Requests system authorization; if still denied, shows the Settings reminder.
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
