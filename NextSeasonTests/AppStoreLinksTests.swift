//
//  AppStoreLinksTests.swift
//  NextSeasonTests
//

import Foundation
import Testing

@testable import NextSeason

/// Verifies the App Store write-review URL is built from the configured Apple ID.
struct AppStoreLinksTests {
    @Test("Write-review URL opens the App Store review composer")
    func writeReviewURLUsesAppStoreAction() {
        let url = AppStoreLinks.writeReview
        #expect(url.scheme == "https")
        #expect(url.host == "apps.apple.com")
        #expect(url.path == "/app/id\(AppStoreLinks.appleID)")
        #expect(url.query == "action=write-review")
    }
}
