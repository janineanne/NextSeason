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
@MainActor
struct DiagnosticsView: View {
    @Environment(\.analytics) private var analytics
    @Environment(\.notificationService) private var notificationService
    @Environment(\.watchlistRepository) private var repository
    @Environment(\.watchlistRefreshService) private var refreshService
    @Environment(\.betaRefreshDiagnostics) private var betaRefreshDiagnostics
    @Environment(AppThemeController.self) private var themeController
    @Environment(\.dismiss) private var dismiss

    @State private var notificationStatus = NotificationStatusModel()
    @State private var reportText = ""
    @State private var isForceRefreshing = false
    @State private var isSendingTestNotification = false
    @State private var isSchedulingDelayedPipelineNotification = false
    @State private var isRunningSimulation = false
    @State private var simulatedUpdateRunner: DiagnosticsSimulatedUpdateRunner?
    @State private var betaBuildAvailability = BetaBuildAvailability.shared
    @State private var isShowingDocumentation = false

    private var betaValidationAvailable: Bool {
        betaBuildAvailability.isAvailable
    }

    var body: some View {
        NavigationStack {
            List {
                BetaAppInfoSection(
                    channelDisplayName: betaBuildAvailability.channelDisplayName,
                    themeDisplayName: themeController.variant.displayName,
                    notificationsEnabledLabel: notificationStatus.diagnosticsEnabledLabel
                )

                if betaValidationAvailable {
                    betaValidationSection
                }

                Section {
                    let launchDiagnostics = AppDiagnosticsLogger.launchDiagnostics()
                    LabeledContent("Previous launch") {
                        Text(launchDiagnostics.previousLaunchEndedUnexpectedly ? "Ended unexpectedly ⚠️" : "Clean or not detected")
                            .foregroundStyle(launchDiagnostics.previousLaunchEndedUnexpectedly ? .orange : .secondary)
                    }
                    LabeledContent("Current launch started") {
                        Text(formattedDate(launchDiagnostics.currentLaunchStartedAt))
                            .foregroundStyle(.secondary)
                    }
                    LabeledContent("Last graceful background") {
                        Text(formattedDate(launchDiagnostics.lastGracefulExitAt))
                            .foregroundStyle(.secondary)
                    }
                    if launchDiagnostics.previousLaunchEndedUnexpectedly {
                        LabeledContent("Prior launch started") {
                            Text(formattedDate(launchDiagnostics.previousLaunchStartedAt))
                                .foregroundStyle(.secondary)
                        }
                        LabeledContent("Detected") {
                            Text(formattedDate(launchDiagnostics.unexpectedTerminationDetectedAt))
                                .foregroundStyle(.secondary)
                        }
                    }

                    let priorBreadcrumbs = launchDiagnostics.priorBreadcrumbs
                    if !priorBreadcrumbs.isEmpty {
                        ForEach(priorBreadcrumbs, id: \.self) { entry in
                            Text(entry)
                                .font(.caption.monospaced())
                        }
                    }

                    let breadcrumbs = AppDiagnosticsLogger.recentBreadcrumbs()
                    if !breadcrumbs.isEmpty {
                        ForEach(breadcrumbs, id: \.self) { entry in
                            Text(entry)
                                .font(.caption.monospaced())
                        }
                    } else {
                        Text("No breadcrumbs recorded this session.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Launch investigation")
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
                }
            }
            .navigationTitle("Diagnostics")
            .task {
                await betaBuildAvailability.refresh()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        isShowingDocumentation = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                    }
                    .accessibilityLabel("Diagnostics help")
                    .accessibilityHint("Explains what each field and action does")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: dismiss.callAsFunction)
                }
            }
            .sheet(isPresented: $isShowingDocumentation) {
                DiagnosticsDocumentationView()
            }
            .task {
                await refreshReport()
            }
            .onChange(of: themeController.variant) {
                refreshReportText()
            }
            .refreshNotificationStatus(notificationStatus)
        }
    }

    @ViewBuilder
    private var betaValidationSection: some View {
        Section {
            LabeledContent("Last background refresh") {
                Text(formattedDate(betaRefreshDiagnostics?.lastBackgroundRefreshAt))
                    .foregroundStyle(.secondary)
            }
            LabeledContent("Next refresh window") {
                Text(formattedNextRefreshWindow)
                    .foregroundStyle(.secondary)
            }
            LabeledContent("Last background fetch result") {
                Text(betaRefreshDiagnostics?.lastBackgroundFetchResult ?? "No background refresh recorded yet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            LabeledContent("Last background notification decision") {
                Text(betaRefreshDiagnostics?.lastBackgroundNotificationDecision ?? "No background notification decision yet.")
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
            LabeledContent("Last foreground refresh") {
                Text(formattedDate(betaRefreshDiagnostics?.lastForegroundRefreshAt))
                    .foregroundStyle(.secondary)
            }
            LabeledContent("Last foreground fetch result") {
                Text(betaRefreshDiagnostics?.lastForegroundFetchResult ?? "No foreground refresh recorded yet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            LabeledContent("Last foreground notification decision") {
                Text(betaRefreshDiagnostics?.lastForegroundNotificationDecision ?? "No foreground notification decision yet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Beta validation")
        }

        Section {
            Button {
                Task { await forceRefreshNow() }
            } label: {
                Label(
                    isForceRefreshing ? "Refreshing…" : "Force Refresh Now",
                    systemImage: "arrow.clockwise"
                )
            }
            .disabled(isForceRefreshing || refreshService == nil)

            notificationActionButton(
                isLoading: isSendingTestNotification,
                loadingTitle: "Sending…",
                title: "Send Test Notification",
                systemImage: "bell.badge"
            ) {
                await sendTestNotification()
            }

            notificationActionButton(
                isLoading: isSchedulingDelayedPipelineNotification,
                loadingTitle: "Scheduling…",
                title: "Schedule Pipeline Test Notification",
                systemImage: "bell.and.waves.left.and.right"
            ) {
                await scheduleDelayedPipelineNotification()
            }

            notificationActionButton(
                isLoading: isRunningSimulation,
                loadingTitle: "Running…",
                title: "Run Simulated Update Scenario",
                systemImage: "play.rectangle.on.rectangle"
            ) {
                await runSimulatedUpdateScenario()
            }
        } header: {
            Text("Beta actions")
        } footer: {
            if !notificationStatus.canDeliverVisibleAlerts {
                Text("Notification test actions require alert permission. Enable notifications in Settings, then return here.")
            }
        }
    }

    private func notificationActionButton(
        isLoading: Bool,
        loadingTitle: String,
        title: String,
        systemImage: String,
        action: @escaping () async -> Void
    ) -> some View {
        Button {
            Task { await action() }
        } label: {
            Label(isLoading ? loadingTitle : title, systemImage: systemImage)
        }
        .disabled(isLoading || !notificationStatus.canDeliverVisibleAlerts)
        .foregroundStyle(notificationStatus.canDeliverVisibleAlerts ? .primary : .secondary)
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

    private static let testNotificationDelaySeconds: TimeInterval = 5

    private func watchlistTestShow() async -> TrackedShow? {
        try? await repository.all().first
    }

    private func prepareSimulatedUpdateRunner(using template: TrackedShow?) {
        guard betaValidationAvailable, let betaRefreshDiagnostics else { return }
        simulatedUpdateRunner = DiagnosticsSimulatedUpdateRunner(
            pipelineTemplate: template,
            notifications: notificationService,
            diagnostics: betaRefreshDiagnostics,
            analytics: analytics
        )
    }

    private func recordMissingWatchlistTestShow() {
        betaRefreshDiagnostics?.recordSimulatedScenarioSummary(
            "Track a show on the watchlist to send a test notification."
        )
        refreshReportText()
    }

    private func forceRefreshNow() async {
        guard let refreshService, !isForceRefreshing else { return }
        isForceRefreshing = true
        // Interactive diagnostics refresh — update silently like Watchlist pull-to-refresh.
        let outcome = await refreshService.refreshAll(force: true, deliverNotifications: false)
        if let outcome {
            betaRefreshDiagnostics?.recordForegroundRefreshCompleted(
                at: .now,
                fetchResult: outcome.fetchResult,
                notificationDecision: outcome.notificationDecision
            )
        }
        isForceRefreshing = false
    }

    private func sendTestNotification() async {
        guard !isSendingTestNotification else { return }
        isSendingTestNotification = true
        await notificationStatus.refresh(using: notificationService)

        guard let tracked = await watchlistTestShow() else {
            recordMissingWatchlistTestShow()
            isSendingTestNotification = false
            return
        }

        let content = DiagnosticsSimulatedData.notificationContent(from: tracked)
        // System-scheduled delivery is more reliable than an immediate (nil-trigger)
        // request, especially when backgrounding the app to verify the alert.
        await notificationService.deliverAfterDelay(
            content,
            requestIdentifier: "debug-test-\(UUID().uuidString)",
            delay: Self.testNotificationDelaySeconds
        )
        betaRefreshDiagnostics?.recordSimulatedScenarioSummary(
            "Test notification scheduled for \(tracked.name): \(content.body)"
        )
        refreshReportText()

        isSendingTestNotification = false
    }

    private func scheduleDelayedPipelineNotification() async {
        guard !isSchedulingDelayedPipelineNotification else { return }
        isSchedulingDelayedPipelineNotification = true
        guard let tracked = await watchlistTestShow() else {
            recordMissingWatchlistTestShow()
            isSchedulingDelayedPipelineNotification = false
            return
        }
        prepareSimulatedUpdateRunner(using: tracked)
        _ = await simulatedUpdateRunner?.runDelayedNewSeasonNotification()
        isSchedulingDelayedPipelineNotification = false
    }

    private func runSimulatedUpdateScenario() async {
        guard !isRunningSimulation else { return }
        isRunningSimulation = true
        guard let tracked = await watchlistTestShow() else {
            recordMissingWatchlistTestShow()
            isRunningSimulation = false
            return
        }
        prepareSimulatedUpdateRunner(using: tracked)
        _ = await simulatedUpdateRunner?.runNextStep()
        isRunningSimulation = false
    }

    private func refreshReport() async {
        await notificationStatus.refresh(using: notificationService)
        refreshReportText()
    }

    private func refreshReportText() {
        reportText = analytics.diagnosticsReport(
            notificationsEnabled: notificationStatus.canDeliverVisibleAlerts,
            currentTheme: themeController.variant.displayName,
            betaRefreshDiagnostics: betaRefreshDiagnostics
        )
    }
}

#if DEBUG
#Preview {
    DiagnosticsView()
        .environment(\.analytics, RecordingAnalyticsService())
        .environment(\.notificationService, NotificationService(analytics: RecordingAnalyticsService()))
        .environment(\.watchlistRepository, InMemoryWatchlistRepository())
        .environment(\.betaRefreshDiagnostics, BetaRefreshDiagnostics())
        .environment(AppThemeController.preview)
}
#endif
