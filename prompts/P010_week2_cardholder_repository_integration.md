# P010 — Week 2：CardHolder 接入持久化 Repository

## 一、项目背景

本项目为 SDD 驱动的 CamCard iOS 功能切片。

目前：

- P001～P009 已完成。
- P009-F02 已在 Xcode 中确认30/30测试通过。
- P009-F03 已修复模型测试中的 Swift 并发警告，用户确认警告消失。
- SwiftDataCardRepository 已实现并具有独立测试。
- CardHolderView 目前仍直接读取 MockBusinessCards.samples。
- 课程参考测试 T01～T20 全部 NOT_RUN。

本轮目标：让 CardHolderView 从 Repository 读取名片，同时保持原有导航及 UI 自动化测试稳定。

## 二、自动保存 Prompt

首先将本条完整任务指令保存到：

`prompts/P010_week2_cardholder_repository_integration.md`

不得覆盖已有 Prompt。

## 三、执行前阅读

只阅读必要文件：

1. docs/spec.md，重点 R01、R07、R09。
2. docs/07_architecture.md。
3. CardSliceApp.swift。
4. ContentView\.swift。
5. Views/CardHolderView\.swift。
6. Views/CardDetailView\.swift。
7. Data/CardRepository.swift。
8. Data/SwiftDataCardRepository.swift。
9. Data/InMemoryCardRepository.swift。
10. Models/BusinessCardRecord.swift。
11. Mocks/MockBusinessCards.swift。
12. CardSliceUITests.swift。

以实际代码为准，不根据旧文档中过时的进度描述重新创建工程。

## 四、允许修改范围

仅允许修改：

- `app/CardSlice/CardSlice/CardSliceApp.swift`
- `app/CardSlice/CardSlice/ContentView.swift`
- `app/CardSlice/CardSlice/Views/CardHolderView.swift`
- `app/CardSlice/CardSliceUITests/CardSliceUITests.swift`

如确实需要，可新增：

- `app/CardSlice/CardSlice/Views/CardHolderViewModel.swift`

除此之外，不得修改业务模型、Repository、持久化实体、Mapper、原有单元测试和 Xcode 工程配置。

## 五、功能要求

### P010-1：正式数据库接入

App 正常启动时，初始化并持有 SwiftData ModelContainer。

使用现有 SwiftDataCardRepository 读取名片。

必须保证 ModelContainer 在 App 使用期间持续存活，避免重现 P009 的生命周期问题。

不得使用 try! 或静默切换到 Mock 数据来掩盖数据库初始化错误。

初始化失败应有明确的错误展示。

### P010-2：CardHolder 数据加载

CardHolderView 不再直接依赖 MockBusinessCards.samples。

通过注入 CardRepository 获取列表。

正确区分：

- 加载中。
- 加载成功且有名片。
- 加载成功但列表为空。
- 加载失败。

空数据应显示现有临时空状态 UI，并保留 [DECISION/TEMP] 标记，不得声称其已与真实 CamCard 空状态一致。

加载失败不能伪装成空数据。

保留现有导航及 CardDetailView 的只读展示功能。

不得自动将三张 Mock 名片写入正式数据库。

### P010-3：保持 UI 自动化测试稳定

此前 testNavigationToDetail 依赖 John Doe 这张 Mock 名片。

现在正式 App 默认可能是空数据库，因此必须为 UI 测试提供隔离的确定性数据源。

建议使用仅 DEBUG 环境有效的专用启动参数，例如：

`--ui-testing-mock-cards`

检测到参数后，为该次测试注入独立的 InMemoryCardRepository，使用 MockBusinessCards.samples。

正常启动时仍使用 SwiftData，不使用测试数据。

修改 testNavigationToDetail，使其通过该启动参数获得测试名片。

禁止 UI 测试污染正式 SwiftData 数据库。

保留原有 UI 测试和业务断言。

### P010-4：删除无效的开发功能

原有 CardHolderView 的“模拟空状态 (Dev Only)”开关是 Mock 阶段使用的临时功能。

正式数据接入后，不应继续通过该开关覆盖真实列表。

可删除该开关，但需要保留真正的空状态展示功能。

## 六、严格禁止事项

- 不实现新增、编辑或删除名片界面。
- 不实现 OCR、扫描、相机或联系人导出。
- 不修改数据库 schema。
- 不添加第三方依赖。
- 不重写既有 Repository。
- 不擅自修改 SDD 需求。
- 不扩大本轮修改范围。
- 不执行 Git 操作。

代码注释尽量使用中文。

## 七、执行效率与测试规则

本轮 Codex 只负责代码修改。

严禁执行：

- xcodebuild
- xcrun
- 模拟器命令
- 自动化测试
- 构建、安装或清理命令

所有 Xcode 构建和测试均由用户亲自完成。

只读取必要文件，直接实施，避免冗长分析和无关操作。

## 八、自动保存 Response

完成后创建：

`records/P010_response.md`

简要记录：

1. 实际修改的文件。
2. 数据依赖注入及 ModelContainer 生命周期设计。
3. 列表加载、空状态和错误状态实现。
4. UI 测试如何获得隔离的 Mock 数据。
5. 未解决问题。
6. 构建及测试：NOT_RUN，等待用户在 Xcode 中验证。
7. T01～T20：NOT_RUN。

不得虚构执行结果。

## 九、完成后停止

只完成 P010。

不要开始 P011，不要自行执行测试。

修改后简要回复即可。