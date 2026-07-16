//
//  NextSeasonUITestCase.swift
//  NextSeasonUITests
//

import XCTest

// MARK: - Overview
//
// This file is the shared base class and harness for the UI test target — it is
// not a test case itself and contains no `test...()` methods. The actual UI test
// classes (e.g. `NavigationUITests`, `SearchAndTrackUITests`) subclass
// `NextSeasonUITestCase` to inherit its setup and helpers, which keeps the
// individual test files small and consistent.
//
// It provides:
//   • App launch: `setUp()` launches the app once with the `-UITesting` argument
//     (switching the app to stubbed network data) and waits for foreground.
//   • Shared constants that keep tests and the app in sync: accessibility IDs
//     (`UITestAccessibilityID`), sentinel search queries (`UITestSearchQuery`,
//     must match `UITestingConfiguration.SearchQuery` in the app target),
//     timeouts (`UITestTimeout`), and stub show data (`UITestPreviewShow`).
//   • Reusable element accessors (e.g. `searchField`, `watchlistEmptyState`) and
//     interaction/assertion helpers (e.g. `search(for:)`, `clearSearchField()`,
//     `waitForSearchResultRow(...)`, `assertExists(...)`, `recordFailureContext(...)`).

enum UITestLaunchArgument {
    static let uiTesting = "-UITesting"
}

enum UITestAccessibilityID {
    enum Search {
        static let idlePrompt = "search.idlePrompt"
        static let tryExampleButton = "search.tryExample"
        static let resultsHint = "search.resultsHint"
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

    var watchlistNoResults: XCUIElement {
        app.descendants(matching: .any)[UITestAccessibilityID.Watchlist.noResults]
    }

    /// The watchlist's own search field (distinct from the Search tab field).
    var watchlistSearchField: XCUIElement {
        app.searchFields[watchlistSearchFieldPlaceholder]
    }

    /// Placeholder `.searchable` exposes as the watchlist field's `value` when empty.
    private var watchlistSearchFieldPlaceholder: String { "Search Watchlist" }

    /// Returns user-entered watchlist search text, ignoring the placeholder/empty value.
    func watchlistSearchFieldText() -> String? {
        guard let value = watchlistSearchField.value as? String else { return nil }
        guard !value.isEmpty, value != watchlistSearchFieldPlaceholder else { return nil }
        return value
    }

    func searchWatchlist(for query: String) {
        let field = watchlistSearchField
        assertExists(field, "Watchlist should expose the “Search Watchlist” field before typing.")

        if watchlistSearchFieldText() != nil {
            clearWatchlistSearchField()
        }

        focusSearchField(field)
        field.typeText(query)

        // Dismiss the keyboard so list rows and the tab bar stay tappable.
        if app.keyboards.buttons["Search"].waitForExistence(timeout: 1) {
            app.keyboards.buttons["Search"].tap()
        }
    }

    func clearWatchlistSearchField() {
        let field = watchlistSearchField
        assertExists(field, "Watchlist search field should exist before clearing.")
        focusSearchField(field)

        let clearCandidates = [
            field.buttons["Clear text"],
            app.buttons["Clear text"],
            app.navigationBars.buttons["Clear text"]
        ]
        for clearButton in clearCandidates where clearButton.waitForExistence(timeout: 1) {
            clearButton.tap()
            if watchlistSearchFieldText() == nil { return }
        }

        guard watchlistSearchFieldText() != nil else { return }

        field.press(forDuration: 1.0)
        if app.menuItems["Select All"].waitForExistence(timeout: 1) {
            app.menuItems["Select All"].tap()
        } else {
            field.typeKey("a", modifierFlags: [.command])
        }
        field.typeKey(XCUIKeyboardKey.delete.rawValue, modifierFlags: [])

        if app.keyboards.buttons["Search"].waitForExistence(timeout: 1) {
            app.keyboards.buttons["Search"].tap()
        }
    }

    var searchNoResults: XCUIElement {
        app.descendants(matching: .any)[UITestAccessibilityID.Search.noResults]
    }

    var searchField: XCUIElement {
        app.searchFields["Search TV shows"]
    }

    /// Placeholder text `.searchable` exposes as `value` when the field is empty.
    private var searchFieldPlaceholder: String { "Search TV shows" }

    /// Returns user-entered search text, ignoring placeholder/empty values.
    func searchFieldText(in field: XCUIElement? = nil) -> String? {
        let field = field ?? searchField
        guard let value = field.value as? String else { return nil }
        guard !value.isEmpty, value != searchFieldPlaceholder else { return nil }
        return value
    }

    var tryExampleButton: XCUIElement {
        app.descendants(matching: .any)[UITestAccessibilityID.Search.tryExampleButton]
    }

    var searchResultsHint: XCUIElement {
        app.descendants(matching: .any)[UITestAccessibilityID.Search.resultsHint]
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
        XCTAssertTrue(
            app.wait(for: .runningForeground, timeout: UITestTimeout.standard),
            "NextSeason should launch to the foreground during UI tests."
        )
    }

    /// Captures the current screen and accessibility tree when an assertion fails.
    func recordFailureContext(_ step: String) {
        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = "Screenshot — \(step)"
        screenshot.lifetime = .keepAlways
        add(screenshot)

        let hierarchy = XCTAttachment(string: app.debugDescription)
        hierarchy.name = "Accessibility hierarchy — \(step)"
        hierarchy.lifetime = .keepAlways
        add(hierarchy)
    }

