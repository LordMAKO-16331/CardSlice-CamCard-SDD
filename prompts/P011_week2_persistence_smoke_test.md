# P011 — Week 2：SwiftData 实际保存与重启恢复验证

## 一、项目状态

CamCard SDD iOS 项目已完成 P001～P010 和相关修复。

最新 Xcode 验证：

- 30/30 自动化测试 PASS。
- 0 编译警告。
- App 正常启动，真实 SwiftData 数据库显示空状态。
- P010 已完成 Repository 数据源接入。
- 课程参考测试 T01～T20 仍为 NOT_RUN。

本轮仅建立一个开发环境专用的数据保存验证入口，不开始相机或 OCR 开发。

## 二、自动保存 Prompt

将本条任务指令完整保存为：

`prompts/P011_week2_persistence_smoke_test.md`

不得覆盖已有 Prompt。

## 三、实现要求

先阅读现有 CardHolder、数据注入逻辑、CardRepository、SwiftDataCardRepository 及相关模型。

以实际工程结构为准。

实现一个仅在 DEBUG 环境显示的临时验证按钮：

`[DEV] 保存测试名片`

要求：

1. 仅在正常 App 启动的 DEBUG 环境可见，不影响使用 Mock 数据源的 UI 自动化测试。
2. 按钮通过现有 CardRepository.insert 保存一张虚拟名片。
3. 保存成功后重新读取 Repository，确保名片立即出现在 CardHolder 列表中。
4. 点击名片仍能进入现有只读详情页。
5. App 完全退出并重新启动后，能够从 SwiftData 读取已经保存的名片。
6. 不得在每次启动时自动插入数据。
7. 不得使用 MockBusinessCards.samples 代替真实数据库保存。
8. 数据库写入失败时必须显示错误，不得静默报告成功。
9. 明确标记 `[DECISION/TEMP]`，以后可删除该开发验证入口。

不增加正式的手动录入功能，不修改 SDD 参考 App 的已观察行为。

## 四、修改范围

优先只修改 CardHolderView\.swift 及现有 CardHolderViewModel.swift（如存在且确有必要）。

若当前架构必须修改其他文件，请先说明原因，不得擅自扩大范围。

禁止修改 SwiftData schema、业务模型、Repository 协议、已有测试和 Xcode 工程配置。

保留原有加载、空状态、错误状态和名片详情导航。

## 五、执行限制

Codex 只负责修改文件。

严禁：

- 执行 xcodebuild、xcrun。
- 启动模拟器。
- 执行任何构建或测试。
- 运行 Git 操作。
- 擅自开始 P012。

由用户亲自在 Xcode 中编译、运行及测试。

## 六、自动保存 Response

完成后创建：

`records/P011_response.md`

简要记录：

- 实际修改文件。
- 临时验证入口的实现方式。
- Repository 保存及重新读取的流程。
- 未解决问题。
- Xcode 构建与测试状态：NOT_RUN，等待用户验证。

课程 T01～T20 仍保持 NOT_RUN。

完成后停止，简要报告即可。