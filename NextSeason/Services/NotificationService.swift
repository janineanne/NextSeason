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

/// Permission prompts, settings, and delivery used by SwiftUI and view models.
@MainActor
protocol NotificationManaging: NotificationDelivering {
    func authorizationStatus() async -> UNAuthorizationStatus
    func needsAuthorizationPrompt() async -> Bool
    func deferAuthorizationPrompt()
    func isDenied() async -> Bool
    func canDeliverVisibleAlerts() async -> Bool
    func openNotificationSettings()
    /// Shows the system permission dialog when still `.notDetermined`; otherwise opens Settings.
    func enableNotificationsFromSettingsEntryPoint() async
    @discardableResult
    func requestAuthorizationIfNeeded() async -> Bool
    func deliver(_ content: SeasonNotificationContent, requestIdentifier: String) async
    func deliverAfterDelay(
        _ content: SeasonNotificationContent,
        requestIdentifier: String,
        delay: TimeInterval
    ) async
}

/// Wraps local notification permission and delivery (FR-011, FR-012).
@MainActor
final class NotificationService: NotificationManaging {
    private let center: UNUserNotificationCenter
    private let userDefaults: UserDefaults
    private let analytics: any AnalyticsTracking
    #if DEBUG
    private let authorizationStatusForTesting: UNAuthorizationStatus?
    #endif

    init(
        center: UNUserNotificationCenter = .current(),
        userDefaults: UserDefaults = .standard,
        analytics: any AnalyticsTracking
    ) {
        self.center = center
        self.userDefaults = userDefaults
        self.analytics = analytics
        #if DEBUG
        self.authorizationStatusForTesting = nil
        #endif
    }

    #if DEBUG
    init(
        userDefaults: UserDefaults,
        authorizationStatusForTesting: UNAuthorizationStatus,
        analytics: any AnalyticsTracking
    ) {
        self.center = .current()
        self.userDefaults = userDefaults
        self.authorizationStatusForTesting = authorizationStatusForTesting
        self.analytics = analytics
    }

    func resetDeferredPromptForTesting() {
        userDefaults.removeObject(forKey: Self.deferredPromptKey)
    }
    #endif

    func authorizationStatus() async -> UNAuthorizationStatus {
        #if DEBUG
        if let authorizationStatusForTesting {
            return authorizationStatusForTesting
        }
        #endif
        return await center.notificationSettings().authorizationStatus
    }

    private static let deferredPromptKey = "notificationPromptDeferred"

    /// True when the user has never been asked and has not deferred the in-app prompt.
    func needsAuthorizationPrompt() async -> Bool {
        guard !UITestingConfiguration.isEnabled else { return false }
        guard !userDefaults.bool(forKey: Self.deferredPromptKey) else { return false }
        return await authorizationStatus() == .notDetermined
    }

    /// Records that the user dismissed the in-app permission prompt without deciding.
    func deferAuthorizationPrompt() {
        userDefaults.set(true, forKey: Self.deferredPromptKey)
    }

    /// True when the user previously denied notification permission.
    func isDenied() async -> Bool {
        guard !UITestingConfiguration.isEnabled else { return false }
        return await authorizationStatus() == .denied
    }

    /// True when alert banners can be shown (permission granted and alerts enabled).
    func canDeliverVisibleAlerts() async -> Bool {
        guard !UITestingConfiguration.isEnabled else { return false }
        #if DEBUG
        if let authorizationStatusForTesting {
            return NotificationAuthorizationPolicy.canDeliverAlerts(authorizationStatusForTesting)
        }
        #endif
        let settings = await center.notificationSettings()
        return NotificationAuthorizationPolicy.canDeliverAlerts(from: settings)
    }

    func openNotificationSettings() {
        // The general app settings page does not expose the notifications toggle
        // after the user taps "Don't Allow". iOS 16+ provides a dedicated deep link.
        if let url = URL(string: UIApplication.openNotificationSettingsURLString),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
            return
        }
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    /// Entry point for Watchlist banner, About, and post-deny alerts.
    /// If permission was never requested (including after "Not Now"), shows the system dialog.
    func enableNotificationsFromSettingsEntryPoint() async {
        guard !UITestingConfiguration.isEnabled else { return }
        let status = await authorizationStatus()
        switch status {
        case .notDetermined:
            // Clear a prior "Not Now" deferral so the system prompt can appear.
            userDefaults.removeObject(forKey: Self.deferredPromptKey)
            _ = await requestAuthorizationIfNeeded()
        case .denied, .authorized, .provisional, .ephemeral:
            openNotificationSettings()
        @unknown default:
            openNotificationSettings()
        }
    }

    /// Requests permission once; returns whether alerts are allowed.
    /// No-ops when the user previously dismissed the in-app prompt with "Not Now".
    @discardableResult
    func requestAuthorizationIfNeeded() async -> Bool {
        guard !userDefaults.bool(forKey: Self.deferredPromptKey) else { return false }
        let status = await authorizationStatus()
        if NotificationAuthorizationPolicy.canDeliverAlerts(status) { return true }
        switch status {
        case .denied:
            return false
        case .notDetermined:
            #if DEBUG
            // When tests inject authorization status, never present the system
            // permission dialog — it blocks the unit-test process until dismissed.
            if authorizationStatusForTesting != nil {
                return false
            }
            #endif
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                analytics.track(
                    .notificationPermission(result: granted ? .granted : .denied)
                )
                return granted
            } catch {
                analytics.track(.notificationPermission(result: .denied))
                analytics.trackNonFatalError(error, context: "notification_authorization")
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

    /// Beta diagnostics helper: schedules delivery with the system so the
    /// notification can arrive after the app is backgrounded or terminated.
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

    private func scheduleNotification(
        _ content: SeasonNotificationContent,
        requestIdentifier: String?,
        trigger: UNNotificationTrigger?
    ) async {
        let settings = await center.notificationSettings()
        guard NotificationAuthorizationPolicy.canDeliverAlerts(from: settings) else { return }

        let notification = UNMutableNotificationContent()
        let title = content.title
        let body = content.body
        notification.title = title
        notification.body = body
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
            analytics.track(.notificationReminderScheduled)
        } catch {
            analytics.trackNonFatalError(error, context: "notification_schedule")
            #if DEBUG
            assertionFailure("Failed to schedule notification: \(error)")
            #endif
        }
    }
}
