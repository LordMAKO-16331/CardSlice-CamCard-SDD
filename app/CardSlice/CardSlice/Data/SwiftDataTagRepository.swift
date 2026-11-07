import Foundation
import SwiftData

/// 使用与名片仓库相同的上下文，确保已加载的名片实体看到最新关联。
@MainActor
final class SwiftDataTagRepository: TagRepository {
    private let context: ModelContext

    init(modelContext: ModelContext) {
        context = modelContext
    }

    func create(name: String) throws -> TagRecord {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { throw TagRepositoryError.invalidName }
        let key = name.folding(options: .caseInsensitive, locale: Locale(identifier: "en_US_POSIX"))
        var descriptor = FetchDescriptor<PersistedTag>(predicate: #Predicate { $0.nameKey == key })
        descriptor.fetchLimit = 1
        guard try read({ try context.fetch(descriptor).isEmpty }) else {
            throw TagRepositoryError.duplicateName(name)
        }

        let record = TagRecord(name: name)
        try write {
            context.insert(PersistedTag(id: record.id, name: name, nameKey: key))
        }
        return record
    }

    func fetchAll() throws -> [TagRecord] {
        let descriptor = FetchDescriptor<PersistedTag>(sortBy: [SortDescriptor(\.nameKey)])
        return try read { try context.fetch(descriptor).map { TagRecord(id: $0.id, name: $0.name) } }
    }

    func fetch(id: UUID) throws -> TagRecord {
        let tag = try storedTag(id: id)
        return TagRecord(id: tag.id, name: tag.name)
    }

    func setTagIDs(_ tagIDs: Set<UUID>, forCardID cardID: UUID) throws {
        var descriptor = FetchDescriptor<PersistedBusinessCard>(predicate: #Predicate { $0.id == cardID })
        descriptor.fetchLimit = 1
        guard let card = try read({ try context.fetch(descriptor).first }) else {
            throw TagRepositoryError.cardNotFound(id: cardID)
        }
        let validIDs = Set(try fetchAll().map(\.id))
        if let missing = tagIDs.subtracting(validIDs).sorted(by: { $0.uuidString < $1.uuidString }).first {
            throw TagRepositoryError.notFound(id: missing)
        }
        try write {
            card.tagIDsData = try JSONEncoder().encode(tagIDs)
        }
    }

    func fetchCards(tagID: UUID) throws -> [BusinessCardRecord] {
        _ = try storedTag(id: tagID)
        return try read {
            try storedCards().compactMap { card in
                guard try tagIDs(of: card).contains(tagID) else { return nil }
                return try BusinessCardPersistenceMapper.mapToRecord(card)
            }
        }
    }

    func delete(id: UUID) throws {
        let tag = try storedTag(id: id)
        // 先完成所有解码，坏数据会中止操作，避免只清理部分关联。
        let affected = try read {
            try storedCards().compactMap { card -> (PersistedBusinessCard, Set<UUID>)? in
                var ids = try tagIDs(of: card)
                guard ids.remove(id) != nil else { return nil }
                return (card, ids)
            }
        }

        try write {
            for (card, ids) in affected {
                card.tagIDsData = try JSONEncoder().encode(ids)
            }
            context.delete(tag)
        }
    }

    private func storedTag(id: UUID) throws -> PersistedTag {
        var descriptor = FetchDescriptor<PersistedTag>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        guard let tag = try read({ try context.fetch(descriptor).first }) else {
            throw TagRepositoryError.notFound(id: id)
        }
        return tag
    }

    private func storedCards() throws -> [PersistedBusinessCard] {
        try context.fetch(FetchDescriptor<PersistedBusinessCard>(
            sortBy: [SortDescriptor(\.createdAt), SortDescriptor(\.id)]
        ))
    }

    private func tagIDs(of card: PersistedBusinessCard) throws -> Set<UUID> {
        guard let data = card.tagIDsData else {
            throw TagRepositoryError.readFailed("名片 \(card.id) 缺少关联数据。")
        }
        return try JSONDecoder().decode(Set<UUID>.self, from: data)
    }

    private func read<T>(_ operation: () throws -> T) throws -> T {
        do {
            return try operation()
        } catch let error as TagRepositoryError {
            throw error
        } catch {
            throw TagRepositoryError.readFailed(error.localizedDescription)
        }
    }

    private func write(_ operation: () throws -> Void) throws {
        // 只回滚本次操作，避免顺带提交或丢弃其他仓库留下的待保存变更。
        guard !context.hasChanges else {
            throw TagRepositoryError.writeFailed("数据库存在待保存的更改，请处理后重试。")
        }
        do {
            try operation()
            try context.save()
        } catch {
            context.rollback()
            throw TagRepositoryError.writeFailed(error.localizedDescription)
        }
    }
}
