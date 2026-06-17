//
//  NotificationService+Environment.swift
//  NextSeason
//

import SwiftUI

private struct NotificationServiceKey: EnvironmentKey {
    @MainActor static let defaultValue = NotificationService()
}

extension EnvironmentValues {
    @MainActor var notificationService: NotificationService {
        get { self[NotificationServiceKey.self] }
        set { self[NotificationServiceKey.self] = newValue }
    }
}
