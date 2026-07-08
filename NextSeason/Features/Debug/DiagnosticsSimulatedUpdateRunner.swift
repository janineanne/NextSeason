//
//  DiagnosticsSimulatedUpdateRunner.swift
//  NextSeason
//

import Foundation

/// Runs a two-step simulated season update through the real watchlist refresh
/// service, without touching the user's normal watchlist repository or TVMaze.
@MainActor
final class DiagnosticsSimulatedUpdateRunner {
    private let dataProvider: DiagnosticsSimulatedDataProvider
    private let repository: SimulatedWatchlistRepository
    private let notificationService: NotificationService
    private let analytics: any AnalyticsTracking
    private let refreshService: WatchlistRefreshService
    private let diagnostics: BetaRefreshDiagnostics
    private let now: @Sendable () -> Date
    private var isSeeded = false

    init(
        dataProvider: DiagnosticsSimulatedDataProvider = DiagnosticsSimulatedDataProvider(),
        notifications: NotificationService,
        diagnostics: BetaRefreshDiagnostics,
        analytics: any AnalyticsTracking,
        now: @escaping @Sendable () -> Date = { .now }
    ) {
        self.dataProvider = dataProvider
        self.repository = SimulatedWatchlistRepository()
        self.notificationService = notifications
        self.analytics = analytics
        self.diagnostics = diagnostics
        self.now = now
        self.refreshService = WatchlistRefreshService(
            tvMaze: dataProvider,
            repository: repository,
            notifications: notifications,
            analytics: analytics,
            diagnostics: diagnostics,
            now: now
        )
    }

    var dataPhaseLabel: String {
        dataProvider.phaseLabel
    }

    func resetScenario() {
        repository.removeAll()
        dataProvider.reset()
        isSeeded = false
    }

    @discardableResult
    func runNextStep() async -> String {
        let betaValidationAvailable = await MainActor.run {
            BetaBuildConfiguration.isAvailable
        }
        guard betaValidationAvailable else {
            return "Simulated scenarios are unavailable in production builds."
        }

        if !isSeeded {
            repository.seed(makeInitialTracked(at: now()))
            isSeeded = true
        }

        let phase = dataProvider.currentPhase
        let outcome = await refreshService.refreshAll(force: true)

        let tracked = repository.show(id: DiagnosticsSimulatedData.showID)
        let statusSummary = tracked?.nextSeason.headlineSummary ?? "No simulated show found"
        let notificationDecision = outcome?.notificationDecision ?? "Refresh did not complete"
        let summary = "Step \(phase.stepNumber) (\(phase.shortLabel)): \(statusSummary). \(notificationDecision)"

        diagnostics.recordSimulatedScenarioSummary(summary)
        dataProvider.advanceAfterRun()

        if phase == .updated {
            resetScenario()
        }

        return summary
    }

    /// Seeds fake data with a dated new season, runs the real refresh + notification
    /// decision path, and schedules delivery after a short delay for background testing.
    @discardableResult
    func runDelayedNewSeasonNotification(
        delayRange: ClosedRange<TimeInterval> = 5 ... 10
    ) async -> String {
        let betaValidationAvailable = await MainActor.run {
            BetaBuildConfiguration.isAvailable
        }
        guard betaValidationAvailable else {
            return "Delayed pipeline tests are unavailable in production builds."
        }

        resetScenario()
        repository.seed(makeInitialTracked(at: now()))
        dataProvider.forcePhase(.updated)
        isSeeded = true

        let delay = TimeInterval.random(in: delayRange)
        let delayedNotifications = DiagnosticsDelayedNotificationDelivering(
            service: notificationService,
            delay: delay
        )
        let pipelineRefresh = WatchlistRefreshService(
            tvMaze: dataProvider,
            repository: repository,
            notifications: delayedNotifications,
            analytics: analytics,
            diagnostics: diagnostics,
            now: now
        )

        let outcome = await pipelineRefresh.refreshAll(force: true)

        let tracked = repository.show(id: DiagnosticsSimulatedData.showID)
        let statusSummary = tracked?.nextSeason.headlineSummary ?? "No simulated show found"
        let notificationDecision = outcome?.notificationDecision ?? "Refresh did not complete"
        let delaySeconds = Int(delay.rounded())
        let summary =
            "Delayed pipeline (\(delaySeconds)s): \(statusSummary). \(notificationDecision)"

        diagnostics.recordSimulatedScenarioSummary(summary)
        resetScenario()

        return summary
    }

    private func makeInitialTracked(at date: Date) -> TrackedShow {
        TrackedShow(
            id: DiagnosticsSimulatedData.showID,
            name: DiagnosticsSimulatedData.showName,
            posterMediumURL: nil,
            summaryHTML: "<p>Beta diagnostics / simulated show. This is fake data for TestFlight validation only.</p>",
            tvMazeURL: nil,
            status: .running,
            nextSeason: .returningNoSeasonYet,
            sourceUpdatedAt: date.addingTimeInterval(-86_400),
            lastCheckedAt: date.addingTimeInterval(-86_400),
            dateAdded: date
        )
    }
}

@MainActor
private final class SimulatedWatchlistRepository: WatchlistRepository {
    private var shows: [Int: TrackedShow] = [:]

    func seed(_ tracked: TrackedShow) {
        shows[tracked.id] = tracked
    }

    func show(id: Int) -> TrackedShow? {
        shows[id]
    }

    func removeAll() {
        shows.removeAll()
    }

    func all() async throws -> [TrackedShow] {
        shows.values.sorted { $0.dateAdded > $1.dateAdded }
    }

    func trackedShow(showID: Int) async throws -> TrackedShow? {
        shows[showID]
    }

    func trackedShowIDs() async throws -> Set<Int> {
        Set(shows.keys)
    }

    func contains(showID: Int) async throws -> Bool {
        shows[showID] != nil
    }

    func add(_ show: Show) async throws {
        guard shows[show.id] == nil else { return }
        shows[show.id] = TrackedShow(from: show)
    }

    func remove(showID: Int) async throws {
        shows.removeValue(forKey: showID)
    }

    func updateAfterRefresh(_ tracked: TrackedShow) async throws {
        shows[tracked.id] = tracked
    }
}

private extension DiagnosticsSimulatedDataProvider.Phase {
    var stepNumber: String {
        switch self {
        case .baseline: "1"
        case .updated: "2"
        }
    }

    var shortLabel: String {
        switch self {
        case .baseline: "baseline fake data"
        case .updated: "updated fake data"
        }
    }
}

private extension NextSeasonStatus {
    var headlineSummary: String {
        switch self {
        case .airing(let season):
            "Season \(season) airing"
        case .scheduled(let season, let premiere):
            "Season \(season) premieres \(premiere.formatted(date: .abbreviated, time: .omitted))"
        case .announcedUndated(let season):
            "Season \(season) announced without a date"
        case .returningNoSeasonYet:
            "Returning, no season announced yet"
        case .ended:
            "Ended"
        case .unknown:
            "Unknown"
        }
    }
}
