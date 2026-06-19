# Post-MVP Architecture

```mermaid
flowchart TB
    User[User]

    subgraph App[NextSeason iOS App]
        UI[SwiftUI Views]
        LocalStore[Local Cache / Watchlist]
        NotificationPrefs[Notification Preferences]
        SyncClient[Sync Client]
    end

    subgraph Backend[Future Backend / Cloud Layer]
        Accounts[User Accounts]
        WatchlistAPI[Watchlist Sync API]
        Scheduler[Season Check Scheduler]
        NotificationService[Notification Service]
    end

    subgraph External[External Services]
        TVMaze[TVMaze API]
        Push[Apple Push Notification Service]
    end

    User --> UI
    UI --> LocalStore
    UI --> NotificationPrefs
    UI --> SyncClient

    SyncClient --> Accounts
    SyncClient --> WatchlistAPI
    WatchlistAPI --> Scheduler
    Scheduler --> TVMaze
    Scheduler --> NotificationService
    NotificationService --> Push
    Push --> App

    WatchlistAPI --> LocalStore
```

## Purpose

This diagram shows what a post-MVP version might add:

- User accounts
- Cloud-synced watchlists
- Scheduled background checks
- Push notifications

This is intentionally not part of the MVP. The MVP can prove the core value before adding account and notification complexity.
