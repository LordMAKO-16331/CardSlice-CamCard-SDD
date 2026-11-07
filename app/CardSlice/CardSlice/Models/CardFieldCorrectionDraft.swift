import Foundation

struct CardCorrectionPhone: Identifiable, Equatable {
    let id: UUID
    var value: String
    var type: PhoneType
    var label: String?
    init(value: String = "", type: PhoneType = .other, label: String? = nil) {
        id = UUID(); self.value = value; self.type = type; self.label = label
    }
}
struct CardCorrectionEmail: Identifiable, Equatable {
    let id: UUID
    var value: String
    init(value: String = "") { id = UUID(); self.value = value }
}

/// 当前图片会话的值类型副本，原始OCR与初始解析均不可由编辑字段覆盖。
struct CardFieldCorrectionDraft: Equatable {
    let original: CardContactParseResult
    var name: String
    var company: String
    var jobTitle: String
    var phones: [CardCorrectionPhone]
    var emails: [CardCorrectionEmail]
    var website: String
    var address: String

    init(result: CardContactParseResult) {
        self.init(original: result, fields: result.fields)
    }

    init(savedRecord record: BusinessCardRecord) {
        let original = CardContactParseResult(rawText: record.ocrRawText ?? "",
            fields: record.parsedFields ?? ParsedContactFields(), reviews: [])
        self.init(original: original, fields: ParsedContactFields(name: record.name, company: record.company,
            jobTitle: record.jobTitle, phones: record.phones, emails: record.emails,
            website: record.website, address: record.address))
    }

    private init(original: CardContactParseResult, fields: ParsedContactFields) {
        self.original = original
        name = fields.name ?? ""; company = fields.company ?? ""; jobTitle = fields.jobTitle ?? ""
        phones = fields.phones.map { CardCorrectionPhone(value: $0.value, type: $0.type, label: $0.label) }
        emails = fields.emails.map { CardCorrectionEmail(value: $0) }
        website = fields.website ?? ""; address = fields.address ?? ""
    }

    var validationMessages: [String] {
        var messages: [String] = []
        for (index, phone) in phones.enumerated() {
            let value = phone.value.trimmingCharacters(in: .whitespacesAndNewlines)
            if value.isEmpty { messages.append("电话第\(index + 1)项为空，请填写或删除。") }
            else if !value.contains(where: \.isNumber) { messages.append("电话第\(index + 1)项需要包含数字。") }
        }
        for (index, email) in emails.enumerated() {
            let value = email.value.trimmingCharacters(in: .whitespacesAndNewlines)
            let parts = value.split(separator: "@", omittingEmptySubsequences: false)
            if value.isEmpty { messages.append("邮箱第\(index + 1)项为空，请填写或删除。") }
            else if parts.count != 2 || parts[0].isEmpty || !parts[1].contains(".") || parts[1].hasPrefix(".") || parts[1].hasSuffix(".") || value.contains(where: \.isWhitespace) {
                messages.append("邮箱第\(index + 1)项格式不完整，请检查。")
            }
        }
        return messages
    }

    func confirmedFields() throws -> ParsedContactFields {
        let errors = validationMessages
        guard errors.isEmpty else { throw CardFieldCorrectionError.invalidFields(errors) }
        func optional(_ value: String) -> String? {
            value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : value
        }
        return ParsedContactFields(name: optional(name), company: optional(company), jobTitle: optional(jobTitle),
            phones: phones.map { PhoneEntry(value: $0.value, type: $0.type, label: $0.label) },
            emails: emails.map(\.value), website: optional(website), address: optional(address),
            rawTextSegments: original.fields.rawTextSegments)
    }
}

enum CardFieldCorrectionError: Error, LocalizedError {
    case invalidFields([String])
    var errorDescription: String? {
        switch self { case .invalidFields(let messages): return messages.joined(separator: "\n") }
    }
}
