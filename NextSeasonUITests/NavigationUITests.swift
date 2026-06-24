//
//  NavigationUITests.swift
//  NextSeasonUITests
//

import XCTest

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

    func testFindShowButtonNavigatesToSearch() {
        search(for: UITestPreviewShow.name)

        let result = app.buttons["\(UITestPreviewShow.name), Ongoing series"]
        XCTAssertTrue(result.waitForExistence(timeout: UITestTimeout.standard))
        result.tap()
        XCTAssertTrue(
            app.navigationBars[UITestPreviewShow.name].waitForExistence(timeout: UITestTimeout.standard),
            "Opening a show from search should push its detail screen."
        )

        app.tabBars.buttons["Watchlist"].tap()
        XCTAssertTrue(watchlistEmptyState.waitForExistence(timeout: UITestTimeout.extended))

        let findShow = app.buttons["Find a Show"]
        XCTAssertTrue(findShow.waitForExistence(timeout: UITestTimeout.standard))
        findShow.tap()

        XCTAssertTrue(
            app.navigationBars["NextSeason"].waitForExistence(timeout: UITestTimeout.standard),
            "Find a Show should land on the search screen root."
        )
        XCTAssertTrue(
            app.searchFields["Search TV shows"].waitForExistence(timeout: UITestTimeout.standard),
            "Find a Show should show the search field."
        )
        XCTAssertFalse(
            app.navigationBars[UITestPreviewShow.name].exists,
            "Find a Show should not reopen a stale detail screen from the search stack."
        )
    }
}
