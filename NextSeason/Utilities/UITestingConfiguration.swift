//
//  UITestingConfiguration.swift
//  NextSeason
//

import Foundation
import SwiftUI

/// Launch-argument helpers for XCUITest runs (`-UITesting`).
enum UITestingConfiguration {
    static let launchArgument = "-UITesting"

    static var isEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains(launchArgument)
    }

    /// Sentinel search queries the stubbed service recognizes so UI tests can
    /// drive the no-results and failure states (the real API isn't hit in tests).
    enum SearchQuery {
        static let noResults = "uitest-no-results"
        static let failure = "uitest-failure"
    }
}

/// Stable accessibility identifiers for UI tests.
enum AccessibilityID {
    enum Tab {
        static let search = "tab.search"
        static let watchlist = "tab.watchlist"
    }

    enum Search {
        static let idlePrompt = "search.idlePrompt"
        static let noResults = "search.noResults"
    }

    enum ShowDetail {
        static let trackButton = "showDetail.track"
    }

    enum Watchlist {
        static let emptyState = "watchlist.emptyState"
    }
}

extension View {
    /// Collapses a view into one labeled accessibility element for XCUITest.
    func uiTestMarker(_ identifier: String, label: String) -> some View {
        accessibilityElement(children: .ignore)
            .accessibilityLabel(label)
            .accessibilityIdentifier(identifier)
    }
}
