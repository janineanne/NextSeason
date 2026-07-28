//
//  AppColors.swift
//  NextSeason
//

import SwiftUI

/// Typed accessors for semantic colors in `Assets.xcassets`.
enum AppColor {
    static let background = Color("AppBackground")
    static let surface = Color("AppSurface")
    static let accent = Color("AccentColor")
    static let trackedStar = Color("TrackedStar")
    static let untrackedStar = Color("UntrackedStar")
    static let warning = Color("Warning")
}

extension View {
    /// Applies the app accent to tab bars, toolbar controls, and tinted buttons.
    func appAccentTint() -> some View {
        tint(AppColor.accent)
    }
}
