# P018 — 正式名片保存与 SwiftData 持久化

## 一、项目背景

本项目为基于 SDD 的 CamCard iOS 功能切片。

目前已经实现：

- 相册图片选择及预处理。
- 名片边界检测、透视矫正。
- 中英文 OCR。
- 联系人字段自动解析。
- 联系人字段人工校正。
- CardRepository 和 SwiftDataCardRepository。
- CardHolder 列表、空状态、详情导航。
- DEBUG 模式的持久化测试名片保存。

用户已在模拟器确认 P017 可以人工修改字段，但仍存在临时开发 UI 堆叠问题。

本轮只将已确认的真实名片信息保存到现有 SwiftData 数据库，暂不开展 UI 重构。

课程参考测试 T01～T20 尚未完成正式验收。

## 二、自动归档

将本条完整指令保存至：

`prompts/P018_real_card_persistence.md`

任务结束后生成：

`records/P018_response.md`

不得覆盖既有记录。

## 三、执行前阅读

请先读取：

1. `docs/spec.md`，重点 R04、R05、R06、R07、R09。
2. `docs/03_reference_tests.md` 中与保存、详情及持久化有关的测试。
3. `docs/07_architecture.md`。
4. `BusinessCardRecord.swift`。
5. `CardFieldCorrectionDraft.swift`。
6. `CardFieldCorrectionView.swift`。
7. `CardImageImportView.swift`。
8. `CardHolderView.swift` 及其 ViewModel（如存在）。
9. `CardRepository.swift`。
10. `SwiftDataCardRepository.swift`。
11. `BusinessCardPersistenceMapper.swift`。
12. 必要的现有测试文件。

以实际工程代码为准，避免重复定义已有模型。

## 四、允许修改范围

优先修改：

- `CardImageImportView.swift`
- `CardHolderView.swift`
- `CardHolderViewModel.swift`（仅在实际存在且必要时）
- `CardFieldCorrectionView.swift`（仅在确认结果传递确有必要时）

允许新增：

- `app/CardSlice/CardSlice/Services/CardRecordAssemblyService.swift`
- `app/CardSlice/CardSliceTests/CardRecordAssemblyTests.swift`

允许在上述新增服务中实现从人工校正结果构造 BusinessCardRecord 的纯业务逻辑。

禁止擅自修改：

- BusinessCardRecord 的现有字段定义。
- SwiftData Schema。
- Repository 协议与现有实现。
- OCR、字段解析和图像识别算法。
- 既有单元测试。
- App 入口、Xcode 工程配置。
- 其他 SDD 文档。

如果当前结构无法在允许范围内安全实现，请停止并报告必要的最小范围变更，不得自行扩大修改。

## 五、正式名片记录构建

从当前图像处理流程和人工确认结果创建新的 BusinessCardRecord。

要求：

1. 每张新名片生成独立 UUID。
2. originalImageData 使用相册导入时保留的原始图片 Data。
3. processedImageData 优先使用已成功进行透视矫正的结果，否则使用 P013 预处理结果。
4. ocrRawText 保留 P015 的真实原始 OCR 文本。
5. parsedFields 保留 P016 的初始解析结果。
6. name、company、jobTitle 等最终字段采用 P017 人工确认后的值。
7. phones 保存全部已确认的电话号码及对应 PhoneType，包括 Fax。
8. emails 保存全部已确认邮箱。
9. website、address 使用人工确认值，不从邮箱或其他字段推测。
10. createdAt、updatedAt 合理初始化。
11. 若当前流程尚未提供标签或备注，不得编造数据。
12. 不得将人工确认的字段反向覆盖初始解析结果或 OCR 原文。
13. 不得将不同图片的 OCR、校正和处理结果混合保存。
14. 新建保存操作不得覆盖已有名片。

如现有模型要求 name 非空，应进行明确校验并向用户说明，禁止用虚构姓名填充缺失字段。

## 六、保存操作

