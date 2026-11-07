# P027-B1-F04 — Week 6：安全建立独立 OCR 批量采集测试目标

## 一、背景与决定

P027-B1-F03 架构审查已经完成。

用户批准采用方案 B：新增独立 OCR 批量采集 XCTest Target。

原 CardSliceTests 使用 CardSlice.app 作为测试宿主，可能在执行采集方法前初始化正式 SwiftData 数据库。

因此，本轮不再修补原有环境变量和模拟器名称判断。

目标是新增一个与正式 App 启动流程隔离的测试目标，直接复用既有 OCR、Parser 和预处理源码。

用户对现有 App 的稳定性与数据安全有严格要求。

保护生产工程是最高优先级。

## 二、自动归档

保存完整指令：

`prompts/P027_B1_F04_Week6_isolated_ocr_capture_target.md`

完成后生成：

`records/P027_B1_F04_Week6_response.md`

## 三、绝对禁止修改的内容

以下内容只能读取，不得改变：

- CardSliceApp.swift
- AppDatabase 及初始化流程
- BusinessCardRecord.swift 的源代码
- Repository 全部文件
- SwiftData 模型及映射
- CardImagePreparationService.swift 的源代码
- CardTextRecognitionService.swift 的源代码
- CardContactFieldParser.swift 的源代码
- 全部正式 UI 与业务 View
- 现有 CardSliceTests 测试源码与断言
- 现有 CardSliceUITests
- 现有 CardSlice Scheme 与 Test Plan
- evaluation/ground_truth.json
- evaluation/evaluate.py
- 已保存的名片数据库

不得运行迁移、清理、卸载、数据库重置或 Git 操作。

## 四、允许的工程修改

允许：

1. 在 CardSlice.xcodeproj 中新增一个独立 XCTest Target。
2. 为该目标新增测试源码。
3. 为该目标注册必要的现有 OCR、Parser、预处理相关源码及其直接依赖。
4. 为该目标注册 A～D 测试图片及 Ground Truth。
5. 新增独立 OCR 采集 Scheme（如果必要）。
6. 更新 evaluation/README.md 中的使用说明。
7. 生成本轮 Prompt、Response。

修改 project.pbxproj 时必须仅作必要的新增配置。

不得重建整个 Xcode 工程。

不得删除或重命名任何现有 Target。

不得改变原有源文件在 CardSlice App Target 和 CardSliceTests 中的成员关系。

## 五、新目标设计

建议名称：

`CardSliceOCRCaptureTests`

要求：

- 使用 iOS XCTest。
- 不以正式 CardSlice.app 为 TEST_HOST。
- 不设置指向 CardSlice.app 的 BUNDLE_LOADER。
- 不执行 CardSliceApp 初始化。
- 不编译 AppDatabase、Repository 或 SwiftData 持久化模块。
- 直接编译所需的现有 OCR、Parser、预处理源码，不复制算法实现。
- 只增加必要的类型依赖。
- 不通过 @testable import CardSlice 强行重新引入正式 App 宿主依赖。

如果独立测试目标在当前 Xcode / iOS 环境中无法无宿主运行，应停止并报告。

不得未经用户批准自动新增一个替代 App 宿主。

## 六、采集行为

建立独立测试方法：

`testCapturePilotOCR()`

要求：

1. 默认读取 A～D 四张 pilot 图片。
2. 自动执行既有预处理、Vision OCR 和字段解析。
3. 不需要 Scheme Arguments。
4. 不需要环境变量。
5. 不需要指定 NewPhone 模拟器名称。
6. 不访问任何名片数据库。
7. 不构造或保存 BusinessCardRecord。
8. 不使用模拟或预设 OCR 结果。
9. 输出符合 P027-A Schema 的 JSON。
10. 作为 XCTest 附件保留。
11. 在日志中打印文件名和实际路径。
12. 单张图片失败时保留错误记录并继续。
13. 测试资源完全缺失时明确失败，不得静默跳过。
14. Corrected Fields 和 Reference Fields 未采集时保留 null。

输入图片继续使用项目现有资源，不修改图片内容。

## 七、保护原有回归

要求：

1. 原 CardSlice Scheme 不变。
2. 原 157 项及后续新增的常规测试保持原有行为。
3. 不自动把独立采集测试加入普通业务回归流程。
4. 原有 CardOCRBatchCaptureTests.swift 保持不变，暂时保留其安全跳过机制。
5. 用户必须主动选择独立采集 Scheme 才运行新测试。
6. 正式 App 的 Bundle ID、部署版本、签名设置和数据目录均不得改变。

## 八、停止条件

遇到以下任何情况，立即停止修改并报告：

- 必须修改生产 App 源码。
- 必须修改原有数据库初始化。
- 需要改变现有 Target 的编译配置。
- 无法避免 CardSlice.app 作为测试宿主。
- 需要复制或重写 OCR 算法。
- 无法确认新增 Target 不会改变正式 App 构建关系。
- 需要额外创建一个 App 宿主才能运行。

不能为了完成任务而擅自绕过上述限制。

## 九、执行限制

Codex 只负责静态读取、必要文件创建、工程配置修改与归档。

禁止执行：

- xcodebuild
- xcrun
- 模拟器运行
- XCTest
- Python 计分工具
- Git 操作
- 清理、迁移、删除或覆盖数据库

构建、运行、回归由用户在 Xcode 中进行。

## 十、执行报告

创建：

`records/P027_B1_F04_Week6_response.md`

至少说明：

1. 新增和修改的文件。
2. 新增 Target 的名称及类型。
3. 是否完全不依赖 CardSlice.app 测试宿主。
4. 复用了哪些现有源码。
5. 是否包含 AppDatabase、Repository 或 SwiftData。
6. 是否影响原有 Scheme、Target 或测试。
7. A～D 资源如何加载。
8. JSON 附件如何取得。
9. 用户如何在 Xcode 中启动独立采集。
10. 已知风险及停止条件。
11. 构建、测试和采集：NOT_RUN。

完成后立即停止。

不得开始 P027-B2 或修改业务代码。
