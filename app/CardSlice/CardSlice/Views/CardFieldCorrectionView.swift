import SwiftUI

@MainActor
struct CardFieldCorrectionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: CardFieldCorrectionDraft
    private let initial: CardFieldCorrectionDraft
    private let editingSavedRecord: Bool
    private let initialNotes: String?
    @State private var notes: String
    private let onConfirm: (CardFieldCorrectionDraft, ParsedContactFields, String?) async throws -> Void
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showingDiscard = false

    init(draft: CardFieldCorrectionDraft,
         onConfirm: @escaping (CardFieldCorrectionDraft, ParsedContactFields) async throws -> Void) {
        self.init(draft: draft, initialNotes: nil) { draft, fields, _ in
            try await onConfirm(draft, fields)
        }
    }

    init(draft: CardFieldCorrectionDraft, savedNotes: String,
         onSave: @escaping (ParsedContactFields, String?) async throws -> Void) {
        self.init(draft: draft, initialNotes: savedNotes) { _, fields, notes in
            try await onSave(fields, notes)
        }
    }

    private init(draft: CardFieldCorrectionDraft, initialNotes: String?,
                 onConfirm: @escaping (CardFieldCorrectionDraft, ParsedContactFields, String?) async throws -> Void) {
        _draft = State(initialValue: draft)
        initial = draft
        self.initialNotes = initialNotes
        _notes = State(initialValue: initialNotes ?? "")
        editingSavedRecord = initialNotes != nil
        self.onConfirm = onConfirm
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    identityField("姓名", text: $draft.name)
                    identityField("公司", text: $draft.company)
                    identityField("职位", text: $draft.jobTitle)
                } header: {
                    Text("基本信息")
                } footer: {
                    Text(editingSavedRecord ? "保存后将更新这张名片。" : "确认校正后可返回结果页核对，再保存名片。")
                }
                Section("电话号码") {
                    ForEach($draft.phones) { $phone in
                        let id = phone.id
                        VStack(alignment: .leading, spacing: 0) {
                            Picker("电话类别", selection: $phone.type) {
                                ForEach(PhoneType.allCases, id: \.self) { Text($0.displayLabel).tag($0) }
                            }
                            HStack(spacing: 8) {
                                TextField("电话号码", text: $phone.value).keyboardType(.phonePad)
                                deleteContactButton("删除电话") {
                                    draft.phones.removeAll { $0.id == id }
                                }
                            }
                        }
                    }
                    .onDelete { draft.phones.remove(atOffsets: $0) }
                    Button("新增电话") { draft.phones.append(CardCorrectionPhone()) }
                }
                Section("电子邮箱") {
                    ForEach($draft.emails) { $email in
                        let id = email.id
                        HStack(spacing: 8) {
                            TextField("邮箱地址", text: $email.value)
                                .keyboardType(.emailAddress).textInputAutocapitalization(.never).autocorrectionDisabled()
                            deleteContactButton("删除邮箱") {
                                draft.emails.removeAll { $0.id == id }
                            }
                        }
                    }
                    .onDelete { draft.emails.remove(atOffsets: $0) }
                    Button("新增邮箱") { draft.emails.append(CardCorrectionEmail()) }
                }
                Section("网站与地址") {
                    TextField("网站", text: $draft.website).keyboardType(.URL)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                    TextField("地址", text: $draft.address, axis: .vertical).lineLimit(2...6)
                }
                if editingSavedRecord {
                    Section("备注") {
                        TextEditor(text: $notes)
                            .frame(minHeight: 100)
                            .accessibilityLabel("名片备注")
                    }
                }
                Section("原始识别与解析参考") {
                    DisclosureGroup("OCR 原文") { Text(draft.original.rawText).textSelection(.enabled) }
                    DisclosureGroup("未分类原文与歧义") {
                        ForEach(Array(draft.original.fields.rawTextSegments.enumerated()), id: \.offset) { _, line in Text(line) }
                        ForEach(Array(draft.original.reviews.enumerated()), id: \.offset) { _, review in
                            Text("\(review.field)：\(review.candidates.joined(separator: " / "))\n\(review.reason)")
                        }
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .disabled(isSubmitting)
            .navigationTitle(editingSavedRecord ? "编辑名片" : "人工校正")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        if draft != initial || notes != (initialNotes ?? "") { showingDiscard = true } else { dismiss() }
                    }
                    .disabled(isSubmitting)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSubmitting ? "正在提交…" : (editingSavedRecord ? "保存" : "确认校正")) {
                        submit()
                    }
                    .disabled(isSubmitting)
                }
            }
            .confirmationDialog("丢弃本次未确认修改？", isPresented: $showingDiscard, titleVisibility: .visible) {
                Button("丢弃修改", role: .destructive) { dismiss() }
                Button("继续编辑", role: .cancel) {}
            }
        }
        .interactiveDismissDisabled()
        .alert("无法提交修改", isPresented: Binding(get: { errorMessage != nil },
                                                    set: { if !$0 { errorMessage = nil } })) {
            Button("确定") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func identityField(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            TextField(label, text: text, prompt: Text("请输入" + label), axis: .vertical)
                .lineLimit(1...3)
                .accessibilityLabel(label)
        }
    }

    private func deleteContactButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(role: .destructive, action: action) {
            Label(title, systemImage: "trash")
                .labelStyle(.iconOnly)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(Text(title))
    }

    private func submit() {
        guard !isSubmitting else { return }
        isSubmitting = true
        let submittedDraft = draft
        let submittedNotes = editingSavedRecord && notes != initialNotes ? notes : nil
        Task {
            defer { isSubmitting = false }
            do {
                let fields = try submittedDraft.confirmedFields()
                try await onConfirm(submittedDraft, fields, submittedNotes)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

// 仅用于界面展示，保留电话类型的原始存储值。
extension PhoneType {
    var displayLabel: String {
        switch self {
        case .mobile: "手机"
        case .office: "办公电话"
        case .fax: "传真"
        case .other: "其他电话"
        }
    }
}
