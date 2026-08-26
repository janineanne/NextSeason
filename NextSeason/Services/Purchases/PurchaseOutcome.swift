//
//  PurchaseOutcome.swift
//  NextSeason
//

import Foundation

/// Result of a StoreKit purchase or restore attempt, mapped for UI handling.
nonisolated enum PurchaseOutcome: Equatable, Sendable {
    case success
    case cancelled
    case pending
    case failed(String)
}

nonisolated enum PurchaseError: LocalizedError, Equatable {
    case productUnavailable
    case unverified

    var errorDescription: String? {
        switch self {
        case .productUnavailable:
            String(localized: "That purchase option is not available right now.")
        case .unverified:
            String(localized: "NextSeason couldn't verify this purchase. Please try again.")
        }
    }
}
