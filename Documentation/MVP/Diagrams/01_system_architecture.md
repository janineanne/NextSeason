# NextSeason System Architecture

```mermaid
flowchart TB
    User[User]

    subgraph App[NextSeason iOS App]
        Root[NextSeasonApp / AppRootView]
        Nav[AppNavigationCoordinator]
        Content[ContentView / TabView]

        subgraph Features[SwiftUI Features]
            Search[SearchView + SearchViewModel]
            Detail[ShowDetailView + ShowDetailViewModel]
            Watchlist[WatchlistView + WatchlistViewModel]
            Diagnostics[Diagnostics + Theme Switcher]
        end

        subgraph Services[Services]
            TVMazeClient[TVMazeClient actor]
            Calculator[NextSeasonCalculator]
            Refresh[WatchlistRefreshService]
            Scheduler[RefreshScheduler]
            Notifications[NotificationService]
            Analytics[AnalyticsService]
            Metrics[MetricKitDiagnosticsSubscriber]
        end

        subgraph Persistence[Persistence]
            Repo[WatchlistRepository]
            SwiftDataRepo[SwiftDataWatchlistRepository]
            Store[(SwiftData ModelContainer)]
            Entity[TrackedShowEntity]
        end
    end

    subgraph External[External Systems]
        TVMaze[(TVMaze API)]
        UNCenter[UNUserNotificationCenter]
        BGTasks[BGTaskScheduler]
        MetricKit[MetricKit]
    end

    User --> Content
    Root --> Content
    Root --> Store
    Root --> Repo
    Root --> Refresh
    Root --> Notifications
    Root --> Analytics
    Root --> Nav

    Content --> Search
    Content --> Watchlist
    Content --> Diagnostics
    Nav --> Content

    Search --> TVMazeClient
    Search --> Repo
    Search --> Analytics
    Search --> Detail

    Detail --> TVMazeClient
    Detail --> Repo
    Detail --> Calculator
    Detail --> Notifications
    Detail --> Analytics

    Watchlist --> Repo
    Watchlist --> Refresh
    Watchlist --> Notifications
    Watchlist --> Detail
    Watchlist --> Analytics

    Refresh --> Repo
    Refresh --> TVMazeClient
    Refresh --> Calculator
    Refresh --> Notifications
    Refresh --> Analytics

    Scheduler --> BGTasks
    Scheduler --> Refresh
    Notifications --> UNCenter
    TVMazeClient --> TVMaze
    SwiftDataRepo --> Store
    Store --> Entity
    Repo --> SwiftDataRepo
    Metrics --> MetricKit
```

## Notes

The MVP remains a local-first iOS app. The app has no user accounts, backend, or cloud sync. TVMaze is the only external data provider used by the running product.
