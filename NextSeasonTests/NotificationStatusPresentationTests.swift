//
//  NotificationStatusPresentationTests.swift
//  NextSeasonTests
//

import Testing

@testable import NextSeason

struct NotificationStatusPresentationTests {
    @Test("Status labels and symbols reflect delivery capability")
    func statusLabelsAndSymbols() {
        let enabled = NotificationStatusPresentation(
            canDeliverVisibleAlerts: true,
            isAuthorizationNotDetermined: false
        )
        #expect(enabled.statusLabel == "Enabled")
        #expect(enabled.diagnosticsEnabledLabel == "Yes")
        #expect(enabled.symbolName == "bell.fill")
        #expect(enabled.showsDisabledBanner == false)

        let disabled = NotificationStatusPresentation(
            canDeliverVisibleAlerts: false,
            isAuthorizationNotDetermined: false
        )
        #expect(disabled.statusLabel == "Disabled")
        #expect(disabled.diagnosticsEnabledLabel == "No")
        #expect(disabled.symbolName == "bell.slash")
        #expect(disabled.showsDisabledBanner)
    }

    @Test("Enablement button title depends on whether permission was requested")
    func enablementButtonTitle() {
        #expect(
            NotificationStatusPresentation.enablementButtonTitle(isAuthorizationNotDetermined: true)
                == "Enable Notifications"
        )
        #expect(
            NotificationStatusPresentation.enablementButtonTitle(
                isAuthorizationNotDetermined: false)
                == "Open Settings"
        )
    }
}
