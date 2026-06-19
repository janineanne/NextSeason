//
//  NotificationService.swift
//  NextSeason
//

import Foundation
import UIKit
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

    private static let deferredPromptKey = "notificationPromptDeferred"

    #if DEBUG
    static func resetDeferredPromptForTesting() {
        UserDefaults.standard.removeObject(forKey: deferredPromptKey)
    }
    #endif

    /// True when the user has never been asked and has not deferred the in-app prompt.
    func needsAuthorizationPrompt() async -> Bool {
        guard !UITestingConfiguration.isEnabled else { return false }
        guard !UserDefaults.standard.bool(forKey: Self.deferredPromptKey) else { return false }
        return await authorizationStatus() == .notDetermined
    }

    /// Records that the user dismissed the in-app permission prompt without deciding.
    func deferAuthorizationPrompt() {
        UserDefaults.standard.set(true, forKey: Self.deferredPromptKey)
    }

    /// True when the user previously denied notification permission.
    func isDenied() async -> Bool {
        guard !UITestingConfiguration.isEnabled else { return false }
        return await authorizationStatus() == .denied
    }

    func openNotificationSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    /// Requests permission once; returns whether alerts are allowed.
    @discardableResult
    func requestAuthorizationIfNeeded() async -> Bool {
        let status = await authorizationStatus()
        if NotificationAuthorizationPolicy.canDeliverAlerts(status) { return true }
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
        await scheduleNotification(content, requestIdentifier: nil, trigger: nil)
    }

    func deliver(_ content: SeasonNotificationContent, requestIdentifier: String) async {
        await scheduleNotification(content, requestIdentifier: requestIdentifier, trigger: nil)
    }

    #if DEBUG
    /// Debug helper: schedules delivery with the system so the notification can arrive
    /// after the app is backgrounded or terminated.
    func deliverAfterDelay(
        _ content: SeasonNotificationContent,
        requestIdentifier: String,
        delay interval: TimeInterval
    ) async {
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, interval),
            repeats: false
        )
        await scheduleNotification(content, requestIdentifier: requestIdentifier, trigger: trigger)
    }
    #endif

    private func scheduleNotification(
        _ content: SeasonNotificationContent,
        requestIdentifier: String?,
        trigger: UNNotificationTrigger?
    ) async {
        let settings = await center.notificationSettings()
        guard NotificationAuthorizationPolicy.canDeliverAlerts(settings.authorizationStatus) else { return }

        let notification = UNMutableNotificationContent()
        notification.title = content.title
        notification.body = content.body
        notification.sound = .default
        notification.userInfo = ["showID": content.showID]

        let identifier = requestIdentifier
            ?? "show-\(content.showID)-\(StatusChangeDetector.signature(for: content.status))"
        let request = UNNotificationRequest(
            identifier: identifier,
            content: notification,
            trigger: trigger
        )

        do {
            try await center.add(request)
        } catch {
            #if DEBUG
            assertionFailure("Failed to schedule notification: \(error)")
            #endif
        }
    }
}
