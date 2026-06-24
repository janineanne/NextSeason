# Architecture Decision Context

```mermaid
flowchart TD
    Goal[Goal: useful MVP for tracking TV show seasons]

    Goal --> KeepSmall[Keep MVP small]
    Goal --> ProveValue[Prove core product value]
    Goal --> Portfolio[Support portfolio story]

    KeepSmall --> NoLogin[No login in MVP]
    KeepSmall --> LocalWatchlist[Local watchlist only]
    KeepSmall --> OneDataSource[Use one primary data source: TVMaze]

    ProveValue --> Search[Search for shows]
    ProveValue --> Save[Save shows]
    ProveValue --> Calculate[Calculate next-season status]

    Portfolio --> Docs[Strong documentation]
    Portfolio --> Diagrams[Architecture diagrams]
    Portfolio --> Decisions[Visible decision log]

    NoLogin --> FutureAccounts[Accounts deferred]
    LocalWatchlist --> FutureSync[Sync deferred]
    Calculate --> LocalNotifications[Local notifications in MVP]
    LocalNotifications --> FuturePush[Push/cloud notifications deferred]
```

## Purpose

This diagram captures why the MVP is shaped the way it is.

The key decision is not that accounts, sync, or push notifications are unimportant.
It is that they should come after the app proves the basic watchlist and
season-status experience. **Local notifications** are part of the MVP; **push
and cloud-delivered notifications** remain post-MVP.
