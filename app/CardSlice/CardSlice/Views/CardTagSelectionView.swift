import SwiftUI

@MainActor
struct CardTagSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: CardHolderViewModel
    private let cardID: UUID
    private let onSaved: (Set<UUID>) -> Void
    @State private var selectedIDs: Set<UUID>
    @State private var errorMessage: String?

    init(cardID: UUID, selectedIDs: Set<UUID>, viewModel: CardHolderViewModel,
         onSaved: @escaping (Set<UUID>) -> Void) {
        self.cardID = cardID
        self.viewModel = viewModel
        self.onSaved = onSaved
        _selectedIDs = State(initialValue: selectedIDs)
    }

    var body: some View {
        NavigationStack {
            Form {
                if let errorMessage {
                    Text(errorMessage).foregroundStyle(.red)
                }
                if let loadError = viewModel.tagLoadError {
                    Text(loadError).foregroundStyle(.red)
                    Button("重试") { viewModel.loadTags() }
                } else if viewModel.tags.isEmpty {
                    Text("暂无可选标签。可在名片夹的「管理标签」中创建。")
                        .foregroundStyle(.secondary)
                }
                ForEach(viewModel.tags) { tag in
                    Toggle(tag.name, isOn: Binding(
                        get: { selectedIDs.contains(tag.id) },
                        set: { selected in
                            if selected { selectedIDs.insert(tag.id) }
                            else { selectedIDs.remove(tag.id) }
                        }
                    ))
                }
            }
            .navigationTitle("选择标签")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(viewModel.tagLoadError != nil)
                }
            }
        }
    }

    private func save() {
        do {
            let ids = selectedIDs.intersection(viewModel.tags.map(\.id))
            try viewModel.saveTags(ids, forCardID: cardID)
            onSaved(ids)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
