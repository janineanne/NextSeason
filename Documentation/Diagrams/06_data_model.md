# Conceptual Data Model

```mermaid
classDiagram
    class Show {
        +id
        +name
        +summary
        +imageURL
        +status
        +premiered
        +ended
    }

    class Episode {
        +id
        +name
        +season
        +number
        +airdate
    }

    class WatchlistItem {
        +showID
        +showName
        +imageURL
        +updatedAt
        +notes/status fields
    }

    class SeasonStatus {
        +state
        +message
        +lastKnownSeason
        +lastKnownAirdate
    }

    class TVMazeClient {
        +searchShows(query)
        +fetchEpisodes(showID)
    }

    class WatchlistStore {
        +items
        +add(show)
        +remove(showID)
        +load()
        +save()
    }

    class NextSeasonCalculator {
        +calculate(show, episodes)
    }

    Show "1" --> "many" Episode
    Show "1" --> "0..1" WatchlistItem
    WatchlistStore --> WatchlistItem
    TVMazeClient --> Show
    TVMazeClient --> Episode
    NextSeasonCalculator --> Show
    NextSeasonCalculator --> Episode
    NextSeasonCalculator --> SeasonStatus
```

## Purpose

This is a conceptual model, not necessarily a one-to-one copy of Swift files.

It shows the main things the app knows about:

- Shows from TVMaze
- Episodes/seasons from TVMaze
- Locally saved watchlist items
- Calculated season status
