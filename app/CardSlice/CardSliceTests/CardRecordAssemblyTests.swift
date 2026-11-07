import Testing
import Foundation
import CoreGraphics
import SwiftData
@testable import CardSlice

@MainActor
struct CardRecordAssemblyTests {
    private func fixture() -> (PreparedCardImage, RecognizedCardText, CardContactParseResult, CardFieldCorrectionDraft) {
        let prepared = PreparedCardImage(originalData: Data("original-image".utf8), processedData: Data("prepared-image".utf8), pixelWidth: 100, pixelHeight: 50)
        let ocr = RecognizedCardText(lines: [RecognizedCardTextLine(text: "Initial OCR", confidence: 0.9, boundingBox: .zero)], languages: ["zh-Hans", "en-US"])
        let parsed = CardContactParseResult(rawText: ocr.rawText, fields: ParsedContactFields(name: "初始姓名", company: "初始公司"), reviews: [])
        var draft = CardFieldCorrectionDraft(result: parsed)
        draft.name = "确认姓名"; draft.company = "确认公司"; draft.jobTitle = "Designer"
        draft.phones = [CardCorrectionPhone(value: "+1 202-555-0101", type: .mobile), CardCorrectionPhone(value: "+44 (20) 7946-0123", type: .fax)]
        draft.emails = [CardCorrectionEmail(value: "one@example.com"), CardCorrectionEmail(value: "two@example.org")]
        return (prepared, ocr, parsed, draft)
    }
    private func record() throws -> BusinessCardRecord {
        let (p, o, i, d) = fixture()
        return try CardRecordAssemblyService.assemble(prepared: p, correctedData: nil, ocr: o, initial: i, draft: d, recognizedImageData: p.processedData)
    }
    @Test func testConfirmedIdentityIsUsed() throws {
        let r = try record()
        #expect(r.name == "确认姓名" && r.company == "确认公司" && r.jobTitle == "Designer")
    }
    @Test func testOriginalOCRIsPreserved() throws { #expect(try record().ocrRawText == "Initial OCR") }
    @Test func testInitialParsedFieldsAreNotOverwritten() throws {
        let r = try record()
        #expect(r.parsedFields?.name == "初始姓名")
        #expect(r.parsedFields?.company == "初始公司")
    }
    @Test func testOriginalAndPreparedImagesAreDistinct() throws {
        let r = try record()
        #expect(r.originalImageData == Data("original-image".utf8))
        #expect(r.processedImageData == Data("prepared-image".utf8))
    }
    @Test func testCorrectedImageIsPreferred() throws {
        let (p, o, i, d) = fixture()
        let corrected = Data("corrected-image".utf8)
        let r = try CardRecordAssemblyService.assemble(prepared: p, correctedData: corrected, ocr: o, initial: i, draft: d, recognizedImageData: corrected)
        #expect(r.processedImageData == corrected)
        #expect(r.originalImageData == p.originalData)
    }
    @Test func testAllPhonesAndFaxArePreserved() throws {
        let r = try record()
        #expect(r.phones.map(\.type) == [.mobile, .fax])
        #expect(r.phones.map(\.value) == ["+1 202-555-0101", "+44 (20) 7946-0123"])
    }
    @Test func testAllEmailsArePreserved() throws {
        #expect(try record().emails == ["one@example.com", "two@example.org"])
    }
    @Test func testMissingOptionalFieldsAreNotInvented() throws {
        let r = try record()
        #expect(r.website == nil && r.address == nil && r.notes == nil && r.tagIDs.isEmpty)
    }
    @Test func testSeparateRecordsHaveUniqueIDs() throws {
        let a = try record(), b = try record()
        #expect(a.id != b.id)
        #expect(a.createdAt == a.updatedAt)
    }
    @Test func testRecordCanBeSavedAndReadThroughSwiftDataRepository() async throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: PersistedBusinessCard.self, configurations: configuration)
        defer { withExtendedLifetime(container) {} }
        let repository = SwiftDataCardRepository(modelContext: container.mainContext)
        let r = try record()
        try await repository.insert(r)
        let read = try await repository.fetch(id: r.id)
        #expect(read.name == r.name && read.phones == r.phones && read.emails == r.emails)
        #expect(read.originalImageData == r.originalImageData && read.processedImageData == r.processedImageData)
        #expect(read.ocrRawText == r.ocrRawText && read.parsedFields == r.parsedFields)
    }
    @Test func testMissingNameIsRejected() {
        let (p, o, i, initialDraft) = fixture()
        var d = initialDraft; d.name = "  "
        #expect(throws: CardRecordAssemblyError.self) {
            try CardRecordAssemblyService.assemble(prepared: p, correctedData: nil, ocr: o, initial: i, draft: d, recognizedImageData: p.processedData)
        }
    }
    @Test func testMismatchedImageOrParsingIsRejected() {
        let (p, o, i, d) = fixture()
        #expect(throws: CardRecordAssemblyError.self) {
            try CardRecordAssemblyService.assemble(prepared: p, correctedData: nil, ocr: o, initial: i, draft: d, recognizedImageData: Data("another-image".utf8))
        }
        let wrong = CardContactParseResult(rawText: "another OCR", fields: ParsedContactFields(), reviews: [])
        #expect(throws: CardRecordAssemblyError.self) {
            try CardRecordAssemblyService.assemble(prepared: p, correctedData: nil, ocr: o, initial: wrong, draft: d, recognizedImageData: p.processedData)
        }
    }
    @Test func testDuplicateSubmissionIsBlockedDuringAndAfterSave() async throws {
        let state = CardRecordSaveState(), r = try record()
        var inserts = 0
        let first = await state.save(r) { record in
            inserts += 1
            #expect(record.id == r.id)
            let duplicate = await state.save(r) { _ in inserts += 1 }
            #expect(!duplicate)
        }
        #expect(first && state.savedID == r.id)
        let again = await state.save(r) { _ in inserts += 1 }
        #expect(!again && inserts == 1)
    }
    @Test func testFailedRetryRetainsUUIDAndReportsError() async throws {
        let state = CardRecordSaveState(), r = try record()
        let failed = await state.save(r) { _ in throw CardRepositoryError.saveFailed("test failure") }
        #expect(!failed && state.errorMessage != nil && state.savedID == nil && !state.isSaving)
        let differentRecord = try record()
        let retried = await state.save(differentRecord) { retry in #expect(retry.id == r.id) }
        #expect(retried && state.savedID == r.id)
    }
}
