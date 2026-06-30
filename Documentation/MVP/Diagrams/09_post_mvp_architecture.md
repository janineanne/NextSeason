# Post-MVP Architecture Options

```mermaid
flowchart TB
    User[User]

    subgraph App[NextSeason iOS App]
        UI[SwiftUI UI]
        LocalStore[(Local SwiftData Store)]
        LocalNotifications[Local Notifications]
        AnalyticsAbstraction[AnalyticsTracking]
        ProviderSearch[Search Provider Abstraction]
        SyncClient[Future Sync Client]
    end

    subgraph CurrentExternal[Current External Service]
        TVMaze[TVMaze API]
    end

    subgraph FutureData[Possible Future Data Providers]
        TMDb[TMDb or other paginated search provider]
        TVDB[TVDB or poster/image provider]
        Streaming[Streaming availability provider]
    end

    subgraph FutureBackend[Optional Future Backend]
        Accounts[Sign in with Apple / Accounts]
        WatchlistSync[Watchlist Sync API]
        RemoteAnalytics[Privacy-preserving Analytics]
        ServerScheduler[Server-side Season Checks]
        Push[APNs Push Notifications]
    end

    User --> UI
    UI --> LocalStore
    UI --> LocalNotifications
    UI --> ProviderSearch
    UI --> SyncClient
    UI --> AnalyticsAbstraction

    ProviderSearch --> TVMaze
    ProviderSearch -. possible .-> TMDb
    ProviderSearch -. possible .-> TVDB
    UI -. possible .-> Streaming

    SyncClient -. optional .-> Accounts
    SyncClient -. optional .-> WatchlistSync
    WatchlistSync -. optional .-> ServerScheduler
    ServerScheduler -. optional .-> TVMaze
    ServerScheduler -. optional .-> Push
    AnalyticsAbstraction -. optional .-> RemoteAnalytics
    Push -. optional .-> UI
```

## Notes

Post-MVP expansion should be driven by beta feedback and analytics. The highest-value likely additions are improved search, streaming availability, notification preferences, and persistence recovery/migration support.
