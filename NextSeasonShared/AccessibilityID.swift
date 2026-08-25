//
//  AccessibilityID.swift
//  NextSeasonShared
//
//  Compiled into the app and UI test targets so identifier strings stay in sync.
//

import Foundation

/// Launch argument that switches the app to stubbed network data for XCUITest.
enum UITestingLaunchArgument {
    static let uiTesting = "-UITesting"
}

/// Sentinel search queries recognized by the stubbed service during UI testing.
enum UITestingSearchQuery {
    static let noResults = "uitest-no-results"
    static let failure = "uitest-failure"
}

/// Stable accessibility identifiers for UI tests.
enum AccessibilityID {
    enum App {
        static let aboutButton = "app.aboutButton"
    }

    enum PersistenceRecovery {
        /// Blocking launch recovery screen (`PersistenceRecoveryView`).
        static let screen = "persistenceRecovery.screen"
        static let exportDiagnostics = "persistenceRecovery.exportDiagnostics"
        static let resetLocalData = "persistenceRecovery.resetLocalData"
        static let tryAgain = "persistenceRecovery.tryAgain"
    }

    enum Tab {
        static let search = "tab.search"
        static let watchlist = "tab.watchlist"
    }

    enum Search {
        static let idlePrompt = "search.idlePrompt"
        static let tryExampleButton = "search.tryExample"
        static let resultsHint = "search.resultsHint"
        static let loadMoreButton = "search.loadMore"
        static let tvdbAttribution = "search.tvdbAttribution"
        static let noResults = "search.noResults"
        static let trackButton = "search.track"
        static let result = "search.result"
    }

    enum ShowDetail {
        static let trackButton = "showDetail.track"
    }

    enum Watchlist {
        static let emptyState = "watchlist.emptyState"
        static let noResults = "watchlist.noResults"
        static let row = "watchlist.row"
        static let searchButton = "watchlist.search"
        static let trackButton = "watchlist.track"
        static let undoButton = "watchlist.undo"
        static let confirmButton = "watchlist.confirm"
    }
}
