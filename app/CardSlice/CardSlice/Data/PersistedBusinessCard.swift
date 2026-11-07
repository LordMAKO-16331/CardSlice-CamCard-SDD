import Foundation
import SwiftData

/// SwiftData 持久化实体 [R09]
/// 与逻辑模型 BusinessCardRecord 保持隔离。
@Model
final class PersistedBusinessCard {
    @Attribute(.unique) var id: UUID
    
    // 图像数据
    @Attribute(.externalStorage) var originalImageData: Data?
    @Attribute(.externalStorage) var processedImageData: Data?
    
    // OCR 与解析
    var ocrRawText: String?
    var parsedFieldsData: Data? // ParsedContactFields 的 JSON 数据
    
    // 联系人字段
    var name: String
    var company: String?
    var jobTitle: String?
    var phonesData: Data? // [PhoneEntry] 的 JSON 数据
    var emailsData: Data? // [String] 的 JSON 数据
    var website: String?
    var address: String?
    
    // 关联与备注
    var tagIDsData: Data? // Set<UUID> 的 JSON 数据
    var notes: String?
    
    // 时间戳
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID,
        originalImageData: Data? = nil,
        processedImageData: Data? = nil,
        ocrRawText: String? = nil,
        parsedFieldsData: Data? = nil,
        name: String,
        company: String? = nil,
        jobTitle: String? = nil,
        phonesData: Data? = nil,
        emailsData: Data? = nil,
        website: String? = nil,
        address: String? = nil,
        tagIDsData: Data? = nil,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.originalImageData = originalImageData
        self.processedImageData = processedImageData
        self.ocrRawText = ocrRawText
        self.parsedFieldsData = parsedFieldsData
        self.name = name
        self.company = company
        self.jobTitle = jobTitle
        self.phonesData = phonesData
        self.emailsData = emailsData
        self.website = website
        self.address = address
        self.tagIDsData = tagIDsData
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
