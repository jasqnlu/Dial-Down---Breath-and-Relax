import Testing
@testable import BreathRelaxStretch

// The data export builds CSV rows by joining raw strings with commas. Routine
// names, display names, and author names are user-controlled, so they must be
// escaped per RFC 4180 (quoting) and neutralized against spreadsheet formula
// injection (a name like "=HYPERLINK(...)" executing when the exported file is
// opened in Excel/Numbers). These tests pin DataExportView.csvField(_:).
struct CSVFieldTests {

    // MARK: - RFC 4180 quoting

    @Test func plainFieldPassesThroughUnchanged() {
        #expect(DataExportView.csvField("Morning Reset") == "Morning Reset")
    }

    @Test func fieldWithCommaIsQuoted() {
        #expect(DataExportView.csvField("Neck, Shoulders") == "\"Neck, Shoulders\"")
    }

    @Test func embeddedQuotesAreDoubledAndFieldQuoted() {
        #expect(DataExportView.csvField(#"say "hi""#) == #""say ""hi""""#)
    }

    @Test func fieldWithNewlineIsQuoted() {
        #expect(DataExportView.csvField("line1\nline2") == "\"line1\nline2\"")
    }

    // MARK: - Formula-injection neutralization
    // OWASP: fields starting with = + - @ (or tab/CR) become live formulas in
    // Excel and Numbers. A leading apostrophe forces text interpretation.

    @Test func leadingEqualsIsNeutralized() {
        #expect(DataExportView.csvField("=HYPERLINK(\"http://evil\")")
                == "\"'=HYPERLINK(\"\"http://evil\"\")\"")
    }

    @Test func leadingPlusMinusAtAreNeutralized() {
        #expect(DataExportView.csvField("+1234") == "'+1234")
        #expect(DataExportView.csvField("-cmd") == "'-cmd")
        #expect(DataExportView.csvField("@sum") == "'@sum")
    }

    @Test func neutralizedFieldWithCommaIsAlsoQuoted() {
        #expect(DataExportView.csvField("=A1,B1") == "\"'=A1,B1\"")
    }

    @Test func equalsInsideFieldIsLeftAlone() {
        // Only a *leading* formula character is dangerous.
        #expect(DataExportView.csvField("a=b") == "a=b")
    }

    @Test func emptyFieldStaysEmpty() {
        #expect(DataExportView.csvField("") == "")
    }
}
