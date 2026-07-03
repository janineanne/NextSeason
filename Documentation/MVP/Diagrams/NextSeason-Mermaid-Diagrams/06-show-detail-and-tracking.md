# 06 — Show Detail and Tracking

```mermaid
flowchart TD
    Detail[ShowDetailView] --> VM[ShowDetailViewModel]
    VM --> TVMaze[TVMazeService]
    VM --> Repo[WatchlistRepository]
    TVMaze --> Domain[Show domain model]
    Domain --> Calculator[NextSeasonCalculator]
    Calculator --> Status[NextSeasonStatus]
    Detail --> CTA{Tracked?}
    CTA -->|No| Add[Add to Watchlist]
    CTA -->|Yes| Remove[Remove from Watchlist]
    Add --> RepoAdd[repository.add(show)]
    Remove --> Undo[WatchlistUndoRemoval]
    Undo --> Pending[Pending removal toast]
    Pending -->|Undo| Restore[Cancel removal]
    Pending -->|Confirm / timeout| RepoRemove[repository.remove(id)]
    RepoAdd --> NotifyChange[onWatchlistChanged]
    RepoRemove --> NotifyChange
    NotifyChange --> Coordinator[AppNavigationCoordinator]
```
