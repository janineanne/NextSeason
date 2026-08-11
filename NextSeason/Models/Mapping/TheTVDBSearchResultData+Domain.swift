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
    /// `thumbnail` for posters; pulls IMDb from `remote_ids` for TVMaze
    /// fallback lookup later.
    nonisolated func toDomain() -> TVDBSearchResult? {
        guard let tvdbID, let id = Int(tvdbID) else { return nil }
        let trimmedName = name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmedName.isEmpty else { return nil }

        let poster =
            imageURL.flatMap(URL.init(string:))
            ?? thumbnail.flatMap(URL.init(string:))
        let imdbID = remoteIDs?.first { remote in
            remote.sourceName?.caseInsensitiveCompare("IMDB") == .orderedSame
        }?.id

        return TVDBSearchResult(
            id: id,
            name: trimmedName,
            year: year,
            network: network,
            status: status,
            posterURL: poster,
            imdbID: imdbID
        )
    }
}
