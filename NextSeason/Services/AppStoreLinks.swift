//
//  AppStoreLinks.swift
//  NextSeason
//

import Foundation

/// App Store product-page URLs, including the write-a-review deep link.
///
/// The numeric Apple ID is assigned in App Store Connect (App Information)
/// and is stable for the life of the app record.
nonisolated enum AppStoreLinks {
    /// App Store Connect Apple ID for NextSeason TV.
    static let appleID = "6784502780"

    /// Opens the App Store page where the user can write a review.
    ///
    /// Apple documents appending `action=write-review` to the product URL
    /// as the supported persistent alternative to `RequestReviewAction`.
    static let writeReview = URL(
        string: "https://apps.apple.com/app/id\(appleID)?action=write-review"
    )!
}
