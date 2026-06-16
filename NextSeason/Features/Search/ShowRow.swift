//
//  ShowRow.swift
//  NextSeason
//

import SwiftUI

/// A single show in the search results list: poster, title, and status.
struct ShowRow: View {
    let show: Show

    var body: some View {
        HStack(spacing: 12) {
            poster
            VStack(alignment: .leading, spacing: 4) {
                Text(show.name)
                    .font(.headline)
                Text(show.status.displayLabel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(show.name), \(show.status.displayLabel)")
    }

    private var poster: some View {
        AsyncImage(url: show.posterMediumURL) { phase in
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
                    .foregroundStyle(.secondary)
            }
    }
}

#Preview {
    List {
        ShowRow(show: .preview)
    }
}
