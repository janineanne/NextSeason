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
    /// UserDefaults: marketing version when a show notification was first experienced.
    static let deliveredVersionKey = "reviewPrompt.notificationDeliveredVersion"
    /// UserDefaults: marketing version when `RequestReviewAction` was last attempted.
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

    /// True when this version delivered a notification and has not yet attempted a review prompt.
    var isEligibleToRequest: Bool {
        hasDeliveredNotificationThisVersion && !hasRequestedThisVersion
    }

    /// Records that the user experienced a show notification in this version.
    /// Returns `false` when this version was already marked.
    @discardableResult
    func markNotificationReceived() -> Bool {
        guard !hasDeliveredNotificationThisVersion else { return false }
        defaults.set(currentVersion, forKey: Self.deliveredVersionKey)
        return true
    }

    /// Records that this marketing version already attempted a review request.
    func markRequested() {
        defaults.set(currentVersion, forKey: Self.requestedVersionKey)
    }
}
