import Foundation
import SwiftData
import Testing
@testable import CardSlice

@MainActor
struct CardSavedRecordEditingTests {
    private func fixture() -> BusinessCardRecord {
        let date = Date(timeIntervalSince1970: 1_000)
        return BusinessCardRecord(originalImageData: Data([1, 2]), processedImageData: Data([3, 4]),
            ocrRawText: "Raw OCR", parsedFields: ParsedContactFields(name: "OCR name"),
            name: "Saved name", company: "Saved company", jobTitle: "Engineer",
            phones: [PhoneEntry(value: "+1 202-555-0101", type: .office)],
            emails: ["first@example.com", "second@example.com"], website: "https://example.com",
            address: "12 Example Street", tagIDs: [UUID()], notes: "Original note",
            createdAt: date, updatedAt: date)
    }

    @Test func testDraftLoadsCurrentSavedFieldsInsteadOfOCR() async throws {
        let card = fixture()
        let repository = try InMemoryCardRepository(initialRecords: [card])
        let editor = CardSavedRecordEditor(repository: repository)
        let loaded = try await editor.load(id: card.id)
        let draft = CardFieldCorrectionDraft(savedRecord: loaded)
        #expect(draft.name == card.name && draft.company == card.company && draft.jobTitle == card.jobTitle)
        #expect(draft.phones.map(\.value) == card.phones.map(\.value))
        #expect(draft.emails.map(\.value) == card.emails)
        #expect(draft.website == card.website && draft.address == card.address)
        #expect(draft.original.fields == card.parsedFields)
        #expect(draft.original.rawText == card.ocrRawText)
    }

    @Test func testDiscardingDraftDoesNotWrite() async throws {
        let card = fixture()
        let repository = try InMemoryCardRepository(initialRecords: [card])
        var draft = CardFieldCorrectionDraft(savedRecord: card)
        draft.name = "Discarded name"
        draft.phones.removeAll()
        #expect(draft.name != card.name)
        let read = try await repository.fetch(id: card.id)
        #expect(read == card)
    }

    @Test func testSaveUpdatesOnlyTargetAndPreservesMetadata() async throws {
        let card = fixture(), other = fixture()
        let repository = try InMemoryCardRepository(initialRecords: [card, other])
        let editor = CardSavedRecordEditor(repository: repository)
        var draft = CardFieldCorrectionDraft(savedRecord: card)
        draft.name = "Updated name"
        draft.company = "Updated company"
        draft.jobTitle = "Designer"
        draft.phones[0].value = "+44 (20) 7946-0123"
        draft.phones[0].type = .fax
        draft.emails.removeFirst()
        draft.emails.append(CardCorrectionEmail(value: "new@example.org"))
        draft.website = ""
        draft.address = "24 Example Street"
        let updated = try await editor.save(id: card.id, fields: draft.confirmedFields())
        let read = try await repository.fetch(id: card.id)
        #expect(read == updated)
        #expect(read.name == "Updated name" && read.company == "Updated company" && read.jobTitle == "Designer")
        #expect(read.phones == [PhoneEntry(value: "+44 (20) 7946-0123", type: .fax)])
        #expect(read.emails == ["second@example.com", "new@example.org"])
        #expect(read.website == nil && read.address == "24 Example Street")
        #expect(read.id == card.id && read.createdAt == card.createdAt && read.updatedAt > card.updatedAt)
        #expect(read.originalImageData == card.originalImageData && read.processedImageData == card.processedImageData)
        #expect(read.ocrRawText == card.ocrRawText && read.parsedFields == card.parsedFields)
        #expect(read.tagIDs == card.tagIDs && read.notes == card.notes)
        let untouched = try await repository.fetch(id: other.id)
        let all = try await repository.fetchAll()
        #expect(untouched == other && all.count == 2)
    }

