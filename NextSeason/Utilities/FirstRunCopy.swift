//
//  FirstRunCopy.swift
//  NextSeason
//

import Foundation

/// Shared first-run messaging across Search idle, Watchlist empty, and notification prompts.
enum FirstRunCopy {
    static let exampleSearchQuery = "Severance"
    static let tryExampleButtonTitle = "Try an Example"

    static let searchIdleDescription =
        "Search for a show to see its next-season status. Use the search field above, or try an example."

    static let watchlistEmptyDescription =
        "Track shows you care about — tap the star on any search result."

    static let searchResultsHint =
        "Tap the star to track a show, or tap the row to see its next-season details."

    static let searchResultsLimitMessage =
        "Don't see your show? NextSeason shows TVMaze's top matches only. You may find more on TVMaze.com."

    static let notificationPromptMessage =
        "Get alerts when a tracked show's next season gets a release date or status update."

    static let notificationsSettingsReminderMessage =
        "You can turn on notifications in Settings to get alerts when a tracked show's next season gets a release date or status update."

    static let notificationsDisabledBannerMessage =
        "Turn on notifications in Settings to get alerts when a tracked show's next season gets a release date or status update."

    static let actorDetailsPlannedMessage =
        "Actor details are planned for a future release."
}
