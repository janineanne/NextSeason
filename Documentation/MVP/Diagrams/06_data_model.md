# Current Data Model

```mermaid
classDiagram
    class Show {
        +Int id
        +String name
        +String? summaryHTML
        +URL? posterMediumURL
        +URL? tvMazeURL
        +ShowStatus status
        +Date updatedAt
        +[Season] seasons
        +NextEpisode? nextEpisode
    }

    class Season {
        +Int id
        +Int number
        +String? name
        +Date? premiereDate
        +Date? endDate
        +Int? episodeOrder
    }

    class NextEpisode {
        +Int id
        +String? name
        +Int season
        +Int number
        +Date? airDate
    }

    class NextSeasonStatus {
        <<enum>>
        announced
        scheduled
        available
        ended
        unknown
    }

    class TrackedShow {
        +Int id
        +String name
        +URL? posterMediumURL
        +String? summaryHTML
        +URL? tvMazeURL
        +ShowStatus status
        +NextSeasonStatus nextSeason
        +Date sourceUpdatedAt
        +Date lastCheckedAt
        +String? lastNotifiedSignature
        +String? pendingChangeSignature
        +Bool isStale
        +Date dateAdded
    }

    class TrackedShowEntity {
        +Int tvMazeID unique
        +String name
        +URL? posterMediumURL
        +String? summaryHTML
        +URL? tvMazeURL
        +String statusRaw
        +Data nextSeasonSnapshot
        +Date sourceUpdatedAt
        +Date lastCheckedAt
        +String? lastNotifiedSignature
        +String? pendingChangeSignature
        +Bool isStale
        +Date dateAdded
    }

    class ShowData {
        <<DTO>>
        +Int id
        +String name
        +ImageData? image
        +NetworkData? network
        +EmbeddedData? embedded
    }

    class SeasonData {
        <<DTO>>
    }

    class NextEpisodeData {
        <<DTO>>
    }

    Show "1" --> "many" Season
    Show "1" --> "0..1" NextEpisode
    Show --> NextSeasonStatus : calculated from
    Show --> TrackedShow : converted when tracked
    TrackedShowEntity --> TrackedShow : decodes to domain
    TrackedShow --> TrackedShowEntity : encodes to persistence
    ShowData --> Show : maps to domain
    SeasonData --> Season : maps to domain
    NextEpisodeData --> NextEpisode : maps to domain
```

## Notes

`TrackedShowEntity` stores `NextSeasonStatus` as encoded data. This keeps the persisted watchlist compact, but future schema changes should be covered by a SwiftData migration plan and migration testing.
