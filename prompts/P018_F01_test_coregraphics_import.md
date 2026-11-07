# P018-F01 — 修复测试 Target 的 CoreGraphics 导入错误

用户在 Xcode 执行 Command+B 构建 App 成功，但执行 Command+U 时失败。

当前唯一编译错误位于：\
`app/CardSlice/CardSliceTests/CardRecordAssemblyTests.swift`

错误：\
`Static property 'zero' is not available due to missing import of defining module 'CoreGraphics'`

请检查该文件实际代码，仅修复缺失模块导入的问题。若确认是 CoreGraphics 类型的 `.zero` 引起，添加必要的 `import CoreGraphics`。

不要修改测试断言、测试逻辑或业务实现；不要修改其他 Swift 文件。

请自动保存：

- `prompts/P018_F01_test_coregraphics_import.md`：本条完整指令。
- `records/P018_F01_response.md`：简短记录实际修改内容，标记构建与测试 NOT_RUN。

禁止运行 xcodebuild、xcrun、模拟器及任何测试命令。

完成后立即停止，不开始其他任务。