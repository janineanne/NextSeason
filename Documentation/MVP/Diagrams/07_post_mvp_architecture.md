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
        NotificationService[Cloud Notification Service]
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

This diagram shows what a post-MVP version might add on top of the current MVP:

- User accounts
- Cloud-synced watchlists
- Server-side scheduled season checks
- **Push notifications** (via APNs and a backend notification service)

## Relationship to the MVP

The MVP already includes **local notifications** scheduled on-device when watchlist
season status changes (`NotificationService`, `RefreshScheduler`, and
`BGTaskScheduler`). Those are not shown here because they do not require accounts,
cloud sync, or push infrastructure.

Post-MVP work would add **push/cloud notifications** so alerts can reach the user
even when the app has not run recently, plus the account and sync layer that
supports cross-device watchlists.
