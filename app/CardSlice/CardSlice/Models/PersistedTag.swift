import Foundation
import SwiftData

/// 正式标签实体。名片继续通过现有 UUID 集合关联标签。
@Model
final class PersistedTag {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var nameKey: String
    var name: String

    init(id: UUID, name: String, nameKey: String) {
        self.id = id
        self.name = name
        self.nameKey = nameKey
    }
}
