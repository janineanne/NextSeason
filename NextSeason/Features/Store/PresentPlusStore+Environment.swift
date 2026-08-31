//
//  PresentPlusStore+Environment.swift
//  NextSeason
//

import SwiftUI

private struct PresentPlusStoreKey: EnvironmentKey {
    static let defaultValue: (() -> Void)? = nil
}

extension EnvironmentValues {
    /// Presents the NextSeason Plus purchase sheet from Search, Show Detail, or About.
    ///
    /// Set by the root tab host; `nil` means presentation is unavailable
    /// (previews or tests that omit the wiring).
    var presentPlusStore: (() -> Void)? {
        get { self[PresentPlusStoreKey.self] }
        set { self[PresentPlusStoreKey.self] = newValue }
    }
}
