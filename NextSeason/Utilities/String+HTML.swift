//
//  String+HTML.swift
//  NextSeason
//

import Foundation

extension String {
    /// Decodes the small set of HTML entities that appear in TVMaze text.
    nonisolated var decodingBasicHTMLEntities: String {
        replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&apos;", with: "'")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&nbsp;", with: " ")
    }

    /// Removes HTML tags and decodes entities to produce plain display text.
    /// Used as a fallback when rich formatting isn't needed or fails.
    nonisolated var strippingHTMLTags: String {
        replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .decodingBasicHTMLEntities
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
