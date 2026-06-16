//
//  NotificationService.swift
//  NextSeason
//

import Foundation
import UserNotifications

/// Abstraction for delivering season-change alerts (testable without UserNotifications).
@MainActor
protocol NotificationDelivering: AnyObject {
    func deliver(_ content: SeasonNotificationContent) async
}

/// Wraps local notification permission and delivery (FR-011, FR-012).
@MainActor
final class NotificationService: NotificationDelivering {
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    /// True when the user has never been asked for notification permission.
    func needsAuthorizationPrompt() async -> Bool {
        await authorizationStatus() == .notDetermined
    }

    /// Requests permission once; returns whether alerts are allowed.
    @discardableResult
    func requestAuthorizationIfNeeded() async -> Bool {
        let status = await authorizationStatus()
        if Self.canDeliverAlerts(status) { return true }
        switch status {
        case .denied:
            return false
        case .notDetermined:
            do {
                return try await center.requestAuthorization(options: [.alert, .sound, .badge])
            } catch {
                return false
            }
        default:
            return false
        }
    }

    func deliver(_ content: SeasonNotificationContent) async {
        let settings = await center.notificationSettings()
        guard Self.canDeliverAlerts(settings.authorizationStatus) else { return }

        let notification = UNMutableNotificationContent()
        notification.title = content.title
        notification.body = content.body
        notification.sound = .default
        notification.userInfo = ["showID": content.showID]

        let request = UNNotificationRequest(
            identifier: "show-\(content.showID)-\(StatusChangeDetector.signature(for: content.status))",
            content: notification,
            trigger: nil
        )

        try? await center.add(request)
    }

    private static func canDeliverAlerts(_ status: UNAuthorizationStatus) -> Bool {
        switch status {
        case .authorized, .provisional, .ephemeral:
            true
        case .notDetermined, .denied:
            false
        @unknown default:
            false
        }
    }
}
