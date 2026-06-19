# NextSeason MVP System Architecture

```mermaid
flowchart TB
    User[User]

    subgraph App[NextSeason iOS App]
        UI[SwiftUI Views]
        VM[View Models / UI State]
        Search[Show Search Feature]
        Watchlist[Local Watchlist Feature]
        Calculator[Next Season Calculator]
        Persistence[Local Persistence]
        Models[Domain Models]
    end

    subgraph External[External Services]
        TVMaze[TVMaze API]
    end

    User --> UI
    UI --> VM
    VM --> Search
    VM --> Watchlist
    VM --> Calculator

    Search --> TVMaze
    TVMaze --> Search

    Search --> Models
    Watchlist --> Models
    Calculator --> Models

    Watchlist --> Persistence
    Persistence --> Watchlist

    Calculator --> UI
    Watchlist --> UI
    Search --> UI
```

## Purpose

This diagram shows the MVP as a local-first iOS app.

The app fetches show data from TVMaze, lets the user maintain a local watchlist, and uses local calculation logic to present useful season-status information. There is no account system or backend in the MVP.
