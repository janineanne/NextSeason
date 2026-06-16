//
//  SummaryFormatterTests.swift
//  NextSeasonTests
//

import Testing
import Foundation
@testable import NextSeason

struct SummaryFormatterTests {
    @Test("Tags are stripped, leaving plain text")
    func plainText() {
        let result = SummaryFormatter.attributedString(from: "<p>Hello world</p>")
        #expect(String(result.characters) == "Hello world")
    }

    @Test("Bold tags become strong emphasis")
    func bold() {
        let result = SummaryFormatter.attributedString(from: "<p>Hello <b>world</b></p>")
        #expect(String(result.characters) == "Hello world")
        let hasStrong = result.runs.contains {
            $0.inlinePresentationIntent?.contains(.stronglyEmphasized) == true
        }
        #expect(hasStrong)
    }

    @Test("Italic tags become emphasis")
    func italic() {
        let result = SummaryFormatter.attributedString(from: "<p>Hello <i>world</i></p>")
        let hasEmphasis = result.runs.contains {
            $0.inlinePresentationIntent?.contains(.emphasized) == true
        }
        #expect(hasEmphasis)
    }

    @Test("Basic HTML entities are decoded")
    func entities() {
        let result = SummaryFormatter.attributedString(from: "<p>Tom &amp; Jerry</p>")
        #expect(String(result.characters) == "Tom & Jerry")
    }

    @Test("Paragraphs are preserved as blank-line separators")
    func paragraphs() {
        let result = SummaryFormatter.attributedString(from: "<p>One</p><p>Two</p>")
        #expect(String(result.characters) == "One\n\nTwo")
    }

    @Test("A stray space + non-breaking space is collapsed (Call the Midwife)")
    func collapsesSpaceAndNonBreakingSpace() {
        let result = SummaryFormatter.attributedString(from: "<p>Following. \u{00A0}Based on memoirs.</p>")
        #expect(String(result.characters) == "Following. Based on memoirs.")
    }

    @Test("Repeated spaces are collapsed to one")
    func collapsesDoubleSpaces() {
        let result = SummaryFormatter.attributedString(from: "<p>One.  Two.</p>")
        #expect(String(result.characters) == "One. Two.")
    }

    @Test("Whitespace normalization preserves paragraph breaks")
    func normalizationKeepsParagraphs() {
        let result = SummaryFormatter.attributedString(from: "<p>A.  B.</p><p>C.</p>")
        #expect(String(result.characters) == "A. B.\n\nC.")
    }

    @Test("Empty HTML yields no displayable content")
    func emptyHTML() {
        #expect(SummaryFormatter.hasDisplayableContent("") == false)
        #expect(String(SummaryFormatter.attributedString(from: "").characters).isEmpty)
    }

    @Test("Whitespace-only HTML yields no displayable content")
    func whitespaceOnlyHTML() {
        #expect(SummaryFormatter.hasDisplayableContent("<p>   </p>") == false)
        #expect(SummaryFormatter.hasDisplayableContent("  \n\t  ") == false)
        #expect(String(SummaryFormatter.attributedString(from: "<p>   </p>").characters).isEmpty)
    }
}
