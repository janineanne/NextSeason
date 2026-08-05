//
//  TVMazeService.swift
//  NextSeason
//

import Foundation

/// Abstraction over the TVMaze API so view models can be tested with a mock.
nonisolated protocol TVMazeService: Sendable {
    /// Shows matching a free-text query, best matches first. Empty query → `[]`.
    func searchShows(matching query: String) async throws -> [Show]

    /// Full show info including embedded seasons and next episode.
    func show(id: Int, bypassCache: Bool) async throws -> Show

    /// Show IDs updated since the given window (`GET /updates/shows`).
    func updatedShows(since period: TVMazeUpdatePeriod) async throws -> [Int: Date]
}

/// Query window for `GET /updates/shows` (`?since=day|week|month`).
nonisolated enum TVMazeUpdatePeriod: String, Sendable {
    case day, week, month

    /// Smallest TVMaze update window that still covers every change since
    /// `oldestCheck`. Background refresh is best-effort and may be delayed, so
    /// the window must grow with the polling gap — otherwise a show that changed
    /// just outside a too-small window would be silently skipped.
    ///
    /// Thresholds: ≤1 day → `.day`, ≤1 week → `.week`, otherwise `.month`
    /// (TVMaze's coarsest supported `since` value).
    static func covering(since oldestCheck: Date, at: Date = .now) -> TVMazeUpdatePeriod {
        let elapsed = at.timeIntervalSince(oldestCheck)
        let oneDay: TimeInterval = 86_400
        let oneWeek: TimeInterval = 604_800

        if elapsed <= oneDay { return .day }
        if elapsed <= oneWeek { return .week }
        return .month
    }
}

extension TVMazeService {
    /// Convenience: fetch show detail using the normal cache policy.
    func show(id: Int) async throws -> Show {
        try await show(id: id, bypassCache: false)
    }
}
