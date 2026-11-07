import Foundation

/// 名片仓库的内存实现 [DECISION]
/// 仅用于单元测试与开发调试，不具备持久化能力。
@MainActor
final class InMemoryCardRepository: CardRepository {
    // 内存存储集合
    private var storage: [UUID: BusinessCardRecord] = [:]
    
    // 插入顺序记录，确保 fetchAll 返回稳定顺序
    private var insertionOrder: [UUID] = []
    
    /// 初始化，支持注入初始数据
    init(initialRecords: [BusinessCardRecord] = []) throws {
        for record in initialRecords {
            if storage[record.id] != nil {
                throw CardRepositoryError.duplicateID(id: record.id)
            }
            storage[record.id] = record
            insertionOrder.append(record.id)
        }
    }
    
    func fetchAll() async throws -> [BusinessCardRecord] {
        // 返回插入顺序的名片，空仓库返回空数组 [F01-1]
        return insertionOrder.compactMap { storage[$0] }
    }
    
    func fetch(id: UUID) async throws -> BusinessCardRecord {
        guard let record = storage[id] else {
            throw CardRepositoryError.notFound(id: id)
        }
        return record
    }
    
    func insert(_ record: BusinessCardRecord) async throws {
        if storage[record.id] != nil {
            throw CardRepositoryError.duplicateID(id: record.id)
        }
        storage[record.id] = record
        insertionOrder.append(record.id)
    }
    
    func update(_ record: BusinessCardRecord) async throws {
        guard storage[record.id] != nil else {
            throw CardRepositoryError.notFound(id: record.id)
        }
        storage[record.id] = record
    }
    
    func delete(id: UUID) async throws {
        guard storage[id] != nil else {
            throw CardRepositoryError.notFound(id: id)
        }
        storage.removeValue(forKey: id)
        insertionOrder.removeAll { $0 == id }
    }
}
