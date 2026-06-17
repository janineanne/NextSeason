//
//  TVMazeAttributionView.swift
//  NextSeason
//

import SwiftUI

/// Required TVMaze credit-back on screens that display their data (PD-002, PD-008).
struct TVMazeAttributionView: View {
    var body: some View {
        Text("Data provided by TVMaze")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}

extension View {
    /// Pins TVMaze attribution above the tab bar or home indicator.
    func tvmazeAttributionInset() -> some View {
        safeAreaInset(edge: .bottom, spacing: 0) {
            TVMazeAttributionView()
                .padding(.vertical, 12)
                .background(.background)
        }
    }
}

#if DEBUG
#Preview {
    TVMazeAttributionView()
}
#endif
