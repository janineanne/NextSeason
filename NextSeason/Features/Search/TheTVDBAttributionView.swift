//
//  TheTVDBAttributionView.swift
//  NextSeason
//

import SwiftUI

/// Required TheTVDB credit on screens that display their search metadata.
///
/// Free-tier licensing requires attribution with a direct link to TheTVDB.com
/// when end users see API metadata. Layout follows their sample banner (logo
/// leading, sample copy trailing, whole control tappable); colors use the app
/// secondary text style so the footer matches the rest of Search.
///
/// Brand assets: `TheTVDBLogo` in the asset catalog
/// (`logo2.png` for light, `logo1.png` for dark), sourced from
/// https://www.thetvdb.com/api-information#attribution
///
/// Shown on Search only (detail / watchlist still credit TVMaze).
struct TheTVDBAttributionView: View {
    var body: some View {
        Link(destination: TheTVDBConfiguration.websiteURL) {
            HStack(spacing: 10) {
                Image("TheTVDBLogo")
                    .resizable()
                    .scaledToFit()
                    // Sample page renders the mark at ~45pt.
                    .frame(height: 45)
                    .accessibilityHidden(true)

                // Whole chip is a Link; accent + underline on "TheTVDB" cues that
                // the control opens their site (same destination for the full row).
                (Text("Metadata provided by ")
                    .foregroundStyle(.secondary)
                    + Text("TheTVDB")
                    .foregroundStyle(AppColor.accent)
                    .underline()
                    + Text(
                        ". Please consider adding missing information or subscribing."
                    )
                    .foregroundStyle(.secondary))
                    .font(.footnote)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, AppSpacing.tight)
        }
        .accessibilityLabel(
            "Metadata provided by TheTVDB. Please consider adding missing information or subscribing."
        )
        .accessibilityHint(String(localized: "Opens TheTVDB.com"))
        .accessibilityIdentifier(AccessibilityID.Search.tvdbAttribution)
    }
}

#if DEBUG
    #Preview {
        TheTVDBAttributionView()
            .padding()
            .appScreenBackground()
    }
#endif
