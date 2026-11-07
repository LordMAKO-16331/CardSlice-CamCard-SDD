# P025-C1B-F02 — Week 5：修复 CardScanWorkflow 类型不可见的编译错误

## 一、问题背景

P025-C1B-F01 完成识别结果预览与人工校正流程修改后，用户在 Xcode 中发现三个编译错误。

文件：

`CardImageImportView.swift`

错误：

1. `Cannot find 'CardScanWorkflow' in scope`
2. `Cannot find 'CardScanWorkflow' in scope`
3. `Reference to member 'source' cannot be resolved without a contextual type`

截图中第 51 行涉及：

`CardScanWorkflow.Stage.review`

此次错误发生在编译阶段，新增流程尚未完成用户验收。

本轮只修复这些编译错误，不重新设计扫描流程。

## 二、自动归档

保存完整 Prompt：

`prompts/P025_C1B_F02_Week5_workflow_compile_fix.md`

完成后生成：

`records/P025_C1B_F02_Week5_response.md`

## 三、检查任务

优先检查：

1. CardImageImportView\.swift
2. CardScanWorkflow 的实际定义及所在文件
3. P025-C1B 和 F01 新增的扫描流程状态文件
4. 相关扫描流程单元测试
5. Xcode 工程的文件编译目标配置（仅在必要时检查）

重点确认：

- CardScanWorkflow 是否真的存在。
- 类型名称是否拼写一致。
- Stage 是否包含 source、crop、review、save 等实际引用的状态。
- 是否存在类型重命名后调用未同步的问题。
- 该类型所在文件是否被 App Target 编译。
- 类型是否错误地只被添加到 Tests Target。
- 是否存在条件编译导致类型不可见。

不要仅因截图显示第 51 行，就直接删除这一行。

## 四、修复要求

根据实际根因采取最小修复：

### 情况 A：类型存在但没有加入 App Target

修复文件的 Target Membership 或必要的工程配置。

不得修改其他无关 Build Settings。

### 情况 B：类型名称或成员名称不一致

统一实际类型与调用，保持原有状态转换语义。

### 情况 C：类型定义意外丢失

在确认不存在同等功能类型后，恢复最小必要的状态类型定义。

不得重新开发一套扫描工作流。

### 情况 D：编译器类型推断失败

补充必要的明确类型信息。

不能用强制转换、强制解包或无意义的替代值掩盖问题。

## 五、保持现有业务

必须保留：

1. 选择图片后进入裁剪。
2. 手动调整边界。
3. 确认裁剪后自动 OCR。
4. OCR 完成后先展示识别结果。
5. 用户选择是否进入人工校正。
6. 人工校正后返回结果预览。
7. 用户主动确认后保存名片。
8. 更换图片后旧任务失效。
9. 原图、处理图、OCR 原文及最终字段正常保存。

不得为了让编译通过而删除新的识别结果预览阶段。

## 六、修改范围

优先只修改：

- CardImageImportView\.swift
- CardScanWorkflow 实际所在文件
- 必要的流程状态定义文件

只有确认存在 Target Membership 问题时，才允许最小修改：

`app/CardSlice/CardSlice.xcodeproj/project.pbxproj`

不得修改 Repository、SwiftData、OCR、Parser、图片处理算法、标签、搜索、备注及 VCF。

如果编译错误来自本轮范围外的其他模块，应停止并说明。

## 七、执行限制

Codex 禁止运行：

- xcodebuild
- xcrun
- 模拟器
- 自动化测试
- Git 操作
- 工程清理和数据库重置

由用户在 Xcode 中执行全部构建和测试。

## 八、执行报告

说明：

1. 三个编译错误的实际根因。
2. 修改的文件。
3. 是否涉及 Target Membership。
4. 是否保留原有流程状态及测试。
5. 构建与测试：NOT_RUN。
6. 尚未解决的问题。

完成后停止，不开始 P025-C2。
