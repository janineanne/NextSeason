//
//  AccessibilityAuditUITests.swift
//  NextSeasonUITests
//

import XCTest

/// Runs Xcode's accessibility audit on the primary screens reachable under
/// `-UITesting`. About and store sheets are omitted from UI-test launches, so
/// they are not covered here.
@MainActor
final class AccessibilityAuditUITests: XCTestCase, NextSeasonUITesting {
    var app: XCUIApplication!

    override func setUp() async throws {
        try await super.setUp()
        try await launchUITestingApp()
    }

    func testSearchIdlePassesAccessibilityAudit() {
        assertExists(
            searchIdlePrompt,
            "Search tab should show the idle prompt on launch."
        )
        auditCurrentScreen("Search idle")
    }

    func testSearchResultsPassAccessibilityAudit() {
        tapTryExample()
        waitForSearchResultRow(named: UITestPreviewShow.name, timeout: UITestTimeout.extended)
        auditCurrentScreen("Search results")
    }

    func testSearchNoResultsPassAccessibilityAudit() {
        search(for: UITestingSearchQuery.noResults)
        assertExists(
            searchNoResults,
            timeout: UITestTimeout.extended,
            "An empty result set should show the fallback guidance."
        )
        auditCurrentScreen("Search no results")
    }

    func testSearchFailurePassesAccessibilityAudit() {
        search(for: UITestingSearchQuery.failure)
        assertExists(
            app.staticTexts["Something Went Wrong"],
            timeout: UITestTimeout.extended,
            "A failed search should surface an error state."
        )
        auditCurrentScreen("Search failure")
    }

    func testShowDetailPassesAccessibilityAudit() {
        tapTryExample()
        waitForSearchResultRow(named: UITestPreviewShow.name, timeout: UITestTimeout.extended)
            .tap()
        waitForShowDetail()
        auditCurrentScreen("Show detail")
    }

    func testWatchlistEmptyPassesAccessibilityAudit() {
        app.tabBars.buttons["Watchlist"].tap()
        assertExists(
            watchlistEmptyState,
            timeout: UITestTimeout.extended,
            "Watchlist tab should show the empty state when no shows are tracked."
        )
        auditCurrentScreen("Watchlist empty")
    }

    func testPopulatedWatchlistPassesAccessibilityAudit() {
        tapTryExample()
        waitForSearchResultRow(named: UITestPreviewShow.name, timeout: UITestTimeout.extended)

        let trackButton = searchTrackButton()
        assertExists(trackButton, "Search results should expose a track control.")
        trackButton.tap()

        app.tabBars.buttons["Watchlist"].tap()
        waitForWatchlistRow(named: UITestPreviewShow.name, timeout: UITestTimeout.trackState)
        auditCurrentScreen("Watchlist populated")
    }

    // MARK: - Helpers

    /// Audits the current screen and fails with every outstanding issue.
    /// Known issues are ignored in `shouldIgnore` so this test stays a
    /// regression net rather than a permanently red checklist.
    private func auditCurrentScreen(_ name: String) {
        var issueSummaries: [String] = []

        do {
            try app.performAccessibilityAudit { issue in
                if self.shouldIgnore(issue) {
                    return true
                }
                issueSummaries.append(self.formattedIssue(issue))
                return true
            }
        } catch {
            recordFailureContext("Accessibility audit — \(name)")
            XCTFail("Accessibility audit threw on \(name): \(error)")
            return
        }

        guard !issueSummaries.isEmpty else { return }

        recordFailureContext("Accessibility audit — \(name)")
        let summary = issueSummaries.joined(separator: "\n\n")
        let attachment = XCTAttachment(string: summary)
        attachment.name = "Accessibility issues — \(name)"
        attachment.lifetime = .keepAlways
        add(attachment)
        XCTFail(
            "Accessibility audit found \(issueSummaries.count) issue(s) on \(name):\n\(summary)")
    }

    private func formattedIssue(_ issue: XCUIAccessibilityAuditIssue) -> String {
        let element = issue.element
        let identifier = element?.identifier ?? ""
        let label = element?.label ?? ""
        let elementName = identifier.isEmpty ? (label.isEmpty ? "unknown" : label) : identifier
        return """
            \(issue.compactDescription)
            Type: \(issue.auditType)
            Element: \(elementName)
            Label: \(label)
            \(issue.detailedDescription)
            """
    }

    /// Ignore issues that are understood and not yet worth failing CI.
    /// Remove an entry here when the underlying UI is fixed.
    private func shouldIgnore(_ issue: XCUIAccessibilityAuditIssue) -> Bool {
        let label = issue.element?.label ?? ""
        let description = issue.compactDescription

        // Custom `foregroundStyle` on system text styles trips this audit
        // even though the fonts themselves are Dynamic Type styles.
        if issue.auditType.contains(.dynamicType) {
            return true
        }

        // System search field and ContentUnavailableView predict clipping
        // at the largest accessibility sizes.
        if issue.auditType.contains(.textClipped) {
            return true
        }

        // Secondary/caption copy is intentionally `.secondary`. "Nearly
        // passed" is expected at this contrast.
        if issue.auditType.contains(.contrast) {
            return description.hasPrefix("Contrast nearly passed")
        }

        // System search-field clear button is smaller than 44pt by design.
        if description.hasPrefix("Hit area") && label == "Clear text" {
            return true
        }

        // SwiftUI reports an unlabeled node that looks like "Search" on
        // Watchlist even though the toolbar button has an accessibility label.
        if description.contains("looks like: Search") {
            return true
        }

        return false
    }
}
