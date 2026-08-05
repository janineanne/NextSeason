//
//  NotificationAuthorizationPolicy.swift
//  NextSeason
//

import Foundation
import UserNotifications

/// Pure authorization checks shared by notification delivery and tests.
///
/// Kept free of `UNUserNotificationCenter` so unit tests can pass statuses
/// without presenting system sheets.
nonisolated enum NotificationAuthorizationPolicy {
    /// Statuses that may deliver notifications (including quiet provisional / ephemeral).
    static func canDeliverAlerts(_ status: UNAuthorizationStatus) -> Bool {
        switch status {
        case .authorized, .provisional, .ephemeral:
            true
        case .notDetermined, .denied:
            false
        @unknown default:
            false
        }
    }

    /// True when the system will present visible alert banners for this app
    /// (authorized *and* alerts enabled in Settings).
    static func canDeliverAlerts(from settings: UNNotificationSettings) -> Bool {
        canDeliverAlerts(settings.authorizationStatus) && settings.alertSetting == .enabled
    }
}
