import Foundation

@MainActor
enum CardSearchService {
    enum Mode: Equatable {
        case browsing
        case awaitingKeyword
        case matching(String)

        init(isSearching: Bool, query: String) {
            let keyword = CardSearchService.keyword(from: query)
            self = !isSearching ? .browsing : keyword.isEmpty ? .awaitingKeyword : .matching(keyword)
        }
    }

    struct Matcher {
        let keyword: String
        private let digits: String

        init(keyword: String) {
            self.keyword = keyword
            let phoneSeparators = "+()-–—."
            let isPhoneQuery = keyword.allSatisfy {
                $0.isNumber || $0.isWhitespace || phoneSeparators.contains($0)
            }
            digits = isPhoneQuery ? keyword.filter(\.isNumber) : ""
        }

        func range(in value: String) -> Range<String.Index>? {
            guard !keyword.isEmpty else { return nil }
            return value.range(of: keyword, options: .caseInsensitive)
        }

        func matchingPhone(in card: BusinessCardRecord) -> String? {
            guard !digits.isEmpty else { return nil }
            return card.phones.first { $0.value.filter(\.isNumber).contains(digits) }?.value
        }

        func matchingEmail(in card: BusinessCardRecord) -> String? {
            card.emails.first { range(in: $0) != nil }
        }

        func matchingNote(in card: BusinessCardRecord) -> String? {
            guard let note = card.notes, let match = range(in: note) else { return nil }
            let before = note[..<match.lowerBound]
            let after = note[match.upperBound...]
            let prefix = before.suffix(28)
            let suffix = after.prefix(40)
            return (prefix.startIndex == before.startIndex ? "" : "…")
                + String(prefix) + String(note[match]) + String(suffix)
                + (suffix.endIndex == after.endIndex ? "" : "…")
        }

        func matches(_ card: BusinessCardRecord) -> Bool {
            range(in: card.name) != nil
                || card.company.flatMap { range(in: $0) } != nil
                || card.jobTitle.flatMap { range(in: $0) } != nil
                || matchingEmail(in: card) != nil
                || card.notes.flatMap { range(in: $0) } != nil
                || matchingPhone(in: card) != nil
        }
    }

    static func keyword(from query: String) -> String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func filter(_ cards: [BusinessCardRecord], query: String) -> [BusinessCardRecord] {
        let keyword = Self.keyword(from: query)
        guard !keyword.isEmpty else { return cards }
        let matcher = Matcher(keyword: keyword)
        return cards.filter { matcher.matches($0) }
    }
}
