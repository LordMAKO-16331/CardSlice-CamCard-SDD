# P028-B3 — Week 6：接入 36 张正式 OCR 测试名片

## 一、背景

P028-B2 已完成：

- A～D 四张先导样本保留。
- 新增 36 张合成名片。
- 生成 36 条对应 Ground Truth。
- 数据集完成一致性检查。
- 正式 OCR 尚未运行。

现有独立测试目标：

`CardSliceOCRCaptureTests`

现有共享 Scheme：

`OCR Pilot Capture`

此前已成功执行 A～D 四张名片的批量 OCR，并生成 JSON 附件。

本轮只扩展该测试目标，使其能够自动处理新增的 36 张名片。

## 二、自动归档

保存完整 Prompt：

`prompts/P028_B3_Week6_formal_ocr_capture.md`

生成 Response：

`records/P028_B3_Week6_response.md`

## 三、首先检查

只读检查：

1. P028-B2 新增的正式数据集。
2. formal/ground_truth.json 的实际结构。
3. CardSliceOCRCaptureTests 的实现。
4. 独立测试目标的资源配置。
5. evaluation/evaluate.py 的输入参数和 Schema。
6. 现有 Pilot JSON 的数据结构。

确认正式图片能够使用现有 OCR 和 Parser 处理，不需要重新实现算法。

## 四、实现要求

在独立 OCR 测试目标中，增加正式采集入口：

`testCaptureFormalOCR()`

要求：

1. 自动读取新增的 36 张正式测试图片。
2. 根据数据集 Manifest 建立稳定的样本 ID 与图片对应关系。
3. 使用已有的图像预处理、Vision OCR 和字段解析服务。
4. 保留原始 OCR 文字和自动解析字段。
5. 不使用人工正确答案生成识别结果。
6. 不自动修改或覆盖 Ground Truth。
7. 一次运行完成全部 36 张图片的处理。
8. 每张图片的失败信息单独记录。
9. 生成 recognition_results-formal-\<batch_id>.json。
10. 将 JSON 保留为 XCTest 附件。
11. 在控制台输出实际文件路径和采集成功、失败数量。
12. 缺少图片或发生采集错误时明确报告，不能将失败伪装为正常识别。

保留现有：

`testCapturePilotOCR()`

A～D 先导测试不得删除、覆盖或改变。

## 五、评估数据处理

正式样本 36 张与先导样本 4 张，合计 40 张。

必须确保：

- 样本 ID 唯一。
- 图片与对应 Ground Truth 匹配。
- 正式结果能够使用既有 evaluation/evaluate.py 评价。
- 不覆盖原来的先导结果。
- 不把清晰原版扰动图片重复计算为新样本。

先确认 evaluate.py 是否支持指定独立 Ground Truth 文件。

如果不支持，本轮不得擅自修改计分规则或覆盖原 ground_truth.json。

应报告需要如何安全接入，等待下一轮处理。

## 六、严格修改范围

允许修改：

- CardSliceOCRCaptureTests 对应的独立测试源码。
- 新测试所需的独立 Target 资源成员配置。
- 必要的正式评估使用说明。
- 本轮 Prompt 和 Response。

如需修改 project.pbxproj，只允许为独立 OCR 测试目标增加资源引用，不得改变其他 Target 配置。

禁止修改：

- CardSlice App 生产源码。
- App 的最低 iOS 部署版本。
- OCR、Parser、图像预处理算法源码。
- CardSliceApp.swift。
- AppDatabase、Repository、SwiftData。
- 原有业务测试及其断言。
- CardSlice 原 Scheme。
- OCR Pilot Capture 现有成功的先导测试行为。
- evaluation/evaluate.py。
- Ground Truth 的实际内容。
- 用户名片数据。

不新建第二个采集 Target。

不新增正式 App 的运行依赖。

如果无法保证独立测试目标与生产 App 隔离，停止修改并报告。

## 七、执行限制

Codex 不得运行：

- Xcode 构建。
- xcodebuild、xcrun。
- 模拟器。
- XCTest。
- Git 操作。
- 数据库清理或重置。

由用户手动运行正式 OCR 采集。

## 八、执行报告

说明：

1. 实际新增和修改的文件。
2. 是否成功注册全部 36 张测试图片。
3. 新增测试方法名称。
4. 预计如何启动采集。
5. JSON 如何导出。
6. 是否影响已有四张先导采集。
7. 是否影响正式 App 或原有 Scheme。
8. evaluate.py 是否能直接评价正式数据。
9. 构建、测试、采集：NOT_RUN。

完成后停止，不开始其他任务。
