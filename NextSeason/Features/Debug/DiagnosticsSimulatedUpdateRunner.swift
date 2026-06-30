//
//  DiagnosticsSimulatedUpdateRunner.swift
//  NextSeason
//

import Foundation

/// Runs a two-step simulated season update through the same detection and
/// notification path as real refreshes, without touching user watchlist data.
@MainActor
final class DiagnosticsSimulatedUpdateRunner {
    private let dataProvider: DiagnosticsSimulatedDataProvider
    private let notifications: any NotificationDelivering
    private let diagnostics: BetaRefreshDiagnostics
    private let now: @Sendable () -> Date
    private var tracked: TrackedShow?

    init(
        dataProvider: DiagnosticsSimulatedDataProvider = DiagnosticsSimulatedDataProvider(),
        notifications: any NotificationDelivering,
        diagnostics: BetaRefreshDiagnostics,
        now: @escaping @Sendable () -> Date = { .now }
    ) {
        self.dataProvider = dataProvider
        self.notifications = notifications
        self.diagnostics = diagnostics
        self.now = now
    }

    var dataPhaseLabel: String {
        dataProvider.phaseLabel
    }

    func resetScenario() {
        tracked = nil
        dataProvider.reset()
    }

    @discardableResult
    func runNextStep() async -> String {
        guard BetaBuildConfiguration.isAvailable else {
            return "Simulated scenarios are unavailable in production builds."
        }

        let referenceDate = now()
        if tracked == nil {
            tracked = makeInitialTracked(at: referenceDate)
        }

        guard var currentTracked = tracked else {
            return "Failed to initialize simulated tracked show."
        }

        let phase = dataProvider.currentPhase
        let show: Show
        do {
            show = try await dataProvider.show(
                id: DiagnosticsSimulatedData.showID,
                bypassCache: true
            )
        } catch {
            let message = "Simulated fetch failed: \(error.localizedDescription)"
            diagnostics.recordSimulatedScenario(message)
            return message
        }

        let previousStatus = currentTracked.nextSeason
        let newStatus = NextSeasonCalculator.status(for: show, now: referenceDate)
        let evaluation = StatusChangeDetector.evaluate(
            tracked: currentTracked,
            newStatus: newStatus,
            now: referenceDate
        )
        currentTracked = evaluation.tracked
        tracked = currentTracked

        let decision = describeDecision(
            previousStatus: previousStatus,
            evaluation: evaluation,
            phase: phase
        )

        if let notification = evaluation.notification {
            let labeled = SeasonNotificationContent(
                showID: notification.showID,
                showName: notification.showName,
                status: notification.status
            )
            await notifications.deliver(labeled)
        }

        dataProvider.advanceAfterRun()
        if phase == .updated {
            tracked = nil
        }

        let stepLabel = phase == .baseline
            ? "Baseline (undated next season)"
            : "Updated (dated next season)"
        let summary = """
        Step \(phase == .baseline ? "1" : "2") (\(stepLabel)): \
        \(decision)
        """
        diagnostics.recordSimulatedScenario(summary)
        return summary
    }

    private func makeInitialTracked(at date: Date) -> TrackedShow {
        TrackedShow(
            id: DiagnosticsSimulatedData.showID,
            name: DiagnosticsSimulatedData.showName,
            posterMediumURL: nil,
            summaryHTML: "<p>Simulated show for TestFlight beta validation only.</p>",
            tvMazeURL: nil,
            status: .running,
            nextSeason: .returningNoSeasonYet,
            sourceUpdatedAt: date.addingTimeInterval(-86_400),
            lastCheckedAt: date.addingTimeInterval(-86_400),
            dateAdded: date
        )
    }

    private func describeDecision(
        previousStatus: NextSeasonStatus,
        evaluation: StatusChangeDetector.Evaluation,
        phase: DiagnosticsSimulatedDataProvider.Phase
    ) -> String {
        let newStatus = evaluation.tracked.nextSeason
        if let notification = evaluation.notification {
            return "Notification delivered — \(notification.body)"
        }
        if evaluation.tracked.pendingChangeSignature != nil {
            return """
            Pending debounce (\(phase == .baseline ? "first poll" : "confirming")) — \
            \(previousStatus.headlineSummary) → \(newStatus.headlineSummary)
            """
        }
        return "No notification — \(previousStatus.headlineSummary) → \(newStatus.headlineSummary)"
    }
}

private extension NextSeasonStatus {
    var headlineSummary: String {
        switch self {
        case .airing(let season):
            "Season \(season) airing"
        case .scheduled(let season, let premiere):
            "Season \(season) on \(premiere.formatted(date: .abbreviated, time: .omitted))"
        case .announcedUndated(let season):
            "Season \(season) announced (undated)"
        case .returningNoSeasonYet:
            "Returning, no season yet"
        case .ended:
            "Ended"
        case .unknown:
            "Unknown"
        }
    }
}
