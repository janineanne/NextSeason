//
//  NextSeasonStatus+Codable.swift
//  NextSeason
//

import Foundation

nonisolated extension NextSeasonStatus: Codable {
    private enum CodingKeys: String, CodingKey {
        case kind, season, premiere
    }

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
