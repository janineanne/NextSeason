//
//  WatchlistTrackingTests.swift
//  NextSeasonTests
//

import CoreGraphics
import Foundation
import Testing
import UserNotifications
@testable import NextSeason

@MainActor
struct WatchlistTrackingTests {
    private var sampleShow: Show {
        Show(
            id: 44933,
            name: "Severance",
            tvMazeURL: nil,
            summaryHTML: nil,
            posterMediumURL: nil,
            posterOriginalURL: nil,
            status: .running,
            premiered: nil,
            ended: nil,
            network: nil,
            genres: [],
            averageRuntime: nil,
            seasons: [],
            nextEpisode: nil,
            updatedAt: .now
        )
    }

    private func makeNotificationService(analytics: any AnalyticsTracking) -> NotificationService {
        let suiteName = "WatchlistTrackingTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return NotificationService(
            userDefaults: defaults,
            authorizationStatusForTesting: .denied,
            analytics: analytics
        )
    }

    @Test("Toggle with a missing undo coordinator returns ignored without mutating persistence")
    func toggleWithoutCoordinatorReturnsIgnored() async throws {
        let repository = InMemoryWatchlistRepository()
        let analytics = RecordingAnalyticsService()
        try await repository.add(sampleShow)

        let outcome = try await WatchlistTracking.toggle(
            sampleShow,
            isTracked: true,
            anchor: .zero,
            source: .search,
            repository: repository,
            undoRemoval: nil,
            analytics: analytics,
            notifications: makeNotificationService(analytics: analytics),
            prompt: WatchlistNotificationPromptState()
        )

        #expect(outcome == .ignored)
        #expect(try await repository.contains(showID: sampleShow.id))
        #expect(analytics.events.isEmpty)
    }

    @Test("A second quick tap while removal is pending undoes that removal")
    func secondTapUndoesPendingRemoval() async throws {
        let repository = InMemoryWatchlistRepository()
        let analytics = RecordingAnalyticsService()
        let undoRemoval = WatchlistUndoRemoval(repository: repository, analytics: analytics)
        let notifications = makeNotificationService(analytics: analytics)
        let prompt = WatchlistNotificationPromptState()
        try await repository.add(sampleShow)

        let first = try await WatchlistTracking.toggle(
            sampleShow,
            isTracked: true,
            anchor: .zero,
            source: .detail,
            repository: repository,
            undoRemoval: undoRemoval,
            analytics: analytics,
            notifications: notifications,
            prompt: prompt
        )
        #expect(first == .removalRequested)
        #expect(undoRemoval.pendingRemoval?.id == sampleShow.id)
        #expect(try await repository.contains(showID: sampleShow.id))

        let second = try await WatchlistTracking.toggle(
            sampleShow,
            isTracked: false,
            anchor: .zero,
            source: .detail,
            repository: repository,
            undoRemoval: undoRemoval,
            analytics: analytics,
            notifications: notifications,
            prompt: prompt
        )

        #expect(second == .undidPendingRemoval)
        #expect(undoRemoval.pendingRemoval == nil)
        #expect(try await repository.contains(showID: sampleShow.id))
    }
}
