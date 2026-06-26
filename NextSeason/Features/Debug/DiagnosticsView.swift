//
//  DiagnosticsView.swift
//  NextSeason
//

import SwiftUI

private struct OpenDiagnosticsKey: EnvironmentKey {
    static let defaultValue: (() -> Void)? = nil
}

extension EnvironmentValues {
    var openDiagnostics: (() -> Void)? {
        get { self[OpenDiagnosticsKey.self] }
        set { self[OpenDiagnosticsKey.self] = newValue }
    }
}

/// Beta diagnostics screen with local usage counters and explicit share controls.
struct DiagnosticsView: View {
    @Environment(\.analytics) private var analytics
    @Environment(\.notificationService) private var notificationService
    @Environment(AppThemeController.self) private var themeController
    @Environment(\.dismiss) private var dismiss

    @State private var notificationsEnabled = false
    @State private var reportText = ""

    var body: some View {
        NavigationStack {
            List {
                Section("App") {
                    LabeledContent("Version", value: AppVersionInfo.displayString)
                    LabeledContent("Current theme", value: themeController.variant.displayName)
                    LabeledContent("Notifications enabled", value: notificationsEnabled ? "Yes" : "No")
                }

                Section("Usage") {
                    let counters = analytics.countersSnapshot()
                    LabeledContent("App launches", value: String(counters.appLaunches))
                    LabeledContent("Searches", value: String(counters.searchesPerformed))
                    LabeledContent("Successful searches", value: String(counters.successfulSearches))
                    LabeledContent("No-result searches", value: String(counters.noResultSearches))
                    LabeledContent("Example searches", value: String(counters.exampleSearchesUsed))
                    LabeledContent("Show detail views", value: String(counters.showDetailViews))
                    LabeledContent("Watchlist adds", value: String(counters.watchlistAdditions))
                    LabeledContent("Watchlist removals", value: String(counters.watchlistRemovals))
                    LabeledContent(
                        "Notification permission requests",
                        value: String(counters.notificationPermissionRequests)
                    )
                    LabeledContent(
                        "Notification permission grants",
                        value: String(counters.notificationPermissionGrants)
                    )
                    LabeledContent(
                        "Notification reminders scheduled",
                        value: String(counters.notificationRemindersScheduled)
                    )
                    LabeledContent("Theme selections", value: String(counters.themeSelections))
                    LabeledContent("Actor name taps", value: String(counters.actorNameTaps))
                }

                Section {
                    ShareLink(item: reportText) {
                        Label("Share Report", systemImage: "square.and.arrow.up")
                    }
                    Button {
                        UIPasteboard.general.string = reportText
                    } label: {
                        Label("Copy Report", systemImage: "doc.on.doc")
                    }
                } footer: {
                    Text("Nothing is sent automatically. Share this report only if you choose to.")
                }
            }
            .navigationTitle("Diagnostics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: dismiss.callAsFunction)
                }
            }
            .task {
                await refreshReport()
            }
            .onChange(of: themeController.variant) {
                refreshReportText()
            }
        }
    }

    private func refreshReport() async {
        let status = await notificationService.authorizationStatus()
        notificationsEnabled = NotificationAuthorizationPolicy.canDeliverAlerts(status)
        refreshReportText()
    }

    private func refreshReportText() {
        reportText = analytics.diagnosticsReport(
            notificationsEnabled: notificationsEnabled,
            currentTheme: themeController.variant.displayName
        )
    }
}

#if DEBUG
#Preview {
    DiagnosticsView()
        .environment(\.analytics, RecordingAnalyticsService())
        .environment(\.notificationService, NotificationService())
        .environment(AppThemeController.preview)
}
#endif
