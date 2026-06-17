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
}
