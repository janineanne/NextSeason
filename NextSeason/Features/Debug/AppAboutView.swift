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
    /// Leading ellipsis that presents the About sheet when an About entry point
    /// is available (beta / DEBUG).
    func appAboutToolbarButton() -> some View {
        modifier(AppAboutToolbarButtonModifier())
    }
}

private struct AppAboutToolbarButtonModifier: ViewModifier {
    @Environment(\.openAppAbout) private var openAppAbout

    func body(content: Content) -> some View {
        content.toolbar {
            if let openAppAbout {
                ToolbarItem(placement: .topBarLeading) {
                    Button("About NextSeason", systemImage: "ellipsis", action: openAppAbout)
                        .labelStyle(.iconOnly)
                        .accessibilityHint("Shows version, purchases, and app information")
                        .accessibilityIdentifier(AccessibilityID.App.aboutButton)
                }
            }
        }
    }
}

/// About sheet: version, notifications, NextSeason Plus, optional tips, and
/// (in Debug / TestFlight) the Diagnostics entry point.
@MainActor
struct AppAboutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.notificationService) private var notificationService
    @Environment(PurchaseService.self) private var purchases
    @State private var betaBuildAvailability = BetaBuildAvailability.shared
    @State private var notificationStatus = NotificationStatusModel()
    @State private var isShowingPlusStore = false

    let openDiagnostics: () -> Void

    var body: some View {
        NavigationStack {
            List {
                BetaAppInfoSection(channelDisplayName: betaBuildAvailability.channelDisplayName)

                PlusAccountSection(isShowingPlusStore: $isShowingPlusStore)

                TipJarSection()

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
            .sheet(isPresented: $isShowingPlusStore) {
                PlusStoreView()
                    .environment(purchases)
            }
            .alert(
                "Couldn't Complete Purchase",
                isPresented: errorAlertPresented
            ) {
                Button("OK", role: .cancel) {
                    purchases.clearMessages()
                }
            } message: {
                Text(purchases.lastErrorMessage ?? "")
            }
            .alert(
                "Thank You",
                isPresented: thankYouAlertPresented
            ) {
                Button("OK", role: .cancel) {
                    purchases.clearMessages()
                }
            } message: {
                Text(purchases.thankYouMessage ?? "")
            }
        }
    }

    private var errorAlertPresented: Binding<Bool> {
        Binding(
            get: { purchases.lastErrorMessage != nil && !isShowingPlusStore },
            set: { if !$0 { purchases.clearMessages() } }
        )
    }

    private var thankYouAlertPresented: Binding<Bool> {
        Binding(
            get: { purchases.thankYouMessage != nil },
            set: { if !$0 { purchases.clearMessages() } }
        )
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
                \.notificationService, NotificationService(analytics: RecordingAnalyticsService())
            )
            .environment(PurchaseService.preview)
    }
#endif
