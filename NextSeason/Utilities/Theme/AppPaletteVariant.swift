//
//  AppPaletteVariant.swift
//  NextSeason
//

import Foundation

/// Named color palettes for comparing visual directions in debug builds.
enum AppPaletteVariant: String, CaseIterable, Identifiable, Sendable {
    case lavender
    case tealUtility
    case warmSlate

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .lavender:
            "Lavender (Current)"
        case .tealUtility:
            "Teal Utility"
        case .warmSlate:
            "Warm Slate"
        }
    }

    var summary: String {
        switch self {
        case .lavender:
            "Lavender-gray chrome with a muted purple accent."
        case .tealUtility:
            "Cool neutral surfaces with a teal accent."
        case .warmSlate:
            "Warm stone surfaces with a slate accent."
        }
    }
}
