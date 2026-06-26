//
//  GenreDisplayTests.swift
//  NextSeasonTests
//

import Testing
@testable import NextSeason

struct GenreDisplayTests {
    @Test("Empty genres produce an empty display line")
    func emptyGenres() {
        #expect([String]().genreDisplayLine.isEmpty)
    }

    @Test("Single genre is unchanged")
    func singleGenre() {
        #expect(["Drama"].genreDisplayLine == "Drama")
    }

    @Test("Multiple genres use middle dots with non-breaking spaces before separators")
    func multipleGenres() {
        let line = ["Drama", "Science-Fiction", "Mystery"].genreDisplayLine
        #expect(line == "Drama\u{00A0}· Science-Fiction\u{00A0}· Mystery")
    }
}
