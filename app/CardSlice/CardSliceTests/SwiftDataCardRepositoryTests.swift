import Testing
import Foundation
import SwiftData
@testable import CardSlice

@MainActor
struct SwiftDataCardRepositoryTests {
    // 同时持有容器和仓库，避免异步测试期间容器提前释放。
    private struct TestDatabase {
        let container: ModelContainer
        let repository: SwiftDataCardRepository
    }

    
    // 获取临时的内存容器用于基础功能测试
    private func createInMemoryRepository() throws -> TestDatabase {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: PersistedBusinessCard.self, configurations: configuration)
        return TestDatabase(container: container, repository: SwiftDataCardRepository(modelContext: container.mainContext))
    }
    
    // 获取文件系统存储的临时容器用于持久化验证测试
    private func createDiskRepository(at url: URL) throws -> TestDatabase {
        let configuration = ModelConfiguration(url: url)
        let container = try ModelContainer(for: PersistedBusinessCard.self, configurations: configuration)
        return TestDatabase(container: container, repository: SwiftDataCardRepository(modelContext: container.mainContext))
    }

    @Test func testEmptyDatabase() async throws {
        let database = try createInMemoryRepository()
        defer { withExtendedLifetime(database) {} }
        let repository = database.repository
        let all = try await repository.fetchAll()
        #expect(all.isEmpty)
    }
    
    @Test func testInsertAndFetch() async throws {
        let database = try createInMemoryRepository()
        defer { withExtendedLifetime(database) {} }
        let repository = database.repository
        let record = BusinessCardRecord(
            name: "John Doe",
            company: "Tech Co",
            phones: [PhoneEntry(value: "123456", type: .mobile)],
            emails: ["john@example.com"]
        )
        
        try await repository.insert(record)
        let fetched = try await repository.fetch(id: record.id)
        
        #expect(fetched.name == "John Doe")
        #expect(fetched.company == "Tech Co")
        #expect(fetched.phones.first?.value == "123456")
        #expect(fetched.emails.first == "john@example.com")
    }
    
    @Test func testDuplicateIDError() async throws {
        let database = try createInMemoryRepository()
        defer { withExtendedLifetime(database) {} }
        let repository = database.repository
        let record = BusinessCardRecord(name: "User")
        
        try await repository.insert(record)
        await #expect(throws: CardRepositoryError.duplicateID(id: record.id)) {
            try await repository.insert(record)
        }
    }
    
    @Test func testUpdateAndFetch() async throws {
        let database = try createInMemoryRepository()
        defer { withExtendedLifetime(database) {} }
        let repository = database.repository
        var record = BusinessCardRecord(name: "Old Name")
        try await repository.insert(record)
        
        record.name = "New Name"
        try await repository.update(record)
        
        let fetched = try await repository.fetch(id: record.id)
        #expect(fetched.name == "New Name")
    }
    
    @Test func testDeleteAndFetch() async throws {
        let database = try createInMemoryRepository()
        defer { withExtendedLifetime(database) {} }
        let repository = database.repository
        let record = BusinessCardRecord(name: "To Delete")
        try await repository.insert(record)
        
        try await repository.delete(id: record.id)
        await #expect(throws: CardRepositoryError.notFound(id: record.id)) {
            try await repository.fetch(id: record.id)
        }
    }
    
    @Test func testStableSorting() async throws {
        let database = try createInMemoryRepository()
        defer { withExtendedLifetime(database) {} }
        let repository = database.repository
        let record1 = BusinessCardRecord(name: "First", createdAt: Date().addingTimeInterval(-100))
        let record2 = BusinessCardRecord(name: "Second", createdAt: Date())
        
        try await repository.insert(record2) // 乱序插入
        try await repository.insert(record1)
        
        let all = try await repository.fetchAll()
        #expect(all.count == 2)
        #expect(all[0].name == "First")
        #expect(all[1].name == "Second")
    }
    
    @Test func testComplexFieldsPersistence() async throws {
        let database = try createInMemoryRepository()
        defer { withExtendedLifetime(database) {} }
        let repository = database.repository
        let originalData = "original".data(using: .utf8)
        let processedData = "processed".data(using: .utf8)
        let parsed = ParsedContactFields(name: "Parsed Name")
        
        let record = BusinessCardRecord(
            originalImageData: originalData,
            processedImageData: processedData,
            ocrRawText: "OCR Text",
            parsedFields: parsed,
            name: "Complex User",
            phones: [
                PhoneEntry(value: "111", type: .mobile),
                PhoneEntry(value: "222", type: .fax)
            ],
            emails: ["a@b.com", "c@d.com"],
            tagIDs: [UUID(), UUID()],
            notes: "Some notes"
        )
        
        try await repository.insert(record)
        let fetched = try await repository.fetch(id: record.id)
        
        #expect(fetched.name == "Complex User")
        #expect(fetched.originalImageData == originalData)
        #expect(fetched.processedImageData == processedData)
        #expect(fetched.ocrRawText == "OCR Text")
        #expect(fetched.parsedFields?.name == "Parsed Name")
        #expect(fetched.phones.count == 2)
        #expect(fetched.phones.contains(where: { $0.type == .fax }))
        #expect(fetched.emails.count == 2)
        #expect(fetched.tagIDs.count == 2)
        #expect(fetched.notes == "Some notes")
    }
    
    @Test func testMissingWebsiteIsNil() async throws {
        let database = try createInMemoryRepository()
        defer { withExtendedLifetime(database) {} }
        let repository = database.repository
        let record = BusinessCardRecord(name: "No Website", website: nil)
        
        try await repository.insert(record)
        let fetched = try await repository.fetch(id: record.id)
        #expect(fetched.website == nil)
    }
    
    @Test func testDatePersistence() async throws {
        let database = try createInMemoryRepository()
        defer { withExtendedLifetime(database) {} }
        let repository = database.repository
        let createdAt = Date(timeIntervalSince1970: 1000)
        let updatedAt = Date(timeIntervalSince1970: 2000)
        let record = BusinessCardRecord(name: "Date User", createdAt: createdAt, updatedAt: updatedAt)
        
        try await repository.insert(record)
        let fetched = try await repository.fetch(id: record.id)
        
        // 使用时间间隔比较避免精度问题 [F01-4]
        #expect(abs(fetched.createdAt.timeIntervalSince(createdAt)) < 0.001)
        #expect(abs(fetched.updatedAt.timeIntervalSince(updatedAt)) < 0.001)
    }
    
    @Test func testMappingMissingDataError() throws {
        // 模拟 PersistedBusinessCard 缺失必要数据 [F01-2]
        let persisted = PersistedBusinessCard(id: UUID(), name: "Invalid")
        persisted.phonesData = nil // 强制为 nil
        
        #expect(throws: CardRepositoryError.self) {
            try BusinessCardPersistenceMapper.mapToRecord(persisted)
        }
    }
    
    @Test func testMappingCorruptedJSONError() throws {
        // 模拟 PersistedBusinessCard 包含损坏的 JSON [F01-4]
        let persisted = PersistedBusinessCard(id: UUID(), name: "Corrupted")
        persisted.phonesData = "invalid json".data(using: .utf8)
        persisted.emailsData = try? JSONEncoder().encode(["a@b.com"])
        persisted.tagIDsData = try? JSONEncoder().encode(Set<UUID>())
        
        #expect(throws: (any Error).self) {
            try BusinessCardPersistenceMapper.mapToRecord(persisted)
        }
    }
    
    // 真实持久化验证测试 [P009 要求]
    @Test func testRealPersistenceAcrossInstances() async throws {
        // 创建临时测试目录 [F01-4]
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let dbURL = tempDir.appendingPathComponent("TestStore.sqlite")
        
        let recordID = UUID()
        let testName = "Persistent User"
        let testEmail = "persist@example.com"
        
        // 1. 在第一个容器中写入数据
        do {
            let database = try createDiskRepository(at: dbURL)
            defer { withExtendedLifetime(database) {} }
            let repository = database.repository
            let record = BusinessCardRecord(id: recordID, name: testName, emails: [testEmail])
            try await repository.insert(record)
        }
        
        // 2. 销毁旧容器，创建指向同一位置的新容器，验证读取
        do {
            let database = try createDiskRepository(at: dbURL)
            defer { withExtendedLifetime(database) {} }
            let repository = database.repository
            let fetched = try await repository.fetch(id: recordID)
            #expect(fetched.name == testName)
            #expect(fetched.id == recordID)
            #expect(fetched.emails.first == testEmail)
        }
    }
}
