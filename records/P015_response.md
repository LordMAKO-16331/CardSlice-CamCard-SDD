# P015 执行报告

- 新增 Services/CardTextRecognitionService.swift、CardSliceTests/CardTextRecognitionTests.swift；修改 Views/CardImageImportView.swift。另新增本轮完整Prompt及本报告，未改其他文件或既有测试。
- OCR：离线VNRecognizeTextRequest，accurate模式，关闭语言词典纠正，保留每个观测首选候选的原始字符串。按上边缘自上而下归组，组内自左向右排列；同排容差为较小框高的0.5（DECISION/TEMP），复杂分栏/竖排语义顺序未保证。
- 语言：每次请求先查询当前accurate Request支持的语言，严格校验zh-Hans、en-US；任一缺失抛出unavailableLanguages并明确提示，不静默降级。请求查询或执行失败均包装requestFailed。
- 输入：存在矫正结果时用correctedImage.data，否则用preparedImage.processedData，不要求矩形检测成功，不覆盖原图；UI明确显示识别来源。
- 结果：RecognizedCardText保存rawText、lines、实际语言；每行含text、confidence、Vision归一化boundingBox。rawText由排序后原文逐行以换行符组合，不解析或补全联系人字段。置信度不代表正确率。
- 错误区分：emptyInput、undecodableImage、requestFailed、noText、unavailableLanguages。无文字单独显示状态，其他错误显示明确提示。
- UI：主动点击识别、识别中加载反馈、禁用重复处理；结果区标记DECISION/TEMP并可滚动/选择原文。换图、矫正、恢复、关闭时清理过期OCR结果；后台返回检查请求UUID与取消状态，不允许旧结果覆盖。
- 新增8项测试：testEmptyDataIsRejected、testNonImageDataIsRejected、testClearEnglishImageProducesValidLines、testRawTextPreservesLineTextAndPunctuation、testReadingOrderIsTopToBottomThenLeftToRight、testBlankImageReturnsNoText、testLanguageValidationAndMissingLanguageError、testRuntimeChineseEnglishAvailabilityIsExplicit。使用程序生成英/中文及纯白图片，真实OCR测试不逐字要求精确一致；结果结构测试使用明确合成行，不替代真实OCR测试。
- 风险：运行环境语言支持、真实名片识别率、复杂分栏/竖排顺序、小屏结果区布局及中文合成测试需用户在Xcode确认；后台同步Vision可能运行至结束但旧结果不提交。无文字与请求错误代码分支并非已完成实际人工验收。
- Xcode构建和测试：NOT_RUN；用户此前确认的测试通过不代表本轮结果。课程T01～T20：NOT_RUN。
- 未运行构建、测试、模拟器、安装清理或Git；未实现字段解析、人工表单、正式名片保存、SwiftData修改或相机；未开始P016。
