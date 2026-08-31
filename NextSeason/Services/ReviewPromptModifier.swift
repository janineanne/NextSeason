//
//  ReviewPromptModifier.swift
//  NextSeason
//

import StoreKit
import SwiftUI

/// Calls `RequestReviewAction` a few seconds after the first show notification
/// of this version once the scene is active. That covers background delivery
/// the user never taps. StoreKit decides whether to show the system prompt.
struct ReviewPromptModifier: ViewModifier {
    @Environment(\.requestReview) private var requestReview
    @Environment(\.scenePhase) private var scenePhase
    @Bindable var coordinator: ReviewPromptCoordinator

    func body(content: Content) -> some View {
        content.task(id: taskID) {
            guard !UITestingConfiguration.isEnabled else { return }
            guard scenePhase == .active else { return }
            if await coordinator.prepareReviewRequestIfEligible() {
                requestReview()
            }
        }
    }

    /// `-1` while inactive cancels an in-flight delay. Incrementing
    /// `deliveryGeneration` while active restarts the wait.
    private var taskID: Int {
        scenePhase == .active ? coordinator.deliveryGeneration : -1
    }
}

extension View {
    /// Attaches the review prompt flow to a root view. Skipped under UI testing.
    func requestReviewAfterShowNotification(
        coordinator: ReviewPromptCoordinator
    ) -> some View {
        modifier(ReviewPromptModifier(coordinator: coordinator))
    }
}
