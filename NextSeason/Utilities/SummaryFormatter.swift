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

    static func attributedString(from html: String) -> AttributedString {
        let text = plainText(fromHTML: html)
        let options = AttributedString.MarkdownParsingOptions(
            interpretedSyntax: .inlineOnlyPreservingWhitespace
        )
        if let attributed = try? AttributedString(markdown: text, options: options) {
            return attributed
        }
        return AttributedString(text)
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
