import Foundation
import Testing
@testable import CardSlice

@MainActor
struct CardVCardExportTests {
    private func text(_ card: BusinessCardRecord) throws -> String {
        String(decoding: try CardVCardExportService.data(for: card), as: UTF8.self)
    }

    @Test func testRequiredPropertiesAndMissingOptionalFields() throws {
        let card = BusinessCardRecord(name: "Mira Stone", emails: ["mira@example.com"])
        let output = try text(card)
        #expect(output == "BEGIN:VCARD\r\nVERSION:3.0\r\nN:;Mira Stone;;;\r\nFN:Mira Stone\r\nEMAIL:mira@example.com\r\nEND:VCARD\r\n")
    }

    @Test func testChineseNameUsesUTF8WithoutSplittingName() throws {
        let data = try CardVCardExportService.data(for: BusinessCardRecord(name: "欧阳晓"))
        let output = try #require(String(data: data, encoding: .utf8))
        #expect(output.contains("N:;欧阳晓;;;\r\n"))
        #expect(output.contains("FN:欧阳晓\r\n"))
    }

    @Test func testCompanyTitleAndAllPhoneTypes() throws {
        let card = BusinessCardRecord(name: "林晓", company: "星河科技", jobTitle: "设计师",
                                      phones: [PhoneEntry(value: "13800138000", type: .mobile),
                                               PhoneEntry(value: "010-55550123", type: .office),
                                               PhoneEntry(value: "010-55550124", type: .fax),
                                               PhoneEntry(value: "+1 202-555-0101", type: .other)])
        let lines = try text(card).components(separatedBy: "\r\n")
        #expect(lines.contains("ORG:星河科技"))
        #expect(lines.contains("TITLE:设计师"))
        #expect(lines.filter { $0.hasPrefix("TEL") } ==
                ["TEL;TYPE=CELL:13800138000", "TEL;TYPE=WORK:010-55550123",
                 "TEL;TYPE=WORK,FAX:010-55550124", "TEL:+1 202-555-0101"])
    }

    @Test func testMultipleEmailsWebsiteAndStructuredAddress() throws {
        let card = BusinessCardRecord(name: "林晓", emails: ["first@example.com", "second@example.org"],
                                      website: "https://example.com/?a=1,2;b=3", address: "北京市示例路 12 号")
        let lines = try text(card).components(separatedBy: "\r\n")
        #expect(lines.filter { $0.hasPrefix("EMAIL:") } == ["EMAIL:first@example.com", "EMAIL:second@example.org"])
        #expect(lines.contains("URL:https://example.com/?a=1,2;b=3"))
        #expect(lines.contains("ADR:;;北京市示例路 12 号;;;;"))
    }

    @Test func testEscapesSpecialCharactersAndEveryNewlineStyle() throws {
        let card = BusinessCardRecord(name: "林晓", company: "A\\B; C, D\r\n第二行\r第三行\n第四行",
                                      address: "A;B, C")
        let output = try text(card)
        #expect(output.contains("ORG:A\\\\B\\; C\\, D\\n第二行\\n第三行\\n第四行\r\n"))
        #expect(output.contains("ADR:;;A\\;B\\, C;;;;\r\n"))
    }

    @Test func testLongUTF8LineFoldsAndUnfoldsWithoutDataLoss() throws {
        let address = String(repeating: "北京市示例路🚪", count: 30)
        let data = try CardVCardExportService.data(for: BusinessCardRecord(name: "林晓", address: address))
        let output = try #require(String(data: data, encoding: .utf8))
        #expect(output.contains("\r\n "))
        #expect(output.components(separatedBy: "\r\n").allSatisfy { $0.utf8.count <= 75 })
        #expect(output.replacingOccurrences(of: "\r\n ", with: "").contains("ADR:;;\(address);;;;\r\n"))
    }

    @Test func testBlankNameIsRejected() {
        #expect(throws: CardVCardExportError.missingName) {
            try CardVCardExportService.data(for: BusinessCardRecord(name: " \r\n\t"))
        }
    }

    @Test func testUsesLatestValuesAndLeavesInputUnchanged() throws {
        var card = BusinessCardRecord(ocrRawText: "OCR-only", parsedFields: ParsedContactFields(name: "Parsed-only"),
                                      name: "Old Name", notes: "[DECISION/TEMP]")
        let original = try text(card)
        card.name = "New Name"
        card.company = "New Company"
        let edited = card
        let output = try text(card)
        #expect(original.contains("FN:Old Name\r\n"))
        #expect(output.contains("FN:New Name\r\n"))
        #expect(output.contains("ORG:New Company\r\n"))
        for excluded in ["Old Name", "OCR-only", "Parsed-only", "[DECISION/TEMP]", card.id.uuidString] {
            #expect(!output.contains(excluded))
        }
        #expect(card == edited)
    }

    @Test func testTemporaryFilesAreUniqueAndContainVCFData() throws {
        let card = BusinessCardRecord(name: "林晓")
        let first = try CardVCardExportService.makeTemporaryFile(for: card)
        defer { CardVCardExportService.removeTemporaryFile(at: first) }
        let second = try CardVCardExportService.makeTemporaryFile(for: card)
        defer { CardVCardExportService.removeTemporaryFile(at: second) }
        #expect(first != second)
        #expect(first.lastPathComponent != second.lastPathComponent)
        #expect(first.pathExtension == "vcf" && second.pathExtension == "vcf")
        #expect(try Data(contentsOf: first) == CardVCardExportService.data(for: card))
    }
}
