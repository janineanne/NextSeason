//
//  AppThemeEnvironment.swift
//  NextSeason
//

import SwiftUI

private struct AppThemeColorsKey: EnvironmentKey {
    static let defaultValue = AppThemeColors.colors(for: .lavender, colorScheme: .light)
}

extension EnvironmentValues {
    var appThemeColors: AppThemeColors {
        get { self[AppThemeColorsKey.self] }
        set { self[AppThemeColorsKey.self] = newValue }
    }
}

private struct AppThemeColorsModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    var controller: AppThemeController

    func body(content: Content) -> some View {
        content
            .environment(\.appThemeColors, controller.colors(for: colorScheme))
    }
}

extension View {
    /// Publishes the active palette into the environment for child views.
    func appThemeColors(from controller: AppThemeController) -> some View {
        modifier(AppThemeColorsModifier(controller: controller))
    }

    /// Applies a palette for SwiftUI previews without a theme controller.
    func appThemePreview(_ variant: AppPaletteVariant = .lavender) -> some View {
        modifier(AppThemePreviewModifier(variant: variant))
    }
}

private struct AppThemePreviewModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    let variant: AppPaletteVariant

    func body(content: Content) -> some View {
        content
            .environment(\.appThemeColors, AppThemeColors.colors(for: variant, colorScheme: colorScheme))
    }
}
