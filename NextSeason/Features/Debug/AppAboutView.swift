//
//  AppAboutView.swift
//  NextSeason
//

import SwiftUI

private struct OpenAppAboutKey: EnvironmentKey {
    static let defaultValue: (() -> Void)? = nil
}

extension EnvironmentValues {
    var openAppAbout: (() -> Void)? {
        get { self[OpenAppAboutKey.self] }
        set { self[OpenAppAboutKey.self] = newValue }
    }
}

/// Lightweight beta-only About sheet used as the Diagnostics entry point.
@MainActor
struct AppAboutView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var betaBuildAvailability = BetaBuildAvailability.shared

    let openDiagnostics: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section("App") {
                    LabeledContent("Version", value: AppVersionInfo.displayString)
                    LabeledContent("Build channel", value: betaBuildAvailability.channelDisplayName)
                }

                Section("Credits") {
                    Text("Data provided by TVMaze")
                        .appSecondaryText()
                }

                if betaBuildAvailability.isAvailable {
                    Section {
                        Button {
                            openDiagnostics()
                        } label: {
                            Label("Diagnostics", systemImage: "stethoscope")
                        }
                    } footer: {
                        Text("Diagnostics are available only in Debug and TestFlight builds.")
                    }
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await betaBuildAvailability.refresh()
            }
        }
    }
}

#Preview {
	AppAboutView(openDiagnostics: {})
}
