//
//  ReviewPromptModifier.swift
//  NextSeason
//

import StoreKit
import SwiftUI

/// Calls `RequestReviewAction` a few seconds after the first show notification
/// of this version, while the scene is active. StoreKit decides whether to show
/// the system prompt.
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
    func requestReviewAfterShowNotification(
        coordinator: ReviewPromptCoordinator
    ) -> some View {
        modifier(ReviewPromptModifier(coordinator: coordinator))
    }
}