    func assertExists(
        _ element: XCUIElement,
        timeout: TimeInterval = UITestTimeout.standard,
        _ message: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        if !element.waitForExistence(timeout: timeout) {
            recordFailureContext(message)
            XCTFail(message, file: file, line: line)
        }
    }

    func assertNotExists(
        _ element: XCUIElement,
        _ message: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        if element.exists {
            recordFailureContext(message)
            XCTFail(message, file: file, line: line)
        }
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

    /// Search result row in the list (NavigationLink). Labels include genres after the status.
    func searchResultRow(
        named showName: String,
        showID: Int = UITestPreviewShow.id,
        status: String = "Ongoing series"
    ) -> XCUIElement {
        let byID = app.descendants(matching: .any)["\(UITestAccessibilityID.Search.result).\(showID)"]
        if byID.exists { return byID }

        let prefix = "\(showName), \(status)"
        return app.descendants(matching: .any).matching(
            NSPredicate(format: "label BEGINSWITH[c] %@", prefix)
        ).firstMatch
    }

    /// Waits for a search result row by stable identifier, then by combined label.
    @discardableResult
    func waitForSearchResultRow(
        named showName: String,
        showID: Int = UITestPreviewShow.id,
        status: String = "Ongoing series",
        timeout: TimeInterval = UITestTimeout.standard
    ) -> XCUIElement {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            let row = searchResultRow(named: showName, showID: showID, status: status)
            if row.exists { return row }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }

        let searchValue = searchFieldText() ?? searchFieldPlaceholder
        recordFailureContext("Search should return “\(showName)”")
        XCTFail(
            """
            Search should return “\(showName)” (id: \(UITestAccessibilityID.Search.result).\(showID)). \
            Search field value: “\(searchValue)”.
            """
        )
        return searchResultRow(named: showName, showID: showID, status: status)
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
        app.descendants(matching: .any)["\(UITestAccessibilityID.ShowDetail.trackButton).\(showID)"]
    }

    /// Detail-only track control; does not match the search-row star.
    @discardableResult
    func waitForShowDetail(
        showID: Int = UITestPreviewShow.id,
        timeout: TimeInterval = UITestTimeout.standard
    ) -> XCUIElement {
        let button = showDetailTrackButton(showID: showID)
        assertExists(
            button,
            timeout: timeout,
            "Show detail should display the track control (id: \(UITestAccessibilityID.ShowDetail.trackButton).\(showID))."
        )
        return button
    }

    /// Taps `field` and waits for the keyboard, retrying the tap a few times.
    /// XCUITest can drop synthesized key events when typing races the focus
    /// handoff to a `.searchable` field, so callers must confirm focus first.
    @discardableResult
    func focusSearchField(_ field: XCUIElement, timeout: TimeInterval = UITestTimeout.standard) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            field.tap()
            if app.keyboards.element.waitForExistence(timeout: 1) {
                return true
            }
        }
        return app.keyboards.element.exists
    }

    func search(for query: String) {
        let searchField = self.searchField
        assertExists(
            searchField,
            "Search tab should expose the “Search TV shows” field before typing."
        )

        if searchFieldText(in: searchField) != nil {
            clearSearchField(clearingField: searchField)
        }

        // Focus immediately before typing so any prior keyboard dismissal (e.g.
        // from clearing) can't leave the field unfocused when key events arrive.
        focusSearchField(searchField)
        searchField.typeText(query)

        // Dismiss the keyboard so the track button and tab bar stay tappable.
        if app.keyboards.buttons["Search"].waitForExistence(timeout: 1) {
            app.keyboards.buttons["Search"].tap()
        }
    }

    func tapTryExample() {
        XCTAssertTrue(tryExampleButton.waitForExistence(timeout: UITestTimeout.standard))
        tryExampleButton.tap()
    }

    func clearSearchField(clearingField field: XCUIElement? = nil) {
        let searchField = field ?? self.searchField
        assertExists(searchField, "Search field should exist before clearing.")

        focusSearchField(searchField)

        let clearCandidates = [
            searchField.buttons["Clear text"],
            app.buttons["Clear text"],
            app.navigationBars.buttons["Clear text"]
        ]
        for clearButton in clearCandidates where clearButton.waitForExistence(timeout: 1) {
            clearButton.tap()
            if searchFieldText(in: searchField) == nil { return }
        }

        guard searchFieldText(in: searchField) != nil else { return }

        // Prefer select-all over per-character delete; tapping keyboard keys is flaky on
        // narrow simulators (XCTest fails to scroll the delete key into view).
        searchField.press(forDuration: 1.0)
        if app.menuItems["Select All"].waitForExistence(timeout: 1) {
            app.menuItems["Select All"].tap()
        } else {
            searchField.typeKey("a", modifierFlags: [.command])
        }
        searchField.typeKey(XCUIKeyboardKey.delete.rawValue, modifierFlags: [])

        if app.keyboards.buttons["Search"].waitForExistence(timeout: 1) {
            app.keyboards.buttons["Search"].tap()
        }
    }

    @discardableResult
    func waitForSearchFieldValue(
        _ expected: String,
        timeout: TimeInterval = UITestTimeout.extended
    ) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if searchFieldText() == expected {
                return true
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }
        return false
    }
}
