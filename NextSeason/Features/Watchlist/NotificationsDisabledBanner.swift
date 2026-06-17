//
//  NotificationsDisabledBanner.swift
//  NextSeason
//

import SwiftUI

/// Shown on the watchlist when the user tracks shows but has denied notifications.
struct NotificationsDisabledBanner: View {
    let openSettings: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notifications Are Off")
                .font(.headline)
            Text("Turn on notifications in Settings to get alerts when a tracked show gets a next season date.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("Open Settings", action: openSettings)
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG
#Preview {
    List {
        NotificationsDisabledBanner(openSettings: {})
    }
}
#endif
