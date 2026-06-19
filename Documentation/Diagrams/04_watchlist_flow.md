# Watchlist Flow

```mermaid
flowchart TD
    Results[Search results]
    Detail[Show detail / selected show]
    Add[User taps Add to Watchlist]
    Normalize[Convert API show into local watchlist model]
    Store[Persist locally]
    Watchlist[Watchlist screen]
    Status[Display saved show and calculated status]

    Results --> Detail
    Detail --> Add
    Add --> Normalize
    Normalize --> Store
    Store --> Watchlist
    Watchlist --> Status

    Watchlist --> Remove[User removes show]
    Remove --> Delete[Delete from local persistence]
    Delete --> Watchlist
```

## Purpose

This diagram shows that the watchlist is local MVP state.

There is no sync, no login, and no account-owned watchlist yet. That keeps the MVP smaller and makes the app testable without backend infrastructure.
