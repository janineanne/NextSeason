//
//  ShowRowSkeleton.swift
//  NextSeason
//

import SwiftUI

/// Placeholder row shown while search results are loading.
struct ShowRowSkeleton: View {
    private var fill: Color {
        Color(.quaternaryLabel).opacity(0.35)
    }

    var body: some View {
        HStack(spacing: AppSpacing.row) {
            RoundedRectangle(cornerRadius: 8)
                .fill(fill)
                .frame(width: 60, height: 90)
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(fill)
                    .frame(height: 16)
                    .frame(maxWidth: 200)
                RoundedRectangle(cornerRadius: 4)
                    .fill(fill)
                    .frame(height: 14)
                    .frame(maxWidth: 140)
            }
            Spacer(minLength: 0)
        }
        .accessibilityHidden(true)
    }
}

#if DEBUG
#Preview {
    List {
        ShowRowSkeleton()
        ShowRowSkeleton()
    }
    .listStyle(.plain)
}
#endif
