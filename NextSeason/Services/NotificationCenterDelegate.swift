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
    private static var bufferedShowID: Int?

    static func setCoordinator(_ coordinator: AppNavigationCoordinator) {
        self.coordinator = coordinator
        flushBufferedNavigation()
    }

    static func install(center: UNUserNotificationCenter = .current()) {
        center.delegate = NotificationCenterDelegate.shared
        flushBufferedNavigation()
    }

    static func routeToShow(showID: Int) {
        if let coordinator {
            coordinator.queueShowNavigation(showID: showID)
        } else {
            bufferedShowID = showID
        }
    }

    private static func flushBufferedNavigation() {
        guard let showID = bufferedShowID, let coordinator else { return }
        bufferedShowID = nil
        coordinator.queueShowNavigation(showID: showID)
    }

    static func showID(from userInfo: [AnyHashable: Any]) -> Int? {
        if let id = userInfo["showID"] as? Int { return id }
        if let number = userInfo["showID"] as? NSNumber { return number.intValue }
        return nil
    }

    #if DEBUG
    /// Clears routing state between unit tests.
    static func resetForTesting() {
        coordinator = nil
        bufferedShowID = nil
    }
    #endif
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
        NotificationRouting.routeToShow(showID: showID)
    }
}
