import Foundation
import SwiftData
import Testing
@testable import CardSlice

@MainActor
struct TagRepositoryTests {
    private func memoryContainer() throws -> ModelContainer {
        try ModelContainer(for: PersistedBusinessCard.self, PersistedTag.self,
                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    }

    @Test func testCreatesAndReadsTrimmedTags() throws {
        let container = try memoryContainer()
        defer { withExtendedLifetime(container) {} }
        let tags = SwiftDataTagRepository(modelContext: container.mainContext)
        let client = try tags.create(name: "  客户 \n")
        let partner = try tags.create(name: "Partner")
        #expect(client.name == "客户")
        #expect(client.id != partner.id)
        #expect(try tags.fetch(id: client.id) == client)
        #expect(try Set(tags.fetchAll()) == [client, partner])
    }

    @Test func testRejectsBlankAndCaseInsensitiveDuplicates() throws {
        let container = try memoryContainer()
        defer { withExtendedLifetime(container) {} }
        let tags = SwiftDataTagRepository(modelContext: container.mainContext)
        #expect(throws: TagRepositoryError.invalidName) { try tags.create(name: " \n ") }
        let original = try tags.create(name: "Client")
        #expect(throws: TagRepositoryError.duplicateName("CLIENT")) { try tags.create(name: " CLIENT ") }
        #expect(try tags.fetchAll() == [original])
    }

    @Test func testSharedAndMultipleTagsAndDeletionCleanup() async throws {
        let container = try memoryContainer()
        defer { withExtendedLifetime(container) {} }
        let cards = SwiftDataCardRepository(modelContext: container.mainContext)
        let tags = SwiftDataTagRepository(modelContext: container.mainContext)
        let first = BusinessCardRecord(name: "甲", notes: "保留")
        let second = BusinessCardRecord(name: "乙")
        try await cards.insert(first)
        try await cards.insert(second)
        let shared = try tags.create(name: "共享")
        let other = try tags.create(name: "保留标签")
        try tags.setTagIDs([shared.id, other.id], forCardID: first.id)
        try tags.setTagIDs([shared.id], forCardID: second.id)
        #expect(try Set(tags.fetchCards(tagID: shared.id).map(\.id)) == [first.id, second.id])
        let assigned = try await cards.fetch(id: first.id)
        #expect(assigned.tagIDs == [shared.id, other.id])

        try tags.delete(id: shared.id)
        let remaining = try await cards.fetchAll()
        var expectedFirst = first
        expectedFirst.tagIDs = [other.id]
        #expect(Set(remaining.map(\.id)) == [first.id, second.id])
        #expect(remaining.contains(expectedFirst))
        #expect(remaining.contains(second))
        #expect(try tags.fetchAll() == [other])
        #expect(throws: TagRepositoryError.notFound(id: shared.id)) { try tags.delete(id: shared.id) }
    }

    @Test func testMissingTagAndCardDoNotChangeAssociations() async throws {
        let container = try memoryContainer()
        defer { withExtendedLifetime(container) {} }
        let tags = SwiftDataTagRepository(modelContext: container.mainContext)
        let cards = SwiftDataCardRepository(modelContext: container.mainContext)
        let card = BusinessCardRecord(name: "保留")
        try await cards.insert(card)
        let missing = UUID()
        #expect(throws: TagRepositoryError.notFound(id: missing)) { try tags.delete(id: missing) }
        #expect(throws: TagRepositoryError.notFound(id: missing)) { try tags.setTagIDs([missing], forCardID: card.id) }
        #expect(throws: TagRepositoryError.cardNotFound(id: missing)) { try tags.setTagIDs([], forCardID: missing) }
        let read = try await cards.fetch(id: card.id)
        #expect(read == card)
    }

    @Test func testCorruptAssociationAbortsDelete() async throws {
        let container = try memoryContainer()
        defer { withExtendedLifetime(container) {} }
        let context = container.mainContext
        let tags = SwiftDataTagRepository(modelContext: context)
        let cards = SwiftDataCardRepository(modelContext: context)
        let tag = try tags.create(name: "保留")
        let card = BusinessCardRecord(name: "有效", tagIDs: [tag.id])
        try await cards.insert(card)
        context.insert(PersistedBusinessCard(id: UUID(), name: "损坏", tagIDsData: Data([0xFF])))
        try context.save()

        #expect(throws: TagRepositoryError.self) { try tags.delete(id: tag.id) }
        #expect(try tags.fetch(id: tag.id) == tag)
        let read = try await cards.fetch(id: card.id)
        #expect(read.tagIDs == [tag.id])
    }

    @Test func testExistingDiskStoreUpgradeAndTagRoundTrip() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("Cards.sqlite")
        let record = BusinessCardRecord(originalImageData: Data([1, 2]), processedImageData: Data([3, 4]),
                                        ocrRawText: "原文", parsedFields: ParsedContactFields(name: "识别姓名"),
                                        name: "更正姓名", notes: "原备注",
                                        createdAt: Date(timeIntervalSince1970: 1_000),
                                        updatedAt: Date(timeIntervalSince1970: 2_000))
        do {
            let container = try ModelContainer(for: PersistedBusinessCard.self, configurations: ModelConfiguration(url: url))
            defer { withExtendedLifetime(container) {} }
            try await SwiftDataCardRepository(modelContext: container.mainContext).insert(record)
        }
        let tag: TagRecord
        do {
            let container = try ModelContainer(for: PersistedBusinessCard.self, PersistedTag.self,
                                               configurations: ModelConfiguration(url: url))
            defer { withExtendedLifetime(container) {} }
            let cards = SwiftDataCardRepository(modelContext: container.mainContext)
            let read = try await cards.fetch(id: record.id)
            #expect(read == record)
            let tags = SwiftDataTagRepository(modelContext: container.mainContext)
            tag = try tags.create(name: "磁盘标签")
            try tags.setTagIDs([tag.id], forCardID: record.id)
        }
        do {
            let container = try ModelContainer(for: PersistedBusinessCard.self, PersistedTag.self,
                                               configurations: ModelConfiguration(url: url))
            defer { withExtendedLifetime(container) {} }
            let tags = SwiftDataTagRepository(modelContext: container.mainContext)
            var expected = record
            expected.tagIDs = [tag.id]
            #expect(try tags.fetch(id: tag.id) == tag)
            #expect(try tags.fetchCards(tagID: tag.id) == [expected])
        }
    }
}
