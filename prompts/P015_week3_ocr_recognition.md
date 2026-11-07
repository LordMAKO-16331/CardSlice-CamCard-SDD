# P015 — Week 3：中英文 OCR 文字识别

## 一、当前项目状态

CamCard SDD iOS 课程项目已完成 P001～P014。

最新人工验收：

- P014 可以检测两张测试名片的四角边界。
- 黄色矩形轮廓显示正确。
- 透视矫正后图片正常。
- 风景图没有明显矩形时正常提示检测失败。
- 所有现有 Xcode 自动化测试均通过。
- P014 前已有37项自动化测试，本轮以 Xcode 实际数量为准。
- 课程参考测试 T01～T20 仍全部 NOT_RUN。

本轮只实现中英文 OCR，保留原始文字识别结果，供后续字段解析使用。

## 二、自动保存 Prompt

将本条完整指令保存到：

`prompts/P015_week3_ocr_recognition.md`

不得覆盖历史文件。

## 三、执行前阅读

只阅读必要文件：

1. `docs/spec.md`，重点 R04。
2. `docs/07_architecture.md`。
3. `CardImagePreparationService.swift`。
4. `CardRectangleDetectionService.swift`。
5. `CardPerspectiveCorrectionService.swift`。
6. `CardImageImportView.swift`。
7. `BusinessCardRecord.swift`。
8. 现有 Swift Testing 测试结构。

以实际文件路径和类型定义为准。

## 四、允许修改范围

允许新建：

- `app/CardSlice/CardSlice/Services/CardTextRecognitionService.swift`
- `app/CardSlice/CardSliceTests/CardTextRecognitionTests.swift`

允许修改：

- `app/CardSlice/CardSlice/Views/CardImageImportView.swift`

禁止修改其他文件。

尤其不得修改 Repository、SwiftData 实体、Mapper、业务模型、App 入口和现有测试。

确实需要扩大范围时，停止并报告。

## 五、P015-1：OCR 服务

使用 Apple Vision 的 VNRecognizeTextRequest。

要求：

1. 输入为可解码图片 Data。
2. 支持简体中文与英文识别。
3. 默认采用准确度优先模式（accurate）。
4. 优先识别 zh-Hans、en-US，实际使用前检查当前 Vision Request 支持的语言。
5. 对不支持的语言提供合理处理和明确说明，不允许直接崩溃或静默宣称支持。
6. 识别过程不依赖网络服务。
7. 识别结果按可解释的阅读顺序排列。
8. 原始文字保留换行，不得随意删除姓名、数字、符号或标点。
9. 不得以 AI 推测内容补充 OCR 没有识别出的字段。
10. 保留独立的 OCR 服务，不能把 Vision 识别代码直接全部塞进 SwiftUI View。

设计独立结果结构，至少包含：

- rawText：按顺序组合的原始识别文本。
- lines：所有识别到的文本行。
- 每行 text。
- 每行 confidence。
- 每行 Vision 归一化 boundingBox。

置信度只作为识别参考，不等于文字正确率。

## 六、P015-2：输入图片的选择

在现有 P012～P014 图像处理流程后接入 OCR。

规则：

- 如果用户已完成透视矫正，优先识别矫正后的图片。
- 否则识别 P013 预处理后的图片。
- 不得为 OCR 强制要求必须检测成功矩形。
- 不得覆盖原始图片数据。
- 在结果中或 UI 中明确当前使用的是矫正图片还是预处理图片。

不允许将不存在的矫正结果伪装成有效输入。

## 七、P015-3：错误处理

至少区分：

1. 输入 Data 为空。
2. 图片无法解码。
3. Vision 识别请求执行失败。
4. 无任何可识别文字。
5. 所请求语言在当前运行环境中不可用。

识别不到文字不等于程序崩溃。

错误必须能在 UI 中明确展示，不得只打印到控制台。

## 八、P015-4：UI 接入

在现有图片预览页增加临时开发操作：

`识别图片文字`

要求：

1. 保留相册选择、图片预处理、边界检测和透视矫正。
2. 用户主动点击后开始 OCR。
3. 显示识别中的加载状态。
4. 识别成功后展示原始文字结果，允许滚动查看。
5. 可以展示识别到的文字行数。
6. 可以区分识别成功、无文字及错误状态。
7. 更换图片时清理旧 OCR 结果。
8. 重新应用或恢复透视矫正后，应清除已过期的 OCR 结果，避免误认为结果来自当前图片。
9. 用户关闭预览时清理临时识别状态。
10. 防止过期异步任务覆盖新图片的结果。
11. 避免连续点击导致重复识别。
12. 不破坏现有 DEV 名片持久化按钮、CardHolder 列表、详情页及空状态。

OCR 结果区域应明确标记为 `[DECISION/TEMP]`，尚非最终 CamCard 界面。

## 九、P015-5：单元测试

使用 Swift Testing，新建独立测试文件。

至少覆盖：

1. 空 Data 输入被拒绝。
2. 非图片 Data 被拒绝。
3. 可解码且含有清晰英文文本的测试图片能够执行 OCR。
4. OCR 结果中包含有效文字行及合理置信度范围。
5. rawText 与 lines 的组合关系正确。
6. 没有文字的图片可以安全处理。
7. 中英文语言配置的可用性检查和失败处理。

如能够稳定构造中文测试图片，增加中文识别测试。

测试尽量使用程序生成的合成图片，不依赖个人相册或真实联系人信息。

由于 OCR 结果受系统版本、字体和图片质量影响，不要通过要求每个字符完全一致的脆弱断言制造测试不稳定。

不能为了使测试通过而伪造 OCR 输出或删除有效断言。

## 十、严格禁止

- 不实现姓名、电话、邮箱、公司等字段解析。
- 不实现人工校正表单。
- 不创建或保存正式名片记录。
- 不修改 SwiftData。
- 不实现相机采集。
- 不修改数据库 Schema。
- 不添加第三方依赖。
- 不修改既有37项测试。
- 不擅自扩大任务范围。

## 十一、执行效率

Codex 只负责读取必要文件、修改代码和归档。

禁止执行：

- xcodebuild
- xcrun
- 模拟器操作
- 自动化测试
- 构建、安装、清理操作
- Git 操作

所有 Xcode 构建、测试和模拟器验收由用户亲自完成。

不要生成冗长分析报告。

## 十二、自动生成 Response

创建：

`records/P015_response.md`

简要记录：

1. 新建及修改的文件。
2. Vision OCR 的具体实现方式。
3. 中英文语言配置策略。
4. 输入图片的选择逻辑。
5. OCR 结果结构及错误处理。
6. 新增测试名称与数量。
7. 尚未解决的风险。
8. Xcode 构建和测试：NOT_RUN。
9. 课程 T01～T20：NOT_RUN。

完成后停止，不开始 P016。