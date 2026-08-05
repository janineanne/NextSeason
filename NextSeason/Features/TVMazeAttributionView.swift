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
            .appSecondaryText()
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, AppSpacing.tight)
            .accessibilityAddTraits(.isStaticText)
    }
}

#if DEBUG
    #Preview {
        TVMazeAttributionView()
    }
#endif
