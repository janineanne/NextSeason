//
//  AppThemeIconService.swift
//  NextSeason
//

import SwiftUI
import UIKit

/// Maps the active palette and color scheme to alternate app icon names for theme preview builds.
@MainActor
enum AppThemeIconService {
    /// `nil` selects the primary icon (`AppIcon`, lavender light).
    static func alternateIconName(for variant: AppPaletteVariant, colorScheme: ColorScheme) -> String? {
        switch (variant, colorScheme) {
        case (.lavender, .light):
            nil
        case (.lavender, .dark):
            "LavenderDark"
        case (.tealUtility, .light):
            "TealUtilityLight"
        case (.tealUtility, .dark):
            "TealUtilityDark"
        case (.warmSlate, .light):
            "WarmSlateLight"
        case (.warmSlate, .dark):
            "WarmSlateDark"
        @unknown default:
            nil
        }
    }

    static func syncIcon(variant: AppPaletteVariant, colorScheme: ColorScheme) {
        guard !UITestingConfiguration.isEnabled else { return }
        guard UIApplication.shared.supportsAlternateIcons else { return }

        let desiredName = alternateIconName(for: variant, colorScheme: colorScheme)
        guard !matchesCurrentIcon(desiredName) else { return }

        UIApplication.shared.setAlternateIconName(desiredName) { error in
            if let error {
                #if DEBUG
                print("AppThemeIconService: failed to set alternate icon: \(error.localizedDescription)")
                #endif
            }
        }
    }

    /// Re-reads the system appearance after returning from Settings, then updates the icon.
    static func syncIconAfterForegroundReturn(variant: AppPaletteVariant, fallback colorScheme: ColorScheme) {
        let scheme = resolvedSystemColorScheme(fallback: colorScheme)
        syncIcon(variant: variant, colorScheme: scheme)
    }

    /// iOS may report the asset-catalog name (`AppIcon-TealUtilityLight`) while we request the
    /// Info.plist key (`TealUtilityLight`). Treat those as equivalent.
    private static func matchesCurrentIcon(_ desiredName: String?) -> Bool {
        let current = UIApplication.shared.alternateIconName

        if desiredName == current {
            return true
        }

        if desiredName == nil {
            return current == nil || current == "AppIcon"
        }

        guard let desiredName, let current else {
            return false
        }

        return current == "AppIcon-\(desiredName)"
    }

    private static func resolvedSystemColorScheme(fallback: ColorScheme) -> ColorScheme {
        let style = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive || $0.activationState == .foregroundInactive }?
            .traitCollection.userInterfaceStyle
            ?? UITraitCollection.current.userInterfaceStyle

        switch style {
        case .dark:
            return .dark
        case .light:
            return .light
        case .unspecified:
            return fallback
        @unknown default:
            return fallback
        }
    }
}

private struct AppThemeIconUpdater: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase

    var controller: AppThemeController

    func body(content: Content) -> some View {
        content
            .onAppear {
                AppThemeIconService.syncIconAfterForegroundReturn(
                    variant: controller.variant,
                    fallback: colorScheme
                )
            }
            .onChange(of: controller.variant) { _, _ in
                AppThemeIconService.syncIcon(
                    variant: controller.variant,
                    colorScheme: colorScheme
                )
            }
            .onChange(of: colorScheme) { _, scheme in
                AppThemeIconService.syncIcon(
                    variant: controller.variant,
                    colorScheme: scheme
                )
            }
            .onChange(of: scenePhase) { _, phase in
                guard phase == .active else { return }
                AppThemeIconService.syncIconAfterForegroundReturn(
                    variant: controller.variant,
                    fallback: colorScheme
                )
            }
    }
}

extension View {
    /// Keeps the home-screen icon aligned with the active palette preview.
    func appThemeIcon(from controller: AppThemeController) -> some View {
        modifier(AppThemeIconUpdater(controller: controller))
    }
}
