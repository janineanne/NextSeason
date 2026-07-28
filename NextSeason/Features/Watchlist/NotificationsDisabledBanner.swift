//
//  NotificationsDisabledBanner.swift
//  NextSeason
//

import SwiftUI

/// Shown on the watchlist when the user tracks shows but has denied notifications.
struct NotificationsDisabledBanner: View {
    let buttonTitle: String
    let openSettings: () -> Void

    init(buttonTitle: String = "Open Settings", openSettings: @escaping () -> Void) {
        self.buttonTitle = buttonTitle
        self.openSettings = openSettings
    }

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.row) {
            Image(systemName: "bell.slash.fill")
                .font(.title2)
                .foregroundStyle(AppColor.warning)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: AppSpacing.tight) {
                Text("Notifications Are Off")
                    .font(.headline)
                    .appPrimaryText()
                Text(FirstRunCopy.notificationsDisabledBannerMessage)
                    .font(.subheadline)
                    .appSecondaryText()
                Button(buttonTitle, action: openSettings)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .padding(.top, 2)
            }
        }
        .padding(AppSpacing.row)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(AppColor.surface)
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(AppColor.warning.opacity(0.12))
                }
        }
        .listRowInsets(EdgeInsets(top: 8, leading: AppSpacing.screen, bottom: 8, trailing: AppSpacing.screen))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
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
