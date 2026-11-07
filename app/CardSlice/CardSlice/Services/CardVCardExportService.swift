import Foundation

enum CardVCardExportError: Error, LocalizedError, Equatable {
    case missingName

    var errorDescription: String? {
        "名片没有有效姓名。请先编辑姓名再导出。"
    }
}

@MainActor
enum CardVCardExportService {
    static func data(for card: BusinessCardRecord) throws -> Data {
        guard let name = nonBlank(card.name) else { throw CardVCardExportError.missingName }
        let fullName = escape(name)
        // 以完整姓名填入一个 N 分量，保留显示值且不推断姓氏。
        var lines = ["BEGIN:VCARD", "VERSION:3.0", "N:;\(fullName);;;", "FN:\(fullName)"]

        if let company = nonBlank(card.company) { lines.append("ORG:\(escape(company))") }
        if let title = nonBlank(card.jobTitle) { lines.append("TITLE:\(escape(title))") }

        for phone in card.phones {
            guard let number = nonBlank(phone.value) else { continue }
            let key: String
            switch phone.type {
            case .mobile: key = "TEL;TYPE=CELL"
            case .office: key = "TEL;TYPE=WORK"
            case .fax: key = "TEL;TYPE=WORK,FAX"
            case .other: key = "TEL"
            }
            lines.append("\(key):\(escape(number))")
        }
        for email in card.emails {
            if let value = nonBlank(email) { lines.append("EMAIL:\(escape(value))") }
        }
        if let website = nonBlank(card.website) {
            // URL 是 URI 值。保留 URI 分隔符，并对空白、换行及非 ASCII 字符进行百分号编码。
            let uriCharacters = CharacterSet(charactersIn:
                "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~:/?#[]@!$&'()*+,;=%")
            if let uri = website.addingPercentEncoding(withAllowedCharacters: uriCharacters) {
                lines.append("URL:\(uri)")
            }
        }
        if let address = nonBlank(card.address) {
            // 原模型只有一个地址文本字段，完整放入街道分量。
            lines.append("ADR:;;\(escape(address));;;;")
        }
        lines.append("END:VCARD")
        return Data((lines.map(fold).joined(separator: "\r\n") + "\r\n").utf8)
    }

    static func makeTemporaryFile(for card: BusinessCardRecord) throws -> URL {
        let contents = try data(for: card)
        let files = FileManager.default
        let exportID = UUID().uuidString
        let directory = files.temporaryDirectory.appendingPathComponent("CardSlice-\(exportID)", isDirectory: true)
        try files.createDirectory(at: directory, withIntermediateDirectories: false)
        let url = directory.appendingPathComponent("Contact-\(exportID).vcf")
        do {
            try contents.write(to: url, options: .atomic)
            return url
        } catch {
            try? files.removeItem(at: directory)
            throw error
        }
    }

    static func removeTemporaryFile(at url: URL) {
        try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
    }

    private static func nonBlank(_ text: String?) -> String? {
        guard let text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return text
    }

    private static func escape(_ text: String) -> String {
        text.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: ";", with: "\\;")
            .replacingOccurrences(of: ",", with: "\\,")
            .replacingOccurrences(of: "\r\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\n")
            .replacingOccurrences(of: "\n", with: "\\n")
    }

    private static func fold(_ line: String) -> String {
        var result = ""
        var bytesOnLine = 0
        for scalar in line.unicodeScalars {
            let width = String(scalar).utf8.count
            if bytesOnLine + width > 75 {
                result += "\r\n "
                bytesOnLine = 1
            }
            result.unicodeScalars.append(scalar)
            bytesOnLine += width
        }
        return result
    }
}
