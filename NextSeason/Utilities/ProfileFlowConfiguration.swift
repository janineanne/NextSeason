//
//  ProfileFlowConfiguration.swift
//  NextSeason
//

import Foundation

/// Launch-argument helpers for Instruments profiling on device (`-ProfileFlow <name>`).
enum ProfileFlowConfiguration {
    static let launchFlag = "-ProfileFlow"

    enum Flow: String, CaseIterable {
        case search
        case showDetails
        case viewWishlist
        case addToWishlist
        case removeFromWishlist
    }

    static var activeFlow: Flow? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: launchFlag),
              index + 1 < arguments.count
        else { return nil }
        return Flow(rawValue: arguments[index + 1])
    }

    static var isEnabled: Bool { activeFlow != nil }
}
