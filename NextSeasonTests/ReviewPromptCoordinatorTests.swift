//
//  ReviewPromptCoordinatorTests.swift
//  NextSeasonTests
//

import Foundation
import Testing

@testable import NextSeason

@MainActor
struct ReviewPromptCoordinatorTests {
    @Test("A show notification makes this version eligible after the delay")
    func firstDeliveryBecomesEligibleAndRequestsOnce() async {
        var slept: Duration?
        let coordinator = makeCoordinator { slept = $0 }

        #expect(coordinator.isEligibleToRequest == false)
        #expect(await coordinator.prepareReviewRequestIfEligible() == false)

        coordinator.noteShowNotificationDelivered()
        #expect(coordinator.isEligibleToRequest)
        #expect(coordinator.deliveryGeneration == 1)

        #expect(await coordinator.prepareReviewRequestIfEligible())
        #expect(slept == ReviewPromptCoordinator.promptDelay)
        #expect(coordinator.isEligibleToRequest == false)
        #expect(await coordinator.prepareReviewRequestIfEligible() == false)
    }

    @Test("A second notification in the same version does not request again")
    func duplicateDeliveryDoesNotReRequest() async {
        let coordinator = makeCoordinator { _ in }
        coordinator.noteShowNotificationDelivered()
        #expect(await coordinator.prepareReviewRequestIfEligible())

        coordinator.noteShowNotificationDelivered()
        #expect(coordinator.deliveryGeneration == 1)
        #expect(await coordinator.prepareReviewRequestIfEligible() == false)
    }

    @Test("Cancelling the delay leaves this version eligible")
    func cancelledDelayDoesNotRecordRequest() async {
        let behavior = SleepBehavior()
        let coordinator = makeCoordinator { _ in
            if behavior.shouldCancel { throw CancellationError() }
        }
        coordinator.noteShowNotificationDelivered()

        #expect(await coordinator.prepareReviewRequestIfEligible() == false)
        #expect(coordinator.isEligibleToRequest)

        behavior.shouldCancel = false
        #expect(await coordinator.prepareReviewRequestIfEligible())
        #expect(coordinator.isEligibleToRequest == false)
    }

    @Test("A new marketing version can request after its own first notification")
    func newVersionRequiresANewNotification() async {
        let defaults = makeDefaults()
        let versionOne = makeCoordinator(userDefaults: defaults, version: "1.0") { _ in }
        versionOne.noteShowNotificationDelivered()
        #expect(await versionOne.prepareReviewRequestIfEligible())

        let versionTwo = makeCoordinator(userDefaults: defaults, version: "1.1") { _ in }
        #expect(versionTwo.isEligibleToRequest == false)

        versionTwo.noteShowNotificationDelivered()
        #expect(await versionTwo.prepareReviewRequestIfEligible())
    }

    private func makeCoordinator(
        userDefaults: UserDefaults? = nil,
        version: String = "1.0",
        sleep: @escaping (Duration) async throws -> Void
    ) -> ReviewPromptCoordinator {
        ReviewPromptCoordinator(
            userDefaults: userDefaults ?? makeDefaults(),
            marketingVersion: version,
            sleep: sleep
        )
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "ReviewPromptCoordinatorTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}

private final class SleepBehavior: @unchecked Sendable {
    var shouldCancel = true
}
