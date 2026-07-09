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
            UserDefaults.standard.set(variant.rawValue, forKey: Self.storageKey)
        }
    }

    init(variant: AppPaletteVariant = .warmSlate) {
        if let raw = UserDefaults.standard.string(forKey: Self.storageKey),
           let saved = AppPaletteVariant(rawValue: raw) {
            self.variant = saved
        } else {
            self.variant = variant
        }
    }

    func colors(for colorScheme: ColorScheme) -> AppThemeColors {
        AppThemeColors.colors(for: variant, colorScheme: colorScheme)
    }
}
