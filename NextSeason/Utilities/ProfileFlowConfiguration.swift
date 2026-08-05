//
//  ProfileFlowConfiguration.swift
//  NextSeason
//

import Foundation
import os

/// Launch-argument helpers for Instruments profiling on device (`-ProfileFlow <name>`).
enum ProfileFlowConfiguration {
    static let launchFlag = "-ProfileFlow"

    /// Signposts emitted into the Points of Interest track when profiling with Instruments.
    enum Signpost {
        static let log = OSLog(
            subsystem: "com.TrialByFyre.NextSeason",
            category: .pointsOfInterest
        )
        static let signposter = OSSignposter(logHandle: log)
    }

    enum Flow: String, CaseIterable {
        /// Populates the watchlist on device before a `launch-with-data` profile (setup only).
        case seedWatchlist
        /// Search for a known show (happy path).
        case search
        /// Search query that should return no TVMaze matches (empty-state path).
        case searchEmpty
        /// Open show detail from search results.
        case showDetails
        /// Navigate to the watchlist tab.
        case viewWishlist
        /// Add a show from search / detail.
        case addToWishlist
        /// Remove a tracked show from the watchlist.
        case removeFromWishlist
        /// Search → detail → back, repeated (stress).
        case stressSearchDetailsBack
        /// Add/remove the same show repeatedly (stress).
        case stressAddRemoveWishlist
        /// Empty-result search repeated (stress).
        case stressSearchEmpty
        /// Cold launch with populated watchlist; script runs multiple times.
        case launchWithData

        /// Setup flows run once to prepare data; they are not timed as the profile under test.
        var isSetupOnly: Bool { self == .seedWatchlist }

        var isStress: Bool {
            switch self {
            case .stressSearchDetailsBack, .stressAddRemoveWishlist, .stressSearchEmpty:
                true
            default:
                false
            }
        }
    }

    /// Queries used when seeding a populated watchlist for cold-launch profiling.
    enum SeedData {
        static let watchlistSearchQueries = [
            "Severance",
            "Breaking Bad",
            "The Office",
            "Arcane",
            "Shogun",
        ]
    }

    /// Search strings for profile flows against the live TVMaze API.
    enum SearchQuery {
        /// Unlikely to match any show; exercises the no-results empty state.
        static let emptyResults = "zzzzxnoresultsnexseasonprofile999"
    }

    /// Active profiling flow from `PROFILE_FLOW` env (preferred) or `-ProfileFlow <name>`.
    static var activeFlow: Flow? {
        if let env = ProcessInfo.processInfo.environment["PROFILE_FLOW"],
            let flow = Flow(rawValue: env)
        {
            return flow
        }
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: launchFlag),
            index + 1 < arguments.count
        else { return nil }
        return Flow(rawValue: arguments[index + 1])
    }

    static var isEnabled: Bool { activeFlow != nil }
}
