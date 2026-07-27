//
//  AppScreenBackground.swift
//  NextSeason
//

import SwiftUI

extension View {
    /// Screen fill from the active app palette.
    func appScreenBackground() -> some View {
        modifier(AppScreenBackgroundModifier())
    }

    /// Plain list on the app background instead of system white/black.
    func appPlainListStyle() -> some View {
        listStyle(.plain)
            .scrollContentBackground(.hidden)
    }

    /// Rounded surface for distinct callouts and detail sections (not list rows).
    func appSurfaceCard(cornerRadius: CGFloat = 12) -> some View {
        modifier(AppSurfaceCardModifier(cornerRadius: cornerRadius))
    }

    /// Show names, section headings, and other primary content labels.
    /// Uses the system primary style so content adapts to glass, contrast, and accessibility.
    func appPrimaryText() -> some View {
        foregroundStyle(.primary)
    }

    /// Status lines, metadata, and supporting descriptions.
    func appSecondaryText() -> some View {
        foregroundStyle(.secondary)
    }
}

private struct AppScreenBackgroundModifier: ViewModifier {
    @Environment(\.appThemeColors) private var colors

    func body(content: Content) -> some View {
        content.background(colors.background.ignoresSafeArea())
    }
}

private struct AppSurfaceCardModifier: ViewModifier {
    @Environment(\.appThemeColors) private var colors

    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content.background(colors.surface, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

#if DEBUG
#Preview("Surface card") {
    VStack(spacing: 16) {
        Text("Next Season")
            .font(.headline)
        Text("Season 2 premieres Jan 1, 2027")
    }
    .padding()
    .appSurfaceCard()
    .padding()
    .appScreenBackground()
    .appThemePreview()
}
#endif
