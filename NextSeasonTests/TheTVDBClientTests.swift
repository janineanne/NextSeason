//
//  TheTVDBClientTests.swift
//  NextSeasonTests
//

import Foundation
import Testing

@testable import NextSeason

struct TheTVDBClientTests {
    @Test("nextOffset advances by raw API row count when sparse records are dropped")
    func nextOffsetUsesRawCountNotDomainCount() {
        let rawItems = [
            TheTVDBSearchResultData(
                tvdbID: "1",
                name: "Valid",
                year: "2024",
                network: nil,
                status: nil,
                imageURL: nil,
                thumbnail: nil
            ),
            TheTVDBSearchResultData(
                tvdbID: nil,
                name: "Missing ID",
                year: nil,
                network: nil,
                status: nil,
                imageURL: nil,
                thumbnail: nil
            ),
            TheTVDBSearchResultData(
                tvdbID: "3",
                name: "   ",
                year: nil,
                network: nil,
                status: nil,
                imageURL: nil,
                thumbnail: nil
            ),
        ]

        let page = TheTVDBClient.makeSearchPage(
            rawItems: rawItems,
            requestOffset: 20,
            pageSize: 10,
            links: nil
        )

        #expect(page.results.map(\.id) == [1])
        #expect(page.nextOffset == 23)
        #expect(page.hasMore == false)
    }

    @Test("Full raw page reports hasMore even if domain filtering empties results")
    func fullRawPageKeepsHasMoreAfterFiltering() {
        let rawItems = (0..<10).map { index in
            TheTVDBSearchResultData(
                tvdbID: nil,
                name: "Sparse \(index)",
                year: nil,
                network: nil,
                status: nil,
                imageURL: nil,
                thumbnail: nil
            )
        }

        let page = TheTVDBClient.makeSearchPage(
            rawItems: rawItems,
            requestOffset: 0,
            pageSize: 10,
            links: nil
        )

        #expect(page.results.isEmpty)
        #expect(page.nextOffset == 10)
        #expect(page.hasMore == true)
    }

    @Test("total_items metadata drives hasMore using raw fetched count")
    func totalItemsUsesRawFetchedCount() {
        let rawItems = [
            TheTVDBSearchResultData(
                tvdbID: "1",
                name: "Valid",
                year: nil,
                network: nil,
                status: nil,
                imageURL: nil,
                thumbnail: nil
            ),
            TheTVDBSearchResultData(
                tvdbID: nil,
                name: "Sparse",
                year: nil,
                network: nil,
                status: nil,
                imageURL: nil,
                thumbnail: nil
            ),
        ]
        let links = TheTVDBLinksData(next: nil, totalItems: 30, pageSize: 10)

        let page = TheTVDBClient.makeSearchPage(
            rawItems: rawItems,
            requestOffset: 0,
            pageSize: 10,
            links: links
        )

        // offset(0) + raw(2) < total(30) — must not use domain count (1).
        #expect(page.hasMore == true)
        #expect(page.nextOffset == 2)
        #expect(page.results.count == 1)
    }
}
