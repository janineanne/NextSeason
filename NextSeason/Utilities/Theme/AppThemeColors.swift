//
//  AppThemeColors.swift
//  NextSeason
//

import SwiftUI

/// Resolved app colors for the current color scheme.
struct AppThemeColors: Equatable, Sendable {
    let background: Color
    let surface: Color
    /// Titles, show names, and section headers.
    let accent: Color
    /// Tab bar tint and prominent buttons (may differ from `accent` when text needs a lighter dark-mode color).
    let controlTint: Color
    let mutedText: Color
    let trackedStar: Color
    /// Empty watchlist star — neutral grey, independent of palette accent.
    let untrackedStar: Color
    let warning: Color

    static func colors(for colorScheme: ColorScheme) -> AppThemeColors {
        switch colorScheme {
        case .dark:
            dark
        default:
            light
        }
    }
}

private extension AppThemeColors {
    static let untrackedStarLight = Color(white: 0.24)
    static let untrackedStarDark = Color(white: 0.83)

    static let light = AppThemeColors(
        background: Color(red: 0.941, green: 0.949, blue: 0.945),
        surface: Color(red: 0.980, green: 0.984, blue: 0.980),
        accent: Color(red: 0.051, green: 0.420, blue: 0.388),
        controlTint: Color(red: 0.051, green: 0.420, blue: 0.388),
        mutedText: Color(red: 0.361, green: 0.400, blue: 0.439),
        trackedStar: Color(red: 0.918, green: 0.639, blue: 0.090),
        untrackedStar: untrackedStarLight,
        warning: Color(red: 0.851, green: 0.451, blue: 0.000)
    )

    static let dark = AppThemeColors(
        background: Color(red: 0.102, green: 0.114, blue: 0.110),
        surface: Color(red: 0.149, green: 0.161, blue: 0.157),
        accent: Color(red: 0.431, green: 0.792, blue: 0.737),
        controlTint: Color(red: 0.431, green: 0.792, blue: 0.737),
        mutedText: Color(red: 0.659, green: 0.690, blue: 0.722),
        trackedStar: Color(red: 1.000, green: 0.839, blue: 0.337),
        untrackedStar: untrackedStarDark,
        warning: Color(red: 1.000, green: 0.584, blue: 0.235)
    )
}
