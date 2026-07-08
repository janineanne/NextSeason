//
//  KeyboardEditing.swift
//  NextSeason
//

import UIKit

/// UIKit bridge for ending text-field editing without collapsing SwiftUI search chrome.
enum KeyboardEditing {
    /// Resigns first responder so the keyboard dismisses while a nav-bar search
    /// field keeps its visible query (unlike toggling `.searchable` presentation).
    static func dismissEditing() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}
