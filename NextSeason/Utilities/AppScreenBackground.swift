//
//  AppScreenBackground.swift
//  NextSeason
//

import SwiftUI

extension View {
    /// Lavender-gray screen fill (`AppBackground` in the asset catalog).
    func appScreenBackground() -> some View {
        background(Color.appBackground.ignoresSafeArea())
    }

    /// Matches navigation bars to the app screen background.
    func appNavigationChrome() -> some View {
        toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
    }

    /// Plain list on the app background instead of system white/black.
    func appPlainListStyle() -> some View {
        listStyle(.plain)
            .scrollContentBackground(.hidden)
    }

    /// Inset card row on `AppSurface` (replaces stark system list row backgrounds).
    func appListRowSurface() -> some View {
        listRowInsets(EdgeInsets(top: 4, leading: AppSpacing.screen, bottom: 4, trailing: AppSpacing.screen))
            .listRowSeparator(.hidden)
            .listRowBackground(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.appSurface)
            )
    }

    /// Rounded surface for insets and cards outside lists.
    func appSurfaceCard(cornerRadius: CGFloat = 12) -> some View {
        background(Color.appSurface, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    /// Surface card used inside lists (clear row chrome, inset card content).
    func appInsetSurfaceCard() -> some View {
        padding(AppSpacing.row)
            .appSurfaceCard()
            .listRowInsets(EdgeInsets(top: 8, leading: AppSpacing.screen, bottom: 8, trailing: AppSpacing.screen))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }

    /// Titles, show names, and section headers (accent purple).
    func appPrimaryText() -> some View {
        foregroundStyle(Color.accentColor)
    }

    /// Metadata lines: genres, timestamps, supporting descriptions.
    func appSecondaryText() -> some View {
        foregroundStyle(Color.appMutedText)
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
}
#endif
