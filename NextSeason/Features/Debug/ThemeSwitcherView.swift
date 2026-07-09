//
//  ThemeSwitcherView.swift
//  NextSeason
//

import SwiftUI

/// Palette picker for beta feedback on color directions.
struct ThemeSwitcherView: View {
    @Environment(AppThemeController.self) private var themeController
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.analytics) private var analytics
    @Environment(\.dismiss) private var dismiss

    @State private var draftVariant: AppPaletteVariant = .warmSlate

    private var draftColors: AppThemeColors {
        AppThemeColors.colors(for: draftVariant, colorScheme: colorScheme)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(AppPaletteVariant.allCases) { variant in
                        Button {
                            draftVariant = variant
                        } label: {
                            ThemeVariantRow(
                                variant: variant,
                                isSelected: draftVariant == variant
                            )
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Palette")
                } footer: {
                    Text("Tap Done to apply and save your choice on this device.")
                }

                Section("Current Swatches") {
                    ThemeSwatchGrid(colors: draftColors)
                }

                Section("Sample UI") {
                    ThemeSampleCard(colors: draftColors)
                }
            }
            .navigationTitle("Theme Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: applyDraftAndDismiss)
                }
            }
            .onAppear {
                draftVariant = themeController.variant
            }
        }
    }

    private func applyDraftAndDismiss() {
        if draftVariant != themeController.variant {
            themeController.variant = draftVariant
            analytics.track(.themeSelected(variant: draftVariant))
        }
        dismiss()
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

/// Toolbar control that opens the palette picker sheet (beta).
struct ThemeSwitcherToolbarButton: View {
    @State private var isPresented = false

    var body: some View {
        Button {
            isPresented = true
        } label: {
            Image(systemName: "paintpalette")
        }
        .accessibilityLabel("Theme")
        .accessibilityHint("Opens the palette switcher")
        .sheet(isPresented: $isPresented) {
            ThemeSwitcherView()
        }
    }
}

extension View {
    /// Leading nav-bar entry for the beta palette picker.
    @ViewBuilder
    func betaThemeSwitcherToolbar() -> some View {
        if UITestingConfiguration.isEnabled {
            self
        } else {
            toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    ThemeSwitcherToolbarButton()
                }
            }
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
