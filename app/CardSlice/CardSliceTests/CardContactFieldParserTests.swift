import Testing
import Foundation
import CoreGraphics
@testable import CardSlice

@MainActor
struct CardContactFieldParserTests {
    private func parse(_ text: String) throws -> CardContactParseResult {
        let lines = text.components(separatedBy: "\n").map {
            RecognizedCardTextLine(text: $0, confidence: 0.95, boundingBox: .zero)
        }
        return try CardContactFieldParser.parse(RecognizedCardText(lines: lines, languages: ["zh-Hans", "en-US"]))
    }
    @Test func testEmptyTextIsSafe() throws {
        let r = try parse("")
        #expect(r.fields.name == nil && r.fields.phones.isEmpty && r.fields.emails.isEmpty)
    }
    @Test func testChineseIdentity() throws {
        let r = try parse("星河科技有限公司\n林晓\n软件工程师")
        #expect(r.fields.name == "林晓")
        #expect(r.fields.company == "星河科技有限公司")
        #expect(r.fields.jobTitle == "软件工程师")
    }
    @Test func testEnglishIdentityCompanyFirst() throws {
        let r = try parse("Example Studio LLC\nAlice Green\nSoftware Engineer")
        #expect(r.fields.name == "Alice Green")
        #expect(r.fields.company == "Example Studio LLC")
        #expect(r.fields.jobTitle == "Software Engineer")
    }
    @Test func testMainlandAndInternationalPhonesPreserveDigits() throws {
        let r = try parse("13800138000\n+44 (20) 7946-0123")
        #expect(r.fields.phones.map(\.value) == ["13800138000", "+44 (20) 7946-0123"])
        #expect(r.fields.phones.allSatisfy { $0.type == .other })
    }
    @Test func testPhoneTypesByNearbyLabels() throws {
        let r = try parse("Mobile: +1 202-555-0101 Office: +1 202-555-0102 Fax: +1 202-555-0103")
        #expect(r.fields.phones.map(\.type) == [.mobile, .office, .fax])
    }
    @Test func testMultiplePhonesAreDeduplicated() throws {
        let r = try parse("Mobile: 138-0013-8000\nMobile: 13800138000\nFax: 010-55550123")
        #expect(r.fields.phones.count == 2)
        #expect(r.fields.phones[0].value == "138-0013-8000")
    }
    @Test func testMultipleEmailsAreDeduplicated() throws {
        let r = try parse("Email: a@example.com; b@example.com.\na@example.com")
        #expect(r.fields.emails == ["a@example.com", "b@example.com"])
    }
    @Test func testWebsiteAndEmailAreDistinct() throws {
        let r = try parse("a@example.com\nhttps://www.example.org")
        #expect(r.fields.emails == ["a@example.com"])
        #expect(r.fields.website == "https://www.example.org")
    }
    @Test func testMissingWebsiteIsNil() throws {
        #expect(try parse("Email: a@example.com").fields.website == nil)
    }
    @Test func testChineseAndEnglishMultilineAddresses() throws {
        let cn = try parse("地址：北京市朝阳区示例路88号\nA座12层")
        #expect(cn.fields.address == "北京市朝阳区示例路88号\nA座12层")
        let en = try parse("123 Example Road\nSuite 400\nBoston, MA 02110")
        #expect(en.fields.address == "123 Example Road\nSuite 400\nBoston, MA 02110")
    }
    @Test func testAddressPostalCodeAndDateAreNotPhones() throws {
        let r = try parse("地址：北京市示例路12345678号\n100000\n2026-11-03\nPostal: 02110")
        #expect(r.fields.phones.isEmpty)
    }
    @Test func testUnknownTextIsPreserved() throws {
        #expect(try parse("让创意连接每一种可能！").fields.rawTextSegments == ["让创意连接每一种可能！"])
    }
    @Test func testSameInputIsDeterministicAndRawTextUnchanged() throws {
        let text = "Name: Mira Stone\nEmail: mira@example.com\nMobile: +1-202-555-0199"
        let a = try parse(text), b = try parse(text)
        #expect(a == b)
        #expect(a.rawText == text)
    }
    @Test func testAmbiguousNamesStayUnselected() throws {
        let r = try parse("Alice Green\nMira Stone")
        #expect(r.fields.name == nil)
        #expect(r.reviews.contains { $0.field == "姓名" && $0.candidates.count == 2 })
    }
    @Test func testAdjacentPhoneLabelAndConflictingTypes() throws {
        let r = try parse("Fax:\n010-55550123\nOffice: 010-55550123")
        #expect(r.fields.phones.count == 1)
        #expect(r.fields.phones.first?.type == .fax)
        #expect(r.reviews.contains { $0.field == "电话类别" })
    }

