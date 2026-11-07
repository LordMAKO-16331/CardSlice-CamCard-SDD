import SwiftUI
import SwiftData
import Combine

@main
@MainActor
struct CardSliceApp: App {
    // 由 SwiftUI 持有，避免视图重建时释放数据库容器。
    @StateObject private var database = AppDatabase()

    var body: some Scene {
        WindowGroup {
            if let repository = database.repository {
                ContentView(repository: repository, tagRepository: database.tagRepository)
            } else {
                VStack(spacing: 16) {
                    Text("数据库初始化失败")
                        .font(.headline)
                    Text(database.errorMessage ?? "无法打开名片数据库。")
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
        }
    }
}

/// App 生命周期内持续强持有容器，仓库继续使用显式 Context 注入。
@MainActor
private final class AppDatabase: ObservableObject {
    private let container: ModelContainer?
    let repository: (any CardRepository)?
    let tagRepository: (any TagRepository)?
    let errorMessage: String?

    init() {
        var initializedContainer: ModelContainer?
        var initializedRepository: (any CardRepository)?
        var initializedTagRepository: (any TagRepository)?
        var initializationError: String?

        #if DEBUG
        let useMockCards = ProcessInfo.processInfo.arguments.contains("--ui-testing-mock-cards")
        #else
        let useMockCards = false
        #endif

        do {
            if useMockCards {
                // 测试分支不创建或访问正式 SwiftData 数据库。
                initializedRepository = try InMemoryCardRepository(initialRecords: MockBusinessCards.samples)
            } else {
                let container = try ModelContainer(for: PersistedBusinessCard.self, PersistedTag.self)
                initializedContainer = container
                initializedRepository = SwiftDataCardRepository(modelContext: container.mainContext)
                initializedTagRepository = SwiftDataTagRepository(modelContext: container.mainContext)
            }
        } catch {
            initializedContainer = nil
            initializedRepository = nil
            initializationError = error.localizedDescription
        }

        // 所有可能抛错的操作结束后，存储属性各初始化一次。
        self.container = initializedContainer
        self.repository = initializedRepository
        self.tagRepository = initializedTagRepository
        self.errorMessage = initializationError
    }
}
