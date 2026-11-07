# P027-B1-F02 — Week 6：使用独立模拟器完成 OCR 先导采集

## 一、当前问题

P027-B1 已实现：

`CardOCRBatchCaptureTests.testCaptureOCRBatch()`

但由于 Xcode Test Plan 的启动环境变量没有传入，测试持续 SKIPPED。

P027-B1-F01 静态审查确认：

- 测试方法本身不访问名片 Repository。
- 不创建 BusinessCardRecord。
- 不修改 SwiftData 记录。
- 但是 XCTest 使用 CardSlice.app 作为测试宿主。
- 宿主初始化时可能打开默认 SwiftData 数据库。

因此不能直接在原有模拟器中无条件删除启动检查。

## 二、已具备的安全测试环境

用户已创建独立模拟器：

`NewPhone`

系统：iOS 27.0。

它与原有的 iPhone 17 模拟器拥有独立的数据容器。

本轮允许在 NewPhone 中运行一次先导 OCR 采集。

允许测试宿主在 NewPhone 的独立容器内初始化数据库，但不允许测试代码执行名片写入、删除或数据库重置。

不修改原有 iPhone 17 模拟器的任何数据。

测试图片 A～D 已作为测试资源，无需导入系统相册。

## 三、自动归档

保存完整 Prompt：

`prompts/P027_B1_F02_Week6_isolated_pilot_capture.md`

完成后生成：

`records/P027_B1_F02_Week6_response.md`

## 四、任务要求

只检查及修改：

`CardSliceTests/CardOCRBatchCaptureTests.swift`

目标：

让 testCaptureOCRBatch() 在明确识别为 NewPhone 的 Debug 模拟器上执行一次 pilot 采集，不依赖此前无法传入的两个手动参数。

实施前：

1. 确认测试宿主仍是 CardSlice.app。
2. 确认采集代码不使用名片 Repository。
3. 确认不执行数据库写入和删除。
4. 确认 A～D 均从测试 Bundle 加载。

若发现新增的数据库修改行为，停止并报告。

## 五、隔离与启用规则

允许在测试文件中添加一次性 pilot 采集开关。

仅当以下条件全部满足时才执行：

1. Debug 测试构建。
2. iOS Simulator 环境。
3. 能可靠确认当前模拟器名称为 NewPhone。
4. 本轮明确启用了一次性 pilot 采集开关。

其中任一条件不满足，继续使用 XCTSkip，并打印实际环境诊断。

可以优先检查 SIMULATOR_DEVICE_NAME 等系统提供的模拟器标识。

不得在无法确定模拟器身份时默认允许采集。

不得依赖用户继续手动配置 OCR_BATCH_CAPTURE 或 --ui-testing-mock-cards。

采集启动后：

- 默认 split = pilot。
- 读取 A～D 四张图片。
- 调用现有预处理、Vision OCR、Parser。
- 生成 recognition_results-pilot-\<batch_id>.json。
- 作为 XCTAttachment 附加到测试报告。
- 打印实际输出路径。

保留所有采集错误检测与测试断言。

## 六、限制

不修改：

- CardSliceApp.swift
- AppDatabase
- Repository
- SwiftData Schema
- OCR 或 Parser 算法
- Ground Truth
- evaluate.py
- Xcode Scheme / Test Plan

不得增加另一个名片数据库，也不得清理现有数据库。

Codex 禁止运行 xcodebuild、xcrun、模拟器、测试、Python 或 Git。

用户手动执行。

## 七、一次性采集后的处理

这是临时测试入口，不是最终默认配置。

用户取得 A～D 的 JSON 后，应将一次性开关恢复为默认关闭，保留采集工具本身。

在报告中说明：

- 修改文件。
- 模拟器隔离方法。
- 采集启用条件。
- 新增的安全诊断。
- JSON 附件获取方式。
- 如何恢复默认关闭。
- 构建和测试：NOT_RUN。

完成后停止。
