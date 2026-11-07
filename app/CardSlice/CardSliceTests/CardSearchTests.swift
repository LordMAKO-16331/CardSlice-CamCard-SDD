import Testing
@testable import CardSlice

@MainActor
struct CardSearchTests {
    private func fixture() -> [BusinessCardRecord] {
        [
            BusinessCardRecord(name: "林晓", company: "星河科技", jobTitle: "软件工程师",
                               phones: [PhoneEntry(value: "010-5555-0123", type: .office),
                                        PhoneEntry(value: "+86 (138) 0013-8000", type: .mobile)],
                               emails: ["lin@example.com", "support@starlab.example"]),
            BusinessCardRecord(name: "Mira Stone", company: "Mira Studio", jobTitle: "Design Director",
                               emails: ["mira@example.org"]),
            BusinessCardRecord(name: "陈青")
        ]
    }

    @Test func testBlankQueryReturnsAllCards() {
        let cards = fixture()
        #expect(CardSearchService.filter(cards, query: " \n\t") == cards)
    }

    @Test func testChineseNameSubstring() {
        let cards = fixture()
        #expect(CardSearchService.filter(cards, query: " 晓 ") == [cards[0]])
    }

    @Test func testEnglishNameIgnoresCase() {
        let cards = fixture()
        #expect(CardSearchService.filter(cards, query: "STONE") == [cards[1]])
    }

    @Test func testCompanySubstring() {
        let cards = fixture()
        #expect(CardSearchService.filter(cards, query: "studio") == [cards[1]])
    }

    @Test func testJobTitleSubstring() {
        let cards = fixture()
        #expect(CardSearchService.filter(cards, query: "DIRECTOR") == [cards[1]])
    }

    @Test func testSearchesEveryPhone() {
        let cards = fixture()
        #expect(CardSearchService.filter(cards, query: "55550123") == [cards[0]])
        #expect(CardSearchService.filter(cards, query: "00138000") == [cards[0]])
    }

    @Test func testPhoneFormattingDifferences() {
        let cards = fixture()
        #expect(CardSearchService.filter(cards, query: "(138) 0013–8000") == [cards[0]])
        #expect(CardSearchService.filter(cards, query: "编号 138") == [])
    }

    @Test func testSearchesAllEmailsByUsernameAndDomain() {
        let cards = fixture()
        #expect(CardSearchService.filter(cards, query: "LIN@") == [cards[0]])
        #expect(CardSearchService.filter(cards, query: "STARLAB.EXAMPLE") == [cards[0]])
    }

    @Test func testNoMatchReturnsEmpty() {
        #expect(CardSearchService.filter(fixture(), query: "不存在的联系人").isEmpty)
    }

    @Test func testMissingOptionalFieldsAreSafe() {
        let card = BusinessCardRecord(name: "陈青")
        #expect(CardSearchService.filter([card], query: "陈") == [card])
        #expect(CardSearchService.filter([card], query: "company").isEmpty)
    }

    @Test func testMultipleFieldMatchesReturnOneCard() {
        let cards = fixture()
        #expect(CardSearchService.filter(cards, query: "mira") == [cards[1]])
    }

    @Test func testPreservesOrderAndOriginalRecords() {
        let cards = fixture()
        let original = cards
        #expect(CardSearchService.filter(cards, query: "example") == [cards[0], cards[1]])
        _ = CardSearchService.filter(cards, query: "13800138000")
        #expect(cards == original)
        #expect(cards[0].phones[1].value == "+86 (138) 0013-8000")
    }

    @Test func testOCRAndInitialCandidatesAreNotSearchable() {
        let card = BusinessCardRecord(ocrRawText: "OCR-only", parsedFields: ParsedContactFields(name: "candidate-only"),
                                      name: "最终姓名", notes: "note-only")
        #expect(CardSearchService.filter([card], query: "note-only") == [card])
        for query in ["OCR-only", "candidate-only"] {
            #expect(CardSearchService.filter([card], query: query).isEmpty)
        }
    }

    @Test func testChineseNoteSubstring() {
        let card = BusinessCardRecord(name: "林晓", notes: "约周五确认报价。")
        #expect(CardSearchService.filter([card], query: "确认报价") == [card])
    }

    @Test func testEnglishNoteSubstringIgnoresCase() {
        let card = BusinessCardRecord(name: "Mira", notes: "Follow-up Monday")
        #expect(CardSearchService.filter([card], query: " UP MON ") == [card])
    }

