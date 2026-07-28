//
//  AppScreenBackground.swift
//  NextSeason
//

import SwiftUI

extension View {
    /// Screen fill from the app color asset.
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

    /// Headings and labels that use the system primary style for glass and accessibility.
    func appPrimaryText() -> some View {
        foregroundStyle(.primary)
    }

    /// Show names and other branded emphasis text.
    func appAccentText() -> some View {
        foregroundStyle(AppColor.accent)
    }

    /// Status lines, metadata, and supporting descriptions.
    func appSecondaryText() -> some View {
        foregroundStyle(.secondary)
    }
}

private struct AppScreenBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.background(AppColor.background.ignoresSafeArea())
    }
}

private struct AppSurfaceCardModifier: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content.background(AppColor.surface, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
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
