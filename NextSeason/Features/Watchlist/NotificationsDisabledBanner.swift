//
//  NotificationsDisabledBanner.swift
//  NextSeason
//

import SwiftUI

/// Shown on the watchlist when the user tracks shows but has denied notifications.
struct NotificationsDisabledBanner: View {
    let openSettings: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.row) {
            Image(systemName: "bell.slash.fill")
                .font(.title2)
                .foregroundStyle(Color.warning)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: AppSpacing.tight) {
                Text("Notifications Are Off")
                    .font(.headline)
                    .appPrimaryText()
                Text("Turn on notifications in Settings to get alerts when a tracked show gets a next season date.")
                    .font(.subheadline)
                    .appSecondaryText()
                Button("Open Settings", action: openSettings)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .padding(.top, 2)
            }
        }
        .padding(AppSpacing.row)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.appSurface)
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.warning.opacity(0.12))
                }
        }
        .listRowInsets(EdgeInsets(top: 8, leading: AppSpacing.screen, bottom: 8, trailing: AppSpacing.screen))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG
#Preview {
    List {
        NotificationsDisabledBanner(openSettings: {})
    }
    .appPlainListStyle()
    .appScreenBackground()
}
#endif
