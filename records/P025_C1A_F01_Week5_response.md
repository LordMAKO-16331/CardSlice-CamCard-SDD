# P025-C1A-F01 执行报告

- 静态排查发现最可疑的位置是图片处理区的 `CardCropEditorView` 调用。它在深层 ViewBuilder 中用三元表达式选择主线程实例方法或 nil，同时依赖成员初始化器推断可选回调。外层 `ScrollView` 诊断不足以单独证实根因。
- `CardImageImportView.swift` 将图片处理区提取为 `imageToolsSection`，由 `cropPreview(for:)` 显式构造主线程可选回调。`CardCropEditorView.swift` 添加明确的初始化器并标注回调的 `@MainActor` 类型。保留原 ScrollView。
- 保留四角拖动、自动候选、无候选手动裁剪、恢复、几何验证及既有 OCR 和保存路径。测试文件未修改。
- Xcode 构建与测试 **NOT_RUN**。待用户验证原诊断是否消失，当前未确认编译器的实际根因。
