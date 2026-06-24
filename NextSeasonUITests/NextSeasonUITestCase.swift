//
//  NextSeasonUITestCase.swift
//  NextSeasonUITests
//

import XCTest

enum UITestLaunchArgument {
    static let uiTesting = "-UITesting"
}

enum UITestAccessibilityID {
    enum Search {
        static let idlePrompt = "search.idlePrompt"
        static let noResults = "search.noResults"
        static let trackButton = "search.track"
    }

    enum ShowDetail {
        static let trackButton = "showDetail.track"
    }

    enum Watchlist {
        static let emptyState = "watchlist.emptyState"
        static let row = "watchlist.row"
        static let trackButton = "watchlist.track"
        static let undoButton = "watchlist.undo"
        static let confirmButton = "watchlist.confirm"
    }
}

/// Sentinel search queries recognized by the stubbed service during UI testing.
/// Must match `UITestingConfiguration.SearchQuery` in the app target.
enum UITestSearchQuery {
    static let noResults = "uitest-no-results"
    static let failure = "uitest-failure"
}

enum UITestTimeout {
    static let standard: TimeInterval = 5
    static let extended: TimeInterval = 10
    /// Tracking persists asynchronously; allow extra time under simulator load.
    static let trackState: TimeInterval = 15
}

/// Values that match the stubbed preview show returned during UI testing.
enum UITestPreviewShow {
    static let name = "Severance"
    static let id = 44933
}

/// Shared setup for UI tests: launches the app with stubbed network data.
@MainActor
class NextSeasonUITestCase: XCTestCase, Sendable {
    var app: XCUIApplication!

    var searchIdlePrompt: XCUIElement {
        app.descendants(matching: .any)[UITestAccessibilityID.Search.idlePrompt]
    }

    var watchlistEmptyState: XCUIElement {
        app.descendants(matching: .any)[UITestAccessibilityID.Watchlist.emptyState]
    }

    var searchNoResults: XCUIElement {
        app.descendants(matching: .any)[UITestAccessibilityID.Search.noResults]
    }

    var watchlistUndoButton: XCUIElement {
        let byID = app.descendants(matching: .any)[UITestAccessibilityID.Watchlist.undoButton]
        if byID.exists { return byID }
        return app.buttons["Undo"]
    }

    var watchlistConfirmButton: XCUIElement {
        let byID = app.descendants(matching: .any)[UITestAccessibilityID.Watchlist.confirmButton]
        if byID.exists { return byID }
        return app.buttons["OK"]
    }

    override func setUp() async throws {
        try await super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = [UITestLaunchArgument.uiTesting]
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: UITestTimeout.standard))
    }

    func waitForButton(_ identifier: String, labelContaining text: String, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            let button = app.descendants(matching: .any)[identifier]
            if button.exists, button.label.localizedCaseInsensitiveContains(text) {
                return true
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }
        return false
    }

    func watchlistRow(named showName: String, showID: Int = UITestPreviewShow.id) -> XCUIElement {
        app.descendants(matching: .any)["\(UITestAccessibilityID.Watchlist.row).\(showID)"]
    }

    /// Waits for a watchlist row by stable identifier, then by combined label.
    @discardableResult
    func waitForWatchlistRow(
        named showName: String,
        showID: Int = UITestPreviewShow.id,
        timeout: TimeInterval = UITestTimeout.extended
    ) -> XCUIElement {
        let byID = watchlistRow(named: showName, showID: showID)
        if byID.waitForExistence(timeout: timeout) {
            return byID
        }

        let byLabel = app.buttons.matching(
            NSPredicate(
                format: "label BEGINSWITH[c] %@ AND label CONTAINS[c] 'Updated'",
                showName
            )
        ).firstMatch
        XCTAssertTrue(
            byLabel.waitForExistence(timeout: timeout),
            "Watchlist should show “\(showName)”."
        )
        return byLabel
    }

    func searchTrackButton(showID: Int = UITestPreviewShow.id) -> XCUIElement {
        let byID = app.descendants(matching: .any)["\(UITestAccessibilityID.Search.trackButton).\(showID)"]
        if byID.exists { return byID }
        return app.buttons["Track \(UITestPreviewShow.name)"]
    }

    func watchlistTrackButton(showID: Int = UITestPreviewShow.id) -> XCUIElement {
        let byID = app.descendants(matching: .any)["\(UITestAccessibilityID.Watchlist.trackButton).\(showID)"]
        if byID.exists { return byID }
        let stop = app.buttons["Stop tracking \(UITestPreviewShow.name)"]
        if stop.exists { return stop }
        return app.buttons["Track \(UITestPreviewShow.name)"]
    }

    func showDetailTrackButton(showID: Int = UITestPreviewShow.id) -> XCUIElement {
        let byID = app.descendants(matching: .any)["\(UITestAccessibilityID.ShowDetail.trackButton).\(showID)"]
        if byID.exists { return byID }
        return app.buttons["Track \(UITestPreviewShow.name)"]
    }

    func search(for query: String) {
        let searchField = app.searchFields["Search TV shows"]
        XCTAssertTrue(searchField.waitForExistence(timeout: UITestTimeout.standard))
        searchField.tap()

        if let currentValue = searchField.value as? String, !currentValue.isEmpty {
            let clearButton = searchField.buttons["Clear text"]
            if clearButton.waitForExistence(timeout: UITestTimeout.standard) {
                clearButton.tap()
            }
        }

        searchField.typeText(query)

        // Dismiss the keyboard so the track button and tab bar stay tappable.
        if app.keyboards.buttons["Search"].waitForExistence(timeout: 1) {
            app.keyboards.buttons["Search"].tap()
        }
    }
}
