//
//  AppThemeIconService.swift
//  NextSeason
//

import SwiftUI
import UIKit

/// Maps the active palette to an alternate app icon for theme preview builds.
///
/// Light/dark artwork lives inside each icon set as appearance variants (see the
/// `Assets.xcassets/AppIcon*` sets), so iOS swaps the light/dark rendering
/// automatically. We only call `setAlternateIconName` when the user deliberately
/// changes the palette — never on a system light/dark change, which previously
/// triggered the "You have changed the icon" alert on every appearance switch.
@MainActor
enum AppThemeIconService {
    /// `nil` selects the primary icon (`AppIcon`, the Lavender palette).
    static func alternateIconName(for variant: AppPaletteVariant) -> String? {
        switch variant {
        case .lavender:
            nil
        case .tealUtility:
            "AppIcon-TealUtility"
        case .warmSlate:
            "AppIcon-WarmSlate"
        }
    }

    static func syncIcon(variant: AppPaletteVariant) {
        guard !UITestingConfiguration.isEnabled else { return }
        guard UIApplication.shared.supportsAlternateIcons else { return }

        let desiredName = alternateIconName(for: variant)
        guard !matchesCurrentIcon(desiredName) else { return }

        UIApplication.shared.setAlternateIconName(desiredName) { error in
            if let error {
                #if DEBUG
                print("AppThemeIconService: failed to set alternate icon: \(error.localizedDescription)")
                #endif
            }
        }
    }

    private static func matchesCurrentIcon(_ desiredName: String?) -> Bool {
        let current = UIApplication.shared.alternateIconName

        if desiredName == nil {
            return current == nil || current == "AppIcon"
        }

        return desiredName == current
    }
}

private struct AppThemeIconUpdater: ViewModifier {
    var controller: AppThemeController

    func body(content: Content) -> some View {
        content
            .onAppear {
                AppThemeIconService.syncIcon(variant: controller.variant)
            }
            .onChange(of: controller.variant) { _, variant in
                AppThemeIconService.syncIcon(variant: variant)
            }
    }
}

extension View {
    /// Keeps the home-screen icon aligned with the active palette preview.
    func appThemeIcon(from controller: AppThemeController) -> some View {
        modifier(AppThemeIconUpdater(controller: controller))
    }
}
