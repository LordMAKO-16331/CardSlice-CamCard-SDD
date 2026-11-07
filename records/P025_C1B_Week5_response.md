# P025-C1B 执行报告

- 修改 `CardImageImportView.swift`，新增 `CardScanWorkflow.swift` 与 `CardScanWorkflowTests.swift`。名片夹继续使用原来的扫描入口、保存成功提示及刷新回调。
- 单一阶段状态控制来源、裁剪、识别、人工确认、保存。相册和系统相机共用预处理，成功后进入裁剪并自动检测。自动候选可切换并直接拖动四角，无候选可手动建立区域，随时可恢复候选或初始边界。
- 底部「确认裁剪」使用既有透视服务。输出有效后自动运行既有 OCR 和解析，并打开共享校正表单。原文仍可查看，未分类和歧义信息继续传给表单。取消表单可重新核对，校验失败由表单保留草稿。
- 返回裁剪会清除旧 OCR、解析、校正和待保存数据，并保留同一图片的可编辑边界。返回来源、重拍或关闭时清空会话。异步结果必须匹配当前请求及阶段；过期任务不会推进 UI。后台图像计算可能继续至完成。
- 保存沿用现有记录组装、仓库和防重状态，保留原图、处理图、OCR 原文、初次解析与最终字段。保存失败可重试，成功后回名片夹并刷新。
- 新增 4 项阶段状态测试。testSuccessfulStagesRequireReviewBeforeSave、testCancelledSourceRejectsOldImageCompletion、testCropAndRecognitionRemainInStageUntilSuccess、testReturningToCropInvalidatesRecognitionAndReview。复用已有裁剪、OCR、校正、持久化和防重/重试测试，未修改旧断言。
- 待人工验收相册取消、候选和无候选裁剪、识别失败重试、识别中返回或关闭、校正表单弹出和取消、保存失败重试及成功刷新。阶段测试未覆盖实际 SwiftUI 交互。相机授权和实拍需真机。
- Xcode 构建和测试 **NOT_RUN**。T01～T20 尚未执行统一正式验收。
