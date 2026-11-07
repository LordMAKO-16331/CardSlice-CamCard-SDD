import Foundation

/// 名片仓库错误类型 [DECISION]
enum CardRepositoryError: Error, LocalizedError, Equatable {
    case notFound(id: UUID)
    case duplicateID(id: UUID)
    case saveFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .notFound(let id):
            return "未找到 ID 为 \(id) 的名片记录。"
        case .duplicateID(let id):
            return "已存在 ID 为 \(id) 的名片记录，无法重复插入。"
        case .saveFailed(let reason):
            return "保存失败：\(reason)"
        }
    }
}

/// 名片数据仓库协议 [R07/R09]
/// 负责名片数据的增删改查逻辑。
@MainActor
protocol CardRepository {
    /// 获取所有名片记录
    func fetchAll() async throws -> [BusinessCardRecord]
    
    /// 按 ID 获取名片记录
    func fetch(id: UUID) async throws -> BusinessCardRecord
    
    /// 插入新名片记录
    func insert(_ record: BusinessCardRecord) async throws
    
    /// 更新现有名片记录
    func update(_ record: BusinessCardRecord) async throws
    
    /// 按 ID 删除名片记录
    func delete(id: UUID) async throws
}
