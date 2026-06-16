//
//  WatchlistRow.swift
//  NextSeason
//

import SwiftUI

struct WatchlistRow: View {
    let tracked: TrackedShow

    var body: some View {
        HStack(spacing: 12) {
            poster
            VStack(alignment: .leading, spacing: 4) {
                Text(tracked.name)
                    .font(.headline)
                Text(tracked.nextSeason.headline)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if tracked.isStale {
                    Label("No longer on TVMaze", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                Text("Updated \(tracked.lastCheckedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var poster: some View {
        AsyncImage(url: tracked.posterMediumURL) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
            case .empty, .failure:
                Rectangle()
                    .fill(.quaternary)
                    .overlay { Image(systemName: "tv").foregroundStyle(.secondary) }
            @unknown default:
                Rectangle().fill(.quaternary)
            }
        }
        .frame(width: 44, height: 66)
        .clipShape(.rect(cornerRadius: 6))
        .accessibilityHidden(true)
    }
}

#if DEBUG
#Preview {
    List {
        WatchlistRow(tracked: TrackedShow(from: .preview))
    }
}
#endif
