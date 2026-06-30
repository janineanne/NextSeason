# App Startup and Environment Setup

```mermaid
sequenceDiagram
    participant iOS
    participant App as NextSeasonApp
    participant Metrics as MetricKitDiagnosticsSubscriber
    participant SwiftData as ModelContainer
    participant Repo as WatchlistRepository
    participant Notifications as NotificationRouting / NotificationService
    participant Refresh as RefreshScheduler
    participant UI as AppRootView

    iOS->>App: Launch app

    alt Normal app launch
        App->>Metrics: installIfNeeded()
        App->>Notifications: install routing + analytics
        App->>SwiftData: create ModelContainer(for: TrackedShowEntity)
        SwiftData-->>App: container
        App->>Repo: create SwiftDataWatchlistRepository
        App->>Refresh: registerBackgroundTask()
        App->>Refresh: configure refresh handler
        App->>Refresh: scheduleNextRefresh()
        App->>UI: inject repository, analytics, notifications, refresh service, theme, coordinator
    else UI testing launch
        App->>SwiftData: create in-memory ModelContainer
        App->>Repo: create InMemoryWatchlistRepository
        App->>UI: inject test-safe services
    else ModelContainer creation fails
        App->>App: fatalError for MVP
        Note over App: Post-MVP roadmap covers migration, recovery, and crash-loop prevention.
    end
```

## Notes

Persistence is created at app startup because the app cannot function meaningfully without a watchlist store. For MVP, container creation failure is treated as unrecoverable; a user-facing recovery flow is deferred to the post-MVP roadmap.
