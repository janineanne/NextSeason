//
//  ShowIDMapping+Environment.swift
//  NextSeason
//

import SwiftUI

private struct ShowIDMappingKey: EnvironmentKey {
    static let defaultValue: any ShowIDMapping = InMemoryShowIDMapping(map: [:])
}

extension EnvironmentValues {
    /// Offline TheTVDB ↔ TVMaze id map. Previews default to an empty map.
    var showIDMapping: any ShowIDMapping {
        get { self[ShowIDMappingKey.self] }
        set { self[ShowIDMappingKey.self] = newValue }
    }
}
