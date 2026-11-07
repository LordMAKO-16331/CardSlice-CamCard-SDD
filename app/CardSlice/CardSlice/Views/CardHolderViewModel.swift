import Foundation
import Combine

/// 管理列表加载状态，所有数据通过 Repository 读取。
@MainActor
final class CardHolderViewModel: ObservableObject {
    enum LoadState {
        case loading
        case loaded([BusinessCardRecord])
        case failed(String)
    }

    @Published private(set) var state: LoadState = .loading
    #if DEBUG
    @Published private(set) var isSavingTestCard = false
    @Published private(set) var testCardMessage: String?

    /// [DECISION/TEMP] 仅正常 DEBUG 启动可用，UI 测试 Mock 模式不开放写入。
    var canSaveTestCard: Bool {
        !ProcessInfo.processInfo.arguments.contains("--ui-testing-mock-cards")
    }

    func saveTestCard() async {
        guard canSaveTestCard, !isSavingTestCard else { return }
        isSavingTestCard = true
        testCardMessage = nil
        defer { isSavingTestCard = false }

        let record = BusinessCardRecord(
            name: "持久化验证名片",
            company: "虚拟测试公司",
            jobTitle: "开发验证",
            phones: [PhoneEntry(value: "+1-202-555-0100", type: .mobile)],
            emails: ["persistence@example.com"],
            notes: "[DECISION/TEMP] 用户点击开发按钮保存的虚拟名片，用于退出并重启后的恢复验证。"
        )

        do {
            try await repository.insert(record)
        } catch {
            testCardMessage = "保存失败：\(error.localizedDescription)"
            return
        }

        // 写入成功后重新读取，读取失败不可报告完整验证成功。
        state = .loading
        do {
            let cards = try await repository.fetchAll()
            state = .loaded(cards)
            testCardMessage = cards.contains(where: { $0.id == record.id })
                ? "测试名片已保存并重新读取；请完全退出 App 后重新启动，验证恢复。"
                : "保存已返回，但重新读取未找到测试名片，请检查。"
        } catch {
            state = .failed(error.localizedDescription)
            testCardMessage = "保存已完成，但重新读取失败：\(error.localizedDescription)"
        }
    }
    #endif

    @Published private(set) var tags: [TagRecord] = []
    @Published private(set) var tagLoadError: String?
    @Published var selectedTagID: UUID?
    private let tagRepository: (any TagRepository)?
    private let repository: any CardRepository

    init(repository: any CardRepository, tagRepository: (any TagRepository)? = nil) {
        self.repository = repository
        self.tagRepository = tagRepository
    }

    var supportsTags: Bool { tagRepository != nil }

    func loadTags() {
        guard let tagRepository else { return }
        do {
            tags = try tagRepository.fetchAll()
            tagLoadError = nil
            if let selectedTagID, !tags.contains(where: { $0.id == selectedTagID }) {
                self.selectedTagID = nil
            }
        } catch {
            tagLoadError = error.localizedDescription
        }
    }

    func createTag(name: String) throws {
        let repository = try requireTagRepository()
        let tag = try repository.create(name: name)
        tags.append(tag)
        tags.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func deleteTag(id: UUID) throws {
        try requireTagRepository().delete(id: id)
        tags.removeAll { $0.id == id }
        if selectedTagID == id { selectedTagID = nil }
        if case .loaded(let cards) = state {
            state = .loaded(cards.map { card in
                var updated = card
                updated.tagIDs.remove(id)
                return updated
            })
        }
    }

    func saveTags(_ ids: Set<UUID>, forCardID id: UUID) throws {
        try requireTagRepository().setTagIDs(ids, forCardID: id)
        if case .loaded(let cards) = state, var card = cards.first(where: { $0.id == id }) {
            card.tagIDs = ids
            applyEditedCard(card)
        }
    }

    func visibleCards(in cards: [BusinessCardRecord], query: String) -> [BusinessCardRecord] {
        let tagged = selectedTagID.map { id in cards.filter { $0.tagIDs.contains(id) } } ?? cards
        return CardSearchService.filter(tagged, query: query)
    }

    private func requireTagRepository() throws -> any TagRepository {
        guard let tagRepository else { throw TagRepositoryError.writeFailed("标签功能当前不可用。") }
        return tagRepository
    }

    var canSaveImportedCard: Bool { repository is SwiftDataCardRepository }

    func insertImportedCard(_ record: BusinessCardRecord) async throws {
        guard canSaveImportedCard else { throw CardRecordAssemblyError.nonPersistentRepository }
        try await repository.insert(record)
    }

    var savedRecordEditor: CardSavedRecordEditor { CardSavedRecordEditor(repository: repository) }

    func applyEditedCard(_ record: BusinessCardRecord) {
        guard case .loaded(var cards) = state, let index = cards.firstIndex(where: { $0.id == record.id }) else { return }
        cards[index] = record
        state = .loaded(cards)
    }

    func deletionCoordinator(for id: UUID) -> CardDeletionCoordinator {
        CardDeletionCoordinator(id: id, repository: repository)
    }

    func applyDeletedCard(id: UUID) {
        guard case .loaded(let cards) = state else { return }
        state = .loaded(cards.filter { $0.id != id })
    }

    func load() async {
        state = .loading
        do {
            let cards = try await repository.fetchAll()
            guard !Task.isCancelled else { return }
            state = .loaded(cards)
        } catch {
            guard !Task.isCancelled else { return }
            state = .failed(error.localizedDescription)
        }
    }
}
