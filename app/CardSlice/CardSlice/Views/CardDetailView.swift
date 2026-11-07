import SwiftUI
import UIKit

/// 名片详情页 [R07]
@MainActor
struct CardDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var contactActionError: String?
    @State private var imageSelection: CardDetailImage?
    @State private var deletionInProgress = false
    @State private var showingDeleteConfirmation = false
    @State private var deleteError: String?
    @State private var deletion: CardDeletionCoordinator?
    private let onDeleted: (UUID) -> Void
    @State private var card: BusinessCardRecord
    @State private var exportTask: Task<Void, Never>?
    @State private var exportFile: URL?
    @State private var showingExport = false
    @State private var exportError: String?
    @State private var activityError: String?
    @State private var editingRecord: BusinessCardRecord?
    @State private var isLoadingEditor = false
    @State private var editError: String?
    private let editor: CardSavedRecordEditor?
    @State private var showingTagSelection = false
    private let tagModel: CardHolderViewModel?
    private let onUpdated: (BusinessCardRecord) -> Void

    init(card: BusinessCardRecord, editor: CardSavedRecordEditor? = nil,
         onUpdated: @escaping (BusinessCardRecord) -> Void = { _ in },
         deletion: CardDeletionCoordinator? = nil, onDeleted: @escaping (UUID) -> Void = { _ in },
         tagModel: CardHolderViewModel? = nil) {
        _card = State(initialValue: card)
        self.editor = editor
        self.onUpdated = onUpdated
        _deletion = State(initialValue: deletion)
        self.onDeleted = onDeleted
        self.tagModel = tagModel
    }
    
    var body: some View {
        List {
            Section("基本信息") {
                VStack(alignment: .leading, spacing: 4) {
                    Text(card.name)
                        .font(.title2.weight(.semibold))
                        .accessibilityAddTraits(.isHeader)
                    if let company = card.company, !company.isEmpty {
                        DetailRow(label: "公司", value: company)
                    }
                    if let job = card.jobTitle, !job.isEmpty {
                        DetailRow(label: "职位", value: job)
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 4)
            }

            // 联系方式 [COURSE]
            if !card.phones.isEmpty || !card.emails.isEmpty {
                Section(header: Text("联系方式")) {
                    // 多电话支持 [T10]
                    ForEach(Array(card.phones.enumerated()), id: \.offset) { _, phone in
                        contactRow(phone.type.displayLabel, value: phone.value, action: .phone)
                    }
                    
                    // 多邮箱支持 [T10]
                    ForEach(Array(card.emails.enumerated()), id: \.offset) { _, email in
                        contactRow("邮箱", value: email, action: .email)
                    }
                }
            }
            
            // 其他信息 [COURSE]
            if card.website != nil || card.address != nil {
                Section(header: Text("网站与地址")) {
                    if let website = card.website, !website.isEmpty {
                        contactRow("网站", value: website, action: .website)
                    }
                    if let address = card.address, !address.isEmpty {
                        DetailRow(label: "地址", value: address)
                    }
                }
            }
            
            // 备注 [COURSE]
            Section("备注") {
                if let notes = card.notes, !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(notes)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                } else if let editor {
                    Button("添加备注") { openEditor(editor) }
                        .disabled(isLoadingEditor || deletionInProgress)
                } else {
                    Text("暂无备注").foregroundStyle(.secondary)
                }
            }

            if let tagModel {
                Section("标签") {
                    let assigned = tagModel.tags.filter { card.tagIDs.contains($0.id) }
                    if assigned.isEmpty {
                        Text("暂无关联标签").foregroundStyle(.secondary)
                    }
                    ForEach(assigned) { tag in Text(tag.name) }
                    Button("选择标签") {
                        tagModel.loadTags()
                        showingTagSelection = true
                    }
                    .disabled(isLoadingEditor || deletionInProgress)
                }
            }

            Section("名片图片") {
                ForEach(CardDetailImage.allCases) { kind in
                    Button {
                        imageSelection = kind
                    } label: {
                        Label(kind.title, systemImage: "photo")
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .disabled(deletionInProgress || exportTask != nil)
                }
            }

            if let editor {
                Section("联系人导出") {
                    Button { exportContact(using: editor) } label: {
                        Label("导出联系人", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .disabled(exportTask != nil || exportFile != nil || deletionInProgress || isLoadingEditor)
                    if exportTask != nil { ProgressView("正在生成 VCF…") }
                }
            }

            if let deletion {
                Section {
                    Button(role: .destructive) {
                        deletion.requestConfirmation()
                        showingDeleteConfirmation = true
                    } label: {
                        Label("删除名片", systemImage: "trash")
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .disabled(isLoadingEditor || deletionInProgress)
                    if deletionInProgress { ProgressView("正在删除名片…") }
                }
            }
        }
        .navigationBarBackButtonHidden(deletionInProgress)
        .navigationTitle("名片详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let editor {
                ToolbarItem(placement: .primaryAction) {
                    if isLoadingEditor {
                        ProgressView()
                    } else {
                        Button("编辑") { openEditor(editor) }
                            .disabled(deletionInProgress)
                    }
                }
            }
        }
        .fullScreenCover(item: $imageSelection) { kind in
            CardDetailImagePreview(title: kind.title, preview: kind.preview(in: card))
        }
        .alert("无法打开", isPresented: Binding(get: { contactActionError != nil },
                                              set: { if !$0 { contactActionError = nil } })) {
            Button("确定") { contactActionError = nil }
        } message: {
            Text(contactActionError ?? "")
        }
        .alert("删除名片？", isPresented: $showingDeleteConfirmation) {
            Button("取消", role: .cancel) { deletion?.cancel() }
            Button("删除", role: .destructive) { deleteConfirmedCard() }
        } message: {
            Text("将删除当前名片「\(card.name)」及其保存的图片和识别信息。")
        }
        .alert("删除失败", isPresented: Binding(get: { deleteError != nil },
                                              set: { if !$0 { deleteError = nil } })) {
            Button("确定") { deleteError = nil }
        } message: {
            Text(deleteError ?? "")
        }
        .task(id: card.id) {
            guard let editor else { return }
            let snapshot = card
            // 与编辑页使用同一读取路径，进入详情时补齐可能过时的列表快照。
            guard let latest = try? await editor.load(id: snapshot.id),
                  !Task.isCancelled, card == snapshot, !isLoadingEditor,
                  editingRecord == nil, !deletionInProgress else { return }
            card = latest
        }
        .sheet(isPresented: $showingExport, onDismiss: finishExport) {
            if let exportFile {
                CardVCardShareSheet(url: exportFile) { error in
                    activityError = error
                    showingExport = false
                }
                .interactiveDismissDisabled()
            }
        }
        .alert("导出联系人失败", isPresented: Binding(get: { exportError != nil },
                                                      set: { if !$0 { exportError = nil } })) {
            Button("确定") { exportError = nil }
        } message: {
            Text(exportError ?? "")
        }
        .onDisappear { exportTask?.cancel() }
        .sheet(isPresented: $showingTagSelection) {
            if let tagModel {
                CardTagSelectionView(cardID: card.id, selectedIDs: card.tagIDs, viewModel: tagModel) { ids in
                    card.tagIDs = ids
                }
            }
        }
        .sheet(item: $editingRecord) { record in
            if let editor {
                CardFieldCorrectionView(draft: CardFieldCorrectionDraft(savedRecord: record),
                                        savedNotes: record.notes ?? "") { fields, notes in
                    let updated = try await editor.save(id: record.id, fields: fields, notes: notes)
                    card = updated
                    onUpdated(updated)
                }
            }
        }
        .alert("无法读取名片", isPresented: Binding(get: { editError != nil },
                                                  set: { if !$0 { editError = nil } })) {
            Button("确定") { editError = nil }
        } message: {
            Text(editError ?? "")
        }
    }
    @ViewBuilder
    private func contactRow(_ label: String, value: String, action: CardDetailContactAction) -> some View {
        if !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Button {
                guard let url = action.url(for: value) else {
                    contactActionError = action.invalidMessage
                    return
                }
                openURL(url) { accepted in
                    if !accepted {
                        Task { @MainActor in contactActionError = action.unavailableMessage }
                    }
                }
            } label: {
                HStack {
                    DetailRow(label: label, value: value)
                    Spacer(minLength: 8)
                    Image(systemName: action.symbol)
                        .accessibilityHidden(true)
                }
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .disabled(deletionInProgress)
        }
    }

    private func exportContact(using editor: CardSavedRecordEditor) {
        guard exportTask == nil, exportFile == nil, !deletionInProgress, !isLoadingEditor else { return }
        let id = card.id
        exportTask = Task {
            defer { exportTask = nil }
            do {
                let latest = try await editor.load(id: id)
                guard !Task.isCancelled, !deletionInProgress, editingRecord == nil,
                      !isLoadingEditor, !showingTagSelection else { return }
                exportFile = try CardVCardExportService.makeTemporaryFile(for: latest)
                showingExport = true
            } catch {
                if !Task.isCancelled { exportError = error.localizedDescription }
            }
        }
    }

    private func finishExport() {
        if let exportFile { CardVCardExportService.removeTemporaryFile(at: exportFile) }
        exportFile = nil
        exportError = activityError
        activityError = nil
    }

    private func deleteConfirmedCard() {
        guard let deletion, !deletionInProgress else { return }
        deletionInProgress = true
        Task {
            defer { deletionInProgress = false }
            do {
                guard try await deletion.confirm() else { return }
                dismiss()
                onDeleted(deletion.id)
            } catch {
                deleteError = error.localizedDescription
            }
        }
    }

    private func openEditor(_ editor: CardSavedRecordEditor) {
        guard !isLoadingEditor, editingRecord == nil else { return }
        isLoadingEditor = true
        let id = card.id
        Task {
            defer { isLoadingEditor = false }
            do { editingRecord = try await editor.load(id: id) }
            catch { editError = error.localizedDescription }
        }
    }
}

/// 分享完成或取消后，由详情页在关闭分享界面时清理文件。
private struct CardVCardShareSheet: UIViewControllerRepresentable {
    let url: URL
    let onComplete: @MainActor (String?) -> Void

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        controller.completionWithItemsHandler = { _, _, _, error in
            let message = error?.localizedDescription
            Task { @MainActor in onComplete(message) }
        }
        return controller
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

/// 详情行辅助组件
struct DetailRow: View {
    let label: String
    let value: String
    
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 12))
        layout {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// 仅生成明确的系统目标，详情页仍展示原始保存值。
enum CardDetailContactAction {
    case phone, email, website

    var symbol: String {
        switch self {
        case .phone: "phone"
        case .email: "envelope"
        case .website: "arrow.up.right"
        }
    }

    var invalidMessage: String {
        switch self {
        case .phone: "此号码无法用于拨号，请检查号码格式。"
        case .email: "此邮箱地址格式无效，请检查后再试。"
        case .website: "此网址无效，仅支持 HTTP 或 HTTPS 网页。"
        }
    }

    var unavailableMessage: String {
        switch self {
        case .phone: "当前设备无法发起拨号。"
        case .email: "当前设备无法打开邮件撰写。"
        case .website: "当前设备无法打开此网页。"
        }
    }

    func url(for rawValue: String) -> URL? {
        let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.unicodeScalars.contains(where: CharacterSet.controlCharacters.contains) else { return nil }
        switch self {
        case .phone:
            let digits = "0123456789"
            let separators = " -–—()."
            guard value.allSatisfy({ digits.contains($0) || separators.contains($0) || $0 == "+" }) else {
                return nil
            }
            let number = value.filter { !separators.contains($0) }
            let dialDigits = number.dropFirst(number.hasPrefix("+") ? 1 : 0)
            guard (3...15).contains(dialDigits.count), dialDigits.allSatisfy({ digits.contains($0) }) else { return nil }
            return URL(string: "tel:" + number)

        case .email:
            let parts = value.split(separator: "@", omittingEmptySubsequences: false)
            guard parts.count == 2, Self.isDomain(String(parts[1]), requiresDot: true),
                  parts[0].range(of: #"^[A-Za-z0-9_+!#$%&'*=/^`{|}~-]+(?:\.[A-Za-z0-9_+!#$%&'*=/^`{|}~-]+)*$"#,
                                 options: .regularExpression) != nil else { return nil }
            let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "@._+-"))
            guard let address = value.addingPercentEncoding(withAllowedCharacters: allowed) else { return nil }
            return URL(string: "mailto:" + address)

        case .website:
            guard !value.isEmpty, !value.contains(where: { $0.isWhitespace || $0.isNewline }),
                  !value.contains("\\"), !value.hasPrefix("//") else { return nil }
            let explicitScheme = value.contains("://") && value.range(
                of: #"^[A-Za-z][A-Za-z0-9+.-]*://"#, options: .regularExpression) != nil
            guard let parts = URLComponents(string: explicitScheme ? value : "https://" + value),
                  let scheme = parts.scheme?.lowercased(), scheme == "http" || scheme == "https",
                  parts.user == nil, parts.password == nil,
                  let host = parts.host, Self.isDomain(host, requiresDot: !explicitScheme),
                  parts.port.map({ (1...65535).contains($0) }) ?? true else { return nil }
            return parts.url
        }
    }

    private static func isDomain(_ value: String, requiresDot: Bool) -> Bool {
        let labels = value.split(separator: ".", omittingEmptySubsequences: false)
        return (!requiresDot || labels.count > 1) && labels.allSatisfy {
            $0.range(of: #"^[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?$"#,
                     options: .regularExpression) != nil
        }
    }
}

enum CardDetailImage: String, CaseIterable, Identifiable {
    case original, processed

    enum Preview {
        case missing, unreadable, image(UIImage)
    }

    var id: Self { self }
    var title: String { self == .original ? "原始图片" : "处理后图片" }

    func preview(in card: BusinessCardRecord) -> Preview {
        let data = self == .original ? card.originalImageData : card.processedImageData
        guard let data, !data.isEmpty else { return .missing }
        guard let image = UIImage(data: data) else { return .unreadable }
        return .image(image)
    }
}

private struct CardDetailImagePreview: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let preview: CardDetailImage.Preview

    var body: some View {
        NavigationStack {
            Group {
                switch preview {
                case .missing:
                    ContentUnavailableView("暂无" + title, systemImage: "photo")
                case .unreadable:
                    ContentUnavailableView("无法读取" + title, systemImage: "photo")
                case .image(let image):
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                        .accessibilityLabel(title)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        CardDetailView(card: MockBusinessCards.samples[0])
    }
}
