# Dependencies and Boundaries

```mermaid
flowchart LR
    subgraph Views[SwiftUI Views]
        SearchView
        ShowDetailView
        WatchlistView
        DiagnosticsView
    end

    subgraph ViewModels[MainActor View Models]
        SearchVM[SearchViewModel]
        DetailVM[ShowDetailViewModel]
        WatchlistVM[WatchlistViewModel]
    end

    subgraph Protocols[Protocols / Abstractions]
        TVMazeService[[TVMazeService]]
        WatchlistRepository[[WatchlistRepository]]
        NotificationDelivering[[NotificationDelivering]]
        AnalyticsTracking[[AnalyticsTracking]]
    end

    subgraph Implementations[Implementations]
        TVMazeClient[TVMazeClient actor]
        SwiftRepo[SwiftDataWatchlistRepository]
        MemoryRepo[InMemoryWatchlistRepository]
        NotificationService[NotificationService]
        AnalyticsService[AnalyticsService]
    end

    subgraph PureLogic[Pure Logic]
        Calculator[NextSeasonCalculator]
        Detector[StatusChangeDetector]
        RefreshPolicy[RefreshPolicy]
        NotificationPolicy[NotificationAuthorizationPolicy]
    end

    Views --> ViewModels
    Views --> Protocols
    ViewModels --> Protocols
    ViewModels --> PureLogic

    TVMazeService --> TVMazeClient
    WatchlistRepository --> SwiftRepo
    WatchlistRepository --> MemoryRepo
    NotificationDelivering --> NotificationService
    AnalyticsTracking --> AnalyticsService

    SwiftRepo --> SwiftData[(SwiftData)]
    TVMazeClient --> Network[(URLSession / TVMaze API)]
    NotificationService --> UserNotifications[(UserNotifications)]
```

## Notes

The important portfolio boundary is that UI code depends on protocols and services rather than directly on URL construction, SwiftData fetches, or notification scheduling.
