import Foundation
import SwiftData
import Testing
@testable import CardSlice

@MainActor
struct TagManagementTests {
    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(for: PersistedBusinessCard.self, PersistedTag.self,
                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    }

    private func results(_ model: CardHolderViewModel, query: String = "") throws -> [BusinessCardRecord] {
        guard case .loaded(let records) = model.state else {
            Issue.record("名片列表应已加载")
            throw TagRepositoryError.readFailed("测试列表未加载")
        }
        return model.visibleCards(in: records, query: query)
    }

    @Test func testCombinesTagAndKeywordFiltersAndKeepsUnfilteredCount() async throws {
        let container = try makeContainer()
        defer { withExtendedLifetime(container) {} }
        let cards = SwiftDataCardRepository(modelContext: container.mainContext)
        let tags = SwiftDataTagRepository(modelContext: container.mainContext)
        let model = CardHolderViewModel(repository: cards, tagRepository: tags)
        let first = BusinessCardRecord(name: "Alice", notes: "跟进报价")
        let second = BusinessCardRecord(name: "Bob")
        let third = BusinessCardRecord(name: "Alice Other")
        for card in [first, second, third] { try await cards.insert(card) }
        try model.createTag(name: "共享")
        try model.createTag(name: "另一个")
        let shared = try #require(model.tags.first { $0.name == "共享" })
        let other = try #require(model.tags.first { $0.name == "另一个" })
        await model.load()
        try model.saveTags([shared.id, other.id], forCardID: first.id)
        try model.saveTags([shared.id], forCardID: second.id)

        model.selectedTagID = shared.id
        #expect(try Set(results(model).map(\.id)) == [first.id, second.id])
        #expect(try results(model, query: "ALICE").map(\.id) == [first.id])
        #expect(try results(model, query: "报价").map(\.id) == [first.id])
        #expect(try results(model, query: "无匹配").isEmpty)
        model.selectedTagID = other.id
        #expect(try results(model).map(\.id) == [first.id])
        model.selectedTagID = nil
        #expect(try results(model).count == 3)
        #expect(try Set(results(model, query: "ALICE").map(\.id)) == [first.id, third.id])
    }

    @Test func testAssociationChangesRefreshFilterAndPreserveContact() async throws {
        let container = try makeContainer()
        defer { withExtendedLifetime(container) {} }
        let cards = SwiftDataCardRepository(modelContext: container.mainContext)
        let tags = SwiftDataTagRepository(modelContext: container.mainContext)
        let model = CardHolderViewModel(repository: cards, tagRepository: tags)
        let card = BusinessCardRecord(originalImageData: Data([1]), ocrRawText: "原文",
                                      name: "联系人", company: "示例公司", emails: ["test@example.com"], notes: "保留")
        try await cards.insert(card)
        try model.createTag(name: "客户")
        let tag = try #require(model.tags.first)
        await model.load()
        model.selectedTagID = tag.id
        #expect(try results(model).isEmpty)

        try model.saveTags([tag.id], forCardID: card.id)
        var expected = card
        expected.tagIDs = [tag.id]
        #expect(try results(model) == [expected])
        let associated = try await cards.fetch(id: card.id)
        #expect(associated == expected)

        try model.saveTags([], forCardID: card.id)
        #expect(try results(model).isEmpty)
        let removed = try await cards.fetch(id: card.id)
        #expect(removed == card)
    }

    @Test func testDeletingSelectedTagRestoresAllCardsAndCleansCachedIDs() async throws {
        let container = try makeContainer()
        defer { withExtendedLifetime(container) {} }
        let cards = SwiftDataCardRepository(modelContext: container.mainContext)
        let tags = SwiftDataTagRepository(modelContext: container.mainContext)
        let model = CardHolderViewModel(repository: cards, tagRepository: tags)
        let card = BusinessCardRecord(name: "Alice", notes: "保留")
        let other = BusinessCardRecord(name: "Bob")
        try await cards.insert(card)
        try await cards.insert(other)
        let removed = try tags.create(name: "移除")
        let retained = try tags.create(name: "保留")
        try tags.setTagIDs([removed.id, retained.id], forCardID: card.id)
        model.loadTags()
        await model.load()
        model.selectedTagID = removed.id
        try model.deleteTag(id: removed.id)

        #expect(model.selectedTagID == nil)
        #expect(model.tags == [retained])
        #expect(try Set(results(model).map(\.id)) == [card.id, other.id])
        var expected = card
        expected.tagIDs = [retained.id]
        #expect(try results(model, query: "Alice") == [expected])
        let stored = try await cards.fetch(id: card.id)
        #expect(stored == expected)
        let untouched = try await cards.fetch(id: other.id)
        #expect(untouched == other)
    }
}
