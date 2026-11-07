import Testing
import Foundation
@testable import CardSlice

@MainActor
struct CardRepositoryTests {

    @Test func testEmptyRepository() async throws {
        let repository = try InMemoryCardRepository()
        let all = try await repository.fetchAll()
        #expect(all.isEmpty, "空仓库应返回空数组 [F01-1]")
    }
    
    @Test func testInsertAndFetch() async throws {
        let repository = try InMemoryCardRepository()
        let card = BusinessCardRecord(name: "Test User")
        
        try await repository.insert(card)
        let fetched = try await repository.fetch(id: card.id)
        
        #expect(fetched.name == "Test User")
        #expect(fetched.id == card.id)
    }
    
    @Test func testFetchAllOrder() async throws {
        let card1 = BusinessCardRecord(name: "User 1")
        let card2 = BusinessCardRecord(name: "User 2")
        let repository = try InMemoryCardRepository(initialRecords: [card1, card2])
        
        let all = try await repository.fetchAll()
        #expect(all.count == 2)
        #expect(all[0].name == "User 1")
        #expect(all[1].name == "User 2")
    }
    
    @Test func testUpdateCard() async throws {
        let card1 = BusinessCardRecord(name: "Original Name")
        let card2 = BusinessCardRecord(name: "Unrelated User")
        let repository = try InMemoryCardRepository(initialRecords: [card1, card2])
        
        var updatedCard = card1
        updatedCard.name = "Updated Name"
        try await repository.update(updatedCard)
        
        let fetched = try await repository.fetch(id: card1.id)
        #expect(fetched.name == "Updated Name")
        
        // 验证另一条未修改记录保持不变 [F01-4]
        let unrelated = try await repository.fetch(id: card2.id)
        #expect(unrelated.name == "Unrelated User")
    }
    
    @Test func testDeleteCard() async throws {
        let card = BusinessCardRecord(name: "To Be Deleted")
        let repository = try InMemoryCardRepository(initialRecords: [card])
        
        try await repository.delete(id: card.id)
        
        await #expect(throws: CardRepositoryError.notFound(id: card.id)) {
            try await repository.fetch(id: card.id)
        }
        
        // 验证删除最后一条记录后 fetchAll 返回空数组 [F01-4]
        let all = try await repository.fetchAll()
        #expect(all.isEmpty)
    }
    
    @Test func testDuplicateInsertError() async throws {
        let card = BusinessCardRecord(name: "Duplicate")
        let repository = try InMemoryCardRepository(initialRecords: [card])
        
        // 验证具体错误值的断言 [F01-2]
        await #expect(throws: CardRepositoryError.duplicateID(id: card.id)) {
            try await repository.insert(card)
        }
    }
    
    @Test func testInitialDuplicateIDError() async throws {
        let card = BusinessCardRecord(name: "Duplicate")
        // 验证初始化时的重复 ID 错误 [F01-3]
        #expect(throws: CardRepositoryError.duplicateID(id: card.id)) {
            try InMemoryCardRepository(initialRecords: [card, card])
        }
    }
    
    @Test func testUpdateNonExistentError() async throws {
        let repository = try InMemoryCardRepository()
        let card = BusinessCardRecord(name: "Non-existent")
        
        await #expect(throws: CardRepositoryError.notFound(id: card.id)) {
            try await repository.update(card)
        }
    }
    
    @Test func testDeleteNonExistentError() async throws {
        let repository = try InMemoryCardRepository()
        let nonExistentID = UUID()
        
        await #expect(throws: CardRepositoryError.notFound(id: nonExistentID)) {
            try await repository.delete(id: nonExistentID)
        }
    }
}
