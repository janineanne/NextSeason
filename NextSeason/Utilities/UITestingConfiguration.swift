//
//  UITestingConfiguration.swift
//  NextSeason
//

import Foundation
import SwiftUI

/// Launch-argument helpers for XCUITest runs (`-UITesting`).
enum UITestingConfiguration {
    static let launchArgument = UITestingLaunchArgument.uiTesting

    static var isEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains(launchArgument)
    }

    /// Sentinel search queries — see `UITestingSearchQuery` in NextSeasonShared.
    typealias SearchQuery = UITestingSearchQuery
}

extension View {
    /// Collapses a view into one labeled accessibility element for XCUITest.
    func uiTestMarker(_ identifier: String, label: String) -> some View {
        accessibilityElement(children: .ignore)
            .accessibilityLabel(label)
            .accessibilityIdentifier(identifier)
    }

    /// VoiceOver hint for list rows that push show detail.
    func showDetailLinkAccessibility() -> some View {
        accessibilityHint("Opens show details")
    }
}
