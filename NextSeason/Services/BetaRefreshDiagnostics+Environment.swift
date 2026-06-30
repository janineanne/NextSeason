//
//  BetaRefreshDiagnostics+Environment.swift
//  NextSeason
//

import SwiftUI

private struct BetaRefreshDiagnosticsKey: EnvironmentKey {
    @MainActor static let defaultValue: BetaRefreshDiagnostics? = nil
}

extension EnvironmentValues {
    @MainActor var betaRefreshDiagnostics: BetaRefreshDiagnostics? {
        get { self[BetaRefreshDiagnosticsKey.self] }
        set { self[BetaRefreshDiagnosticsKey.self] = newValue }
    }
}