    @Test func testUniqueChineseAndEnglishNameCandidatesAreAssigned() throws {
        #expect(try parse("林晓").fields.name == "林晓")
        #expect(try parse("Mira Stone").fields.name == "Mira Stone")
    }
    @Test func testExplicitNameWinsOverUnlabeledShapeWithoutLosingCandidates() throws {
        let input = "Name: Mira Stone\nCreative Partner"
        let result = try parse(input)
        #expect(result.fields.name == "Mira Stone")
        #expect(result.rawText == input)
        #expect(result.reviews.contains { $0.field == "姓名" && $0.candidates == ["Mira Stone", "Creative Partner"] })
        #expect(CardFieldCorrectionDraft(result: result).name == "Mira Stone")
    }
    @Test func testExplicitChineseNameWinsOverShortUnlabeledText() throws {
        let result = try parse("姓名：林晓\n创新未来")
        #expect(result.fields.name == "林晓")
        #expect(result.reviews.contains { $0.candidates.contains("创新未来") })
    }
    @Test func testCompanyFirstIsNotAnExtraNameCandidate() throws {
        let result = try parse("Example Group\nMira Stone\nMobile: +1-202-555-0100\nEmail: mira@example.com")
        #expect(result.fields.name == "Mira Stone")
        #expect(result.fields.company == "Example Group")
        #expect(result.fields.phones.first?.value == "+1-202-555-0100")
        #expect(result.fields.emails == ["mira@example.com"])
        #expect(!result.reviews.contains { $0.field == "姓名" && $0.candidates.contains("Example Group") })
    }
    @Test func testConflictingExplicitNamesRemainAmbiguous() throws {
        let result = try parse("Name: Mira Stone\n姓名：林晓")
        #expect(result.fields.name == nil)
        #expect(result.reviews.contains { $0.field == "姓名" && $0.candidates == ["Mira Stone", "林晓"] })
    }
    @Test func testCompanyUnderNameLabelIsNotAssignedAsName() throws {
        let result = try parse("Name: Example Studio LLC")
        #expect(result.fields.name == nil)
        #expect(result.reviews.contains { $0.field == "姓名" && $0.candidates.contains("Example Studio LLC") })
    }
    @Test func testLowConfidenceOnlyNameRemainsUnselected() throws {
        let line = RecognizedCardTextLine(text: "Mira Stone", confidence: 0.2, boundingBox: .zero)
        let ocr = RecognizedCardText(lines: [line], languages: ["en-US"])
        let result = try CardContactFieldParser.parse(ocr)
        #expect(result.fields.name == nil)
        #expect(result.rawText == ocr.rawText)
        #expect(result.reviews.contains { $0.field == "姓名" && $0.candidates.contains("Mira Stone") })
    }
    @Test func testNoNameEvidenceStaysMissing() throws {
        let result = try parse("Example Technology Ltd\nEmail: hello@example.com\nFax: +1-202-555-0101")
        #expect(result.fields.name == nil)
        #expect(result.fields.company == "Example Technology Ltd")
        #expect(result.fields.phones.first?.type == .fax)
        #expect(result.fields.emails == ["hello@example.com"])
    }
}
