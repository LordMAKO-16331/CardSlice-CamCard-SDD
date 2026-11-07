# P008 — Week 2：Repository 接口与内存测试实现

## 一、项目背景

这是使用 SDD + TRAE 开发的 CamCard 名片数字化与联系人管理功能切片项目。

目前 P001～P007 已执行。

已确认：
- Xcode iOS 工程 CardSlice 正常运行。
- 开发测试环境为 iPhone 17 / iOS 27.0 Simulator。
- P005 建立了 BusinessCardRecord、PhoneEntry、ParsedContactFields、TagRecord 和 MockBusinessCards。
- P006 实现了 CardHolder Mock 列表与空状态。
- P007 实现了只读名片详情和导航。
- Xcode 已实际执行9项测试，全部通过，0失败。
- 课程 T01～T20 仍为 NOT_RUN。

本轮只实现 Repository 数据访问契约与内存测试实现，不接入 SwiftData。

## 二、执行前阅读

请先阅读：

1. `docs/spec.md`，重点 R07、R09。
2. `docs/03_reference_tests.md`，重点 T12、T14、T17、T18。
3. `docs/07_architecture.md` v0.2。
4. `app/CardSlice/CardSlice/Models/BusinessCardRecord.swift`。
5. `app/CardSlice/CardSlice/Mocks/MockBusinessCards.swift`。
6. `app/CardSlice/CardSliceTests/` 中现有的测试文件。

先检查实际文件路径和已有类型。不得创建重复工程。

## 三、本轮允许新建文件

仅允许新增：

1. `app/CardSlice/CardSlice/Data/CardRepository.swift`
2. `app/CardSlice/CardSlice/Data/InMemoryCardRepository.swift`
3. `app/CardSlice/CardSliceTests/CardRepositoryTests.swift`

可以新建 Data 文件夹。

禁止修改现有的 BusinessCardRecord、MockBusinessCards、ContentView、CardHolderView、CardDetailView、App 入口及已有测试。

禁止修改 `.xcodeproj`、docs、prompts、records 等其他文件。

如果新文件没有自动加入对应 Xcode Target，先报告，不得擅自扩大修改范围。

## 四、Repository 接口设计

定义 CardRepository 协议，负责已保存名片的基础数据访问。

本轮至少支持：

- insert：新增一张名片。
- fetch：按 UUID 查找名片。
- fetchAll：获取全部名片。
- update：更新已有名片。
- delete：按 UUID 删除名片。

建议接口通过参数和返回值明确表达操作结果，并支持错误传播。

统一处理以下情况：

- ID 不存在。
- 插入重复 ID。
- 空数据库查询。
- 更新不存在的名片。
- 删除不存在的名片。

请定义可测试的错误类型，避免静默失败。

考虑后续 SwiftData ModelContext 与 SwiftUI 的线程隔离要求，优先使用清晰、一致的 MainActor 隔离策略；不要为了消除并发错误而使用不安全的共享可变全局状态。

本轮不实现搜索、标签、备注的完整 Repository 操作，后续依照独立任务扩展接口。

## 五、InMemoryCardRepository

创建一个符合 CardRepository 协议的内存实现。

要求：

1. 使用 BusinessCardRecord 现有模型。
2. 默认初始化为空数据集合。
3. 可选择通过构造参数注入初始测试记录。
4. 根据 UUID 识别记录，禁止重复 ID。
5. 支持完整增删改查。
6. fetchAll 返回稳定且可预测的记录顺序。
7. 更新或删除不能影响其他无关名片。
8. 不修改现有 MockBusinessCards.samples。
9. 不使用单例或不受管理的全局可变数组。

必须明确：InMemoryCardRepository 不是持久化实现，关闭 App 后不会保留新增数据，不能用于宣称 R09/T18 已通过。

## 六、单元测试

使用当前工程已采用的 Swift Testing。

在新建的 CardRepositoryTests.swift 中编写至少6项测试：

1. 空 Repository 返回空列表。
2. 插入名片后可以按 ID 查询。
3. 插入多张名片后能够正确读取。
4. 修改已有名片后可以读取更新值，且不影响其他记录。
5. 删除名片后无法再次查询到该记录。
6. 重复 ID、更新不存在 ID、删除不存在 ID 能得到明确错误。

测试应使用独立的 Repository 实例，防止测试之间共享状态。

测试数据使用虚拟姓名与联系方式。

不要删除、跳过或修改任何 P005～P007 已有测试。

## 七、严格禁止事项

- 不实现 SwiftData、Core Data 或真实数据库。
- 不修改现有 UI 或 ViewModel。
- 不实现 OCR、相机、联系人导出。
- 不实现完整名片搜索或标签管理。
- 不添加网络服务和第三方依赖。
- 不自动调用 Git 操作。
- 不扩大本轮文件修改范围。

代码注释优先使用中文。

## 八、验证与交付

完成后报告：

1. 实际新增文件的完整路径。
2. CardRepository 的接口设计。
3. InMemoryCardRepository 的数据管理方式。
4. 新增测试名称与覆盖情况。
5. 是否实际构建或运行测试，给出真实结果。
6. 是否修改范围外文件。
7. P009 接入 SwiftData 前还需要确认的问题。

如果无法直接运行 Xcode 测试，由用户在 Xcode 中完成：

- Command + B：构建。
- Command + U：运行所有测试。

现有9项测试必须保持通过；新增测试的结果以实际 Xcode 输出为准。

不得将课程 T01～T20 标记为 PASS。

任务完成后停止，不得自动开始 P009。