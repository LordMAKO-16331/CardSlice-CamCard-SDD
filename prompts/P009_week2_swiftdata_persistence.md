# P009 — Week 2：SwiftData 本地持久化 Repository

## 一、任务背景

当前项目为基于 SDD + TRAE 的 CamCard 名片数字化与联系人管理功能切片复刻。

已完成 P001～P008 及 P008-F01 修复。

当前实际验证结果：
- BusinessCard 模型测试：6/6 PASS。
- Repository 内存仓库测试：9/9 PASS。
- UI 自动化测试：3/3 PASS。
- 合计：18/18 PASS，0 FAIL。
- 测试环境：iPhone 17 / iOS 27.0 Simulator。
- Reference Test Suite T01～T20：全部 NOT_RUN。

本轮目标：在不修改既有逻辑模型和 UI 的前提下，实现真正的 SwiftData 本地持久化 Repository，并编写独立测试。

## 二、执行前必须阅读

1. `docs/spec.md`，重点 R07、R09。
2. `docs/03_reference_tests.md`，重点 T12、T14、T17、T18。
3. `docs/07_architecture.md` v0.2。
4. `app/CardSlice/CardSlice/Models/BusinessCardRecord.swift`
5. `app/CardSlice/CardSlice/Data/CardRepository.swift`
6. `app/CardSlice/CardSlice/Data/InMemoryCardRepository.swift`
7. `app/CardSlice/CardSliceTests/CardRepositoryTests.swift`

先核对当前实际工程结构、SDK 及 SwiftData 可用性。

不得假设你保留了旧 AI 对话的上下文。

## 三、允许修改范围

原则上仅允许新建以下文件：

1. `app/CardSlice/CardSlice/Data/PersistedBusinessCard.swift`
2. `app/CardSlice/CardSlice/Data/SwiftDataCardRepository.swift`
3. `app/CardSlice/CardSliceTests/SwiftDataCardRepositoryTests.swift`

如果需要单独的数据映射文件，可额外新建：

4. `app/CardSlice/CardSlice/Data/BusinessCardPersistenceMapper.swift`

除此之外，不得修改现有文件。

特别禁止修改：

- `BusinessCardRecord.swift`
- `CardRepository.swift`
- `InMemoryCardRepository.swift`
- `MockBusinessCards.swift`
- `ContentView.swift`
- `CardHolderView.swift`
- `CardDetailView.swift`
- `CardSliceApp.swift`
- `.xcodeproj`
- 所有已有测试
- 任何 SDD 文档及 Prompt 记录

若现有接口不能支持实现，停止并报告具体原因，不得擅自改动协议。

## 四、SwiftData 持久化模型

### 1. 独立持久化实体

创建 SwiftData 持久化实体 `PersistedBusinessCard`。

不得直接给现有 `BusinessCardRecord` 添加 `@Model`。

逻辑模型与数据库模型分开，以降低后续数据库结构变化对业务层的影响。

### 2. 数据字段

必须保存并恢复：

- UUID
- 原始图像 Data
- 处理后图像 Data
- OCR Raw Text
- ParsedContactFields
- 姓名
- 公司
- 职位
- 多个 PhoneEntry（包括 Mobile、Office、Fax）
- 多个 Email
- Website
- Address
- tagIDs
- Notes
- createdAt
- updatedAt

对于 SwiftData 不适合直接存储的复杂集合，可使用明确的 Codable 编码与解码方案。

不得静默丢弃不支持的字段。

编码失败和解码失败必须产生明确错误，不能把损坏的数据自动替换成空字段并报告成功。

### 3. 图像持久化

本轮可以采用 SwiftData 支持的数据存储方案。

如果使用外部二进制存储，应明确其适用性。

测试中可使用较小的虚拟图片字节数组。

本轮无需处理真实相机图片，也不需要实现大文件性能优化。

## 五、SwiftDataCardRepository

实现符合现有 `CardRepository` 协议的 `SwiftDataCardRepository`。

必须支持：

- fetchAll()
- fetch(id:)
- insert()
- update()
- delete(id:)

要求：

1. 使用明确传入的 ModelContext，不使用隐式全局单例。
2. 遵守现有 MainActor 隔离策略。
3. 新增记录必须写入持久化上下文并保存。
4. 更新记录必须真正修改已存储的数据。
5. 删除记录后不能重新读取。
6. 重复 UUID 插入时抛出 duplicateID，不得意外覆盖旧记录。
7. 查询不存在 ID 时抛出 notFound。
8. 空数据库 fetchAll 返回空数组。
9. fetchAll 返回稳定、可解释的排序（建议 createdAt + UUID 作为排序依据）。
10. 持久化失败应抛出适当错误，不能只打印日志。
11. 对模型转换过程保持可测试、可审计。

本轮不实现搜索、标签管理或完整业务 UI。

## 六、单元测试

在新的 SwiftDataCardRepositoryTests.swift 中编写测试。

至少覆盖：

1. 空数据库返回空列表。
2. 插入记录后能够按 UUID 读取。
3. 多记录读取及稳定排序。
4. 修改已有记录后正确读取。
5. 删除后无法再读取记录。
6. 重复 UUID 插入产生正确错误。
7. 多电话、多邮箱、Fax、缺失 Website 正确保存和恢复。
8. OCR 原文、初始解析结果、最终确认字段互不覆盖。
9. 标签 UUID、备注和时间戳正确恢复。
10. 图片 Data 能够正确保存与读取。

同时增加一项真实持久化验证：

- 使用测试专属的临时磁盘存储位置。
- 在第一个 ModelContainer 中写入数据。
- 保存后关闭对旧容器和上下文的使用，创建新的容器与上下文，并指向同一存储位置。
- 确认此前保存的记录能够重新读取。
- 测试数据与正式 App 数据完全隔离。

注意：
- 普通内存数据库测试不等于真正的持久化测试。
- 重新创建持久化容器不完全等于用户执行 Kill App / Relaunch。
- 本轮不得据此宣称 T18 正式通过。

测试必须使用独立的存储环境，不得污染开发 App 的本地数据。

## 七、严格禁止事项

- 不修改既有 UI。
- 不把 CardHolder 接入数据库。
- 不实现扫描、OCR 或联系人导出。
- 不增加第三方依赖。
- 不引入云存储或网络服务。
- 不创建第二个 Xcode 工程。
- 不执行未经授权的 Git 操作。
- 不改动此前已通过的测试。

Swift 注释尽量使用中文。

如遇到 SDK API 差异或严格并发问题，先检查当前实际编译环境，不得使用不安全的绕过方法。

## 八、交付报告

任务完成后用中文报告：

1. 新建的全部文件及完整路径。
2. SwiftData 实体的字段和映射方案。
3. Repository 的增删改查实现方式。
4. 数据保存及重新读取的处理方式。
5. 新增测试名称与数量。
6. 是否实际运行构建和测试。
7. 是否修改了允许范围之外的文件。
8. 尚未解决的风险。
9. 下一步最小开发建议。

如果无法运行 Xcode，由用户自行执行 Command+B 和 Command+U。

不得将未经实际执行的测试标记为 PASS。

课程 T01～T20 全部保持 NOT_RUN。

完成后停止，不得自动开始下一项任务。