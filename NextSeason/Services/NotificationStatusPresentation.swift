//
//  NotificationStatusPresentation.swift
//  NextSeason
//

import SwiftUI
import UserNotifications

/// Shared UI-facing notification permission state for About, Watchlist, and Diagnostics.
nonisolated struct NotificationStatusPresentation: Equatable, Sendable {
    /// True when the system can show alert banners for this app.
    var canDeliverVisibleAlerts: Bool
    /// True when the system has never asked for notification permission.
    var isAuthorizationNotDetermined: Bool

    static let unknown = NotificationStatusPresentation(
        canDeliverVisibleAlerts: false,
        isAuthorizationNotDetermined: true
    )

    var statusLabel: String {
        canDeliverVisibleAlerts ? "Enabled" : "Disabled"
    }

    var diagnosticsEnabledLabel: String {
        canDeliverVisibleAlerts ? "Yes" : "No"
    }

    var symbolName: String {
        canDeliverVisibleAlerts ? "bell.fill" : "bell.slash"
    }

    var showsDisabledBanner: Bool {
        !canDeliverVisibleAlerts
    }

    /// Watchlist banner CTA: prompt when never asked, otherwise open Settings.
    var enablementButtonTitle: String {
        Self.enablementButtonTitle(isAuthorizationNotDetermined: isAuthorizationNotDetermined)
    }

    static func enablementButtonTitle(isAuthorizationNotDetermined: Bool) -> String {
        isAuthorizationNotDetermined ? "Enable Notifications" : "Open Settings"
    }

    @MainActor
    static func load(using service: any NotificationManaging) async -> NotificationStatusPresentation {
        let canDeliver = await service.canDeliverVisibleAlerts()
        let status = await service.authorizationStatus()
        return NotificationStatusPresentation(
            canDeliverVisibleAlerts: canDeliver,
            isAuthorizationNotDetermined: status == .notDetermined
        )
    }
}

extension View {
    /// Refreshes notification presentation when the scene becomes active.
    func refreshNotificationStatus(_ status: Binding<NotificationStatusPresentation>) -> some View {
        modifier(NotificationStatusRefreshModifier(status: status))
    }
}

private struct NotificationStatusRefreshModifier: ViewModifier {
    @Environment(\.notificationService) private var notificationService
    @Environment(\.scenePhase) private var scenePhase
    @Binding var status: NotificationStatusPresentation

    func body(content: Content) -> some View {
        content
            .onChange(of: scenePhase) { _, phase in
                guard phase == .active else { return }
                Task { await refresh() }
            }
    }

    private func refresh() async {
        status = await NotificationStatusPresentation.load(using: notificationService)
    }
}
