//
//  NextSeasonApp.swift
//  NextSeason
//

import SwiftData
import SwiftUI

@main
struct NextSeasonApp: App {
    private let modelContainer: ModelContainer
    @State private var watchlistRepository: SwiftDataWatchlistRepository
    @State private var refreshService: WatchlistRefreshService

    init() {
        do {
            let container = try ModelContainer(for: TrackedShowEntity.self)
            modelContainer = container
            let repository = SwiftDataWatchlistRepository(context: ModelContext(container))
            _watchlistRepository = State(initialValue: repository)
            _refreshService = State(initialValue: WatchlistRefreshService(repository: repository))
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        RefreshScheduler.registerBackgroundTask()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.watchlistRepository, watchlistRepository)
                .environment(\.watchlistRefreshService, refreshService)
                .task {
                    RefreshScheduler.configure {
                        await refreshService.refreshAll()
                    }
                    RefreshScheduler.scheduleNextRefresh()
                }
        }
        .modelContainer(modelContainer)
    }
}
