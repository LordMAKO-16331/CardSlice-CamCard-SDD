import Testing
import Foundation
@testable import CardSlice

@MainActor
struct CardFieldCorrectionTests {
    private func source() -> CardContactParseResult {
        CardContactParseResult(rawText: "Original OCR", fields: ParsedContactFields(name: "林晓", company: "示例公司",
            jobTitle: "Engineer", phones: [PhoneEntry(value: "+1 202-555-0100", type: .office)],
            emails: ["sample@example.com"], rawTextSegments: ["未分类"]), reviews: [])
    }
    @Test func testInitializesFromParsedResult() {
        let draft = CardFieldCorrectionDraft(result: source())
        #expect(draft.name == "林晓" && draft.company == "示例公司" && draft.jobTitle == "Engineer")
        #expect(draft.phones.first?.value == "+1 202-555-0100")
        #expect(draft.emails.first?.value == "sample@example.com")
    }
    @Test func testEditsIdentityFields() throws {
        var draft = CardFieldCorrectionDraft(result: source())
        draft.name = "Mira Stone"; draft.company = "Virtual Studio"; draft.jobTitle = "Designer"
        let fields = try draft.confirmedFields()
        #expect(fields.name == "Mira Stone" && fields.company == "Virtual Studio" && fields.jobTitle == "Designer")
    }
    @Test func testMissingFieldsCanBeAdded() throws {
        var draft = CardFieldCorrectionDraft(result: source())
        #expect(draft.website.isEmpty && draft.address.isEmpty)
        draft.website = "https://example.com"; draft.address = "北京市示例路1号"
        #expect(try draft.confirmedFields().website == "https://example.com")
        #expect(try draft.confirmedFields().address == "北京市示例路1号")
    }
    @Test func testAddsAndRemovesPhones() throws {
        var draft = CardFieldCorrectionDraft(result: source())
        draft.phones.append(CardCorrectionPhone(value: "+44 (20) 7946-0123", type: .fax))
        draft.phones.removeFirst()
        #expect(try draft.confirmedFields().phones.map(\.value) == ["+44 (20) 7946-0123"])
    }
    @Test func testChangesPhoneType() throws {
        var draft = CardFieldCorrectionDraft(result: source())
        draft.phones[0].type = .mobile
        #expect(try draft.confirmedFields().phones.first?.type == .mobile)
    }
    @Test func testAddsAndRemovesEmails() throws {
        var draft = CardFieldCorrectionDraft(result: source())
        draft.emails.append(CardCorrectionEmail(value: "second@example.org"))
        draft.emails.removeFirst()
        #expect(try draft.confirmedFields().emails == ["second@example.org"])
    }
    @Test func testOriginalOCRIsUnchanged() {
        var draft = CardFieldCorrectionDraft(result: source())
        draft.name = "更正姓名"
        #expect(draft.original.rawText == "Original OCR")
    }
    @Test func testInitialParsingIsNotOverwritten() throws {
        let original = source()
        var draft = CardFieldCorrectionDraft(result: original)
        draft.name = "更正姓名"; draft.phones[0].value = "+81 3-1234-5678"
        _ = try draft.confirmedFields()
        #expect(draft.original == original)
        #expect(original.fields.name == "林晓")
        #expect(original.fields.phones.first?.value == "+1 202-555-0100")
    }
    @Test func testEmptyOptionalFieldsRemainMissing() throws {
        let result = CardContactParseResult(rawText: "", fields: ParsedContactFields(), reviews: [])
        var draft = CardFieldCorrectionDraft(result: result)
        draft.name = "  "
        let fields = try draft.confirmedFields()
        #expect(fields.name == nil && fields.company == nil && fields.website == nil && fields.address == nil)
        #expect(fields.phones.isEmpty && fields.emails.isEmpty)
    }
    @Test func testConfirmedFieldsMatchUserEdits() throws {
        var draft = CardFieldCorrectionDraft(result: source())
        draft.name = "王晓"; draft.address = "Test Road 12"
        draft.phones[0].value = "+44 (20) 1234-5678"
        let result = try draft.confirmedFields()
        #expect(result.name == draft.name && result.address == draft.address)
        #expect(result.phones[0].value == draft.phones[0].value)
        #expect(result.emails == draft.emails.map(\.value))
        #expect(result.rawTextSegments == ["未分类"])
    }
    @Test func testInvalidEmailPreservesInput() {
        var draft = CardFieldCorrectionDraft(result: source())
        draft.emails[0].value = "invalid-email"
        #expect(!draft.validationMessages.isEmpty)
        #expect(throws: CardFieldCorrectionError.self) { try draft.confirmedFields() }
        #expect(draft.emails[0].value == "invalid-email")
    }
    @Test func testEmptyContactRowsMustBeFilledOrDeleted() {
        var draft = CardFieldCorrectionDraft(result: source())
        draft.phones.append(CardCorrectionPhone())
        draft.emails.append(CardCorrectionEmail())
        #expect(draft.validationMessages.count == 2)
        #expect(throws: CardFieldCorrectionError.self) { try draft.confirmedFields() }
    }
}
