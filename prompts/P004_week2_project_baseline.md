# P004 — Week 2：最小 SwiftUI 启动页

## 一、项目背景

这是使用 SDD + TRAE 开发的 CamCard 限定功能切片复刻项目。

P001～P003 已完成，架构设计见 `docs/07_architecture.md` v0.2。

用户已通过 Xcode 创建原生 iOS App 工程 `CardSlice`，并亲自在 iPhone 模拟器上成功运行默认 App。

本轮只进行第一次小范围代码修改，不实现完整名片管理功能。

## 二、执行前阅读

请先阅读：

1. `docs/spec.md`
2. `docs/03_reference_tests.md`
3. `docs/07_architecture.md`
4. `docs/06_status_issues.md`

不得假设你拥有之前聊天的上下文。

## 三、本轮任务

首先确认以下文件存在：

`app/CardSlice/CardSlice/ContentView.swift`

如果实际文件路径不同，请先报告，不得自行创建重复工程。

确认后，将默认 SwiftUI 页面修改成一个最小的 CardHolder 开发占位页。

页面要求：

- 顶部显示 `CardHolder`。
- 中间显示 `Development Preview`。
- 下方显示 `Week 2 — UI Foundation`。
- 使用简单的 SwiftUI 原生布局。
- 界面明确标记为 `[DECISION/TEMP]` 临时设计。
- 不显示任何未经观察证实的 CamCard 空状态文案。

本轮仅验证 SwiftUI 页面替换流程，不需要实现真正的名片列表。

## 四、严格修改范围

只允许修改：

`app/CardSlice/CardSlice/ContentView.swift`

禁止：

- 创建或修改其他 Swift 文件。
- 修改 `.xcodeproj` 或 App 入口。
- 修改已有 SDD 文档和 Prompt 记录。
- 实现数据库、OCR、相机、字段解析、扫描、导出等功能。
- 添加第三方依赖。
- 擅自运行 Git 或其他终端命令。

请保留现有工程可以运行的结构。

代码应简洁，必要注释使用中文。

## 五、验证方式

完成修改后，请：

1. 检查 SwiftUI 代码的结构与语法。
2. 给出实际修改的文件路径。
3. 解释修改了哪些 UI 元素。
4. 告诉用户如何在 Xcode 中按 `⌘ + R` 运行验证。

本轮由用户亲自通过 Xcode 进行构建和模拟器验证。

不得将尚未运行的构建、单元测试或 Reference Test 标记为成功。

## 六、交付报告

使用中文说明：

1. 修改的文件清单。
2. 启动页包含的内容。
3. 是否修改了其他文件。
4. 是否执行了命令或测试。
5. 下一步建议。

明确保留 T01～T20 全部 `NOT_RUN`。

完成后停止，不得直接开始 P005。