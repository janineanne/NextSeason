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
    @Environment(\.notificationService) private var notificationService
    @Environment(\.scenePhase) private var scenePhase
    @State private var betaBuildAvailability = BetaBuildAvailability.shared
    @State private var notificationsEnabled = false

    let openDiagnostics: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section("App") {
                    LabeledContent("Version", value: AppVersionInfo.displayString)
                    LabeledContent("Build channel", value: betaBuildAvailability.channelDisplayName)
                }

                Section {
                    Button {
                        Task { await handleNotificationsTap() }
                    } label: {
                        LabeledContent {
                            Text(notificationsEnabled ? "Enabled" : "Disabled")
                        } label: {
                            Label(
                                "Notifications",
                                systemImage: notificationsEnabled ? "bell.fill" : "bell.slash"
                            )
                        }
                    }
                    .accessibilityHint(notificationsAccessibilityHint)
                } footer: {
                    Text(notificationsFooterText)
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
                await refreshNotificationStatus()
            }
            .onChange(of: scenePhase) { _, phase in
                guard phase == .active else { return }
                Task { await refreshNotificationStatus() }
            }
        }
    }

    private var notificationsFooterText: String {
        if notificationsEnabled {
            return "Opens Settings where you can manage notification preferences."
        }
        return FirstRunCopy.notificationsSettingsReminderMessage
    }

    private var notificationsAccessibilityHint: String {
        if notificationsEnabled {
            return "Opens Settings to manage notifications."
        }
        return "Opens notification settings or asks for permission."
    }

    private func refreshNotificationStatus() async {
        let status = await notificationService.authorizationStatus()
        notificationsEnabled = NotificationAuthorizationPolicy.canDeliverAlerts(status)
    }

    private func handleNotificationsTap() async {
        let status = await notificationService.authorizationStatus()
        switch status {
        case .notDetermined:
            await notificationService.requestAuthorizationIfNeeded()
        case .denied, .authorized, .provisional, .ephemeral:
            notificationService.openNotificationSettings()
        @unknown default:
            notificationService.openNotificationSettings()
        }
        await refreshNotificationStatus()
    }
}

#Preview {
    AppAboutView(openDiagnostics: {})
        .environment(\.notificationService, NotificationService(analytics: RecordingAnalyticsService()))
}
