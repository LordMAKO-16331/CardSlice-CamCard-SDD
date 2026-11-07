import Foundation
import SwiftData
import Testing
@testable import CardSlice

@MainActor
struct CardSavedRecordDeletionTests {
    @Test func testDeletesOnlyConfirmedUUIDAndRejectsRepeat() async throws {
        let target = BusinessCardRecord(name: "同名", company: "同公司")
        let other = BusinessCardRecord(name: target.name, company: target.company)
        let repository = try InMemoryCardRepository(initialRecords: [target, other])
        let deletion = CardDeletionCoordinator(id: target.id, repository: repository)
        deletion.requestConfirmation()
        let deleted = try await deletion.confirm()
        #expect(deleted && deletion.phase == .deleted)
        await #expect(throws: CardRepositoryError.notFound(id: target.id)) {
            try await repository.fetch(id: target.id)
        }
        deletion.requestConfirmation()
        let repeated = try await deletion.confirm()
        #expect(!repeated)
        let remaining = try await repository.fetchAll()
        #expect(remaining == [other])
    }

    @Test func testCancellingConfirmationLeavesRepositoryUnchanged() async throws {
        let card = BusinessCardRecord(name: "保留")
        let repository = try InMemoryCardRepository(initialRecords: [card])
        let deletion = CardDeletionCoordinator(id: card.id, repository: repository)
        deletion.requestConfirmation()
        deletion.cancel()
        let deleted = try await deletion.confirm()
        #expect(!deleted && deletion.phase == .idle)
        let remaining = try await repository.fetchAll()
        #expect(remaining == [card])
    }

    @Test func testMissingRecordReportsErrorAndAllowsRetry() async throws {
        let card = BusinessCardRecord(name: "保留")
        let repository = try InMemoryCardRepository(initialRecords: [card])
        let id = UUID()
        let deletion = CardDeletionCoordinator(id: id, repository: repository)
        deletion.requestConfirmation()
        await #expect(throws: CardRepositoryError.notFound(id: id)) {
            try await deletion.confirm()
        }
        #expect(deletion.phase == .idle)
        let remaining = try await repository.fetchAll()
        #expect(remaining == [card])
    }

    @Test func testDeletingLastRecordPersistsEmptyListAfterReopen() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("Cards.sqlite")
        let card = BusinessCardRecord(originalImageData: Data([1]), processedImageData: Data([2]),
                                      ocrRawText: "OCR", name: "待删除")
        do {
            let container = try ModelContainer(for: PersistedBusinessCard.self, configurations: ModelConfiguration(url: url))
            defer { withExtendedLifetime(container) {} }
            let repository = SwiftDataCardRepository(modelContext: container.mainContext)
            try await repository.insert(card)
            let deletion = CardDeletionCoordinator(id: card.id, repository: repository)
            deletion.requestConfirmation()
            let deleted = try await deletion.confirm()
            #expect(deleted)
            let remaining = try await repository.fetchAll()
            #expect(remaining.isEmpty)
        }
        do {
            let container = try ModelContainer(for: PersistedBusinessCard.self, configurations: ModelConfiguration(url: url))
            defer { withExtendedLifetime(container) {} }
            let repository = SwiftDataCardRepository(modelContext: container.mainContext)
            let remaining = try await repository.fetchAll()
            #expect(remaining.isEmpty)
        }
    }
}
