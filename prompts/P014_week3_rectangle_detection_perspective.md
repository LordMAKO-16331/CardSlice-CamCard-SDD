# P014 — Week 3：名片边界检测与透视矫正

## 一、项目背景

CamCard SDD iOS 项目已完成 P001～P013。

最新人工验收：

- P013 图片预处理及预览正常。
- 37项 Xcode 自动化测试全部通过。
- Week 2 文档归档已完成。
- 课程参考测试 T01～T20 均为 NOT_RUN。

本轮实现名片矩形边界检测与透视矫正，不提前实现 OCR。

## 二、自动归档

先将本条完整任务保存到：

`prompts/P014_week3_rectangle_detection_perspective.md`

完成后生成：

`records/P014_response.md`

不得覆盖旧文件。

## 三、执行前阅读

仅阅读必要文件：

1. `docs/spec.md`，重点 R03。
2. `docs/07_architecture.md`。
3. `app/CardSlice/CardSlice/Services/CardImagePreparationService.swift`。
4. `app/CardSlice/CardSlice/Views/CardImageImportView.swift`。
5. 新增测试所需的现有测试结构。

路径以实际工程为准。

## 四、允许修改范围

允许新增：

- `app/CardSlice/CardSlice/Services/CardRectangleDetectionService.swift`
- `app/CardSlice/CardSlice/Services/CardPerspectiveCorrectionService.swift`
- `app/CardSlice/CardSliceTests/CardRectangleProcessingTests.swift`

允许修改：

- `app/CardSlice/CardSlice/Views/CardImageImportView.swift`

其他文件禁止修改。

如果现有项目结构导致必须扩大范围，请停止并报告。

## 五、边界检测服务

使用苹果 Vision 框架中的 VNDetectRectanglesRequest。

输入：P013 生成的方向已校正的图片数据。

输出至少包含：

- 是否成功检测到矩形。
- 四个角点：topLeft、topRight、bottomLeft、bottomRight。
- 检测置信度。
- 检测结果对应的图像尺寸。

要求：

1. 使用规范化坐标表达角点。
2. 对角点进行合法性检查。
3. 检测到多个候选矩形时，使用可解释的规则选择候选结果。
4. 检测阈值采用 [DECISION/TEMP] 参数，不能声称已达到课程准确率要求。
5. 无法检测时返回明确的“未检测到矩形”状态，不伪造边界。
6. 不得假定任意照片都包含名片。
7. 不得将检测到的任意矩形直接认定为真实名片。
8. Vision 调用失败时返回明确错误。

## 六、透视矫正服务

使用 Core Image 的 CIPerspectiveCorrection。

要求：

1. 输入处理后的图片以及四个角点。
2. 正确将 Vision 归一化坐标转换为 Core Image 图像坐标。
3. 注意 Vision、Core Image 和 SwiftUI 的坐标原点差异，避免上下翻转或左右颠倒。
4. 校正后的图片应为正常可解码的图片数据。
5. 不能产生无效宽高、空图片或无限范围的渲染结果。
6. 如果边界不合法，应拒绝执行矫正。
7. 不覆盖 P013 保留的原始图片数据。
8. 保留预处理图片，允许用户恢复。
9. 本轮不实现可拖动角点的人工调整。
10. 不执行 OCR 或持久化保存。

## 七、UI 接入

在现有图片预览页面增加临时开发功能：

- `检测名片边界`
- `应用透视矫正`
- `恢复预处理图片`

行为要求：

1. 选择图片并完成 P013 预处理后，可以主动触发矩形检测。
2. 检测成功时，在图片上显示四边形轮廓。
3. 轮廓必须正确对齐预览图片，考虑 aspectFit 留白及坐标转换。
4. 显示明确的检测结果或失败信息。
5. 只有找到合法边界后，才允许应用透视矫正。
6. 矫正完成后展示处理结果。
7. 用户可恢复为 P013 的预处理图片。
8. 更换图片时清理旧的检测、矫正结果。
9. 不允许旧异步任务覆盖新图片的状态。
10. 处理期间提供加载反馈，避免重复操作。
11. 原有图片选择、关闭、列表和 DEV 功能保持不变。
12. 所有临时开发控件标记 [DECISION/TEMP]。

特别注意：不应在检测到矩形后立即不可逆地裁剪图片。用户应能够先查看检测结果，再决定是否应用矫正。

## 八、测试

使用 Swift Testing，新建独立测试文件。

至少测试：

1. 非法或空图片输入的错误处理。
2. 无明显矩形图片能够得到安全结果，不崩溃。
3. 归一化角点到像素坐标的转换正确。
4. 不合法四边形会被拒绝。
5. 使用已知合法角点，可以输出可解码的透视校正图片。
6. 透视校正不会修改原始输入 Data。
7. 输出宽高合理且非零。

尽量使用程序生成的测试图片，不依赖用户相册。

Vision 的识别结果可能受到图片纹理及系统实现影响。不要为强制通过测试而使用不稳定的识别结果假设；几何转换、错误处理和透视校正应有确定性测试。

不得修改原有37项测试。

## 九、严格禁止

- 不实现 OCR 或字段解析。
- 不增加正式名片保存功能。
- 不修改 SwiftData、Repository、业务模型或 App 入口。
- 不实现相机。
- 不添加第三方依赖。
- 不执行 Git 操作。
- 不擅自扩展文件修改范围。

## 十、执行效率

Codex 只负责必要文件读取、代码修改和归档。

禁止运行：

- xcodebuild
- xcrun
- 模拟器
- 自动化测试
- 任何构建、安装或清理命令

由用户自行在 Xcode 中测试。

请优先完成任务，不进行冗长分析或重复验证。

## 十一、Response

创建 `records/P014_response.md`，简要报告：

1. 新增与修改文件。
2. 边界检测实现方式。
3. 坐标转换与透视矫正方法。
4. UI 操作流程。
5. 新增测试名称与数量。
6. 尚未解决的风险。
7. 构建与测试状态：NOT_RUN，等待用户验证。
8. T01～T20：NOT_RUN。

完成后停止，不开始 P015。