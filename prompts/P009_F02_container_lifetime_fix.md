# P009-F02 — 修复 SwiftData 测试中的 ModelContainer 生命周期

## 问题

Xcode 执行 P009 测试时，在 SwiftDataCardRepository.swift 的 fetchPersisted(id:) 方法中，运行 modelContext.fetch(descriptor) 触发 EXC_BREAKPOINT。

人工排查发现 SwiftDataCardRepositoryTests.swift 的 createInMemoryRepository() 存在生命周期风险：

- 在辅助函数内部创建局部 ModelContainer。
- 仅返回持有 ModelContext 的 Repository。
- 辅助函数返回后，ModelContainer 可能被提前释放。
- 随后执行 fetch 或 save 时可能发生运行时异常。

磁盘测试中的 `let (_, repository)` 也需要检查相同的生命周期风险。

## 允许修改

仅允许修改：

`app/CardSlice/CardSliceTests/SwiftDataCardRepositoryTests.swift`

禁止修改 Repository、Mapper、持久化实体、业务模型、UI、Xcode 工程及其他文件。

## 修复要求

1. 建立一个仅供测试使用的辅助结构，例如 TestDatabase，同时持有：
   - `let container: ModelContainer`
   - `let repository: SwiftDataCardRepository`

2. 修改内存数据库创建方法，返回 TestDatabase，而不是仅返回 Repository。

3. 修改所有调用该辅助方法的测试，确保 TestDatabase 在整个数据库操作期间保持存活。

4. 同样检查和修复磁盘数据库测试，确保写入和读取各阶段都持有各自的 ModelContainer。

5. 磁盘测试仍需保持两个独立作用域：
   - 第一个作用域创建容器并写入数据。
   - 退出作用域后使用相同存储路径建立第二个容器并读取数据。

6. 保留现有12项 SwiftData 测试的业务验证逻辑，不得删除测试或跳过失败测试。

7. 不使用强制解包、全局单例、静态共享容器或忽略错误等方式掩盖问题。

8. SwiftData Repository 原有的显式 ModelContext 注入接口保持不变。

## 验证

完成后，用户将在 Xcode 中运行 Command+B 和 Command+U。

预期总数为30项测试，但必须以实际 Xcode 结果为准。

如果仍然发生异常，请保留准确的异常位置、异常信息和失败测试名称，不要擅自扩大修复范围。

## 交付

报告：
- 修改后的测试辅助结构。
- 所有受影响的测试。
- 如何保证 ModelContainer 不会提前释放。
- 是否实际构建或运行测试。
- 是否存在范围外修改。

完成后停止，不开始 P010。

课程 T01～T20 保持 NOT_RUN。