在人工校正确认之后，增加明确的正式保存入口：

`保存名片`

要求：

1. 用户主动点击才执行保存。
2. 调用当前已注入的 CardRepository.insert。
3. 必须使用正式 App 的 SwiftData Repository，不能用 Mock 数据冒充保存成功。
4. 保存期间显示状态并禁用重复提交。
5. 保存失败时显示错误。
6. 保存成功后明确提示，并返回或刷新 CardHolder。
7. 新名片应立即出现在列表中。
8. 点击新名片可以进入现有详情页，查看人工确认后的字段。
9. 取消保存不能创建数据库记录。
10. 同一次确认流程不能因快速重复点击保存多张相同记录。
11. 保存成功后允许用户开始下一张名片处理。
12. 更换图片时不能误保存上一张图片的处理状态。

本轮不实现修改已有名片和删除名片，这些属于后续管理功能。

## 七、数据一致性

重点保证以下四类信息的关系：

A. 原始图像：用户最初导入的图片。

B. 处理图像：经过方向修正、缩放以及可选透视矫正后的图片。

C. 初始识别信息：OCR Raw Text 和初始 ParsedContactFields。

D. 最终确认信息：用户人工校正后的姓名、联系方式等字段。

A、B、C、D 必须共同关联同一个 BusinessCardRecord。

不能因为用户修改姓名或电话而丢失初始 OCR 追溯信息。

不能保存上一张图片的识别数据。

## 八、UI 范围

只增加完成正式保存所必需的控件与提示。

保留现有：

- 相册选择。
- 图像处理。
- OCR。
- 字段解析。
- 人工校正。
- CardHolder。
- 详情页。
- DEBUG 保存测试名片功能。

当前 UI 堆叠问题记录为已知问题，不在本轮进行大规模布局重构。

但不能出现保存按钮完全无法访问或关键错误提示不可见的情况。

所有临时开发 UI 仍标记 [DECISION/TEMP]。

## 九、新增测试

使用 Swift Testing，优先针对记录构建和数据一致性编写确定性测试。

至少覆盖：

1. 人工确认字段正确写入 BusinessCardRecord。
2. OCR 原文保存后不变。
3. 初始解析数据不被人工修改覆盖。
4. 原始图片与处理后图片正确区分。
5. 多电话及 Fax 类型完整保留。
6. 多邮箱完整保留。
7. 缺失可选字段不产生虚构数据。
8. 不同名片生成不同 UUID。
9. 已确认字段构建的记录可经现有 Repository 保存并回读。
10. 不合法的必要字段能够被明确拒绝或处理，不得静默丢失数据。

若涉及 UI 层一次性保存防重，请采用可测试的状态设计，并尽可能补充相关测试。

不得修改或弱化现有测试。

## 十、严格禁止

- 不实现新增 OCR 或图像识别算法。
- 不修改数据库 Schema。
- 不修改现有业务模型结构。
- 不实现编辑、删除已有名片。
- 不实现搜索、标签管理、VCF 导出。
- 不开发相机拍摄。
- 不进行大规模 UI 重构。
- 不添加第三方依赖。
- 不执行 Git 操作。

## 十一、执行效率

Codex 只负责必要文件读取、代码修改和文档归档。

禁止执行：

- xcodebuild
- xcrun
- 模拟器命令
- 任何构建、运行及自动化测试
- 安装、清理和 Git 命令

用户自行在 Xcode 中构建、测试、验收。

不进行冗长分析或无关检查。

## 十二、自动生成 Response

完成后创建：

`records/P018_response.md`

简要记录：

1. 实际新增及修改文件。
2. 数据流如何完成正式保存。
3. 原始图像、处理图像、OCR、初始解析和最终字段如何关联。
4. 新增测试名称与数量。
5. 已知问题。
6. 构建与测试状态：NOT_RUN，等待用户验证。
7. T01～T20：仍未完成正式验收。

完成后停止，不开始 P019。