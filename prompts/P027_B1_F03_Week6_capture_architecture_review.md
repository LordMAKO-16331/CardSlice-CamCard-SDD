# P027-B1-F03 — Week 6：重新审查 OCR 批量采集工具的执行架构

## 一、背景

P027-B1 批量采集工具已完成，但多次运行均被 XCTSkip 跳过。

历史问题包括：

- 环境变量未成功传入测试进程。
- 测试宿主可能初始化正式 SwiftData 数据库。
- 改用 NewPhone 独立模拟器后，四条件保护仍导致跳过。

最新截图显示：

- 使用 NewPhone 模拟器。
- 临时开关为 true。
- 测试仍被跳过。
- 具体失败条件尚未完全确认。

当前用户认为启动机制过于复杂，需要重新评估设计。

本轮目标：找出真正的阻碍，并提供简单、可重复、不会污染数据库的最终解决方案。

## 二、自动归档

保存 Prompt：

`prompts/P027_B1_F03_Week6_capture_architecture_review.md`

生成：

`records/P027_B1_F03_Week6_response.md`

## 三、首先精确诊断

阅读：

- CardOCRBatchCaptureTests.swift
- CardSliceTests 的测试宿主配置
- CardSliceApp.swift
- AppDatabase 初始化及 Mock 模式判断
- 当前 Test Plan 的相关配置

逐项核对：

1. isDebug 的实际编译条件。
2. isSimulator 的判断。
3. SIMULATOR_DEVICE_NAME 的获取方式。
4. enableNewPhonePilotCapture 的定义和值。
5. 为什么条件组合仍导致 XCTSkip。
6. 测试方法是否需要依赖 CardSlice.app 作为宿主。
7. 能否在不初始化正式业务数据库的条件下调用 OCR 和 Parser。

不要仅根据 Scheme 标注 Debug 就认定测试目标的 DEBUG 条件为真。

## 四、重新评估架构

优先考虑：

方案 A：最小修复现有测试。

如果能够通过可靠的独立数据环境和简单条件保证安全，应优先复用现有采集代码。

方案 B：建立不依赖 App 数据库启动流程的专用采集目标。

要求复用已有 OCR 和 Parser，不复制业务算法。

对每个方案说明：

- 需要修改的文件。
- 数据隔离保证。
- 是否需要修改 Xcode Target。
- 用户运行步骤。
- 是否会影响原有单元测试。
- 实际实现成本。

不得把增加更多临时开关作为主要解决办法。

## 五、设计目标

最终用户只需：

1. 运行一个明确命名的采集入口。
2. 自动读取 A～D 图片。
3. 得到 recognition_results JSON。
4. 使用现有 Python 计分工具。

整个过程：

- 不要求手动编辑 Scheme Arguments。
- 不依赖固定模拟器名称。
- 不修改现有名片数据库。
- 不要求把图片手动导入模拟器。
- 不更改 OCR 或字段解析算法。
- 不将模拟结果冒充真实 OCR。
- 不允许采集失败后假装成功。

## 六、本轮限制

本轮先只读审查和提出方案，不修改 Swift 代码或工程配置。

Codex 不运行：

- xcodebuild
- xcrun
- 模拟器
- 自动化测试
- Python 命令
- Git 操作

完成报告后停止，等待确认最终修复方案。

## 七、报告要求

重点回答：

1. 这次被跳过最可能是哪一个条件导致的？
2. 原来为什么需要这么多启动限制？
3. 这些限制哪些可以安全取消？
4. 哪一种方案修改最少且长期可维护？
5. 是否需要真正新增一个独立测试目标？
6. 用户最终应当如何一键执行采集？

构建、测试与采集标记 NOT_RUN。
