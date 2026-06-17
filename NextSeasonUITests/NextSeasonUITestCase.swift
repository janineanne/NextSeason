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
    }

    enum ShowDetail {
        static let trackButton = "showDetail.track"
    }

    enum Watchlist {
        static let emptyState = "watchlist.emptyState"
    }
}

enum UITestTimeout {
    static let standard: TimeInterval = 5
    static let extended: TimeInterval = 10
}

/// Shared setup for UI tests: launches the app with stubbed network data.
@MainActor
class NextSeasonUITestCase: XCTestCase {
    var app: XCUIApplication!

    var searchIdlePrompt: XCUIElement {
        app.descendants(matching: .any)[UITestAccessibilityID.Search.idlePrompt]
    }

    var watchlistEmptyState: XCUIElement {
        app.descendants(matching: .any)[UITestAccessibilityID.Watchlist.emptyState]
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = [UITestLaunchArgument.uiTesting]
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: UITestTimeout.standard))
    }

    func waitForButton(_ identifier: String, labelContaining text: String, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            let button = app.buttons[identifier]
            if button.exists, button.label.localizedCaseInsensitiveContains(text) {
                return true
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }
        return false
    }

    func watchlistRow(named showName: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH[c] %@", showName)).firstMatch
    }
}
