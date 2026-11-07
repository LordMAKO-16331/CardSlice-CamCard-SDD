import Foundation

/// 业务模型与持久化模型转换器 [DECISION]
struct BusinessCardPersistenceMapper {
    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()
    
    /// 将逻辑模型转换为持久化实体
    static func mapToPersisted(_ record: BusinessCardRecord) throws -> PersistedBusinessCard {
        let phonesData = try encoder.encode(record.phones)
        let emailsData = try encoder.encode(record.emails)
        let tagIDsData = try encoder.encode(record.tagIDs)
        let parsedFieldsData = try record.parsedFields.map { try encoder.encode($0) }
        
        return PersistedBusinessCard(
            id: record.id,
            originalImageData: record.originalImageData,
            processedImageData: record.processedImageData,
            ocrRawText: record.ocrRawText,
            parsedFieldsData: parsedFieldsData,
            name: record.name,
            company: record.company,
            jobTitle: record.jobTitle,
            phonesData: phonesData,
            emailsData: emailsData,
            website: record.website,
            address: record.address,
            tagIDsData: tagIDsData,
            notes: record.notes,
            createdAt: record.createdAt,
            updatedAt: record.updatedAt
        )
    }
    
    /// 将持久化实体转换为逻辑模型
    static func mapToRecord(_ persisted: PersistedBusinessCard) throws -> BusinessCardRecord {
        guard let phonesData = persisted.phonesData else {
            throw CardRepositoryError.saveFailed("缺失必要的电话数据存储")
        }
        guard let emailsData = persisted.emailsData else {
            throw CardRepositoryError.saveFailed("缺失必要的邮箱数据存储")
        }
        guard let tagIDsData = persisted.tagIDsData else {
            throw CardRepositoryError.saveFailed("缺失必要的标签数据存储")
        }
        
        let phones = try decoder.decode([PhoneEntry].self, from: phonesData)
        let emails = try decoder.decode([String].self, from: emailsData)
        let tagIDs = try decoder.decode(Set<UUID>.self, from: tagIDsData)
        let parsedFields = try persisted.parsedFieldsData.map { try decoder.decode(ParsedContactFields.self, from: $0) }
        
        return BusinessCardRecord(
            id: persisted.id,
            originalImageData: persisted.originalImageData,
            processedImageData: persisted.processedImageData,
            ocrRawText: persisted.ocrRawText,
            parsedFields: parsedFields,
            name: persisted.name,
            company: persisted.company,
            jobTitle: persisted.jobTitle,
            phones: phones,
            emails: emails,
            website: persisted.website,
            address: persisted.address,
            tagIDs: tagIDs,
            notes: persisted.notes,
            createdAt: persisted.createdAt,
            updatedAt: persisted.updatedAt
        )
    }
    
    /// 更新持久化实体的内容
    static func updatePersisted(_ persisted: PersistedBusinessCard, from record: BusinessCardRecord) throws {
        // F01-3: 先完成所有可能失败的编码操作
        let phonesData = try encoder.encode(record.phones)
        let emailsData = try encoder.encode(record.emails)
        let tagIDsData = try encoder.encode(record.tagIDs)
        let parsedFieldsData = try record.parsedFields.map { try encoder.encode($0) }
        
        // 确认成功后再赋值
        persisted.originalImageData = record.originalImageData
        persisted.processedImageData = record.processedImageData
        persisted.ocrRawText = record.ocrRawText
        persisted.parsedFieldsData = parsedFieldsData
        persisted.name = record.name
        persisted.company = record.company
        persisted.jobTitle = record.jobTitle
        persisted.phonesData = phonesData
        persisted.emailsData = emailsData
        persisted.website = record.website
        persisted.address = record.address
        persisted.tagIDsData = tagIDsData
        persisted.notes = record.notes
        persisted.updatedAt = record.updatedAt
    }
}
