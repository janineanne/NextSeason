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
    @Environment(\.watchlistRefreshService) private var refreshService
    @Environment(\.betaRefreshDiagnostics) private var betaRefreshDiagnostics
    @Environment(AppThemeController.self) private var themeController
    @Environment(\.dismiss) private var dismiss

    @State private var notificationsEnabled = false
    @State private var reportText = ""
    @State private var isForceRefreshing = false
    @State private var isSendingTestNotification = false
    @State private var isRunningSimulation = false
    @State private var simulatedUpdateRunner: DiagnosticsSimulatedUpdateRunner?

    private var betaValidationAvailable: Bool {
        BetaBuildConfiguration.isAvailable
    }

    var body: some View {
        NavigationStack {
            List {
                Section("App") {
                    LabeledContent("Version", value: AppVersionInfo.displayString)
                    LabeledContent("Build channel", value: betaValidationAvailable ? "Beta (DEBUG or TestFlight)" : "Production")
                    LabeledContent("Current theme", value: themeController.variant.displayName)
                    LabeledContent("Notifications enabled", value: notificationsEnabled ? "Yes" : "No")
                }

                if betaValidationAvailable {
                    betaValidationSection
                }

                Section {
                    if !AppDiagnosticsLogger.recentBreadcrumbs().isEmpty {
                        ForEach(AppDiagnosticsLogger.recentBreadcrumbs(), id: \.self) { entry in
                            Text(entry)
                                .font(.caption.monospaced())
                        }
                    } else {
                        Text("No breadcrumbs recorded this session.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Crash investigation")
                } footer: {
                    Text("Breadcrumbs and OSLog entries (subsystem: com.TrialByFyre.NextSeason) help correlate idle crashes with the last app activity. After a crash, reopen the app and share this report, or check Xcode Organizer → Crashes.")
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
                prepareSimulatedUpdateRunnerIfNeeded()
            }
            .onChange(of: themeController.variant) {
                refreshReportText()
            }
        }
    }

    @ViewBuilder
    private var betaValidationSection: some View {
        Section {
            LabeledContent("Last refresh") {
                Text(formattedDate(betaRefreshDiagnostics?.lastRefreshAt))
                    .foregroundStyle(.secondary)
            }
            LabeledContent("Next refresh window") {
                Text(formattedNextRefreshWindow)
                    .foregroundStyle(.secondary)
            }
            LabeledContent("Last fetch result") {
                Text(betaRefreshDiagnostics?.lastFetchResult ?? "No refresh recorded yet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            LabeledContent("Last notification decision") {
                Text(betaRefreshDiagnostics?.lastNotificationDecision ?? "No notification decision yet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let summary = betaRefreshDiagnostics?.lastSimulatedScenarioSummary {
                LabeledContent("Last simulation") {
                    Text(summary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Beta validation")
        } footer: {
            Text("Refresh diagnostics reflect real watchlist polling. Simulated updates use fake data only and never modify your tracked shows.")
        }

        Section("Beta actions") {
            Button {
                Task { await forceRefreshNow() }
            } label: {
                Label(
                    isForceRefreshing ? "Refreshing…" : "Force Refresh Now",
                    systemImage: "arrow.clockwise"
                )
            }
            .disabled(isForceRefreshing || refreshService == nil)

            Button {
                Task { await sendTestNotification() }
            } label: {
                Label(
                    isSendingTestNotification ? "Sending…" : "Send Test Notification",
                    systemImage: "bell.badge"
                )
            }
            .disabled(isSendingTestNotification)

            Button {
                Task { await runSimulatedUpdateScenario() }
            } label: {
                Label(
                    isRunningSimulation ? "Running…" : "Run Simulated Update Scenario",
                    systemImage: "play.rectangle.on.rectangle"
                )
            }
            .disabled(isRunningSimulation)

            if let runner = simulatedUpdateRunner {
                Text("Next simulation step uses \(runner.dataPhaseLabel.lowercased()). Tap twice (step 1 → step 2) to exercise debounce then date-backed notification.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var formattedNextRefreshWindow: String {
        guard let nextDate = betaRefreshDiagnostics?.nextScheduledRefreshAt else {
            return "Not scheduled yet"
        }
        let intervalLabel = BackgroundRefreshConfiguration.isAccelerated
            ? "10 min (accelerated soak test)"
            : "12 h (production cadence)"
        return "\(formattedDate(nextDate)) — \(intervalLabel)"
    }

    private func formattedDate(_ date: Date?) -> String {
        guard let date else { return "Never" }
        return date.formatted(date: .abbreviated, time: .standard)
    }

    private func prepareSimulatedUpdateRunnerIfNeeded() {
        guard betaValidationAvailable,
              simulatedUpdateRunner == nil,
              let betaRefreshDiagnostics else { return }
        simulatedUpdateRunner = DiagnosticsSimulatedUpdateRunner(
            notifications: notificationService,
            diagnostics: betaRefreshDiagnostics
        )
    }

    private func forceRefreshNow() async {
        guard let refreshService, !isForceRefreshing else { return }
        isForceRefreshing = true
        await refreshService.refreshAll(force: true)
        isForceRefreshing = false
    }

    private func sendTestNotification() async {
        guard !isSendingTestNotification else { return }
        isSendingTestNotification = true

        let premiere = Calendar.current.date(byAdding: .month, value: 1, to: .now) ?? .now
        await notificationService.deliver(
            SeasonNotificationContent(
                showID: DiagnosticsSimulatedData.showID,
                showName: DiagnosticsSimulatedData.showName,
                status: .scheduled(season: 3, premiere: premiere)
            )
        )
        betaRefreshDiagnostics?.recordRefreshCompleted(
            at: .now,
            fetchResult: "Test notification requested",
            notificationDecision: "Delivered test notification for \(DiagnosticsSimulatedData.showName)"
        )

        isSendingTestNotification = false
    }

    private func runSimulatedUpdateScenario() async {
        guard !isRunningSimulation else { return }
        isRunningSimulation = true
        prepareSimulatedUpdateRunnerIfNeeded()
        _ = await simulatedUpdateRunner?.runNextStep()
        isRunningSimulation = false
    }

    private func refreshReport() async {
        let status = await notificationService.authorizationStatus()
        notificationsEnabled = NotificationAuthorizationPolicy.canDeliverAlerts(status)
        refreshReportText()
    }

    private func refreshReportText() {
        reportText = analytics.diagnosticsReport(
            notificationsEnabled: notificationsEnabled,
            currentTheme: themeController.variant.displayName,
            betaRefreshDiagnostics: betaRefreshDiagnostics
        )
    }
}

#if DEBUG
#Preview {
    DiagnosticsView()
        .environment(\.analytics, RecordingAnalyticsService())
        .environment(\.notificationService, NotificationService())
        .environment(\.betaRefreshDiagnostics, BetaRefreshDiagnostics())
        .environment(AppThemeController.preview)
}
#endif
