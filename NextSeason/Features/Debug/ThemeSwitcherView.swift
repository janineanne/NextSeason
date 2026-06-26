//
//  ThemeSwitcherView.swift
//  NextSeason
//

import SwiftUI

/// Palette picker for beta feedback on color directions.
struct ThemeSwitcherView: View {
    @Environment(AppThemeController.self) private var themeController
    @Environment(\.appThemeColors) private var themeColors
    @Environment(\.analytics) private var analytics
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(AppPaletteVariant.allCases) { variant in
                        Button {
                            guard themeController.variant != variant else { return }
                            themeController.variant = variant
                            analytics.track(.themeSelected(variant: variant))
                        } label: {
                            ThemeVariantRow(
                                variant: variant,
                                isSelected: themeController.variant == variant
                            )
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Palette")
                } footer: {
                    Text("Your choice is saved on this device.")
                }

                Section("Current Swatches") {
                    ThemeSwatchGrid(colors: themeColors)
                }

                Section("Sample UI") {
                    ThemeSampleCard(colors: themeColors)
                }
            }
            .navigationTitle("Theme Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: dismiss.callAsFunction)
                }
            }
        }
    }
}

private struct ThemeVariantRow: View {
    let variant: AppPaletteVariant
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.row) {
            VStack(alignment: .leading, spacing: 4) {
                Text(variant.displayName)
                    .font(.headline)
                Text(variant.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.tint)
            }
        }
        .contentShape(Rectangle())
    }
}

private struct ThemeSwatchGrid: View {
    let colors: AppThemeColors

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), spacing: 12)], spacing: 12) {
            ThemeSwatch(title: "Background", color: colors.background)
            ThemeSwatch(title: "Surface", color: colors.surface)
            ThemeSwatch(title: "Accent", color: colors.accent)
            ThemeSwatch(title: "Muted", color: colors.mutedText)
            ThemeSwatch(title: "Star", color: colors.trackedStar)
            ThemeSwatch(title: "Warning", color: colors.warning)
        }
        .padding(.vertical, 4)
    }
}

private struct ThemeSwatch: View {
    let title: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(color)
                .frame(height: 44)
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(.quaternary, lineWidth: 1)
                }
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

private struct ThemeSampleCard: View {
    let colors: AppThemeColors

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.tight) {
            Text("Severance")
                .font(.headline)
                .foregroundStyle(colors.accent)
            Text("Season 3 premieres Jan 16, 2027")
                .font(.subheadline)
                .foregroundStyle(colors.mutedText)
            HStack(spacing: AppSpacing.tight) {
                Image(systemName: "star.fill")
                    .foregroundStyle(colors.trackedStar)
                Text("Tracked")
                    .font(.caption)
                    .foregroundStyle(colors.mutedText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.row)
        .background(colors.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .listRowBackground(colors.background)
    }
}

/// Floating control that opens the palette picker sheet.
struct ThemeSwitcherButton: View {
    @State private var isPresented = false

    var body: some View {
        Button {
            isPresented = true
        } label: {
            Label("Theme", systemImage: "paintpalette.fill")
                .font(.body.weight(.semibold))
                .labelStyle(.titleAndIcon)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial, in: Capsule())
        }
        .accessibilityLabel("Theme")
        .accessibilityHint("Opens the palette switcher")
        .padding(.trailing, AppSpacing.screen)
        .padding(.bottom, 80)
        .sheet(isPresented: $isPresented) {
            ThemeSwitcherView()
        }
    }
}

#if DEBUG
#Preview {
    ThemeSwitcherView()
        .environment(AppThemeController.preview)
        .appThemePreview()
}
#endif
