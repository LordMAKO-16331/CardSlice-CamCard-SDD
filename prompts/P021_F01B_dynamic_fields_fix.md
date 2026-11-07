# P021-F01B — 动态联系方式管理统一修复

## 一、任务背景

P021-F01A 已完成只读审查，确认以下问题：

1. CardFieldCorrectionView 的电话和邮箱支持新增、编辑，但没有可见的逐行删除按钮。
2. 现有 onDelete 滑动删除手势不够直观，用户无法稳定找到。
3. 动态行具有稳定 UUID，应优先通过 UUID 删除。
4. CardDetailView 使用联系方式的值作为 ForEach ID，重复值可能导致视图身份冲突。
5. 现有测试缺少删除中间项、清空最后一项及数据库重启恢复的组合验证。

用户已经批准统一修复以上问题。

本轮不开发新功能，只修复动态联系方式管理。

## 二、自动归档

保存完整 Prompt：

`prompts/P021_F01B_dynamic_fields_fix.md`

任务结束后创建：

`records/P021_F01B_response.md`

不得覆盖历史文件。

## 三、允许修改范围

允许修改：

- `app/CardSlice/CardSlice/Views/CardFieldCorrectionView.swift`
- `app/CardSlice/CardSlice/Views/CardDetailView.swift`
- `app/CardSlice/CardSliceTests/CardSavedRecordEditingTests.swift`

仅当无法直接使用现有 UUID 实现安全删除时，才允许修改：

- `app/CardSlice/CardSlice/Models/CardFieldCorrectionDraft.swift`
- `app/CardSlice/CardSliceTests/CardFieldCorrectionTests.swift`

禁止修改其他 Swift 文件。

## 四、修复一：电话与邮箱的可见删除入口

在 CardFieldCorrectionView 中：

1. 每个电话条目增加明显的删除按钮。
2. 每个邮箱条目增加同样的删除按钮。
3. 使用系统删除图标及适当的危险操作样式。
4. 删除按钮带有明确的无障碍标签。
5. 删除时按照当前行的稳定 UUID 操作。
6. 不通过保存的旧数组索引定位删除目标。
7. 保留已有的 onDelete 手势。
8. 不影响电话类型选择、号码修改和邮箱编辑。
9. 删除最后一项后允许集合为空。
10. 新增空白行后允许立即删除。
11. 保留现有输入校验、保存和取消逻辑。
12. 保存过程中遵守现有禁用操作状态。

由于 CardFieldCorrectionView 被人工校正和已保存名片编辑共用，两种入口必须同时正常工作。

## 五、修复二：详情页重复联系方式的显示

检查 CardDetailView 中电话和邮箱的 ForEach。

如果当前使用电话号码或邮箱字符串本身作为唯一 ID，请改为适合只读列表的稳定且不冲突的视图标识方式。

要求：

1. 两个相同的邮箱地址能够正常显示为两行。
2. 两个完全相同的 PhoneEntry 不发生视图 ID 冲突。
3. 不修改或删除数据库中的重复值。
4. 不影响正常详情展示。
5. 不修改 BusinessCardRecord 模型。

## 六、修复三：补充持久化测试

在现有 CardSavedRecordEditingTests 中增加必要测试。

至少覆盖：

1. 三个电话号码中删除中间一项。
2. 删除后剩余号码及类型正确。
3. 删除最后一个电话号码。
4. 多邮箱中删除指定一项。
5. 清空邮箱集合。
6. 保存并重新打开磁盘 ModelContainer 后，删除结果仍然存在。
7. 原始图片、OCR 和其他未编辑字段不受影响。

尽量复用现有测试辅助结构。

不得删除或弱化原有测试。

如果测试文件已有相关场景，可以补充断言，不必重复创建同类型测试。

## 七、数据与操作约束

- 取消编辑不得修改已保存记录。
- 保存操作继续使用现有 Repository.update。
- UUID 和 createdAt 不变。
- 不允许删除其他名片的联系方式。
- 不得修改 OCR、字段解析或图片处理。
- 不得修改 SwiftData Schema。
- 不重构整个 UI。
- 不修改搜索功能。
- 不开始 P022。

## 八、执行效率要求

只读取必要文件，完成最小范围修改。

禁止执行：

- xcodebuild
- xcrun
- 模拟器
- 自动化测试
- Git 操作
- 安装及清理命令

由用户亲自在 Xcode 中完成构建和测试。

## 九、Response

简短说明：

1. 修改的文件。
2. 电话、邮箱删除方式。
3. 详情页重复值问题如何解决。
4. 新增或调整的测试。
5. 是否存在剩余问题。
6. 构建和测试：NOT_RUN，等待用户验证。
7. T01～T20：尚未完成统一正式验收。

完成后立即停止。