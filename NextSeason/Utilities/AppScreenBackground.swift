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

    /// Titles, show names, and section headers.
    func appPrimaryText() -> some View {
        modifier(AppPrimaryTextModifier())
    }

    /// Metadata lines: genres, timestamps, supporting descriptions.
    func appSecondaryText() -> some View {
        modifier(AppSecondaryTextModifier())
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

private struct AppPrimaryTextModifier: ViewModifier {
    @Environment(\.appThemeColors) private var colors

    func body(content: Content) -> some View {
        content.foregroundStyle(colors.accent)
    }
}

private struct AppSecondaryTextModifier: ViewModifier {
    @Environment(\.appThemeColors) private var colors

    func body(content: Content) -> some View {
        content.foregroundStyle(colors.mutedText)
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
