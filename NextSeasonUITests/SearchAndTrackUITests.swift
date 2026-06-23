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

    func testSearchWithNoResultsShowsFallbackGuidance() {
        search(for: UITestSearchQuery.noResults)

        XCTAssertTrue(
            searchNoResults.waitForExistence(timeout: UITestTimeout.extended),
            "An empty result set should show the fallback guidance, not imply the show is missing."
        )
    }

    func testSearchFailureShowsRetryState() {
        search(for: UITestSearchQuery.failure)

        XCTAssertTrue(
            app.staticTexts["Something Went Wrong"].waitForExistence(timeout: UITestTimeout.extended),
            "A failed search should surface an error state."
        )
        XCTAssertTrue(
            app.buttons["Try Again"].waitForExistence(timeout: UITestTimeout.standard),
            "The failure state should offer a retry action."
        )
    }

    func testReopeningTrackedShowReflectsTrackedState() {
        search(for: previewShowName)

        let result = app.buttons["\(previewShowName), Ongoing series"]
        XCTAssertTrue(result.waitForExistence(timeout: UITestTimeout.standard))
        result.tap()

        let trackButton = app.buttons[UITestAccessibilityID.ShowDetail.trackButton]
        XCTAssertTrue(
            waitForButton(UITestAccessibilityID.ShowDetail.trackButton, labelContaining: "Track", timeout: UITestTimeout.standard),
            "An untracked show should offer to Track."
        )
        trackButton.tap()
        XCTAssertTrue(
            waitForButton(UITestAccessibilityID.ShowDetail.trackButton, labelContaining: "Tracking", timeout: UITestTimeout.standard),
            "Tapping Track should mark the show as tracked."
        )

        app.navigationBars.buttons.element(boundBy: 0).tap()

        result.tap()
        XCTAssertTrue(
            waitForButton(UITestAccessibilityID.ShowDetail.trackButton, labelContaining: "Tracking", timeout: UITestTimeout.extended),
            "Reopening an already-tracked show should reflect the tracked state."
        )
    }

    func testRemoveShowFromWatchlist() {
        search(for: previewShowName)

        let result = app.buttons["\(previewShowName), Ongoing series"]
        XCTAssertTrue(result.waitForExistence(timeout: UITestTimeout.standard))
        result.tap()

        let trackButton = app.buttons[UITestAccessibilityID.ShowDetail.trackButton]
        XCTAssertTrue(trackButton.waitForExistence(timeout: UITestTimeout.standard))
        trackButton.tap()
        XCTAssertTrue(waitForButton(UITestAccessibilityID.ShowDetail.trackButton, labelContaining: "Tracking", timeout: UITestTimeout.standard))

        app.tabBars.buttons["Watchlist"].tap()
        let row = watchlistRow(named: previewShowName)
        XCTAssertTrue(row.waitForExistence(timeout: UITestTimeout.extended))

        // A fast swipe may either reveal a Delete action or commit the deletion
        // outright (full-swipe). Handle both: tap Delete if it appears.
        row.swipeLeft()
        let deleteButton = app.buttons["Delete"]
        if deleteButton.waitForExistence(timeout: UITestTimeout.standard) {
            deleteButton.tap()
        }

        XCTAssertTrue(
            watchlistEmptyState.waitForExistence(timeout: UITestTimeout.extended),
            "Removing the only tracked show should return the watchlist to its empty state."
        )
    }

    private func search(for query: String) {
        let searchField = app.searchFields["Search TV shows"]
        XCTAssertTrue(searchField.waitForExistence(timeout: UITestTimeout.standard))
        searchField.tap()
        searchField.typeText(query)
    }
}
