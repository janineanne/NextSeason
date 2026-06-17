//
//  NavigationUITests.swift
//  NextSeasonUITests
//

import XCTest

@MainActor
final class NavigationUITests: NextSeasonUITestCase {
    func testLaunchShowsSearchTab() {
        XCTAssertTrue(
            searchIdlePrompt.waitForExistence(timeout: UITestTimeout.standard),
            "Search tab should show the idle prompt on launch."
        )
        XCTAssertTrue(app.navigationBars["NextSeason"].waitForExistence(timeout: UITestTimeout.standard))
        XCTAssertTrue(app.tabBars.buttons["Search"].exists)
    }

    func testSwitchToWatchlistTabShowsEmptyState() {
        app.tabBars.buttons["Watchlist"].tap()

        XCTAssertTrue(
            watchlistEmptyState.waitForExistence(timeout: UITestTimeout.extended),
            "Watchlist tab should show the empty state when no shows are tracked."
        )
        XCTAssertTrue(app.navigationBars["Watchlist"].waitForExistence(timeout: UITestTimeout.standard))
    }

    func testSwitchBetweenTabs() {
        app.tabBars.buttons["Watchlist"].tap()
        XCTAssertTrue(watchlistEmptyState.waitForExistence(timeout: UITestTimeout.extended))

        app.tabBars.buttons["Search"].tap()
        XCTAssertTrue(searchIdlePrompt.waitForExistence(timeout: UITestTimeout.standard))
    }
}
