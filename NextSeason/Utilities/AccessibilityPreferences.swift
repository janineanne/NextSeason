//
//  AccessibilityPreferences.swift
//  NextSeason
//

import UIKit

/// Runtime accessibility settings that affect timing and layout.
enum AccessibilityPreferences {
    static var isVoiceOverRunning: Bool {
        UIAccessibility.isVoiceOverRunning
    }

    /// How long the undo toast stays before auto-committing removal.
    static func undoRemovalWindowSeconds(isVoiceOverRunning: Bool = isVoiceOverRunning) -> TimeInterval {
        if UITestingConfiguration.isEnabled { return 30 }
        if isVoiceOverRunning { return 20 }
        return 5
    }
}
