# P027-B1 — Week 6：OCR 评估结果自动采集

## 一、任务背景

CamCard SDD iOS 项目已进入 Week 6。

P027-A 已建立独立 OCR 与字段解析评估工具：

- evaluation/README.md
- evaluation/ground_truth.json
- evaluation/recognition_results.json
- evaluation/evaluate.py
- evaluation/test_evaluate.py

现有 A～D 四张先导图片已登记 Ground Truth。

当前问题：

识别结果文件仍为空。如果继续增加 30～50 张测试图片，用户需要重复执行识别并手工复制大量数据。

本轮目标：建立自动化批量采集通道，直接调用现有 OCR 和 Parser，将结果导出为 P027-A 规定的 JSON 格式。

不修改 App 的正式业务流程。

## 二、自动归档

保存本条完整 Prompt：

`prompts/P027_B1_Week6_ocr_batch_capture.md`

完成后生成：

`records/P027_B1_Week6_response.md`

不得覆盖历史文件。

## 三、执行前检查

仅阅读必要文件：

1. evaluation/README.md
2. evaluation/ground_truth.json
3. evaluation/recognition_results.json
4. CardTextRecognitionService.swift
5. CardContactFieldParser.swift
6. CardImagePreparationService.swift
7. 相关 OCR、Parser 测试
8. test_data/ 下现有 A～D 图片
9. 当前 Xcode 测试目标配置

确认现有服务的实际接口、异步执行方式及数据结构。

优先复用现有测试设施。

不得重新编写第二套 OCR 或字段解析算法。

## 四、任务一：设计自动采集入口

优先在测试目标中实现独立的批量采集工具。

建议使用现有 XCTest 测试环境，复用已有 App 模块。

要求：

1. 从指定测试图片目录读取名片图片。
2. 自动调用项目现有图片预处理服务。
3. 调用项目现有 Apple Vision OCR。
4. 使用 OCR 原始输出调用 CardContactFieldParser。
5. 保留 OCR 原文。
6. 保留未经人工更改的字段解析结果。
7. 将结果映射为 evaluation/README.md 规定的 JSON Schema。
8. 每张图片使用已有 sample_id。
9. 图片加载或识别失败时，单独记录错误。
10. 一张失败不得导致整批结果全部丢失。
11. 不创建 BusinessCardRecord。
12. 不写入 SwiftData。
13. 不修改当前模拟器已保存的名片。

此采集工具属于测试与评估基础设施，不是正式 App 用户功能。

## 五、输入图片

先使用 A～D 四张现有样本。

要求：

- 确认实际文件路径。
- 确认测试目标能够访问图片。
- 不复制或重命名图片来掩盖路径错误。
- 不改变 Ground Truth。
- 不修改原始图片内容。

允许使用测试资源 Bundle 或当前工程已有的可靠资源访问方式。

如果图片尚未加入测试资源，应采用最小且可维护的方式注册，不修改正式 App 资源结构。

后续应能通过增加数据文件扩展至 30～50 张样本。

## 六、图像处理与评估口径

需要明确记录实际输入 OCR 的图片版本。

例如：

- 原始图片。
- 经过项目预处理的图片。
- 已有的处理后图片。

不得将不同输入版本的结果混合却不记录。

如果自动采集不能重现用户手动裁剪后的图片，应明确说明：本次评估针对指定预处理输入，不等于完整人工裁剪流程的准确率。

不允许为了提升准确率，针对某张图片手工修改 OCR 结果。

## 七、输出结果

生成符合 P027-A 规范的：

`recognition_results.json`

每张样本至少包含：

- sample_id
- ocr_raw_text
- parsed_fields
- corrected_fields
- capture_error（如有）
- device
- os
- input_variant
- source_image
- captured_at（实际执行时产生）

未经过人工校正的样本：

`corrected_fields = null`

不得将自动解析结果复制到 corrected_fields 冒充人工确认。

未采集的参考 App 结果保持 null。

必须保持与现有 evaluate.py 的字段键及多值数组格式兼容。

## 八、结果文件交付

必须考虑 XCTest 运行环境的文件访问限制。

要求：

1. 使用测试进程允许写入的目录。
2. 不假设模拟器测试可以直接写入 Mac 项目根目录。
3. 优先通过 Xcode 测试附件或其他可明确定位的方式交付 JSON。
4. 在执行说明中写清楚用户如何取得文件。
5. 不要求用户手工复制每张名片的 OCR 文本。
6. 不覆盖人工整理过的正式评估数据。
7. 多次运行时能够识别采集批次，避免新旧结果混淆。

如果实际环境不支持建议的导出方式，应提供可行的最小替代方案。

不得声称未经验证的导出流程一定成功。

## 九、测试要求

先只针对四张先导图片验证采集流程。

检查：

1. 能找到全部输入图片。
2. OCR 原文与解析结果能正确序列化。
3. 中文可正确写入 JSON。
4. 电话和邮箱输出采用数组。
5. Mobile、Office、Fax 类型正确映射。
6. 缺失字段不会出现「未识别」占位词。
7. 某张图片失败后能够记录错误并继续。
8. 生成的 JSON 能被现有 evaluate.py 读取。
9. 不写入正式 App 数据库。

不要为了通过测试而写入预设 OCR 结果。

## 十、修改范围

允许新增：

- 独立的 OCR 批量采集测试文件。
- 必要的测试目标资源配置。
- evaluation/ 下的最小采集说明和示例。

必要时可最小调整 Xcode 测试目标的资源注册。

现有 OCR、Parser、图片处理服务及所有生产业务代码只读。

禁止修改：

- BusinessCardRecord。
- Repository。
- SwiftData。
- OCR 和字段解析算法。
- 正式 App 的 UI 与导航。
- 相机、裁剪、搜索、标签、备注和 VCF。
- 现有 Ground Truth 真值。
- 既有测试断言。

如果无法在测试目标中调用现有服务，请报告阻碍，不要擅自改造生产代码。

## 十一、执行限制

Codex 只负责必要的代码读取、定点修改及归档。

禁止执行：

- xcodebuild
- xcrun
- 模拟器
- 自动化测试
- Python 评估命令
- Git 操作
- 工程清理或数据库重置

由用户自行执行 Xcode 和评估工具验证。

## 十二、Response

生成：

`records/P027_B1_Week6_response.md`

简要说明：

1. 实际新增和修改文件。
2. 如何批量调用现有 OCR 与 Parser。
3. 测试图片的加载方式。
4. 输出 JSON 的位置及获取方法。
5. 与 P027-A 数据结构如何兼容。
6. 如何避免污染正式数据库。
7. 已知限制。
8. 测试与采集：NOT_RUN。
9. 正式准确率评估尚未开始。

完成后停止，不开始 P027-B2。
