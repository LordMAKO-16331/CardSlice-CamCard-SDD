# P008-F01 — Repository 代码审核后的定点修复

## 一、任务背景

本项目使用 SDD + TRAE 开发 CamCard 功能切片。

P001～P007 已完成。P008 已建立 CardRepository、InMemoryCardRepository 和8项单元测试，但人工审核发现以下问题：

1. fetchAll 对空仓库抛出 emptyDatabase，与 P008 要求“返回空列表”冲突。
2. CardRepositoryError 未遵循 Equatable，可能导致 Swift Testing 的具体错误值断言无法编译。
3. initialRecords 存在重复 UUID 时，可能造成插入顺序数组出现重复标识。

本轮只修复上述问题并补充必要测试，不重构其他模块。

## 二、执行前阅读

- docs/spec.md
- docs/07_architecture.md
- app/CardSlice/CardSlice/Data/CardRepository.swift
- app/CardSlice/CardSlice/Data/InMemoryCardRepository.swift
- app/CardSlice/CardSliceTests/CardRepositoryTests.swift

先核对实际路径和现有代码。

## 三、允许修改的文件

仅允许修改：

1. CardRepository.swift
2. InMemoryCardRepository.swift
3. CardRepositoryTests.swift

禁止修改 BusinessCardRecord、MockBusinessCards、任何 SwiftUI 页面、App 入口、其他测试文件及 SDD 文档。

## 四、修复要求

### F01-1：空仓库行为

- fetchAll 在仓库为空时返回空数组。
- 保留 async throws 接口，以兼容后续 SwiftData 持久化实现。
- 删除不再需要的 emptyDatabase 错误定义和错误断言。
- testEmptyRepository 改为验证返回空数组且不抛异常。

### F01-2：错误类型

- 为 CardRepositoryError 增加 Equatable。
- 保留 notFound、duplicateID、saveFailed 的现有错误语义。
- 保证具体错误值的 Swift Testing 断言可以编译并正确比较关联的 UUID。
- 不使用忽略错误内容的断言冒充精确错误验证。

### F01-3：初始化重复 ID

- initialRecords 不允许静默覆盖同 ID 的记录。
- 建议将初始化方法改为 throwing initializer，遇到重复 UUID 抛出 duplicateID。
- 同步修改本轮测试文件内所有初始化调用。
- 确保 storage 和 insertionOrder 始终一致。
- 添加至少一项重复初始 ID 的单元测试。

### F01-4：加强原有测试

- testUpdateCard 应同时验证另一条未修改记录保持不变。
- testDeleteCard 应验证删除最后一条记录后 fetchAll 返回空数组。
- 保留已有有效测试，不删除原有断言。

## 五、约束

- 不引入 SwiftData。
- 不改动已有 UI 和 Mock 数据。
- 不添加第三方依赖。
- 不增加超出 Repository 范围的功能。
- 不执行未经授权的 Git 操作。
- 注释使用中文。
- 必须直接修改现有文件，不创建重复的类型或文件。

## 六、验证及报告

完成后报告：

1. 实际修改的文件。
2. 三项问题分别如何解决。
3. 原有测试如何调整，新增了哪些测试。
4. 是否实际构建或运行测试。
5. 是否修改允许范围以外的文件。

用户将在 Xcode 中执行 Command+B 和 Command+U。

未运行的测试不能标记为 PASS。原有9项自动化测试应保持通过；本轮 Repository 新增测试以 Xcode 实际结果为准。

课程 T01～T20 全部继续保持 NOT_RUN。

完成后停止，不得自动执行 P009。