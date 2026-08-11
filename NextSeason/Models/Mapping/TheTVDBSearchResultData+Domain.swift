//
//  TheTVDBSearchResultData+Domain.swift
//  NextSeason
//

import Foundation

extension TheTVDBSearchResultData {
    /// Maps a TheTVDB search hit into the app's search-result model.
    ///
    /// Returns `nil` when the payload lacks a usable series id or name so a
    /// sparse record does not crash the results list. Prefers `image_url` over
    /// `thumbnail` for posters.
    nonisolated func toDomain() -> TVDBSearchResult? {
        guard let tvdbID, let id = Int(tvdbID) else { return nil }
        let trimmedName = name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmedName.isEmpty else { return nil }

        let poster =
            imageURL.flatMap(URL.init(string:))
            ?? thumbnail.flatMap(URL.init(string:))

        return TVDBSearchResult(
            id: id,
            name: trimmedName,
            year: year,
            network: network,
            status: status,
            posterURL: poster
        )
    }
}
