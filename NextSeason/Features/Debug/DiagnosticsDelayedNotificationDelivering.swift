//
//  DiagnosticsDelayedNotificationDelivering.swift
//  NextSeason
//

import Foundation

/// Routes pipeline notifications through `deliverAfterDelay` so testers can
/// background the app before the alert arrives.
@MainActor
final class DiagnosticsDelayedNotificationDelivering: NotificationDelivering {
    private let service: NotificationService
    private let delay: TimeInterval

    init(service: NotificationService, delay: TimeInterval) {
        self.service = service
        self.delay = delay
    }

    func deliver(_ content: SeasonNotificationContent) async {
        let identifier = "debug-pipeline-\(content.showID)-\(UUID().uuidString)"
        await service.deliverAfterDelay(content, requestIdentifier: identifier, delay: delay)
    }
}
