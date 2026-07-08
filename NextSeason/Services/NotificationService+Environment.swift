//
//  NotificationService+Environment.swift
//  NextSeason
//

import SwiftUI
import UserNotifications

private struct NotificationServiceKey: EnvironmentKey {
    @MainActor static let defaultValue: any NotificationManaging = UnconfiguredNotificationService()
}

extension EnvironmentValues {
    @MainActor var notificationService: any NotificationManaging {
        get { self[NotificationServiceKey.self] }
        set { self[NotificationServiceKey.self] = newValue }
    }
}

@MainActor
private final class UnconfiguredNotificationService: NotificationManaging {
    private func fail() -> Never {
        fatalError("NotificationManaging was not injected. Set it on the root view.")
    }

    func authorizationStatus() async -> UNAuthorizationStatus { fail() }
    func needsAuthorizationPrompt() async -> Bool { fail() }
    func deferAuthorizationPrompt() { fail() }
    func isDenied() async -> Bool { fail() }
    func openNotificationSettings() { fail() }
    @discardableResult
    func requestAuthorizationIfNeeded() async -> Bool { fail() }
    func deliver(_ content: SeasonNotificationContent) async { fail() }
    func deliver(_ content: SeasonNotificationContent, requestIdentifier: String) async { fail() }
    func deliverAfterDelay(
        _ content: SeasonNotificationContent,
        requestIdentifier: String,
        delay: TimeInterval
    ) async {
        fail()
    }
}
