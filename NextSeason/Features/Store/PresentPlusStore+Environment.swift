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
    var presentPlusStore: (() -> Void)? {
        get { self[PresentPlusStoreKey.self] }
        set { self[PresentPlusStoreKey.self] = newValue }
    }
}
