import Foundation

struct CardFieldReview: Equatable {
    let field: String
    let candidates: [String]
    let reason: String
}
struct CardContactParseResult: Equatable {
    let rawText: String
    let fields: ParsedContactFields
    let reviews: [CardFieldReview]
}

/// 本地确定性规则；匹配不代表正确率，结果必须由用户核验。
@MainActor
struct CardContactFieldParser {
    static func parse(_ ocr: RecognizedCardText) throws -> CardContactParseResult {
        var fields = ParsedContactFields()
        var reviews: [CardFieldReview] = []
        var values: [String: [String]] = [:]
        var unknown: [String] = []
        var labeledNames: Set<String> = []
        var eligibleNames: Set<String> = []
        // [DECISION/TEMP] 公司线索用于排除姓名，不把大小写或OCR置信度当作身份概率。
        let organizationPattern = #"\b(?:ltd|inc|llc|technology|technologies|studio|corporation|company|group|services|solutions|trading|limited)\b|科技|公司|工作室|集团|中心"#
        var phoneKeys: Set<String> = []
        var pendingPhoneLabel: String?
        var continuingAddress = false
        func matches(_ pattern: String, _ text: String) throws -> [NSTextCheckingResult] {
            try NSRegularExpression(pattern: pattern, options: [.caseInsensitive]).matches(in: text, range: NSRange(text.startIndex..., in: text))
        }
        func has(_ pattern: String, _ text: String) throws -> Bool { try !matches(pattern, text).isEmpty }
        func capture(_ m: NSTextCheckingResult, _ text: String, _ group: Int = 0) -> String {
            guard let range = Range(m.range(at: group), in: text) else { return "" }
            return String(text[range])
        }
        func add(_ key: String, _ text: String) {
            guard !text.isEmpty, !(values[key] ?? []).contains(text) else { return }
            values[key, default: []].append(text)
        }
        let lines = ocr.lines.isEmpty ? ocr.rawText.components(separatedBy: .newlines).map { ($0, Float(1)) } : ocr.lines.map { ($0.text, $0.confidence) }
        for (raw, confidence) in lines {
            let line = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty else { pendingPhoneLabel = nil; continuingAddress = false; continue }
            if confidence < 0.5 || !confidence.isFinite {
                reviews.append(CardFieldReview(field: "OCR原文", candidates: [raw], reason: "低置信度或无效置信度，请人工核对"))
            }
            if let m = try matches(#"^(姓名|name|公司|company|职位|title|job title|地址|address)\s*[:：]\s*(.+)$"#, line).first {
                let label = capture(m, line, 1).lowercased(), value = capture(m, line, 2)
                let key: String
                switch label {
                case "姓名", "name": key = "姓名"
                case "公司", "company": key = "公司"
                case "职位", "title", "job title": key = "职位"
                default: key = "地址"
                }
                add(key, value)
                if key == "姓名" {
                    let hasOrganizationClue = try has(organizationPattern, value)
                    if confidence.isFinite && confidence >= 0.5 && !hasOrganizationClue {
                        labeledNames.insert(value)
                        eligibleNames.insert(value)
                    } else {
                        reviews.append(CardFieldReview(field: "姓名", candidates: [value], reason: "姓名标签下存在公司线索或低OCR置信度，暂不自动选定"))
                    }
                }
                continuingAddress = key == "地址"; pendingPhoneLabel = nil; continue
            }
            let address = try has(#"[省市区县路街道巷号楼层座]|\b(?:street|road|avenue|boulevard|lane|suite|floor|building|blvd)\b|\b(?:st|rd|ave)\."#, line)
            let continuation = continuingAddress ? try has(#"^(?:[A-Za-z .'-]+,\s*[A-Z]{2}\s*\d{5}(?:-\d{4})?|\d{5,6})$"#, line) : false
            let contactLabel = try has(#"\b(?:mobile|cell|office|tel|phone|fax)\b|手机|电话|传真"#, line)
            if (address || continuation) && !contactLabel && !line.contains("@") {
                add("地址", line); continuingAddress = true; pendingPhoneLabel = nil; continue
            }
            continuingAddress = false
            var remainder = line
            let emails = try matches(#"[A-Z0-9.!#$%&'*+/=?^_{}|~-]+@[A-Z0-9-]+(?:\.[A-Z0-9-]+)+"#, remainder)
            for m in emails {
                let email = capture(m, remainder)
                if !fields.emails.contains(email) { fields.emails.append(email) }
            }
            for m in emails.reversed() { if let r = Range(m.range, in: remainder) { remainder.replaceSubrange(r, with: " ") } }
            let websites = try matches(#"(?:https?://|www\.)[A-Z0-9][A-Z0-9./?&=%_~+#:@-]*"#, remainder)
            for m in websites { add("网站", capture(m, remainder).trimmingCharacters(in: CharacterSet(charactersIn: ".,;，。；)"))) }
            for m in websites.reversed() { if let r = Range(m.range, in: remainder) { remainder.replaceSubrange(r, with: " ") } }
            let phones = try matches(#"(?<![A-Z0-9])\+?\(?\d[\d ()-]{5,}\d\)?(?![A-Z0-9])"#, remainder)
            var acceptedRanges: [NSRange] = []
            for m in phones {
                let number = capture(m, remainder).trimmingCharacters(in: .whitespaces)
                let digits = number.filter(\.isNumber)
                guard (7...15).contains(digits.count), !(try has(#"^\d{4}[-/]\d{1,2}[-/]\d{1,2}$"#, number)) else { continue }
                let prefix = (remainder as NSString).substring(to: m.range.location)
                let labels = try matches(#"\b(?:mobile|cell|office|tel|phone|fax)\b|手机|电话|传真"#, prefix)
                let label = (labels.last.map { capture($0, prefix) } ?? pendingPhoneLabel)?
                    .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: ":：")))
                let mainland = try has(#"^1[3-9]\d{9}$"#, digits)
                let formatted = number.contains("-") || number.contains("(") || number.contains(" ")
                guard label != nil || number.hasPrefix("+") || mainland || (formatted && digits.count >= 10) else { continue }
                let type: PhoneType
                switch label?.lowercased() {
                case "mobile", "cell", "手机": type = .mobile
                case "office", "tel", "phone", "电话": type = .office
                case "fax", "传真": type = .fax
                default: type = .other
                }
                if phoneKeys.insert(digits).inserted { fields.phones.append(PhoneEntry(value: number, type: type, label: label)) }
                else if let old = fields.phones.first(where: { $0.value.filter(\.isNumber) == digits }), old.type != type {
                    reviews.append(CardFieldReview(field: "电话类别", candidates: [old.value, number], reason: "同号标签冲突，保留首项并待确认"))
                }
                acceptedRanges.append(m.range)
            }
            for range in acceptedRanges.reversed() { if let r = Range(range, in: remainder) { remainder.replaceSubrange(r, with: " ") } }
            let stripped = try NSRegularExpression(pattern: #"\b(?:e-?mail|website|web|mobile|cell|office|tel|phone|fax)\b|邮箱|网址|手机|电话|传真"#, options: [.caseInsensitive])
                .stringByReplacingMatches(in: remainder, range: NSRange(remainder.startIndex..., in: remainder), withTemplate: " ")
            let residue = stripped.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: ":：;,，；/|")))
            if residue.isEmpty {
                pendingPhoneLabel = phones.isEmpty && emails.isEmpty && websites.isEmpty && contactLabel ? line : nil
                continue
            }
            pendingPhoneLabel = nil
            let company = try has(organizationPattern, residue)
            let job = try has(#"\b(?:engineer|designer|manager|director|architect|president|developer|consultant|CEO|CTO)\b|工程师|设计师|经理|总监|主管|顾问"#, residue)
            if company && job {
                reviews.append(CardFieldReview(field: "公司/职位", candidates: [raw], reason: "多类线索，未自动拆分")); unknown.append(raw)
            } else if company { add("公司", residue) }
            else if job { add("职位", residue) }
            else if try has(#"^(?:[\p{Han}]{2,4}|[A-Z][a-z]+(?:[-'][A-Z]?[a-z]+)?(?:\s+[A-Z][a-z]+(?:[-'][A-Z]?[a-z]+)?){1,3})$"#, residue) {
                add("姓名", residue)
                if confidence.isFinite && confidence >= 0.5 { eligibleNames.insert(residue) }
                reviews.append(CardFieldReview(field: "姓名", candidates: [residue], reason: "仅姓名外形规则，必须人工确认"))
            } else { unknown.append(raw) }
        }
        func single(_ key: String) -> String? {
            let list = values[key] ?? []
            if list.count > 1 { reviews.append(CardFieldReview(field: key, candidates: list, reason: "多个候选，未自动选择")); return nil }
            return list.first
        }
        // 显式姓名标签优先于仅外形候选；同级多个候选仍保留歧义，绝不取首行强填。
        let allNames = values["姓名"] ?? []
        let explicit = allNames.filter { labeledNames.contains($0) }
        let eligible = allNames.filter { eligibleNames.contains($0) }
        let preferred = explicit.isEmpty ? eligible : explicit
        fields.name = preferred.count == 1 ? preferred.first : nil
        if !allNames.isEmpty {
            let reason: String
            if fields.name != nil {
                reason = explicit.isEmpty ? "唯一可用姓名外形候选，已填入姓名；仍须人工核验" : "唯一有效显式姓名标签候选优先，已填入姓名；其他候选保留供核验"
            } else {
                reason = preferred.isEmpty ? "没有可靠候选，姓名暂未确定；请人工校正" : "存在多个同级姓名候选，姓名暂未确定；请人工校正"
            }
            reviews.append(CardFieldReview(field: "姓名", candidates: allNames, reason: reason))
        }
        fields.company = single("公司"); fields.jobTitle = single("职位"); fields.website = single("网站")
        let addresses = values["地址"] ?? []
        fields.address = addresses.isEmpty ? nil : addresses.joined(separator: "\n")
        fields.rawTextSegments = unknown
        return CardContactParseResult(rawText: ocr.rawText, fields: fields, reviews: reviews)
    }
}
