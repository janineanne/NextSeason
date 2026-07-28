//
//  AppThemeColors.swift
//  NextSeason
//

import SwiftUI

/// Resolved app colors for the current palette and color scheme.
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

    static func colors(for variant: AppPaletteVariant, colorScheme: ColorScheme) -> AppThemeColors {
        switch (variant, colorScheme) {
        case (.lavender, .light):
            lavenderLight
        case (.lavender, .dark):
            lavenderDark
        case (.tealUtility, .light):
            tealUtilityLight
        case (.tealUtility, .dark):
            tealUtilityDark
        case (.warmSlate, .light):
            warmSlateLight
        case (.warmSlate, .dark):
            warmSlateDark
        @unknown default:
            tealUtilityLight
        }
    }
}

private extension AppThemeColors {
    static let untrackedStarLight = Color(white: 0.24)
    static let untrackedStarDark = Color(white: 0.83)

    static let lavenderLight = AppThemeColors(
        background: Color(red: 0.902, green: 0.886, blue: 0.933),
        surface: Color(red: 0.973, green: 0.969, blue: 0.988),
        accent: Color(red: 0.365, green: 0.306, blue: 0.443),
        controlTint: Color(red: 0.365, green: 0.306, blue: 0.443),
        mutedText: Color(red: 0.431, green: 0.416, blue: 0.482),
        trackedStar: Color(red: 0.918, green: 0.639, blue: 0.090),
        untrackedStar: untrackedStarLight,
        warning: Color(red: 0.851, green: 0.451, blue: 0.000)
    )

    static let lavenderDark = AppThemeColors(
        background: Color(red: 0.149, green: 0.129, blue: 0.196),
        surface: Color(red: 0.224, green: 0.208, blue: 0.282),
        accent: Color(red: 0.659, green: 0.596, blue: 0.769),
        controlTint: Color(red: 0.659, green: 0.596, blue: 0.769),
        mutedText: Color(red: 0.792, green: 0.776, blue: 0.816),
        trackedStar: Color(red: 1.000, green: 0.839, blue: 0.337),
        untrackedStar: untrackedStarDark,
        warning: Color(red: 1.000, green: 0.584, blue: 0.235)
    )

    static let tealUtilityLight = AppThemeColors(
        background: Color(red: 0.941, green: 0.949, blue: 0.945),
        surface: Color(red: 0.980, green: 0.984, blue: 0.980),
        accent: Color(red: 0.051, green: 0.420, blue: 0.388),
        controlTint: Color(red: 0.051, green: 0.420, blue: 0.388),
        mutedText: Color(red: 0.361, green: 0.400, blue: 0.439),
        trackedStar: Color(red: 0.918, green: 0.639, blue: 0.090),
        untrackedStar: untrackedStarLight,
        warning: Color(red: 0.851, green: 0.451, blue: 0.000)
    )

    static let tealUtilityDark = AppThemeColors(
        background: Color(red: 0.102, green: 0.114, blue: 0.110),
        surface: Color(red: 0.149, green: 0.161, blue: 0.157),
        accent: Color(red: 0.431, green: 0.792, blue: 0.737),
        controlTint: Color(red: 0.431, green: 0.792, blue: 0.737),
        mutedText: Color(red: 0.659, green: 0.690, blue: 0.722),
        trackedStar: Color(red: 1.000, green: 0.839, blue: 0.337),
        untrackedStar: untrackedStarDark,
        warning: Color(red: 1.000, green: 0.584, blue: 0.235)
    )

    static let warmSlateLight = AppThemeColors(
        background: Color(red: 0.969, green: 0.961, blue: 0.949),
        surface: Color(red: 1.000, green: 1.000, blue: 0.996),
        accent: Color(red: 0.200, green: 0.255, blue: 0.333),
        controlTint: Color(red: 0.200, green: 0.255, blue: 0.333),
        mutedText: Color(red: 0.392, green: 0.455, blue: 0.545),
        trackedStar: Color(red: 0.918, green: 0.639, blue: 0.090),
        untrackedStar: untrackedStarLight,
        warning: Color(red: 0.851, green: 0.451, blue: 0.000)
    )

    static let warmSlateDark = AppThemeColors(
        background: Color(red: 0.110, green: 0.098, blue: 0.090),
        surface: Color(red: 0.161, green: 0.145, blue: 0.141),
        accent: Color(red: 0.796, green: 0.835, blue: 0.882),
        // Dark palettes use a light control tint so nav-bar/tab-bar controls stay
        // legible on the dark background (the light-mode slate was invisible here).
        controlTint: Color(red: 0.796, green: 0.835, blue: 0.882),
        mutedText: Color(red: 0.659, green: 0.635, blue: 0.620),
        trackedStar: Color(red: 1.000, green: 0.839, blue: 0.337),
        untrackedStar: untrackedStarDark,
        warning: Color(red: 1.000, green: 0.584, blue: 0.235)
    )
}
