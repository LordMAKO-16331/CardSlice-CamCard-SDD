import Foundation

/// 电话号码类别 [COURSE]
enum PhoneType: String, Codable, CaseIterable {
    case mobile = "Mobile"
    case office = "Office"
    case fax = "Fax"
    case other = "Other"
}

/// 电话号码条目 [COURSE]
struct PhoneEntry: Codable, Equatable, Hashable {
    var value: String
    var type: PhoneType
    var label: String? // 原始标签
    
    init(value: String, type: PhoneType, label: String? = nil) {
        self.value = value
        self.type = type
        self.label = label
    }
}

/// OCR 初始解析结构化结果 [DECISION]
/// 初始解析结果与最终确认结果必须是两份可区分的数据。
struct ParsedContactFields: Codable, Equatable {
    var name: String?
    var company: String?
    var jobTitle: String?
    var phones: [PhoneEntry] = []
    var emails: [String] = []
    var website: String?
    var address: String?
    var rawTextSegments: [String] = [] // 无法明确分类的文字片段
    
    init(
        name: String? = nil,
        company: String? = nil,
        jobTitle: String? = nil,
        phones: [PhoneEntry] = [],
        emails: [String] = [],
        website: String? = nil,
        address: String? = nil,
        rawTextSegments: [String] = []
    ) {
        self.name = name
        self.company = company
        self.jobTitle = jobTitle
        self.phones = phones
        self.emails = emails
        self.website = website
        self.address = address
        self.rawTextSegments = rawTextSegments
    }
}

/// 标签模型 [COURSE]
struct TagRecord: Codable, Identifiable, Equatable, Hashable {
    var id: UUID = UUID()
    var name: String
    
    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}

/// 已保存名片的逻辑数据模型 [R07/R09]
/// 使用普通 Swift 数据类型，暂不引入 SwiftData @Model。
struct BusinessCardRecord: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    
    // 图片数据 [OPEN] 图片字段暂时允许 Mock Data 为 nil
    var originalImageData: Data?
    var processedImageData: Data?
    
    // OCR 追溯 [COURSE]
    var ocrRawText: String?
    var parsedFields: ParsedContactFields?
    
    // 最终确认字段 [COURSE]
    var name: String
    var company: String?
    var jobTitle: String?
    var phones: [PhoneEntry] = []
    var emails: [String] = []
    var website: String?
    var address: String?
    
    // 关联数据
    var tagIDs: Set<UUID> = []
    var notes: String?
    
    // 时间戳
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    init(
        id: UUID = UUID(),
        originalImageData: Data? = nil,
        processedImageData: Data? = nil,
        ocrRawText: String? = nil,
        parsedFields: ParsedContactFields? = nil,
        name: String,
        company: String? = nil,
        jobTitle: String? = nil,
        phones: [PhoneEntry] = [],
        emails: [String] = [],
        website: String? = nil,
        address: String? = nil,
        tagIDs: Set<UUID> = [],
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.originalImageData = originalImageData
        self.processedImageData = processedImageData
        self.ocrRawText = ocrRawText
        self.parsedFields = parsedFields
        self.name = name
        self.company = company
        self.jobTitle = jobTitle
        self.phones = phones
        self.emails = emails
        self.website = website
        self.address = address
        self.tagIDs = tagIDs
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
