//
//  NotificationStatusModel.swift
//  NextSeason
//

import Foundation

/// Owns UI-facing notification permission state so views refresh via intents
/// instead of loading presentation values inline.
@Observable
@MainActor
final class NotificationStatusModel {
    private(set) var presentation = NotificationStatusPresentation.unknown
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
