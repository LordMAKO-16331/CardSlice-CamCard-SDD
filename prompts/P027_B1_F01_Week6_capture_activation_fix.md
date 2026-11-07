# P027-B1-F01 — Week 6：修复 OCR 批量采集测试无法启动的问题

## 一、问题

现有测试：

`CardOCRBatchCaptureTests.testCaptureOCRBatch()`

用户已在 Xcode 中配置：

- OCR_BATCH_CAPTURE=1
- OCR_BATCH_SPLIT=pilot
- \--ui-testing-mock-cards

但多次执行后仍然显示：

`Test skipped — 批量采集需要显式启用 OCR_BATCH_CAPTURE=1`

说明当前参数配置没有成功传入测试进程。

用户不再需要继续排查 Xcode Test Plan 参数。

本轮目标：让用户在 Xcode 中直接点击 `testCaptureOCRBatch()` 的运行图标，即可执行 A～D 四张先导名片的批量采集。

## 二、自动归档

保存指令：

`prompts/P027_B1_F01_Week6_capture_activation_fix.md`

完成后生成：

`records/P027_B1_F01_Week6_response.md`

## 三、修改要求

只检查和修改：

`CardSliceTests/CardOCRBatchCaptureTests.swift`

以实际路径为准。

1. 取消对 OCR_BATCH_CAPTURE 环境变量的强制依赖。
2. 取消对 --ui-testing-mock-cards 启动参数的强制依赖。
3. 默认采集分组使用 pilot。
4. 保留 Debug 构建限制。
5. 用户手动运行 testCaptureOCRBatch() 时直接执行采集。
6. 不再因为缺少上述两个参数而跳过测试。
7. 必须实际读取 A～D 四张图片。
8. 保留现有预处理、Vision OCR 和 Parser 的调用。
9. 保留识别失败记录和 JSON 序列化。
10. 保留 XCTAttachment 导出机制。
11. 保留输出路径的控制台打印。
12. 图片或测试资源缺失时明确报告失败，不能静默跳过。
13. 不得将预设答案冒充 OCR 结果。
14. 不修改 Ground Truth。

特别核对：

- 测试不创建 BusinessCardRecord。
- 测试不访问或修改 SwiftData。
- 不会污染 App 中已保存的名片。

如果发现实际存在数据库访问，请停止修改并报告。

## 四、临时措施说明

这是为了完成 Week 6 先导评估而启用的临时采集配置。

由于取消了环境变量开关，Debug 全量测试也可能运行批量采集。

请在 Response 中明确记录这一点。

本轮完成先导数据采集后，再恢复默认跳过机制或建立专用测试计划，避免后续全量回归重复采集。

不得将这一临时行为作为最终项目配置而不记录。

## 五、修改限制

禁止修改：

- 生产 App 代码。
- OCR 和 Parser 算法。
- Repository。
- SwiftData。
- Xcode Scheme 和 Test Plan。
- evaluation/ground_truth.json。
- evaluation/evaluate.py。
- 其他现有测试。

禁止 Codex 执行：

- xcodebuild
- xcrun
- 模拟器
- 自动化测试
- Python 命令
- Git 操作

用户负责实际运行。

## 六、执行报告

说明：

1. 修改文件。
2. 删除了哪些启动限制。
3. 保留了哪些数据隔离措施。
4. 测试运行后 JSON 应出现在哪里。
5. 临时配置的影响。
6. 构建与测试：NOT_RUN。

完成后停止，不开始其他任务。
