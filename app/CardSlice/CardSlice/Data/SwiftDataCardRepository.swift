import Foundation
import SwiftData

/// 基于 SwiftData 的名片仓库实现 [R09]
@MainActor
final class SwiftDataCardRepository: CardRepository {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func fetchAll() async throws -> [BusinessCardRecord] {
        // 使用 createdAt + id 进行稳定排序 [P009 要求]
        let descriptor = FetchDescriptor<PersistedBusinessCard>(
            sortBy: [SortDescriptor(\.createdAt), SortDescriptor(\.id)]
        )
        
        let persistedCards = try modelContext.fetch(descriptor)
        return try persistedCards.map { try BusinessCardPersistenceMapper.mapToRecord($0) }
    }
    
    func fetch(id: UUID) async throws -> BusinessCardRecord {
        guard let persisted = try fetchPersisted(id: id) else {
            throw CardRepositoryError.notFound(id: id)
        }
        return try BusinessCardPersistenceMapper.mapToRecord(persisted)
    }
    
    func insert(_ record: BusinessCardRecord) async throws {
        // 检查重复 ID [P009 要求]
        if try fetchPersisted(id: record.id) != nil {
            throw CardRepositoryError.duplicateID(id: record.id)
        }
        
        let persisted = try BusinessCardPersistenceMapper.mapToPersisted(record)
        modelContext.insert(persisted)
        try save()
    }
    
    func update(_ record: BusinessCardRecord) async throws {
        guard let persisted = try fetchPersisted(id: record.id) else {
            throw CardRepositoryError.notFound(id: record.id)
        }
        
        try BusinessCardPersistenceMapper.updatePersisted(persisted, from: record)
        try save()
    }
    
    func delete(id: UUID) async throws {
        guard let persisted = try fetchPersisted(id: id) else {
            throw CardRepositoryError.notFound(id: id)
        }
        
        modelContext.delete(persisted)
        try save()
    }
    
    // MARK: - 私有辅助方法
    
    private func fetchPersisted(id: UUID) throws -> PersistedBusinessCard? {
        let predicate = #Predicate<PersistedBusinessCard> { $0.id == id }
        let descriptor = FetchDescriptor<PersistedBusinessCard>(predicate: predicate)
        return try modelContext.fetch(descriptor).first
    }
    
    private func save() throws {
        do {
            try modelContext.save()
        } catch {
            throw CardRepositoryError.saveFailed(error.localizedDescription)
        }
    }
}
