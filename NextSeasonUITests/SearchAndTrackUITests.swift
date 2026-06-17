//
//  SearchAndTrackUITests.swift
//  NextSeasonUITests
//

import XCTest

@MainActor
final class SearchAndTrackUITests: NextSeasonUITestCase {
    private let previewShowName = "Severance"

    func testSearchOpensShowDetail() {
        search(for: previewShowName)

        let result = app.buttons["\(previewShowName), Ongoing series"]
        XCTAssertTrue(
            result.waitForExistence(timeout: UITestTimeout.standard),
            "Search should return the stubbed Severance result."
        )
        result.tap()

        XCTAssertTrue(app.navigationBars[previewShowName].waitForExistence(timeout: UITestTimeout.standard))
        XCTAssertTrue(app.staticTexts["Next Season"].waitForExistence(timeout: UITestTimeout.standard))
    }

    func testTrackShowAppearsOnWatchlist() {
        search(for: previewShowName)

        let result = app.buttons["\(previewShowName), Ongoing series"]
        XCTAssertTrue(result.waitForExistence(timeout: UITestTimeout.standard))
        result.tap()

        let trackButton = app.buttons[UITestAccessibilityID.ShowDetail.trackButton]
        XCTAssertTrue(trackButton.waitForExistence(timeout: UITestTimeout.standard))
        trackButton.tap()

        app.tabBars.buttons["Watchlist"].tap()
        XCTAssertTrue(
            watchlistRow(named: previewShowName).waitForExistence(timeout: UITestTimeout.extended),
            "Tracked show should appear on the watchlist."
        )
        XCTAssertFalse(watchlistEmptyState.exists)
    }

    private func search(for query: String) {
        let searchField = app.searchFields["Search TV shows"]
        XCTAssertTrue(searchField.waitForExistence(timeout: UITestTimeout.standard))
        searchField.tap()
        searchField.typeText(query)
    }
}
