//
//  AppThemeController.swift
//  NextSeason
//

import SwiftUI

@MainActor
@Observable
final class AppThemeController {
    static let preview = AppThemeController()

    func colors(for colorScheme: ColorScheme) -> AppThemeColors {
        AppThemeColors.colors(for: colorScheme)
    }
}
