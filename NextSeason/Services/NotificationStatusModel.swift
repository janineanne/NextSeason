//
//  NotificationStatusModel.swift
//  NextSeason
//

import Foundation

/// Observable holder for UI-facing notification permission state shared by About,
/// Watchlist, and Diagnostics. Views call `refresh(using:)` (or
/// `refreshNotificationStatus`) instead of loading presentation values inline.
@Observable
@MainActor
final class NotificationStatusModel {
    private(set) var presentation = NotificationStatusPresentation.unknown
    /// Bumps on each refresh so a slower in-flight load cannot overwrite a newer one.
    private var refreshGeneration = 0

    var canDeliverVisibleAlerts: Bool { presentation.canDeliverVisibleAlerts }
    var isAuthorizationNotDetermined: Bool { presentation.isAuthorizationNotDetermined }
    var statusLabel: String { presentation.statusLabel }
    var diagnosticsEnabledLabel: String { presentation.diagnosticsEnabledLabel }
    var symbolName: String { presentation.symbolName }
    var showsDisabledBanner: Bool { presentation.showsDisabledBanner }
    var enablementButtonTitle: String { presentation.enablementButtonTitle }

    func refresh(using service: any NotificationManaging) async {
        refreshGeneration += 1
        let generation = refreshGeneration
        let loaded = await NotificationStatusPresentation.load(using: service)
        guard generation == refreshGeneration else { return }
        presentation = loaded
    }
}
