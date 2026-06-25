//
//  ShowRow.swift
//  NextSeason
//

import SwiftUI

/// Poster, title, and status for a show in search results or the watchlist.
struct ShowRowLabel: View {
    @Environment(\.appThemeColors) private var themeColors

    let name: String
    let subtitle: String
    let posterURL: URL?
    var isStale: Bool = false
    /// Optional tertiary line (genres on search, last-checked on watchlist).
    var detailLine: String?
    /// Watchlist-only footer kept separate so genre lines don't collide.
    var footer: String?

    init(
        name: String,
        subtitle: String,
        posterURL: URL?,
        isStale: Bool = false,
        detailLine: String? = nil,
        footer: String? = nil
    ) {
        self.name = name
        self.subtitle = subtitle
        self.posterURL = posterURL
        self.isStale = isStale
        self.detailLine = detailLine
        self.footer = footer
    }

    init(show: Show) {
        self.init(
            name: show.name,
            subtitle: show.status.displayLabel,
            posterURL: show.posterMediumURL,
            detailLine: show.genres.isEmpty ? nil : show.genres.joined(separator: " · ")
        )
    }

    init(tracked: TrackedShow) {
        let updated = tracked.lastCheckedAt.formatted(date: .abbreviated, time: .shortened)
        self.init(
            name: tracked.name,
            subtitle: tracked.nextSeason.headline,
            posterURL: tracked.posterMediumURL,
            isStale: tracked.isStale,
            footer: "Updated \(updated)"
        )
    }

    var body: some View {
        HStack(spacing: AppSpacing.row) {
            poster
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)
                    .appPrimaryText()
                Text(subtitle)
                    .font(.subheadline)
                    .lineLimit(2)
                    .appPrimaryText()
                if isStale {
                    Text("No longer on TVMaze")
                        .font(.caption)
                        .foregroundStyle(themeColors.warning)
                }
                if let detailLine {
                    Text(detailLine)
                        .font(.caption)
                        .appSecondaryText()
                }
                if let footer {
                    Text(footer)
                        .font(.caption)
                        .appSecondaryText()
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        var parts = [name, subtitle]
        if isStale {
            parts.append("No longer on TVMaze")
        }
        if let detailLine {
            parts.append(detailLine)
        }
        if let footer {
            parts.append(footer)
        }
        return parts.joined(separator: ", ")
    }

    private var poster: some View {
        AsyncImage(url: posterURL) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
            case .empty, .failure:
                placeholder
            @unknown default:
                placeholder
            }
        }
        .frame(width: 60, height: 90)
        .clipShape(.rect(cornerRadius: 8))
        .accessibilityHidden(true)
    }

    private var placeholder: some View {
        Rectangle()
            .fill(.quaternary)
            .overlay {
                Image(systemName: "tv")
            }
    }
}

/// Track / untrack control shown beside a show list row.
struct ShowRowTrackButton: View {
    @Environment(\.appThemeColors) private var themeColors

    let showID: Int
    let showName: String
    let isTracked: Bool
    let isUpdating: Bool
    var trackButtonIdentifier: String = AccessibilityID.Search.trackButton
    let action: (CGRect) -> Void

    @State private var buttonFrame: CGRect = .zero

    var body: some View {
        Button {
            action(buttonFrame)
        } label: {
            Group {
                if isUpdating {
                    ProgressView()
                } else {
                    Image(systemName: isTracked ? "star.fill" : "star")
                }
            }
            .frame(width: 44, height: 44)
        }
        .buttonStyle(.borderless)
        .tint(isTracked ? themeColors.trackedStar : themeColors.accent)
        .disabled(isUpdating)
        .accessibilityLabel(trackAccessibilityLabel)
        .accessibilityIdentifier("\(trackButtonIdentifier).\(showID)")
        .accessibilityHint("Adds or removes this show from your watchlist")
        .background {
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        updateFrame(from: geometry)
                    }
                    .onChange(of: geometry.frame(in: .global)) { _, _ in
                        updateFrame(from: geometry)
                    }
                    .onChange(of: geometry.size) { _, _ in
                        updateFrame(from: geometry)
                    }
            }
        }
    }

    private func updateFrame(from geometry: GeometryProxy) {
        let frame = geometry.frame(in: .global)
        guard frame.width > 0, frame.height > 0 else { return }
        buttonFrame = frame
    }

    private var trackAccessibilityLabel: String {
        if isUpdating { return "Updating watchlist for \(showName)" }
        return isTracked ? "Stop tracking \(showName)" : "Track \(showName)"
    }
}

#if DEBUG
#Preview {
    List {
        ShowRowLabel(show: .preview)
        ShowRowLabel(tracked: TrackedShow(from: .preview))
        HStack {
            ShowRowLabel(show: .preview)
            ShowRowTrackButton(
                showID: Show.preview.id,
                showName: Show.preview.name,
                isTracked: true,
                isUpdating: false
            ) { _ in }
        }
    }
}
#endif