    @Test func testMissingAndEmptyNotesAreSafe() {
        let cards = [BusinessCardRecord(name: "甲"), BusinessCardRecord(name: "乙", notes: "")]
        #expect(CardSearchService.filter(cards, query: "报价").isEmpty)
        #expect(CardSearchService.filter(cards, query: " ") == cards)
    }

    @Test func testSearchReflectsUpdatedAndClearedNotes() {
        var card = BusinessCardRecord(name: "林晓", notes: "旧报价")
        #expect(CardSearchService.filter([card], query: "旧报价") == [card])
        card.notes = "新报价"
        #expect(CardSearchService.filter([card], query: "旧报价").isEmpty)
        #expect(CardSearchService.filter([card], query: "新报价") == [card])
        card.notes = nil
        #expect(CardSearchService.filter([card], query: "新报价").isEmpty)
    }

    @Test func testNameAndNoteMatchOnlyOnce() {
        let card = BusinessCardRecord(name: "Mira Stone", notes: "Call Mira")
        #expect(CardSearchService.filter([card], query: "mira") == [card])
    }

    @Test func testBrowseAndActiveBlankSearchAreDistinct() throws {
        let cards = fixture()
        let model = CardHolderViewModel(repository: try InMemoryCardRepository(initialRecords: cards))
        #expect(CardSearchService.Mode(isSearching: false, query: "") == .browsing)
        #expect(model.visibleCards(in: cards, query: "") == cards)
        #expect(CardSearchService.Mode(isSearching: true, query: " \n ") == .awaitingKeyword)
        #expect(CardSearchService.Mode(isSearching: true, query: " STUDIO ") == .matching("STUDIO"))
        #expect(CardSearchService.Mode(isSearching: false, query: "STUDIO") == .browsing)
        #expect(model.visibleCards(in: cards, query: "") == cards)
    }

    @Test func testHighlightRangesPreserveOriginalChineseAndEnglishText() throws {
        let name = fixture()[0].name
        let nameRange = try #require(CardSearchService.Matcher(keyword: "晓").range(in: name))
        #expect(String(name[nameRange]) == "晓")

        let company = try #require(fixture()[1].company)
        let companyRange = try #require(CardSearchService.Matcher(keyword: "STUDIO").range(in: company))
        #expect(String(company[companyRange]) == "Studio")
    }

    @Test func testNormalizedPhoneShowsOriginalNumber() {
        let card = fixture()[0]
        let matcher = CardSearchService.Matcher(keyword: "13800138000")
        #expect(matcher.matchingPhone(in: card) == "+86 (138) 0013-8000")
        #expect(matcher.range(in: card.phones[1].value) == nil)
    }

    @Test func testMatchingEmailShowsStoredValue() {
        let matcher = CardSearchService.Matcher(keyword: "STARLAB")
        #expect(matcher.matchingEmail(in: fixture()[0]) == "support@starlab.example")
        #expect(matcher.matchingEmail(in: fixture()[2]) == nil)
    }

    @Test func testMatchingNoteKeepsRelevantTextAndDoesNotDuplicateCard() throws {
        let card = BusinessCardRecord(name: "Mira", notes: String(repeating: "前", count: 80) + "Mira next week")
        let matcher = CardSearchService.Matcher(keyword: "mira")
        let snippet = try #require(matcher.matchingNote(in: card))
        #expect(snippet.hasPrefix("…"))
        #expect(snippet.hasSuffix("Mira next week"))
        #expect(matcher.range(in: snippet) != nil)
        #expect(CardSearchService.filter([card], query: "mira") == [card])
    }

    @Test func testTagSearchReflectsEditsAndDeletion() async throws {
        let tag = fixture()[0].id
        var tagged = fixture()[0]
        tagged.tagIDs = [tag]
        tagged.notes = "报价旧版"
        let untagged = BusinessCardRecord(name: "报价")
        let repository = try InMemoryCardRepository(initialRecords: [tagged, untagged])
        let model = CardHolderViewModel(repository: repository)
        await model.load()
        model.selectedTagID = tag

        func results() -> [BusinessCardRecord] {
            guard case .loaded(let cards) = model.state else { return [] }
            return model.visibleCards(in: cards, query: "报价")
        }

        #expect(results().map(\.id) == [tagged.id])
        tagged.notes = "报价新版"
        model.applyEditedCard(tagged)
        let updated = try #require(results().first)
        #expect(CardSearchService.Matcher(keyword: "报价").matchingNote(in: updated) == "报价新版")
        model.applyDeletedCard(id: tagged.id)
        #expect(results().isEmpty)
        #expect(model.selectedTagID == tag)
    }

}
