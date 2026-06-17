//
//  NotificationAuthorizationPolicyTests.swift
//  NextSeasonTests
//

import Testing
import UserNotifications
@testable import NextSeason

struct NotificationAuthorizationPolicyTests {
    @Test("Authorized, provisional, and ephemeral statuses can deliver alerts")
    func allowedStatuses() {
        #expect(NotificationAuthorizationPolicy.canDeliverAlerts(.authorized))
        #expect(NotificationAuthorizationPolicy.canDeliverAlerts(.provisional))
        #expect(NotificationAuthorizationPolicy.canDeliverAlerts(.ephemeral))
    }

    @Test("Undetermined and denied statuses cannot deliver alerts")
    func blockedStatuses() {
        #expect(NotificationAuthorizationPolicy.canDeliverAlerts(.notDetermined) == false)
        #expect(NotificationAuthorizationPolicy.canDeliverAlerts(.denied) == false)
    }
}
