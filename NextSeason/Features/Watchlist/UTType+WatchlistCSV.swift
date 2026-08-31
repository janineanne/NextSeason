//
//  UTType+WatchlistCSV.swift
//  NextSeason
//

import UniformTypeIdentifiers

extension UTType {
    /// File-based CSV for watchlist export.
    ///
    /// The system `commaSeparatedText` type also conforms to `public.text`, so
    /// ShareLink delivers it as text and Numbers' share extension never gets a
    /// file. This exported type conforms only to `public.data`.
    nonisolated static let watchlistCSV = UTType(
        exportedAs: "com.TrialByFyre.NextSeason.watchlist-csv")
}
