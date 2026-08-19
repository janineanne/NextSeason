//
//  PersistentStoreResetTests.swift
//  NextSeasonTests
//

import Foundation
import SwiftData
import Testing

@testable import NextSeason

@MainActor
struct PersistentStoreResetTests {
    @Test("Reset removes the store and sidecars, then a new container opens empty")
    func resetRemovesStoreAndAllowsNewContainer() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let storeURL = directory.appendingPathComponent("default.store")
        let unrelatedURL = directory.appendingPathComponent("keep-me.txt")
        try "unrelated".write(to: unrelatedURL, atomically: true, encoding: .utf8)

        try {
            _ = try NextSeasonModelContainer.make(
                configuration: ModelConfiguration(url: storeURL)
            )
        }()
        try Data("wal".utf8).write(
            to: URL(fileURLWithPath: storeURL.path + "-wal")
        )
        try Data("shm".utf8).write(
            to: URL(fileURLWithPath: storeURL.path + "-shm")
        )

        try PersistentStoreReset.removeStore(at: storeURL)

        let leftovers = try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        )
        .map(\.lastPathComponent)
        #expect(leftovers.contains("keep-me.txt"))
        #expect(leftovers.contains { $0.hasPrefix("default.store") } == false)

        let container = try NextSeasonModelContainer.make(
            configuration: ModelConfiguration(url: storeURL)
        )
        let fetched = try ModelContext(container).fetch(
            FetchDescriptor<TrackedShowEntity>()
        )
        #expect(fetched.isEmpty)
    }

    @Test("Reset is a no-op when the store directory does not exist")
    func resetMissingDirectoryIsNoOp() throws {
        let missing = FileManager.default.temporaryDirectory
            .appendingPathComponent("nextseason-missing-\(UUID().uuidString)", isDirectory: true)
            .appendingPathComponent("default.store")
        try PersistentStoreReset.removeStore(at: missing)
    }

    private func makeTemporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "nextseason-store-reset-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}
