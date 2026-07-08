//
//  NotificationServiceTests.swift
//  NextSeasonTests
//

import Testing
import UserNotifications
@testable import NextSeason

@MainActor
struct NotificationServiceTests {
    private static let suiteName = "NotificationServiceTests"

    private func makeDefaults() -> UserDefaults {
        let defaults = UserDefaults(suiteName: Self.suiteName)!
        defaults.removePersistentDomain(forName: Self.suiteName)
        return defaults
    }

    private func makeService(
        authorizationStatus: UNAuthorizationStatus = .notDetermined
    ) -> NotificationService {
        NotificationService(
            userDefaults: makeDefaults(),
            authorizationStatusForTesting: authorizationStatus,
            analytics: RecordingAnalyticsService()
        )
    }

    @Test("Needs prompt when authorization is undetermined and not deferred")
    func needsPromptWhenUndetermined() async {
        let service = makeService()
        #expect(await service.needsAuthorizationPrompt())
    }

    @Test("Does not need prompt after the user defers")
    func doesNotNeedPromptAfterDefer() async {
        let service = makeService()
        service.deferAuthorizationPrompt()
        #expect(await service.needsAuthorizationPrompt() == false)
    }

    @Test("Does not need prompt when authorization is already granted")
    func doesNotNeedPromptWhenAuthorized() async {
        let service = makeService(authorizationStatus: .authorized)
        #expect(await service.needsAuthorizationPrompt() == false)
    }

    @Test("Does not need prompt when authorization was denied")
    func doesNotNeedPromptWhenDenied() async {
        let service = makeService(authorizationStatus: .denied)
        #expect(await service.needsAuthorizationPrompt() == false)
    }

    @Test("Does not request authorization after the user defers the in-app prompt")
    func doesNotRequestWhenDeferred() async {
        let service = makeService(authorizationStatus: .notDetermined)
        service.deferAuthorizationPrompt()
        #expect(await service.requestAuthorizationIfNeeded() == false)
    }

    @Test("Reset clears a deferred prompt so the prompt can appear again")
    func resetDeferredPromptRestoresPromptEligibility() async {
        let service = makeService()
        service.deferAuthorizationPrompt()
        #expect(await service.needsAuthorizationPrompt() == false)

        service.resetDeferredPromptForTesting()
        #expect(await service.needsAuthorizationPrompt())
    }
}