    @Test func testMissingRecordReturnsNotFoundWithoutInserting() async throws {
        let repository = try InMemoryCardRepository()
        let id = UUID()
        let editor = CardSavedRecordEditor(repository: repository)
        await #expect(throws: CardRepositoryError.notFound(id: id)) {
            try await editor.save(id: id, fields: ParsedContactFields(name: "New name"))
        }
        let all = try await repository.fetchAll()
        #expect(all.isEmpty)
    }

    @Test func testBlankNameDoesNotChangeRecord() async throws {
        let card = fixture()
        let repository = try InMemoryCardRepository(initialRecords: [card])
        let editor = CardSavedRecordEditor(repository: repository)
        await #expect(throws: CardFieldCorrectionError.self) {
            try await editor.save(id: card.id, fields: ParsedContactFields(name: " "))
        }
        let read = try await repository.fetch(id: card.id)
        #expect(read == card)
    }

    @Test func testEditPersistsWhenDiskContainerIsReopened() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("EditedCards.sqlite")
        let card = fixture()
        do {
            let container = try ModelContainer(for: PersistedBusinessCard.self, configurations: ModelConfiguration(url: url))
            defer { withExtendedLifetime(container) {} }
            let repository = SwiftDataCardRepository(modelContext: container.mainContext)
            try await repository.insert(card)
            var draft = CardFieldCorrectionDraft(savedRecord: card)
            draft.name = "Persisted edit"
            draft.company = "Persisted company"
            _ = try await CardSavedRecordEditor(repository: repository).save(id: card.id, fields: draft.confirmedFields())
        }
        do {
            let container = try ModelContainer(for: PersistedBusinessCard.self, configurations: ModelConfiguration(url: url))
            defer { withExtendedLifetime(container) {} }
            let repository = SwiftDataCardRepository(modelContext: container.mainContext)
            let read = try await repository.fetch(id: card.id)
            let all = try await repository.fetchAll()
            #expect(read.name == "Persisted edit" && read.company == "Persisted company")
            #expect(read.id == card.id && read.createdAt == card.createdAt && read.updatedAt > card.updatedAt)
            #expect(read.originalImageData == card.originalImageData && read.processedImageData == card.processedImageData)
            #expect(read.ocrRawText == card.ocrRawText && read.parsedFields == card.parsedFields)
            #expect(read.tagIDs == card.tagIDs && read.notes == card.notes)
            #expect(all.count == 1)
        }
    }

    @Test func testContactRemovalsPersistAcrossDiskReopens() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("ContactRemovals.sqlite")
        var card = fixture()
        card.phones.append(PhoneEntry(value: "+1 202-555-0102", type: .mobile))
        card.phones.append(PhoneEntry(value: "+1 202-555-0103", type: .fax))
        let other = fixture()

        do {
            let container = try ModelContainer(for: PersistedBusinessCard.self, configurations: ModelConfiguration(url: url))
            defer { withExtendedLifetime(container) {} }
            let repository = SwiftDataCardRepository(modelContext: container.mainContext)
            try await repository.insert(card)
            try await repository.insert(other)
            var draft = CardFieldCorrectionDraft(savedRecord: card)
            let middlePhoneID = draft.phones[1].id
            let firstEmailID = draft.emails[0].id
            draft.phones.removeAll { $0.id == middlePhoneID }
            draft.emails.removeAll { $0.id == firstEmailID }
            _ = try await CardSavedRecordEditor(repository: repository).save(id: card.id, fields: draft.confirmedFields())
        }

        do {
            let container = try ModelContainer(for: PersistedBusinessCard.self, configurations: ModelConfiguration(url: url))
            defer { withExtendedLifetime(container) {} }
            let repository = SwiftDataCardRepository(modelContext: container.mainContext)
            let read = try await repository.fetch(id: card.id)
            #expect(read.phones == [card.phones[0], card.phones[2]])
            #expect(read.emails == [card.emails[1]])
            var draft = CardFieldCorrectionDraft(savedRecord: read)
            let phoneIDs = draft.phones.map(\.id)
            for id in phoneIDs { draft.phones.removeAll { $0.id == id } }
            let lastEmailID = try #require(draft.emails.first?.id)
            draft.emails.removeAll { $0.id == lastEmailID }
            _ = try await CardSavedRecordEditor(repository: repository).save(id: card.id, fields: draft.confirmedFields())
        }

        do {
            let container = try ModelContainer(for: PersistedBusinessCard.self, configurations: ModelConfiguration(url: url))
            defer { withExtendedLifetime(container) {} }
            let repository = SwiftDataCardRepository(modelContext: container.mainContext)
            let read = try await repository.fetch(id: card.id)
            #expect(read.phones.isEmpty && read.emails.isEmpty)
            var expected = card
            expected.phones = []
            expected.emails = []
            expected.updatedAt = read.updatedAt
            #expect(read == expected)
            let untouched = try await repository.fetch(id: other.id)
            #expect(untouched == other)
        }
    }

    @Test func testNoteEditsAndClearingPersistAcrossDiskReopens() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("CardNotes.sqlite")
        var original = fixture()
        original.notes = nil
        let other = fixture()
        let notes: [String?] = ["初次联系，编号 123。\nFollow-up: Monday!", "更新备注。\nCall at 10:30.", nil]

        for (index, note) in notes.enumerated() {
            let container = try ModelContainer(for: PersistedBusinessCard.self, configurations: ModelConfiguration(url: url))
            defer { withExtendedLifetime(container) {} }
            let repository = SwiftDataCardRepository(modelContext: container.mainContext)
            if index == 0 {
                try await repository.insert(original)
                try await repository.insert(other)
            }

            let editor = CardSavedRecordEditor(repository: repository)
            let saved = try await editor.load(id: original.id)
            let previousNote = index == 0 ? nil : notes[index - 1]
            #expect(saved.notes == previousNote)
            let draft = CardFieldCorrectionDraft(savedRecord: saved)
            let updated = try await editor.save(id: saved.id, fields: draft.confirmedFields(), notes: note ?? "")
            let read = try await repository.fetch(id: saved.id)
            #expect(updated.notes == note)
            var expected = original
            expected.notes = note
            expected.updatedAt = read.updatedAt
            #expect(read == expected)
            let untouched = try await repository.fetch(id: other.id)
            #expect(untouched == other)
        }

        let container = try ModelContainer(for: PersistedBusinessCard.self, configurations: ModelConfiguration(url: url))
        defer { withExtendedLifetime(container) {} }
        let repository = SwiftDataCardRepository(modelContext: container.mainContext)
        let reopened = try await repository.fetch(id: original.id)
        #expect(reopened.notes == nil)
    }
}
