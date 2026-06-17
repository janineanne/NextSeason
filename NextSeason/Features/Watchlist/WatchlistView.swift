//
//  WatchlistView.swift
//  NextSeason
//

import SwiftUI

struct WatchlistView: View {
    @Environment(\.watchlistRepository) private var repository
    @Environment(\.watchlistRefreshService) private var refreshService
    @Environment(\.notificationService) private var notificationService

    @Binding var navigationPath: NavigationPath
    @State private var viewModel: WatchlistViewModel?
    @State private var notificationsDenied = false
    #if DEBUG
    @State private var isSchedulingTestNotification = false
    #endif

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if let viewModel {
                    content(for: viewModel)
                } else {
                    ProgressView("Loading watchlist…")
                }
            }
            .navigationTitle("Watchlist")
            .navigationDestination(for: TrackedShow.self) { tracked in
                ShowDetailView(show: Show(tracked: tracked))
            }
            .task {
                if viewModel == nil {
                    viewModel = WatchlistViewModel(
                        repository: repository,
                        refreshService: refreshService
                    )
                }
                await viewModel?.load()
                notificationsDenied = await notificationService.isDenied()
            }
            .refreshable {
                await viewModel?.refreshFromNetwork()
                notificationsDenied = await notificationService.isDenied()
            }
        }
    }

    @ViewBuilder
    private func content(for viewModel: WatchlistViewModel) -> some View {
        switch viewModel.state {
        case .loading:
            ProgressView("Loading watchlist…")
                .controlSize(.large)
        case .loaded(let shows) where shows.isEmpty:
            ContentUnavailableView(
                "No Tracked Shows",
                systemImage: "star",
                description: Text("Search for a show and tap Track to monitor its next season.")
            )
        case .loaded(let shows):
            List {
                if notificationsDenied {
                    NotificationsDisabledBanner {
                        notificationService.openNotificationSettings()
                    }
                }
                ForEach(shows) { tracked in
                    NavigationLink(value: tracked) {
                        WatchlistRow(tracked: tracked)
                    }
                }
                .onDelete { offsets in
                    for index in offsets {
                        let showID = shows[index].id
                        Task { await viewModel.remove(showID: showID) }
                    }
                }
                #if DEBUG
                debugSection(for: shows)
                #endif
            }
            .listStyle(.plain)
            .tvmazeAttributionInset()
        case .failed(let message):
            ContentUnavailableView {
                Label("Something Went Wrong", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button("Try Again") {
                    Task { await viewModel.load() }
                }
            }
        }
    }

    #if DEBUG
    @ViewBuilder
    private func debugSection(for shows: [TrackedShow]) -> some View {
        Section {
            if let show = shows.first {
                Button("Send Test Notification") {
                    Task { await sendTestNotification(for: show) }
                }
                .disabled(isSchedulingTestNotification)
                Text(testNotificationInstructions(showName: show.name))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Track a show to send a test notification.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Debug")
        }
    }

    private static let testNotificationDelaySeconds = 5
    private static var testNotificationDelay: Duration { .seconds(testNotificationDelaySeconds) }

    private func testNotificationInstructions(showName: String) -> String {
        if isSchedulingTestNotification {
            return "Sending in \(Self.testNotificationDelaySeconds) seconds — background the app now, then tap the notification when it arrives."
        }
        return "Uses “\(showName)”. Waits \(Self.testNotificationDelaySeconds) seconds before sending; background the app during the countdown, then tap the notification."
    }

    private func sendTestNotification(for tracked: TrackedShow) async {
        guard !isSchedulingTestNotification else { return }
        isSchedulingTestNotification = true

        await notificationService.deliverAfterDelay(
            SeasonNotificationContent(
                showID: tracked.id,
                showName: tracked.name,
                status: tracked.nextSeason
            ),
            requestIdentifier: "debug-\(UUID().uuidString)",
            delay: TimeInterval(Self.testNotificationDelaySeconds)
        )

        isSchedulingTestNotification = false
    }
    #endif
}

#if DEBUG
#Preview {
    @Previewable @State var path = NavigationPath()
    WatchlistView(navigationPath: $path)
        .environment(\.watchlistRepository, InMemoryWatchlistRepository())
}
#endif
