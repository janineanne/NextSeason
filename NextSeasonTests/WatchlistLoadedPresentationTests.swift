//
//  WatchlistLoadedPresentationTests.swift
//  NextSeasonTests
//

import Testing

@testable import NextSeason

struct WatchlistLoadedPresentationTests {
    @Test("An empty watchlist shows the empty overlay and title spacer")
    func emptyWatchlistShowsEmptyOverlayAndSpacer() {
        let presentation = WatchlistLoadedPresentation(
            hasShows: false,
            hasVisibleRows: false,
            hasPendingRemoval: false,
            showsNotificationBanner: false
        )

        #expect(presentation.overlay == .emptyWatchlist)
        #expect(presentation.showsTitlePreservingSpacer)
        #expect(presentation.showsAttribution == false)
        #expect(presentation.showsNotificationBanner == false)
    }

    @Test("The notification banner suppresses the title-preserving spacer")
    func notificationBannerSuppressesTitleSpacer() {
        let presentation = WatchlistLoadedPresentation(
            hasShows: false,
            hasVisibleRows: false,
            hasPendingRemoval: false,
            showsNotificationBanner: true
        )

        #expect(presentation.overlay == .emptyWatchlist)
        #expect(presentation.showsNotificationBanner)
        #expect(presentation.showsTitlePreservingSpacer == false)
        #expect(presentation.showsAttribution == false)
    }

    @Test("A search miss shows the no-results overlay and title spacer")
    func searchMissShowsNoResultsOverlay() {
        let presentation = WatchlistLoadedPresentation(
            hasShows: true,
            hasVisibleRows: false,
            hasPendingRemoval: false,
            showsNotificationBanner: false
        )

        #expect(presentation.overlay == .noSearchResults)
        #expect(presentation.showsTitlePreservingSpacer)
        #expect(presentation.showsAttribution == false)
    }

    @Test("A populated list shows attribution and no overlay")
    func populatedListShowsAttribution() {
        let presentation = WatchlistLoadedPresentation(
            hasShows: true,
            hasVisibleRows: true,
            hasPendingRemoval: false,
            showsNotificationBanner: true
        )

        #expect(presentation.overlay == .none)
        #expect(presentation.showsAttribution)
        #expect(presentation.showsTitlePreservingSpacer == false)
        #expect(presentation.showsNotificationBanner)
    }

    @Test("An empty list with a pending removal uses the no-results overlay")
    func pendingRemovalOnEmptyListUsesNoResultsOverlay() {
        let presentation = WatchlistLoadedPresentation(
            hasShows: false,
            hasVisibleRows: false,
            hasPendingRemoval: true,
            showsNotificationBanner: false
        )

        #expect(presentation.overlay == .noSearchResults)
        #expect(presentation.showsTitlePreservingSpacer)
        #expect(presentation.showsAttribution == false)
    }
}
