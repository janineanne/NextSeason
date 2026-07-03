//
//  DiagnosticsSimulatedDataProvider.swift
//  NextSeason
//

import Foundation

/// Reserved show identity for beta-only simulated update scenarios.
/// Never written to the real watchlist repository.
nonisolated enum DiagnosticsSimulatedData {
    static let showID = 777_777
    static let showName = "Beta diagnostics / simulated"
}

/// Fake TVMaze data for beta validation. Returns baseline season data on the first
/// fetch, then a newer dated season on the second fetch.
final class DiagnosticsSimulatedDataProvider: TVMazeService, @unchecked Sendable {
    enum Phase: Sendable {
        case baseline
        case updated
    }

    private let lock = NSLock()
    private nonisolated(unsafe) var phase: Phase = .baseline
    private let now: @Sendable () -> Date

    init(now: @escaping @Sendable () -> Date = { .now }) {
        self.now = now
    }

    var currentPhase: Phase {
        lock.lock()
        defer { lock.unlock() }
        return phase
    }

    var phaseLabel: String {
        switch currentPhase {
        case .baseline:
            "Baseline (undated next season)"
        case .updated:
            "Updated (dated next season)"
        }
    }

    func reset() {
        lock.lock()
        phase = .baseline
        lock.unlock()
    }

    func forcePhase(_ newPhase: Phase) {
        lock.lock()
        phase = newPhase
        lock.unlock()
    }

    func advanceAfterRun() {
        lock.lock()
        phase = phase == .baseline ? .updated : .baseline
        lock.unlock()
    }

    func searchShows(matching query: String) async throws -> [Show] { [] }

    func show(id: Int, bypassCache: Bool) async throws -> Show {
        guard id == DiagnosticsSimulatedData.showID else {
            throw TVMazeError.notFound
        }
        return makeShow(for: currentPhase)
    }

    func updatedShows(since period: TVMazeUpdatePeriod) async throws -> [Int: Date] {
        [DiagnosticsSimulatedData.showID: now()]
    }

    private func makeShow(for phase: Phase) -> Show {
        let referenceDate = now()
        let airedSeasons = [
            Season(
                id: 1,
                number: 1,
                premiereDate: TVMazeDate.dateOnly("2024-01-10"),
                endDate: TVMazeDate.dateOnly("2024-03-10"),
                episodeOrder: 8
            ),
            Season(
                id: 2,
                number: 2,
                premiereDate: TVMazeDate.dateOnly("2025-01-10"),
                endDate: TVMazeDate.dateOnly("2025-03-10"),
                episodeOrder: 8
            )
        ]

        let upcomingSeason: Season
        switch phase {
        case .baseline:
            upcomingSeason = Season(
                id: 3,
                number: 3,
                premiereDate: nil,
                endDate: nil,
                episodeOrder: nil
            )
        case .updated:
            let premiere = Calendar.current.date(byAdding: .month, value: 2, to: referenceDate)
                ?? referenceDate.addingTimeInterval(60 * 60 * 24 * 60)
            upcomingSeason = Season(
                id: 3,
                number: 3,
                premiereDate: premiere,
                endDate: nil,
                episodeOrder: 10
            )
        }

        return Show(
            id: DiagnosticsSimulatedData.showID,
            name: DiagnosticsSimulatedData.showName,
            tvMazeURL: nil,
            summaryHTML: "<p>Simulated show for TestFlight beta validation only.</p>",
            posterMediumURL: nil,
            posterOriginalURL: nil,
            status: .running,
            premiered: TVMazeDate.dateOnly("2024-01-10"),
            ended: nil,
            network: "Beta diagnostics",
            genres: ["Diagnostics"],
            averageRuntime: 45,
            seasons: airedSeasons + [upcomingSeason],
            nextEpisode: nil,
            updatedAt: referenceDate
        )
    }
}
