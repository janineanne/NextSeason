# Show Detail and Watchlist Flow

```mermaid
sequenceDiagram
    actor User
    participant Detail as ShowDetailView
    participant VM as ShowDetailViewModel
    participant API as TVMazeClient actor
    participant Calc as NextSeasonCalculator
    participant Repo as WatchlistRepository
    participant Notifications as NotificationService
    participant Analytics as AnalyticsService
    participant Watchlist as WatchlistView
    participant Undo as WatchlistUndoRemoval

    User->>Detail: Open show detail
    Detail->>VM: load(show)
    VM->>API: show(id, embedded seasons + next episode)
    API-->>VM: Show with season data
    VM->>Calc: status(for: show)
    Calc-->>VM: NextSeasonStatus
    VM->>Repo: contains(showID)
    Repo-->>VM: tracked / not tracked
    VM->>Analytics: showDetailViewed(showID)
    VM-->>Detail: display metadata + next-season status

    alt User tracks show
        User->>Detail: Tap Track
        VM->>Repo: add(show)
        Repo-->>VM: saved TrackedShowEntity
        VM->>Notifications: needsAuthorizationPrompt / request if user agrees
        VM->>Analytics: watchlistAdded(source: detail, showID)
        VM-->>Detail: tracked state
    else User stops tracking from detail
        User->>Detail: Tap Stop Tracking
        VM->>Repo: remove(showID)
        VM->>Analytics: watchlistRemoved(source: detail, showID)
        VM-->>Detail: untracked state
    end

    User->>Watchlist: View saved shows
    Watchlist->>Repo: all()
    Repo-->>Watchlist: [TrackedShow]
    Watchlist->>Analytics: watchlistViewed

    alt User removes from Watchlist
        User->>Watchlist: Delete / remove show
        Watchlist->>Undo: stage removal + show undo toast
        Undo->>Repo: remove(showID)
        Undo->>Analytics: watchlistRemoved(source: watchlist, showID)
        alt User taps Undo
            User->>Watchlist: Undo
            Undo->>Repo: restore show
            Undo->>Analytics: watchlistAdded(source: watchlist, showID)
        else Undo window expires
            Undo->>Undo: finalize removal
        end
    end
```

## Notes

The current watchlist removal flow keeps the list mounted and uses the undo coordinator to avoid the crash-prone empty-list transition that previously occurred during deletion.
