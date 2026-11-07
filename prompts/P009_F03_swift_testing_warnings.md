# P009-F03 — Swift Testing 并发警告定点修复

当前 CamCard 工程已在 Xcode 中确认30项自动化测试全部通过，但仍有25项编译警告。

本轮只处理 CardSliceTests.swift 中与 Swift 并发、MainActor 隔离有关的警告，不处理无关警告，不开始 P010。

## 1. 自动归档 Prompt

请先将我发送的这条完整任务指令保存为：

`prompts/P009_F03_swift_testing_warnings.md`

如果文件不存在则创建，已有则不要重复覆盖其他内容。

## 2. 修改要求

仅允许修改：

`app/CardSlice/CardSliceTests/CardSliceTests.swift`

请检查该文件中测试方法与业务模型之间的 Actor 隔离关系。

重点分析：

- `Expression is 'async' but is not marked with 'await'`
- `Main actor-isolated initializer ...`

优先采用正确的 `@MainActor` 隔离方式解决警告。

要求：

- 保留原有6项模型测试及所有断言。
- 不修改业务模型、Repository 或 UI。
- 不修改测试目标。
- 不通过屏蔽警告来解决问题。
- 不扩大修改范围。
- 如有不能在本文件内安全解决的问题，报告即可。

## 3. 执行效率要求

只阅读完成本任务必要的文件。

禁止运行：

- xcodebuild
- xcrun
- 模拟器
- 自动化测试
- 其他构建、安装、清理命令

所有编译和测试由我在 Xcode 中手动完成。

## 4. 自动生成执行报告

完成代码修改后，自动创建：

`records/P009_F03_response.md`

报告简要包括：

- 实际修改的文件。
- 警告的原因与修复方法。
- 是否存在未解决的问题。
- 是否修改任务范围外文件。
- Xcode 构建与测试状态：NOT_RUN，等待用户验证。

不要把之前的30项通过结果冒充成本轮修改后的测试结果。

## 5. 完成后停止

只修改代码与本轮 Prompt、Response 文件。

不要开始 P010，不要执行任何测试，不要生成冗长报告。