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

    /// True when the user has never been asked for notification permission.
    func needsAuthorizationPrompt() async -> Bool {
        guard !UITestingConfiguration.isEnabled else { return false }
        return await authorizationStatus() == .notDetermined
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
    /// Debug helper: waits, then delivers immediately. Uses a background task so the wait
    /// can finish after the app is backgrounded.
    func deliverAfterDelay(
        _ content: SeasonNotificationContent,
        requestIdentifier: String,
        delay interval: TimeInterval
    ) async {
        let settings = await center.notificationSettings()
        guard NotificationAuthorizationPolicy.canDeliverAlerts(settings.authorizationStatus) else { return }

        let backgroundTask = BackgroundTaskHandle(name: "NextSeason.testNotification")
        defer { backgroundTask.end() }

        do {
            try await Task.sleep(for: .seconds(max(1, interval)))
        } catch {
            return
        }

        await scheduleNotification(content, requestIdentifier: requestIdentifier, trigger: nil)
    }

    @MainActor
    private final class BackgroundTaskHandle {
        private var id: UIBackgroundTaskIdentifier = .invalid

        init(name: String) {
            id = UIApplication.shared.beginBackgroundTask(withName: name) { [weak self] in
                Task { @MainActor in
                    self?.end()
                }
            }
        }

        func end() {
            guard id != .invalid else { return }
            UIApplication.shared.endBackgroundTask(id)
            id = .invalid
        }
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
