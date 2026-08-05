//
//  NextSeasonStatus+Codable.swift
//  NextSeason
//

import Foundation

/// Codable storage for `NextSeasonStatus` on `TrackedShowEntity`.
///
/// Uses a keyed `kind` discriminator (not enum case order) so adding cases later
/// does not break decoding of previously persisted values. Associated values
/// (`season`, `premiere`) are optional keys present only when that kind needs them.
nonisolated extension NextSeasonStatus: Codable {
    private enum CodingKeys: String, CodingKey {
        case kind, season, premiere
    }

    /// Stable string tags written to disk; rename only with a migration plan.
    private enum Kind: String, Codable {
        case airing, scheduled, announcedUndated, returningNoSeasonYet, ended, unknown
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(Kind.self, forKey: .kind) {
        case .airing:
            self = .airing(season: try container.decode(Int.self, forKey: .season))
        case .scheduled:
            self = .scheduled(
                season: try container.decode(Int.self, forKey: .season),
                premiere: try container.decode(Date.self, forKey: .premiere)
            )
        case .announcedUndated:
            self = .announcedUndated(season: try container.decode(Int.self, forKey: .season))
        case .returningNoSeasonYet:
            self = .returningNoSeasonYet
        case .ended:
            self = .ended
        case .unknown:
            self = .unknown
        }
    }

    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .airing(let season):
            try container.encode(Kind.airing, forKey: .kind)
            try container.encode(season, forKey: .season)
        case .scheduled(let season, let premiere):
            try container.encode(Kind.scheduled, forKey: .kind)
            try container.encode(season, forKey: .season)
            try container.encode(premiere, forKey: .premiere)
        case .announcedUndated(let season):
            try container.encode(Kind.announcedUndated, forKey: .kind)
            try container.encode(season, forKey: .season)
        case .returningNoSeasonYet:
            try container.encode(Kind.returningNoSeasonYet, forKey: .kind)
        case .ended:
            try container.encode(Kind.ended, forKey: .kind)
        case .unknown:
            try container.encode(Kind.unknown, forKey: .kind)
        }
    }
}

extension ShowStatus {
    /// TVMaze's exact status string for SwiftData (`statusRaw`). Distinct from
    /// `displayLabel`, which is user-facing copy. `.unknown` round-trips the
    /// original API value unchanged.
    nonisolated var persistenceRawValue: String {
        switch self {
        case .running: "Running"
        case .ended: "Ended"
        case .toBeDetermined: "To Be Determined"
        case .inDevelopment: "In Development"
        case .unknown(let value): value
        }
    }
}
