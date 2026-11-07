# P010-F01 — 修复 AppDatabase 初始化编译错误

当前 P010 在 Xcode 执行 Command+B 时构建失败。

错误位置：\
`app/CardSlice/CardSlice/CardSliceApp.swift` 第52行。

错误信息：\
`Immutable value 'self.container' may only be initialized once`

## 任务要求

1. 仅修改 `CardSliceApp.swift` 中 `AppDatabase.init()` 的初始化逻辑。
2. 检查 `container`、`repository`、`errorMessage` 的存储属性声明。
3. 优先使用局部临时变量，在 do/catch 完成后统一初始化各个 let 属性，确保每条初始化路径只赋值一次。
4. 保留现有 DEBUG UI 测试依赖注入逻辑。
5. 保留 ModelContainer 的生命周期管理。
6. 保留数据库初始化失败时的错误处理，不使用 try! 或静默回退到 Mock 数据。
7. 不修改其他 Swift 源文件，不重构架构。

## 自动保存文档

将本条任务保存到：

`prompts/P010_F01_appdatabase_initialization.md`

完成后创建：

`records/P010_F01_response.md`

简要记录修改内容和未验证事项。

## 执行限制

- 禁止执行 xcodebuild、xcrun 或任何测试命令。
- 禁止启动模拟器。
- 不执行 Git 操作。
- 不开始 P011。
- 不修改本轮范围外的项目文件。
- 只完成必要修改并简短报告。

构建与测试由我在 Xcode 中手动完成。