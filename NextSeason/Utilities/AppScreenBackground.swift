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

    /// Inset card row on the app surface (replaces stark system list row backgrounds).
    func appListRowSurface() -> some View {
        modifier(AppListRowSurfaceModifier())
    }

    /// Rounded surface for insets and cards outside lists.
    func appSurfaceCard(cornerRadius: CGFloat = 12) -> some View {
        modifier(AppSurfaceCardModifier(cornerRadius: cornerRadius))
    }

    /// Surface card used inside lists (clear row chrome, inset card content).
    func appInsetSurfaceCard() -> some View {
        padding(AppSpacing.row)
            .appSurfaceCard()
            .listRowInsets(EdgeInsets(top: 8, leading: AppSpacing.screen, bottom: 8, trailing: AppSpacing.screen))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
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

private struct AppListRowSurfaceModifier: ViewModifier {
    @Environment(\.appThemeColors) private var colors

    func body(content: Content) -> some View {
        content
            .listRowInsets(EdgeInsets(top: 4, leading: AppSpacing.screen, bottom: 4, trailing: AppSpacing.screen))
            .listRowSeparator(.hidden)
            .listRowBackground(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(colors.surface)
            )
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
