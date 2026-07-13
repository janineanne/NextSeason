//
//  NotificationCenterDelegate.swift
//  NextSeason
//

import Foundation
import UIKit
import UserNotifications

/// Forwards notification taps to `AppNavigationCoordinator` on the main actor.
@MainActor
enum NotificationRouting {
    static weak var coordinator: AppNavigationCoordinator?
    static var analytics: (any AnalyticsTracking)?
    private static var bufferedShowID: Int?
    private static var bufferedAnimated = false

    static func setCoordinator(_ coordinator: AppNavigationCoordinator) {
        self.coordinator = coordinator
        flushBufferedNavigation()
    }

    static func setAnalytics(_ analytics: any AnalyticsTracking) {
        self.analytics = analytics
    }

    static func install(center: UNUserNotificationCenter = .current()) {
        center.delegate = NotificationCenterDelegate.shared
        flushBufferedNavigation()
    }

    /// - Parameter animated: `true` when the app was already foreground-active at the
    ///   time of the tap (in-app navigation), `false` for a launch/foreground tap.
    static func routeToShow(showID: Int, animated: Bool) {
        analytics?.track(.notificationTapped(showID: showID))
        if let coordinator {
            coordinator.queueShowNavigation(showID: showID, animated: animated)
        } else {
            bufferedShowID = showID
            bufferedAnimated = animated
        }
    }

    private static func flushBufferedNavigation() {
        guard let showID = bufferedShowID, let coordinator else { return }
        bufferedShowID = nil
        coordinator.queueShowNavigation(showID: showID, animated: bufferedAnimated)
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
        analytics = nil
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
        // A tap while the app is already foreground-active is an in-app navigation
        // (animate); a tap that brings the app forward from background/launch is not.
        let wasActive = UIApplication.shared.applicationState == .active
        NotificationRouting.routeToShow(showID: showID, animated: wasActive)
    }
}
