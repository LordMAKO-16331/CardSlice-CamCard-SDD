import SwiftUI

@MainActor
struct TagManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: CardHolderViewModel
    @State private var isCreating = false
    @State private var name = ""
    @State private var pendingDeletion: TagRecord?
    @State private var confirmingDeletion = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                if isCreating {
                    Section("新建标签") {
                        TextField("标签名称", text: $name)
                        Button("确认创建") { create() }
                            .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        Button("取消创建", role: .cancel) {
                            name = ""
                            isCreating = false
                            errorMessage = nil
                        }
                    }
                }
                if let errorMessage {
                    Text(errorMessage).foregroundStyle(.red)
                }
                if let loadError = viewModel.tagLoadError {
                    Section {
                        Text(loadError).foregroundStyle(.red)
                        Button("重试") { viewModel.loadTags() }
                    }
                }
                Section("已保存标签") {
                    if viewModel.tags.isEmpty && viewModel.tagLoadError == nil {
                        Text("暂无标签").foregroundStyle(.secondary)
                    }
                    ForEach(viewModel.tags) { tag in
                        HStack {
                            Text(tag.name)
                            Spacer()
                            Button(role: .destructive) {
                                pendingDeletion = tag
                                confirmingDeletion = true
                            } label: {
                                Image(systemName: "trash")
                                    .frame(minWidth: 44, minHeight: 44)
                            }
                            .buttonStyle(.borderless)
                            .accessibilityLabel("删除标签 \(tag.name)")
                        }
                    }
                }
            }
            .navigationTitle("管理标签")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("新建标签") { isCreating = true }
                        .disabled(isCreating)
                }
            }
            .alert("删除标签？", isPresented: $confirmingDeletion, presenting: pendingDeletion) { tag in
                Button("取消", role: .cancel) { pendingDeletion = nil }
                Button("删除", role: .destructive) {
                    defer { pendingDeletion = nil }
                    do {
                        try viewModel.deleteTag(id: tag.id)
                        errorMessage = nil
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
            } message: { tag in
                Text("将移除「\(tag.name)」及其名片关联。关联名片会保留。")
            }
        }
        .onAppear { viewModel.loadTags() }
    }

    private func create() {
        do {
            try viewModel.createTag(name: name)
            name = ""
            isCreating = false
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
