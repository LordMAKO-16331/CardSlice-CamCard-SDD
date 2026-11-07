# P021-F01A 动态字段管理完整性审查

## 范围与结论

当前 SwiftUI 表单中，支持动态新增行的联系人字段只有电话和邮箱。姓名、公司、职位、网站、地址是单值字段，清空可选值会转为 nil。OCR 原文、未分类行和歧义提示是只读列表。已保存名片编辑和 OCR 后人工校正共用 CardFieldCorrectionView，因此两者都缺少显式的逐行删除入口。静态代码有 Form 内的 onDelete 手势处理，具体设备上手势可用性待人工验证。

## 问题与覆盖

| 严重程度 | 文件、组件及字段 | 已有能力与缺口 | 建议的最小修复与范围 | 现有测试覆盖 |
|---|---|---|---|---|
| 高 | [CardFieldCorrectionView 电话区](../app/CardSlice/CardSlice/Views/CardFieldCorrectionView.swift#L32) | 可新增、编辑号码和切换类型。onDelete 可按偏移删除，但行内没有可见删除按钮，也没有编辑模式入口。空白新行会阻止提交，找不到删除手势时只能填写或取消整个表单。 | 在共享电话行增加可见、带无障碍标签的删除按钮，按该行 UUID 删除。保留滑动删除。只改共享表单。 | CardFieldCorrectionTests 覆盖数组增删、类型变更和空行校验。CardSavedRecordEditingTests 覆盖改号码与类型后回读。无 UI 删除可达性测试。 |
| 高 | [CardFieldCorrectionView 邮箱区](../app/CardSlice/CardSlice/Views/CardFieldCorrectionView.swift#L44) | 可新增和编辑邮箱。删除同样只有 onDelete 手势。误加空行时无法通过可见控件取消这一行。 | 在共享邮箱行增加同样的删除控件，按 UUID 删除。只改共享表单。 | CardFieldCorrectionTests 覆盖数组增删、无效邮箱、空行。CardSavedRecordEditingTests 覆盖移除首个邮箱、添加新邮箱后仓库回读。无 UI 可达性测试。 |
| 中（覆盖缺口） | [CardFieldCorrectionDraft 行标识](../app/CardSlice/CardSlice/Models/CardFieldCorrectionDraft.swift#L3) 与共享表单双向绑定，涉及电话和邮箱 | 每行有稳定 UUID，ForEach 绑定同一数组，onDelete 偏移也用于同一数组。静态检查未见索引错配。现有测试删除的是首项，未覆盖删除中间项后继续编辑后续行，或删完最后一项后再新增。 | 新增逐行删除时取稳定 UUID，不捕获数组索引或删除后的绑定。用两种入口手测中间项、最后一项及重新新增。若提取可测的按 ID 删除方法，再定点修改 Draft 和对应测试。 | 部分。模型测试覆盖原本为空的集合和移除首项。未覆盖中间项、最后一项及焦点/绑定行为。 |
| 中（覆盖缺口） | CardSavedRecordEditor.save、BusinessCardPersistenceMapper、CardSavedRecordEditingTests，涉及电话和邮箱 | 保存把两个最终数组整体赋给同一 UUID 的记录，经 Mapper JSON 编码后落盘。删除最后一行可得到空数组。现有磁盘重开测试只编辑姓名和公司，未验证删除电话、清空联系方式后磁盘重开。 | 补一项磁盘回归，组合验证中间项删除、剩余项编辑和最后一项清空，重开后读取实际数组。范围为 CardSavedRecordEditingTests.swift。 | 部分。内存仓库回读覆盖改电话和邮箱增删，组装测试覆盖多值写入回读。缺少动态删除与重开磁盘的组合证据。 |
| 中 | [CardDetailView 联系方式列表](../app/CardSlice/CardSlice/Views/CardDetailView.swift#L67)，涉及相同电话值或邮箱 | 草稿行有不同 UUID，允许两个值相同的条目保存。详情 ForEach 使用值本身作为 ID，完全相同的 PhoneEntry 或邮箱会发生 ID 冲突，列表展示可能不稳定。 | 只在只读详情行改用枚举位置作为当前快照的唯一键，保持现有重复值保存语义。范围为 CardDetailView.swift。 | 未覆盖重复值在详情里的渲染。需人工检查重复行显示及只删除其中一条。 |

## 状态与数据流

- [草稿校验](../app/CardSlice/CardSlice/Models/CardFieldCorrectionDraft.swift#L49) 在提交前拒绝空白电话和邮箱行。移除最后一行后遍历空数组，confirmedFields 输出空集合，不会自动补回一行。
- [共享表单](../app/CardSlice/CardSlice/Views/CardFieldCorrectionView.swift#L71) 编辑值类型副本。取消后确认丢弃只关闭表单，提交回调不会执行。保存期间禁用表单与取消，失败保留副本和错误提示。testDiscardingDraftDoesNotWrite 覆盖修改副本不污染仓库，实际取消对话框待手测。
- [已保存名片编辑](../app/CardSlice/CardSlice/Views/CardDetailView.swift#L141) 从当前保存记录填充草稿，提交后按 UUID 更新并同步详情与列表。[人工校正](../app/CardSlice/CardSlice/Views/CardImageImportView.swift#L274) 从解析结果或本会话草稿填充，确认只替换会话内状态，随后单独点击保存才组装和写入。两者共用新增、修改、删除及校验行为，持久化时机按流程区分。
- Mapper 对两个数组完整编码与解码，原始 OCR 和初始解析继续独立保留。源码提供持久化路径，尚无本轮运行结果。

## 提请审核的统一修复范围

首要修复限定在 CardFieldCorrectionView.swift。电话和邮箱共享逐行删除控件，绑定继续使用现有 ForEach 和稳定 UUID，删除动作只移除对应 UUID。两种入口一起复用，保持校验、提交和取消逻辑。若同时处理重复详情行及补齐持久化覆盖，再纳入 CardDetailView.swift 和 CardSavedRecordEditingTests.swift。只有需要抽取按 ID 删除方法进行单测时，才纳入 CardFieldCorrectionDraft.swift 和 CardFieldCorrectionTests.swift。

验收用同一组场景走两种入口。新增空行后删除，删除三项中的中间项后继续编辑末项，清空最后一项并重新新增，取消后重开，保存后重开 App 并回读。另用相同联系方式验证详情展示和单行删除。

本轮仅静态审查。构建、测试和模拟器验证均为 NOT_RUN。等待用户审核修复范围。
