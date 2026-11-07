import Foundation

enum TagRepositoryError: Error, LocalizedError, Equatable {
    case notFound(id: UUID)
    case cardNotFound(id: UUID)
    case invalidName
    case duplicateName(String)
    case readFailed(String)
    case writeFailed(String)

    var errorDescription: String? {
        switch self {
        case .notFound(let id): return "找不到标签 \(id)。"
        case .cardNotFound(let id): return "找不到名片 \(id)。"
        case .invalidName: return "标签名称不能为空。"
        case .duplicateName(let name): return "已存在标签「\(name)」。"
        case .readFailed(let reason): return "读取标签数据失败：\(reason)"
        case .writeFailed(let reason): return "保存标签数据失败：\(reason)"
        }
    }
}

@MainActor
protocol TagRepository {
    func create(name: String) throws -> TagRecord
    func fetchAll() throws -> [TagRecord]
    func fetch(id: UUID) throws -> TagRecord
    func delete(id: UUID) throws
    func setTagIDs(_ tagIDs: Set<UUID>, forCardID cardID: UUID) throws
    func fetchCards(tagID: UUID) throws -> [BusinessCardRecord]
}
