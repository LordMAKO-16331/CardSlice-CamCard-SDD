import Foundation
import SwiftUI
import ImageIO

/// CardHolder 首页与列表 [R01]
@MainActor
struct CardHolderView: View {
    @StateObject private var viewModel: CardHolderViewModel
    @State private var showingImageImport = false
    @State private var showingSavedCard = false
    @State private var showingTagManagement = false
    @State private var searchQuery = ""
    @State private var isSearchPresented = false

    init(repository: any CardRepository, tagRepository: (any TagRepository)? = nil) {
        _viewModel = StateObject(wrappedValue: CardHolderViewModel(repository: repository, tagRepository: tagRepository))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.supportsTags { tagControls }
                switch viewModel.state {
                case .loading:
                    ProgressView("正在加载名片…")
                case .loaded(let cards):
                    switch CardSearchService.Mode(isSearching: isSearchPresented, query: searchQuery) {
                    case .browsing:
                        if cards.isEmpty {
                            emptyStateView
                        } else {
                            cardList(cards)
                        }
                    case .awaitingKeyword:
                        ContentUnavailableView("请输入搜索关键词", systemImage: "magnifyingglass")
                    case .matching(let keyword):
                        cardList(cards, matcher: CardSearchService.Matcher(keyword: keyword))
                    }
                case .failed(let message):
                    VStack(spacing: 16) {
                        Text("名片加载失败")
                            .font(.headline)
                        Text(message)
                            .foregroundStyle(.secondary)
                        Button("重试") {
                            Task { await viewModel.load() }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("名片夹")
            .searchable(text: $searchQuery, isPresented: $isSearchPresented,
                        placement: .navigationBarDrawer(displayMode: .always),
                        prompt: "搜索姓名、公司、职位、电话、邮箱或备注")
            .onChange(of: isSearchPresented) { _, presented in
                if !presented { searchQuery = "" }
            }
            .navigationDestination(for: UUID.self) { id in
                if case .loaded(let cards) = viewModel.state,
                   let card = cards.first(where: { $0.id == id }) {
                    CardDetailView(card: card, editor: viewModel.savedRecordEditor,
                                   onUpdated: viewModel.applyEditedCard,
                                   deletion: viewModel.deletionCoordinator(for: card.id),
                                   onDeleted: viewModel.applyDeletedCard,
                                   tagModel: viewModel.supportsTags ? viewModel : nil)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("扫描名片") {
                        showingImageImport = true
                    }
                }
                #if DEBUG
                if viewModel.canSaveTestCard {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Text("[DECISION/TEMP] 开发工具")
                            Button("[开发] 保存测试名片") {
                                Task { await viewModel.saveTestCard() }
                            }
                            .disabled(viewModel.isSavingTestCard || isLoading)
                            if let message = viewModel.testCardMessage {
                                Text(message)
                            }
                        } label: {
                            if viewModel.isSavingTestCard {
                                ProgressView().accessibilityLabel("正在保存测试名片")
                            } else {
                                Label("开发工具", systemImage: "wrench.and.screwdriver")
                            }
                        }
                    }
                }
                #endif
                ToolbarItem(placement: .navigationBarTrailing) {
                    if case .loaded(let cards) = viewModel.state {
                        Text("全部名片：\(cards.count) 张")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .sheet(isPresented: $showingTagManagement) {
            TagManagementView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingImageImport) {
            CardImageImportView(canSave: viewModel.canSaveImportedCard, insertRecord: { record in
                try await viewModel.insertImportedCard(record)
            }, onSaved: {
                showingSavedCard = true
                Task { await viewModel.load() }
            })
        }
        .alert("名片已保存", isPresented: $showingSavedCard) {
            Button("确定") {}
        } message: {
            Text("已写入本地数据库。列表将重新读取；如读取失败，请使用列表重试按钮。")
        }
        .task {
            viewModel.loadTags()
            await viewModel.load()
        }
    }

    #if DEBUG
    private var isLoading: Bool {
        if case .loading = viewModel.state { return true }
        return false
    }
    #endif

    private var tagControls: some View {
        HStack {
            Menu {
                Button("全部名片") { viewModel.selectedTagID = nil }
                ForEach(viewModel.tags) { tag in
                    Button(tag.name) { viewModel.selectedTagID = tag.id }
                }
            } label: {
                let name = viewModel.tags.first { $0.id == viewModel.selectedTagID }?.name ?? "全部名片"
                Label(name, systemImage: "line.3.horizontal.decrease.circle")
                    .accessibilityLabel("标签筛选：\(name)")
            }
            Spacer()
            Button("管理标签") { showingTagManagement = true }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    /// 空状态视图 [DECISION/TEMP]
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "person.text.rectangle")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            Text("暂无名片")
                .font(.title3)
                .foregroundColor(.secondary)
            
            Text("可拍摄名片，或从相册选取图片。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding()
    }
    
    private func cardList(_ cards: [BusinessCardRecord], matcher: CardSearchService.Matcher? = nil) -> some View {
        let results = viewModel.visibleCards(in: cards, query: matcher?.keyword ?? "")
        return VStack(spacing: 0) {
            if viewModel.selectedTagID != nil || matcher != nil {
                Text(matcher == nil ? "筛选结果：\(results.count) 张" : "搜索结果：\(results.count) 张")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
            }

            if results.isEmpty {
                ContentUnavailableView("未找到匹配名片", systemImage: "magnifyingglass")
            } else {
                List(results) { card in
                    NavigationLink(value: card.id) {
                        CardRow(card: card, matcher: matcher)
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
    }
}

/// 名片行组件
private struct CardRow: View {
    let card: BusinessCardRecord
    let matcher: CardSearchService.Matcher?
    
    var body: some View {
        HStack(spacing: 15) {
            CardRowThumbnail(card: card)

            VStack(alignment: .leading, spacing: 4) {
                // 姓名 [COURSE]
                highlighted(card.name)
                    .font(.headline)
                
                // 职位与公司 [COURSE]
                Group {
                    if let job = card.jobTitle, !job.isEmpty {
                        highlighted(job)
                    }
                    if let company = card.company, !company.isEmpty {
                        highlighted(company)
                    }
                }
                .font(.subheadline)
                .foregroundColor(.secondary)

                if let matcher {
                    Group {
                        if let phone = matcher.matchingPhone(in: card) {
                            summary("匹配电话：", value: phone)
                        }
                        if let email = matcher.matchingEmail(in: card) {
                            summary("匹配邮箱：", value: email)
                        }
                        if let note = matcher.matchingNote(in: card) {
                            summary("匹配备注：", value: note)
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func summary(_ label: String, value: String) -> Text {
        var text = AttributedString(label)
        text.append(highlightedValue(value))
        return Text(text)
    }

    private func highlighted(_ value: String) -> Text {
        Text(highlightedValue(value))
    }

    private func highlightedValue(_ value: String) -> AttributedString {
        guard let range = matcher?.range(in: value) else { return AttributedString(value) }

        var result = AttributedString(String(value[..<range.lowerBound]))
        var match = AttributedString(String(value[range]))
        match.backgroundColor = Color.yellow.opacity(0.35)
        match.foregroundColor = Color.primary
        result.append(match)
        result.append(AttributedString(String(value[range.upperBound...])))
        return result
    }

}

private struct CardRowThumbnail: View {
    let card: BusinessCardRecord
    @Environment(\.displayScale) private var displayScale
    @State private var loadedRequest: CardThumbnailRequest?
    @State private var thumbnail: CGImage?

    var body: some View {
        let request = CardThumbnailRequest(cardID: card.id, processed: card.processedImageData,
                                           original: card.originalImageData,
                                           maxPixelSize: min(240, max(60, Int((60 * displayScale).rounded(.up)))))
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemGray5))
            if loadedRequest == request, let thumbnail {
                Image(decorative: thumbnail, scale: displayScale)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "photo")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 60, height: 40)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .accessibilityHidden(true)
        .task(id: request) {
            guard !Task.isCancelled, loadedRequest != request else { return }
            let worker = Task.detached(priority: .utility) { request.decode() }
            let image = await withTaskCancellationHandler {
                await worker.value
            } onCancel: {
                worker.cancel()
            }
            guard !Task.isCancelled else { return }
            thumbnail = image
            loadedRequest = request
        }
    }
}

/// 同一列表行仅复用与记录、图片及显示尺寸匹配的缩略图。
nonisolated struct CardThumbnailRequest: Equatable, Sendable {
    let cardID: UUID
    let processed: Data?
    let original: Data?
    let maxPixelSize: Int

    func decode() -> CGImage? {
        guard !Task.isCancelled else { return nil }
        if let image = thumbnail(from: processed) { return image }
        guard !Task.isCancelled else { return nil }
        return thumbnail(from: original)
    }

    private func thumbnail(from data: Data?) -> CGImage? {
        guard let data, !data.isEmpty,
              let source = CGImageSourceCreateWithData(data as CFData, [kCGImageSourceShouldCache: false] as CFDictionary) else {
            return nil
        }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
            kCGImageSourceShouldCacheImmediately: true
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }
}
