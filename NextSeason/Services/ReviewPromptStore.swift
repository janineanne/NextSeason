//
//  ReviewPromptStore.swift
//  NextSeason
//

import Foundation

/// Persists whether a show notification has been experienced and whether a
/// review was already requested for the current marketing version.
///
/// One request attempt per `CFBundleShortVersionString`. A later version can
/// ask again, but only after that version has also delivered a show notification.
struct ReviewPromptStore: Sendable {
    static let deliveredVersionKey = "reviewPrompt.notificationDeliveredVersion"
    static let requestedVersionKey = "reviewPrompt.requestedVersion"

    private let defaults: UserDefaults
    private let marketingVersion: String

    init(
        defaults: UserDefaults = .standard,
        marketingVersion: String = AppVersionInfo.marketingVersion
    ) {
        self.defaults = defaults
        self.marketingVersion = marketingVersion
    }

    var currentVersion: String { marketingVersion }

    var deliveredVersion: String? {
        defaults.string(forKey: Self.deliveredVersionKey)
    }

    var requestedVersion: String? {
        defaults.string(forKey: Self.requestedVersionKey)
    }

    var hasDeliveredNotificationThisVersion: Bool {
        deliveredVersion == currentVersion
    }

    var hasRequestedThisVersion: Bool {
        requestedVersion == currentVersion
    }

    var isEligibleToRequest: Bool {
        hasDeliveredNotificationThisVersion && !hasRequestedThisVersion
    }

    /// Records that the user experienced a show notification in this version.
    /// Returns `false` when this version was already marked.
    @discardableResult
    func markNotificationDelivered() -> Bool {
        guard !hasDeliveredNotificationThisVersion else { return false }
        defaults.set(currentVersion, forKey: Self.deliveredVersionKey)
        return true
    }

    func markRequested() {
        defaults.set(currentVersion, forKey: Self.requestedVersionKey)
    }
}
