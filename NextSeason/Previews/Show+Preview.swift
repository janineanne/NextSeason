//
//  Show+Preview.swift
//  NextSeason
//
//  Sample data for SwiftUI previews only.
//

#if DEBUG
    import Foundation

    extension Show {
        static let preview = Show(
            id: 44933,
            name: "Severance",
            tvMazeURL: URL(string: "https://www.tvmaze.com/shows/44933/severance"),
            summaryHTML:
                "<p>Mark leads a team whose memories are surgically divided between <b>work</b> and <i>personal</i> lives.</p>",
            posterMediumURL: nil,
            posterOriginalURL: nil,
            status: .running,
            premiered: TVMazeDate.dateOnly("2022-02-18"),
            ended: nil,
            network: "Apple TV",
            genres: ["Drama", "Science-Fiction", "Mystery"],
            averageRuntime: 49,
            seasons: [
                Season(
                    id: 1, number: 1, premiereDate: TVMazeDate.dateOnly("2022-02-18"),
                    endDate: TVMazeDate.dateOnly("2022-04-08"), episodeOrder: 9),
                Season(
                    id: 2, number: 2, premiereDate: TVMazeDate.dateOnly("2025-01-17"),
                    endDate: TVMazeDate.dateOnly("2025-03-21"), episodeOrder: 10),
                Season(id: 3, number: 3, premiereDate: nil, endDate: nil, episodeOrder: nil),
            ],
            nextEpisode: nil,
            updatedAt: .now
        )

        /// A show with no summary text, to preview how the detail screen degrades
        /// when TVMaze has no description.
        static let previewMissingSummary = Show(
            id: 250,
            name: "Untitled Drama Project",
            tvMazeURL: URL(string: "https://www.tvmaze.com/shows/250/untitled-drama-project"),
            summaryHTML: nil,
            posterMediumURL: nil,
            posterOriginalURL: nil,
            status: .running,
            premiered: TVMazeDate.dateOnly("2024-03-01"),
            ended: nil,
            network: "Example Network",
            genres: ["Drama"],
            averageRuntime: 45,
            seasons: [
                Season(
                    id: 1, number: 1, premiereDate: TVMazeDate.dateOnly("2024-03-01"),
                    endDate: TVMazeDate.dateOnly("2024-05-01"), episodeOrder: 8)
            ],
            nextEpisode: nil,
            updatedAt: .now
        )

        static let previewList: [Show] = [
            .preview,
            Show(
                id: 82,
                name: "Game of Thrones",
                tvMazeURL: URL(string: "https://www.tvmaze.com/shows/82/game-of-thrones"),
                summaryHTML: "<p>Noble families vie for control of the Iron Throne.</p>",
                posterMediumURL: nil,
                posterOriginalURL: nil,
                status: .ended,
                premiered: TVMazeDate.dateOnly("2011-04-17"),
                ended: TVMazeDate.dateOnly("2019-05-19"),
                network: "HBO",
                genres: ["Drama", "Adventure", "Fantasy"],
                averageRuntime: 60,
                seasons: [],
                nextEpisode: nil,
                updatedAt: .now
            ),
        ]
    }

    extension TVDBSearchResult {
        /// Matches `Show.preview` via TheTVDB id `371980` (Severance).
        /// UI tests assert search-row identifiers against this id (`tvdbID`).
        nonisolated static let previewSearchResult = TVDBSearchResult(
            id: 371980,
            name: "Severance",
            year: "2022",
            network: "Apple TV",
            status: "Continuing",
            posterURL: nil,
            imdbID: "tt11280740"
        )
    }

    /// A `TheTVDBService` that returns fixed search pages so previews/UI tests
    /// never hit the network.
    ///
    /// Sentinel queries match `UITestingSearchQuery` so XCUITests can drive
    /// empty and failure states through the same Search UI as production.
    struct PreviewTheTVDBService: TheTVDBService {
        let stub: TVDBSearchResult
        /// Extra pages returned from `offset > 0` (empty by default).
        var moreResults: [TVDBSearchResult] = []

        func searchSeries(matching query: String, offset: Int) async throws -> TheTVDBSearchPage {
            switch query {
            case UITestingConfiguration.SearchQuery.noResults:
                return TheTVDBSearchPage(results: [], hasMore: false)
            case UITestingConfiguration.SearchQuery.failure:
                throw TheTVDBError.server(statusCode: 500)
            default:
                if offset > 0 {
                    return TheTVDBSearchPage(results: moreResults, hasMore: false)
                }
                return TheTVDBSearchPage(
                    results: [stub],
                    // Offer "Load more" only when the preview was given a second page.
                    hasMore: !moreResults.isEmpty
                )
            }
        }
    }

    /// A `TVMazeService` that returns fixed data so previews never hit the network.
    ///
    /// `lookupShow` maps the preview TheTVDB / IMDb ids onto `stub` so Search's
    /// resolve path works under `-UITesting` without live redirects.
    struct PreviewTVMazeService: TVMazeService {
        let stub: Show

        func searchShows(matching query: String) async throws -> [Show] {
            // Recognize UI-test sentinels so tests can exercise the empty and failure
            // states. Previews never use these queries, so behavior there is unchanged.
            // (Guest search now goes through TheTVDB; this remains for profile tooling.)
            switch query {
            case UITestingConfiguration.SearchQuery.noResults:
                return []
            case UITestingConfiguration.SearchQuery.failure:
                throw TVMazeError.server(statusCode: 500)
            default:
                return [stub]
            }
        }

        func lookupShow(theTVDBID: Int) async throws -> Show {
            guard theTVDBID == TVDBSearchResult.previewSearchResult.id else {
                throw TVMazeError.notFound
            }
            return stub
        }

        func lookupShow(imdbID: String) async throws -> Show {
            guard imdbID == TVDBSearchResult.previewSearchResult.imdbID else {
                throw TVMazeError.notFound
            }
            return stub
        }

        func show(id: Int, bypassCache: Bool) async throws -> Show { stub }
        func updatedShows(since period: TVMazeUpdatePeriod) async throws -> [Int: Date] { [:] }
    }
#endif
