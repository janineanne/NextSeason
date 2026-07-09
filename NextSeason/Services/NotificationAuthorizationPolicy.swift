//
//  NotificationAuthorizationPolicy.swift
//  NextSeason
//

import Foundation
import UserNotifications

/// Pure authorization checks shared by notification delivery and tests.
nonisolated enum NotificationAuthorizationPolicy {
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

    /// True when the system will present visible alert banners for this app.
    static func canDeliverAlerts(from settings: UNNotificationSettings) -> Bool {
        canDeliverAlerts(settings.authorizationStatus) && settings.alertSetting == .enabled
    }
}
