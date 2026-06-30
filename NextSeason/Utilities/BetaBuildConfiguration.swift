//
//  BetaBuildConfiguration.swift
//  NextSeason
//

import Foundation

/// Identifies builds where beta diagnostics are allowed (DEBUG or TestFlight).
/// App Store production builds always return `false`.
enum BetaBuildConfiguration {
    static var isAvailable: Bool {
        #if DEBUG
        return true
        #else
        return isTestFlightBuild
        #endif
    }

    private static var isTestFlightBuild: Bool {
        guard let receiptURL = Bundle.main.appStoreReceiptURL else { return false }
        return receiptURL.lastPathComponent == "sandboxReceipt"
    }
}
