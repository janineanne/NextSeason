//
//  AppThemeEnvironment.swift
//  NextSeason
//

import SwiftUI

private struct AppThemeColorsKey: EnvironmentKey {
    static let defaultValue = AppThemeColors.colors(for: .light)
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

    /// Applies the active palette tint to buttons, links, and other controls.
    func appControlTint() -> some View {
        modifier(AppControlTintModifier())
    }

    /// Applies the app palette for SwiftUI previews without a theme controller.
    func appThemePreview() -> some View {
        modifier(AppThemePreviewModifier())
    }
}

private struct AppControlTintModifier: ViewModifier {
    @Environment(\.appThemeColors) private var colors

    func body(content: Content) -> some View {
        content.tint(colors.controlTint)
    }
}

private struct AppThemePreviewModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .environment(\.appThemeColors, AppThemeColors.colors(for: colorScheme))
    }
}
