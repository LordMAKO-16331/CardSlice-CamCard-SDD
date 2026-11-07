# P013 — Week 3：名片图片预处理管线

## 一、项目背景

当前项目为 SDD 驱动的 CamCard iOS 功能切片。

已完成：

- P001～P012 及相关修复任务。
- Week 2 阶段总结和文档同步。
- 30项自动化测试全部通过（用户 Xcode 验收）。
- SwiftData 名片保存和 App 重启恢复的开发验证。
- PhotosPicker 单张图片选择与预览。

当前仍未实现：

- 名片边界检测与透视矫正。
- 中英文 OCR。
- 字段解析与人工校正。
- 从图片生成正式名片记录。

课程参考测试 T01～T20 仍为 NOT_RUN。

本轮只建立可独立测试的图像预处理能力。

## 二、自动保存 Prompt

将本条完整任务指令保存为：

`prompts/P013_week3_image_preprocessing.md`

保留原文，不覆盖历史 Prompt。

## 三、执行前阅读

请先阅读必要文件：

1. `docs/spec.md`，重点 R02、R03、R04。
2. `docs/07_architecture.md`。
3. `docs/08_week2_summary.md`。
4. `app/CardSlice/CardSlice/Views/CardImageImportView.swift`。
5. `app/CardSlice/CardSlice/Views/CardHolderView.swift`。
6. `app/CardSlice/CardSlice/Models/BusinessCardRecord.swift`。
7. 现有测试目录与测试框架。

以实际工程文件为准，不要依据旧文档中的历史快照推断当前代码状态。

## 四、允许修改范围

允许新建：

- `app/CardSlice/CardSlice/Services/CardImagePreparationService.swift`
- `app/CardSlice/CardSliceTests/CardImagePreparationTests.swift`

允许修改：

- `app/CardSlice/CardSlice/Views/CardImageImportView.swift`

仅当现有页面之间的数据传递确实需要调整时，才允许修改：

- `app/CardSlice/CardSlice/Views/CardHolderView.swift`

不得修改其他文件。

特别禁止修改业务模型、Repository、SwiftData 实体、Mapper、App 入口、已有测试与 Xcode 工程配置。

如必须扩大修改范围，应停止并报告。

## 五、P013-1：图像预处理服务

创建独立的 CardImagePreparationService。

输入为用户从相册选择的原始图片 Data。

输出应包含：

1. 原始图片 Data。
2. 预处理后图片 Data。
3. 处理后图像的像素宽度。
4. 处理后图像的像素高度。

可以设计独立的 PreparedCardImage 值类型承载结果。

要求：

- 保留原始 Data，不得覆盖或修改。
- 能处理常见的 JPEG、PNG、HEIC 等系统可解码图片。
- 按图片方向元数据正确处理旋转方向。
- 生成能够被系统正常解码的处理后图片。
- 保留原始图像宽高比例。
- 不拉伸、不裁剪名片内容。
- 对过大的图片合理缩小尺寸。
- 建议临时将处理后图像最长边限制为3000像素。
- 不得将小图片强制放大。
- 可采用约0.9的 JPEG 压缩质量。
- 尺寸与压缩参数标记为 [DECISION/TEMP]，方便后续 OCR 精度测试调整。

优先考虑使用系统 ImageIO、CoreGraphics 等 API，避免不必要的全尺寸图像解码与内存开销。

处理服务不得依赖 SwiftUI View 或 PhotosPicker UI。

## 六、P013-2：错误处理

至少区分：

- 输入数据为空。
- 图片格式不受支持或无法解码。
- 图片尺寸无效。
- 图像处理或编码失败。

不能将失败结果伪装成成功，也不能返回虚假的空图片。

错误应能够由 UI 显示为用户可理解的提示。

## 七、P013-3：接入现有图片预览

在 P012 现有相册选择流程中调用预处理服务。

要求：

1. 用户选择图片后，先读取原始 Data。
2. 将图片交给 CardImagePreparationService。
3. 成功后展示处理后的图片。
4. 保留原始图片和处理结果，供后续 P014 使用。
5. 在预览界面简要显示处理后图片的像素尺寸。
6. 处理期间显示加载状态，避免重复触发。
7. 处理失败时显示明确错误。
8. 用户取消或关闭预览时正确清理当前临时状态。
9. 如果存在异步加载任务，避免已关闭页面的旧任务结果错误覆盖新选择。
10. 不改变 CardHolder 已有名片列表、详情、空状态及 DEV 数据保存功能。

当前 P012 预览文案如果仍然写有“请选择一张名片图保存”，请修正为“请选择一张名片图片进行预览”，因为本轮不会保存图片。

不得在页面中声称已经完成 OCR、自动裁剪或透视校正。

## 八、P013-4：单元测试

使用当前项目已有的 Swift Testing 框架，新增独立测试。

至少覆盖：

1. 空 Data 输入时返回明确错误。
2. 非图片数据输入时拒绝处理。
3. 正常图片能够生成可解码的处理后 Data。
4. 原始图片 Data 与输入保持一致。
5. 大图缩小后最长边不超过设定阈值，且比例基本保持一致。
6. 小图不会被强制放大。

如能稳定构造带方向信息的测试图片，再增加方向校正测试。

测试图片可以通过代码生成，不依赖真实用户相册。

不要为通过测试而删除或弱化已有断言。

本轮不增加真实相册 UI 自动化测试；相册交互由用户在模拟器中人工验证。

## 九、严格禁止事项

- 不实现名片边界检测。
- 不实现透视矫正。
- 不实现 OCR。
- 不创建正式名片记录。
- 不把预处理图片写入 SwiftData。
- 不实现相机拍照。
- 不修改数据库结构。
- 不添加第三方依赖。
- 不执行 Git 操作。

如果某项要求与实际项目代码存在冲突，先报告，不得擅自扩大任务。

## 十、执行效率与测试规则

Codex 本轮只负责必要的文件读取与代码修改。

禁止执行：

- xcodebuild
- xcrun
- 模拟器命令
- 构建、运行及自动化测试
- 安装与清理命令

用户将在 Xcode 中自行构建和测试。

不要生成冗长分析，不要重复读取无关文件。

## 十一、自动保存 Response

完成后创建：

`records/P013_response.md`

简要记录：

1. 实际新增、修改的文件。
2. 图像预处理的实现方式。
3. 原始图片与处理后图片如何保存于当前预览状态。
4. 错误处理方式。
5. 新增单元测试的数量与名称。
6. 尚未解决的问题。
7. Xcode 构建和测试状态：NOT_RUN，等待用户验证。
8. 课程参考测试 T01～T20：NOT_RUN。

不能编造测试通过记录。

## 十二、完成后停止

只完成 P013，不开始 P014。

完成代码修改与归档后，简短报告并停止。