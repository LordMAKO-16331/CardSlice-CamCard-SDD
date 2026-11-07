import Foundation

@MainActor
struct CardSavedRecordEditor {
    let repository: any CardRepository

    func load(id: UUID) async throws -> BusinessCardRecord {
        try await repository.fetch(id: id)
    }

    func save(id: UUID, fields: ParsedContactFields, notes: String? = nil) async throws -> BusinessCardRecord {
        guard let name = fields.name, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CardFieldCorrectionError.invalidFields(["保存前请填写姓名。"])
        }
        // 只更新该 UUID 对应记录的可编辑字段，保留其余数据。
        var record = try await repository.fetch(id: id)
        record.name = name
        record.company = fields.company
        record.jobTitle = fields.jobTitle
        record.phones = fields.phones
        record.emails = fields.emails
        record.website = fields.website
        record.address = fields.address
        if let notes {
            record.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes
        }
        record.updatedAt = Date()
        try await repository.update(record)
        return record
    }
}
