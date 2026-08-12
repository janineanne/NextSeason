//
//  FirstRunCopy.swift
//  NextSeason
//

import Foundation

/// Shared first-run messaging across Search idle, Watchlist empty, and notification prompts.
enum FirstRunCopy {
    static let exampleSearchQuery = "Severance"
    static let tryExampleButtonTitle = String(localized: "Try an Example")

    static let searchIdleDescription = String(
        localized:
            "Search for a show to see its next-season status. Use the search field above, or try an example."
    )

    static let watchlistEmptyDescription = String(
        localized: "Track shows you care about — tap the star on any search result."
    )

    static let searchResultsHint = String(
        localized:
            "Tap the star to track a show, or tap the row to see its next-season details."
    )

    /// Empty-state guidance when TheTVDB returned no actionable (index-mapped) hits.
    static let searchEmptyDescription = String(
        localized:
            "Try a more specific title — add a subtitle or the year (for example, “Title: Subtitle” or “Title 2019”)."
    )

    /// Shown when filtered search pages found nothing actionable yet, but more
    /// TheTVDB pages remain (so Load More can continue the search).
    static let searchMoreAvailableDescription = String(
        localized:
            "No trackable shows in these results yet. Load more to keep looking."
    )

    static let notificationPromptMessage = String(
        localized:
            "Get alerts when a tracked show's next season gets a release date or status update."
    )

    static let notificationsSettingsReminderMessage = String(
        localized:
            "You can turn on notifications in Settings to get alerts when a tracked show's next season gets a release date or status update."
    )

    static let notificationsDisabledBannerMessage = String(
        localized:
            "Enable notifications to get alerts when a tracked show's next season gets a release date or status update."
    )
}
