//
//  StatusChangeDetectorTests.swift
//  NextSeasonTests
//

import Foundation
import Testing
@testable import NextSeason

struct StatusChangeDetectorTests {
    private let now = TVMazeDate.dateOnly("2026-06-14")!
    private let premiere = TVMazeDate.dateOnly("2026-09-01")!
    private let laterPremiere = TVMazeDate.dateOnly("2026-10-01")!

    private func tracked(
        nextSeason: NextSeasonStatus,
        pendingChangeSignature: String? = nil,
        lastNotifiedSignature: String? = nil
    ) -> TrackedShow {
        TrackedShow(
            id: 1,
            name: "Test Show",
            posterMediumURL: nil,
            status: .running,
            nextSeason: nextSeason,
            sourceUpdatedAt: .distantPast,
            lastCheckedAt: .distantPast,
            lastNotifiedSignature: lastNotifiedSignature,
            pendingChangeSignature: pendingChangeSignature,
            dateAdded: .distantPast
        )
    }

    @Test("A premiere date notifies immediately without waiting for a second poll")
    func dateBackedChangeNotifiesImmediately() {
        let show = tracked(nextSeason: .announcedUndated(season: 2))
        let evaluation = StatusChangeDetector.evaluate(
            tracked: show,
            newStatus: .scheduled(season: 2, premiere: premiere),
            now: now
        )

        #expect(evaluation.notification != nil)
        #expect(evaluation.tracked.lastNotifiedSignature == StatusChangeDetector.signature(for: .scheduled(season: 2, premiere: premiere)))
        #expect(evaluation.tracked.pendingChangeSignature == nil)
    }

    @Test("A non-date-backed change waits for a confirming poll")
    func ambiguousChangeDebouncesUntilSecondPoll() {
        let show = tracked(nextSeason: .returningNoSeasonYet)
        let first = StatusChangeDetector.evaluate(
            tracked: show,
            newStatus: .announcedUndated(season: 2),
            now: now
        )

        #expect(first.notification == nil)
        #expect(first.tracked.pendingChangeSignature == StatusChangeDetector.signature(for: .announcedUndated(season: 2)))

        let second = StatusChangeDetector.evaluate(
            tracked: first.tracked,
            newStatus: .announcedUndated(season: 2),
            now: now
        )

        #expect(second.notification != nil)
        #expect(second.tracked.pendingChangeSignature == nil)
    }

    @Test("The same transition is never notified twice")
    func duplicateTransitionIsSuppressed() {
        var show = tracked(nextSeason: .announcedUndated(season: 2))
        show.lastNotifiedSignature = StatusChangeDetector.signature(for: .scheduled(season: 2, premiere: premiere))

        let evaluation = StatusChangeDetector.evaluate(
            tracked: show,
            newStatus: .scheduled(season: 2, premiere: premiere),
            now: now
        )

        #expect(evaluation.notification == nil)
    }

    @Test("A changed premiere date is a meaningful, immediately notifiable update")
    func scheduledDateChangeNotifiesImmediately() {
        let show = tracked(nextSeason: .scheduled(season: 2, premiere: premiere))
        let evaluation = StatusChangeDetector.evaluate(
            tracked: show,
            newStatus: .scheduled(season: 2, premiere: laterPremiere),
            now: now
        )

        #expect(evaluation.notification != nil)
        #expect(evaluation.tracked.lastNotifiedSignature == StatusChangeDetector.signature(for: .scheduled(season: 2, premiere: laterPremiere)))
    }

    @Test("Transition to airing notifies immediately")
    func airingTransitionNotifiesImmediately() {
        let show = tracked(nextSeason: .scheduled(season: 2, premiere: premiere))
        let evaluation = StatusChangeDetector.evaluate(
            tracked: show,
            newStatus: .airing(season: 2),
            now: now
        )

        #expect(evaluation.notification != nil)
        #expect(evaluation.notification?.status == .airing(season: 2))
    }

    @Test("Transition to ended debounces until a second poll confirms it")
    func endedTransitionDebouncesUntilConfirmed() {
        let show = tracked(nextSeason: .returningNoSeasonYet)
        let first = StatusChangeDetector.evaluate(
            tracked: show,
            newStatus: .ended,
            now: now
        )

        #expect(first.notification == nil)
        #expect(first.tracked.pendingChangeSignature == StatusChangeDetector.signature(for: .ended))

        let second = StatusChangeDetector.evaluate(
            tracked: first.tracked,
            newStatus: .ended,
            now: now
        )

        #expect(second.notification != nil)
        #expect(second.notification?.status == .ended)
    }

    @Test("A transient edit that reverts before confirmation clears the pending signature")
    func flappingChangeClearsPendingWithoutNotifying() {
        let show = tracked(nextSeason: .returningNoSeasonYet)
        let first = StatusChangeDetector.evaluate(
            tracked: show,
            newStatus: .announcedUndated(season: 2),
            now: now
        )
        #expect(first.tracked.pendingChangeSignature != nil)

        let reverted = StatusChangeDetector.evaluate(
            tracked: first.tracked,
            newStatus: .returningNoSeasonYet,
            now: now
        )

        #expect(reverted.notification == nil)
        #expect(reverted.tracked.pendingChangeSignature == nil)
    }

    @Test("Cosmetic status churn that is not a meaningful delta does not notify")
    func nonMeaningfulChangeDoesNotNotify() {
        let show = tracked(nextSeason: .unknown)
        let evaluation = StatusChangeDetector.evaluate(
            tracked: show,
            newStatus: .returningNoSeasonYet,
            now: now
        )

        #expect(evaluation.notification == nil)
        #expect(evaluation.tracked.pendingChangeSignature == nil)
    }
}
