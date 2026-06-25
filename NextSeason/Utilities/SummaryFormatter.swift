//
//  SummaryFormatter.swift
//  NextSeason
//

import Foundation

/// Renders TVMaze's light summary HTML as an `AttributedString`, preserving
/// paragraphs, bold, and italics while letting SwiftUI apply the app's font and
/// Dynamic Type (PD-009).
///
/// The limited tag set is converted to Markdown and parsed with
/// `inlineOnlyPreservingWhitespace`, which keeps our line breaks intact. Plain
/// text is used as a fallback if parsing ever fails.
nonisolated enum SummaryFormatter {
    /// Whether the HTML contains any text worth showing after tag stripping and
    /// whitespace normalization.
    static func hasDisplayableContent(_ html: String?) -> Bool {
        guard let html else { return false }
        return !plainText(fromHTML: html).isEmpty
    }

    /// Custom URL scheme for emphasis taps (analytics only; no navigation).
    static let analyticsEmphasisScheme = "nextseason-analytics"

    /// Bold label inserted into summaries so beta testers can trigger
    /// `actor_name_tapped` even when TVMaze provides no emphasis markup.
    static let analyticsTapTargetMarkdown = "**Tap here for Actor Name Analytics**"

    /// Like `attributedString(from:)`, but bold segments are tappable via the
    /// custom analytics URL scheme without changing their appearance.
    /// When `showID` is provided, a bold analytics tap target is inserted at a
    /// stable pseudo-random position in the summary.
    static func attributedStringWithTappableEmphasis(from html: String, showID: Int? = nil) -> AttributedString {
        let text: String
        if let showID {
            text = plainTextWithAnalyticsTapTarget(fromHTML: html, showID: showID)
        } else {
            text = plainText(fromHTML: html)
        }
        var attributed = attributedString(fromPlainText: text)
        for run in attributed.runs {
            guard run.inlinePresentationIntent?.contains(.stronglyEmphasized) == true else { continue }
            attributed[run.range].link = URL(string: "\(analyticsEmphasisScheme)://emphasis")!
        }
        return attributed
    }

    static func attributedString(from html: String) -> AttributedString {
        attributedString(fromPlainText: plainText(fromHTML: html))
    }

    private static func attributedString(fromPlainText text: String) -> AttributedString {
        let options = AttributedString.MarkdownParsingOptions(
            interpretedSyntax: .inlineOnlyPreservingWhitespace
        )
        if let attributed = try? AttributedString(markdown: text, options: options) {
            return attributed
        }
        return AttributedString(text)
    }

    private static func plainTextWithAnalyticsTapTarget(fromHTML html: String, showID: Int) -> String {
        let summary = plainText(fromHTML: html)
        let marker = analyticsTapTargetMarkdown
        guard !summary.isEmpty else { return marker }

        switch analyticsTapPlacement(for: showID) {
        case .leading:
            return marker + " " + summary
        case .middle:
            return insertAnalyticsTapTargetAtMiddle(marker, in: summary)
        case .trailing:
            return summary + " " + marker
        }
    }

    private enum AnalyticsTapPlacement {
        case leading
        case middle
        case trailing
    }

    private static func analyticsTapPlacement(for showID: Int) -> AnalyticsTapPlacement {
        switch abs(showID &* 2654435761) % 3 {
        case 0: .leading
        case 1: .middle
        default: .trailing
        }
    }

    private static func insertAnalyticsTapTargetAtMiddle(_ marker: String, in text: String) -> String {
        guard !text.isEmpty else { return marker }
        let midpoint = text.count / 2
        let offsetIndex = text.index(text.startIndex, offsetBy: min(midpoint, text.count - 1))
        let insertIndex: String.Index
        if let space = text[offsetIndex...].firstIndex(of: " ") {
            insertIndex = space
        } else if let space = text[..<offsetIndex].lastIndex(of: " ") {
            insertIndex = space
        } else {
            insertIndex = text.endIndex
        }
        var result = text
        result.insert(contentsOf: " " + marker + " ", at: insertIndex)
        return result
    }

    private static func plainText(fromHTML html: String) -> String {
        var text = html

        let blockReplacements: [(String, String)] = [
            ("</p>", "\n\n"),
            ("<br>", "\n"),
            ("<br/>", "\n"),
            ("<br />", "\n")
        ]
        for (tag, replacement) in blockReplacements {
            text = text.replacingOccurrences(of: tag, with: replacement, options: .caseInsensitive)
        }

        text = text.replacingOccurrences(of: "\u{00A0}", with: " ")

        // TVMaze often puts a trailing space inside emphasis tags, e.g.
        // `<b>Murdoch Mysteries </b>is`. Move that space outside the marker so
        // Markdown parsing succeeds: `**Murdoch Mysteries** is`.
        let spacedClosingTags: [(String, String)] = [
            (" </b>", "** "),
            (" </strong>", "** "),
            (" </i>", "* "),
            (" </em>", "* ")
        ]
        for (pattern, replacement) in spacedClosingTags {
            text = text.replacingOccurrences(of: pattern, with: replacement, options: .caseInsensitive)
        }

        // Opening tags may include attributes; closing tags may include whitespace.
        let inlinePatterns: [(String, String)] = [
            ("<(?:b|strong)(?:\\s[^>]*)?>", "**"),
            ("</(?:b|strong)\\s*>", "**"),
            ("<(?:i|em)(?:\\s[^>]*)?>", "*"),
            ("</(?:i|em)\\s*>", "*")
        ]
        for (pattern, replacement) in inlinePatterns {
            text = text.replacingOccurrences(
                of: pattern,
                with: replacement,
                options: [.regularExpression, .caseInsensitive]
            )
        }

        // Drop any remaining tags (e.g. opening <p>, stray markup).
        text = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)

        text = text.decodingBasicHTMLEntities

        // Normalize messy source whitespace without disturbing paragraph breaks.
        text = text.replacingOccurrences(of: "[ \\t]+", with: " ", options: .regularExpression)
        text = text.replacingOccurrences(of: " *\\n *", with: "\n", options: .regularExpression)

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
