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

        let replacements: [(String, String)] = [
            ("</p>", "\n\n"),
            ("<br>", "\n"),
            ("<br/>", "\n"),
            ("<br />", "\n"),
            ("<b>", "**"), ("</b>", "**"),
            ("<strong>", "**"), ("</strong>", "**"),
            ("<i>", "*"), ("</i>", "*"),
            ("<em>", "*"), ("</em>", "*")
        ]
        for (tag, markdown) in replacements {
            text = text.replacingOccurrences(of: tag, with: markdown, options: .caseInsensitive)
        }

        // Drop any remaining tags (e.g. opening <p>, stray markup).
        text = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)

        text = text.decodingBasicHTMLEntities

        // Normalize messy source whitespace (TVMaze summaries often contain stray
        // non-breaking spaces and double spaces) without disturbing the paragraph
        // and line breaks we inserted above.
        text = text.replacingOccurrences(of: "\u{00A0}", with: " ")
        text = text.replacingOccurrences(of: "[ \\t]+", with: " ", options: .regularExpression)
        text = text.replacingOccurrences(of: " *\\n *", with: "\n", options: .regularExpression)

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
