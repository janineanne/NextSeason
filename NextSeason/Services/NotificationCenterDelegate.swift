//
//  NotificationCenterDelegate.swift
//  NextSeason
//

import Foundation
import UserNotifications

/// Forwards notification taps to `AppNavigationCoordinator` on the main actor.
@MainActor
enum NotificationRouting {
    static weak var coordinator: AppNavigationCoordinator?

    static func install(center: UNUserNotificationCenter = .current()) {
        center.delegate = NotificationCenterDelegate.shared
    }

    static func showID(from userInfo: [AnyHashable: Any]) -> Int? {
        if let id = userInfo["showID"] as? Int { return id }
        if let number = userInfo["showID"] as? NSNumber { return number.intValue }
        return nil
    }
}

final class NotificationCenterDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationCenterDelegate()

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        guard let showID = NotificationRouting.showID(from: userInfo) else { return }
        await MainActor.run {
            NotificationRouting.coordinator?.queueShowNavigation(showID: showID)
        }
    }
}
