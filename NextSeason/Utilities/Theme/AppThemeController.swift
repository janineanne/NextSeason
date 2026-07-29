//
//  AppThemeController.swift
//  NextSeason
//

import SwiftUI

@MainActor
@Observable
final class AppThemeController {
    static let preview = AppThemeController()

    private static let storageKey = "appPaletteVariant"

    var variant: AppPaletteVariant {
        didSet {
            // Persistence kept for when the theme switcher is re-enabled
            // (see ThemeSwitcherView.swift status comment).
            UserDefaults.standard.set(variant.rawValue, forKey: Self.storageKey)
        }
    }

    init(variant: AppPaletteVariant = .tealUtility) {
        // Theme switcher is parked; lock the app to tealUtility until it returns.
        // Previously restored the last selection from UserDefaults:
        // if let raw = UserDefaults.standard.string(forKey: Self.storageKey),
        //    let saved = AppPaletteVariant(rawValue: raw) {
        //     self.variant = saved
        // } else {
        //     self.variant = variant
        // }
        self.variant = variant
    }

    func colors(for colorScheme: ColorScheme) -> AppThemeColors {
        AppThemeColors.colors(for: variant, colorScheme: colorScheme)
    }
}
