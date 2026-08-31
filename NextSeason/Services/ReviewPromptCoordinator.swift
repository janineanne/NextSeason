//
//  ReviewPromptCoordinator.swift
//  NextSeason
//

import Foundation

/// Decides when StoreKit's `RequestReviewAction` may be called.
///
/// Eligible after the first production show notification of the current
/// marketing version is accepted by the system (including background local
/// delivery). Foreground banners and taps remain a fallback. The SwiftUI
/// modifier then waits `promptDelay` so the user is active before asking.
@MainActor
@Observable
final class ReviewPromptCoordinator {
    /// Matches Apple's sample: a brief pause after the meaningful moment.
    static let promptDelay: Duration = .seconds(2)

    private let store: ReviewPromptStore
    private let sleep: (Duration) async throws -> Void

    /// Bumped when a newly eligible delivery arrives so the view task restarts.
    private(set) var deliveryGeneration = 0

    /// - Parameter sleep: Injectable delay for tests; defaults to `Task.sleep(for:)`.
    init(
        userDefaults: UserDefaults = .standard,
        marketingVersion: String = AppVersionInfo.marketingVersion,
        sleep: @escaping (Duration) async throws -> Void = { try await Task.sleep(for: $0) }
    ) {
        self.store = ReviewPromptStore(
            defaults: userDefaults,
            marketingVersion: marketingVersion
        )
        self.sleep = sleep
    }

    var isEligibleToRequest: Bool { store.isEligibleToRequest }

    /// Call when a production show notification is scheduled, presented, or opened.
    func noteShowNotificationDelivered() {
        store.markNotificationReceived()
        guard store.isEligibleToRequest else { return }
        deliveryGeneration += 1
    }

    /// Waits the prompt delay, then records the attempt if still eligible.
    /// Returns `true` when the view should call `RequestReviewAction`.
    func prepareReviewRequestIfEligible() async -> Bool {
        guard store.isEligibleToRequest else { return false }
        do {
            try await sleep(Self.promptDelay)
        } catch {
            return false
        }
        guard Task.isCancelled == false else { return false }
        guard store.isEligibleToRequest else { return false }
        store.markRequested()
        return true
    }
}
