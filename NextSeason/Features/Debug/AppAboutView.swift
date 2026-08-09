//
//  AppAboutView.swift
//  NextSeason
//

import SwiftUI

// Optional UI presentation callback (nil = unavailable), not a required injected
// service — kept here beside About rather than in a `+Environment` file.
private struct OpenAppAboutKey: EnvironmentKey {
    static let defaultValue: (() -> Void)? = nil
}

extension EnvironmentValues {
    /// Presents the About sheet when set by the app root (beta / DEBUG).
    var openAppAbout: (() -> Void)? {
        get { self[OpenAppAboutKey.self] }
        set { self[OpenAppAboutKey.self] = newValue }
    }
}

extension View {
    /// Pins a subtle About footer above the tab bar when an About entry point is
    /// available (beta / DEBUG). Kept off show detail so content screens stay clean.
    func appAboutFooter() -> some View {
        modifier(AppAboutFooterModifier())
    }
}

private struct AppAboutFooterModifier: ViewModifier {
    @Environment(\.openAppAbout) private var openAppAbout

    func body(content: Content) -> some View {
        content.safeAreaInset(edge: .bottom, spacing: 0) {
            if openAppAbout != nil {
                AppAboutFooterButton()
            }
        }
    }
}

/// Quiet version line used as the beta About entry point on Search and Watchlist.
private struct AppAboutFooterButton: View {
    @Environment(\.openAppAbout) private var openAppAbout

    var body: some View {
        Button {
            openAppAbout?()
        } label: {
            Text("About NextSeason")
                .font(.footnote)
                .appSecondaryText()
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.tight)
        }
        .buttonStyle(.plain)
        .accessibilityHint("Shows version and beta diagnostics")
        .accessibilityIdentifier(AccessibilityID.App.aboutFooter)
    }
}

/// Lightweight beta-only About sheet used as the Diagnostics entry point.
@MainActor
struct AppAboutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.notificationService) private var notificationService
    @State private var betaBuildAvailability = BetaBuildAvailability.shared
    @State private var notificationStatus = NotificationStatusModel()

    let openDiagnostics: () -> Void

    var body: some View {
        NavigationStack {
            List {
                BetaAppInfoSection(channelDisplayName: betaBuildAvailability.channelDisplayName)

                Section {
                    Button {
                        Task { await handleNotificationsTap() }
                    } label: {
                        LabeledContent {
                            Text(notificationStatus.statusLabel)
                        } label: {
                            Label(
                                "Notifications",
                                systemImage: notificationStatus.symbolName
                            )
                        }
                    }
                    .accessibilityHint(notificationsAccessibilityHint)

                    VStack(alignment: .leading, spacing: AppSpacing.tight) {
                        Text("How notifications work")
                            .font(.subheadline.weight(.semibold))
                            .appPrimaryText()
                        Text(notificationsExplanation)
                            .font(.subheadline)
                            .appSecondaryText()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("How notifications work. \(notificationsExplanation)")
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
                await notificationStatus.refresh(using: notificationService)
            }
            .refreshNotificationStatus(notificationStatus)
        }
    }

    private let notificationsExplanation = String(
        localized:
            "NextSeason periodically checks your watchlist for new seasons and will notify you when one is found. iOS decides when apps may perform background checks, so opening the app occasionally helps keep your watchlist up to date."
    )

    private var notificationsFooterText: String {
        if notificationStatus.canDeliverVisibleAlerts {
            return String(
                localized: "Opens Settings where you can manage notification preferences."
            )
        }
        return FirstRunCopy.notificationsSettingsReminderMessage
    }

    private var notificationsAccessibilityHint: String {
        if notificationStatus.canDeliverVisibleAlerts {
            return String(localized: "Opens Settings to manage notifications.")
        }
        return String(localized: "Opens notification settings or asks for permission.")
    }

    private func handleNotificationsTap() async {
        await notificationService.enableNotificationsFromSettingsEntryPoint()
        await notificationStatus.refresh(using: notificationService)
    }
}

#if DEBUG
    #Preview {
        AppAboutView(openDiagnostics: {})
            .environment(
                \.notificationService, NotificationService(analytics: RecordingAnalyticsService()))
    }
#endif
