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

extension View {
    /// Adds the standard trailing "About NextSeason" toolbar button when an
    /// About entry point is available in the environment.
    func appAboutToolbarButton() -> some View {
        modifier(AppAboutToolbarButtonModifier())
    }
}

private struct AppAboutToolbarButtonModifier: ViewModifier {
    @Environment(\.openAppAbout) private var openAppAbout

    func body(content: Content) -> some View {
        content.toolbar {
            if let openAppAbout {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        openAppAbout()
                    } label: {
                        Image(systemName: "info.circle")
                    }
                    .accessibilityLabel("About NextSeason")
                    .accessibilityHint("Shows version and beta diagnostics")
                }
            }
        }
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

    private let notificationsExplanation =
        "NextSeason periodically checks your watchlist for new seasons and will notify you when one is found. iOS decides when apps may perform background checks, so opening the app occasionally helps keep your watchlist up to date."

    private var notificationsFooterText: String {
        if notificationStatus.canDeliverVisibleAlerts {
            return "Opens Settings where you can manage notification preferences."
        }
        return FirstRunCopy.notificationsSettingsReminderMessage
    }

    private var notificationsAccessibilityHint: String {
        if notificationStatus.canDeliverVisibleAlerts {
            return "Opens Settings to manage notifications."
        }
        return "Opens notification settings or asks for permission."
    }

    private func handleNotificationsTap() async {
        await notificationService.enableNotificationsFromSettingsEntryPoint()
        await notificationStatus.refresh(using: notificationService)
    }
}

#if DEBUG
#Preview {
    AppAboutView(openDiagnostics: {})
        .environment(\.notificationService, NotificationService(analytics: RecordingAnalyticsService()))
}
#endif
