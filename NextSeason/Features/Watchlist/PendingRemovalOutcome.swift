//
//  PendingRemovalOutcome.swift
//  NextSeason
//

import Foundation

/// Terminal or significant transitions for the single pending watchlist removal.
///
/// Callers should react to these outcomes instead of inferring undo vs. commit
/// from `pendingRemoval` clearing or by querying persistence.
enum PendingRemovalOutcome: Equatable {
    /// Deferred removal was persisted, or an immediate removal finished persisting.
    case committed(showID: Int)
    /// User restored the show (deferred cancel or immediate undo-after-delete).
    case undone(showID: Int)
    /// Deferred removal was cancelled without persisting (e.g. navigating to Show Detail).
    case cancelled(showID: Int)
    /// A new pending removal committed this show before its undo window ended.
    case replaced(showID: Int)
    /// Persistence failed after the undo window ended or during immediate delete.
    case failed(showID: Int)
}
