# P019 — 已保存名片的编辑与更新

## 一、项目背景

CamCard SDD iOS 课程项目已完成 P001～P018 及相关修复。

当前已实现：

- 相册图片导入、预处理、边界检测和透视校正。
- 中英文 OCR 和基础字段解析。
- 人工校正识别结果。
- 名片正式保存到 SwiftData。
- CardHolder 列表、详情与重启恢复。
- 现有自动化回归测试此前已全部通过。

已知问题：

- 部分姓名和公司存在识别错误或未分类情况。
- 当前临时开发界面存在堆叠。

上述问题保留记录，本轮不修复 OCR 或重构 UI。

本轮目标：实现已保存名片的编辑及更新，对应 R07、T14 和 R09 的相关要求。

## 二、自动归档

将本条完整指令保存为：

`prompts/P019_saved_card_editing.md`

完成后生成：

`records/P019_response.md`

不得覆盖历史文件。

## 三、执行前阅读

只阅读必要文件：

1. docs/spec.md，重点 R07、R09。
2. docs/03_reference_tests.md，重点 T13、T14、T18。
3. BusinessCardRecord.swift。
4. CardDetailView\.swift。
5. CardHolderView\.swift。
6. CardHolderViewModel.swift（如存在）。
7. CardFieldCorrectionView\.swift。
8. CardFieldCorrectionDraft.swift。
9. CardRepository.swift。
10. 现有 Repository 测试。

以实际工程结构为准。

## 四、允许修改范围

允许修改：

- CardDetailView\.swift
- CardHolderView\.swift
- CardHolderViewModel.swift（如存在）
- CardFieldCorrectionView\.swift（仅复用或适配编辑功能时）
- CardFieldCorrectionDraft.swift（仅确有必要时）

允许新增：

- CardSavedRecordEditor.swift（如需要独立编辑状态）
- CardSavedRecordEditingTests.swift

上述文件均使用项目现有目录结构。

禁止修改 BusinessCardRecord、SwiftData Schema、Repository 协议及实现、OCR、图像处理、App 入口和既有测试。

如必须扩大范围，先报告。

## 五、编辑功能

在已保存名片的详情页增加：

`编辑`

点击后进入编辑界面。

支持修改：

1. 姓名
2. 公司
3. 职位
4. 多个电话号码及其类型
5. 多个邮箱
6. Website
7. Address

优先复用 P017 已有字段校正组件，避免重复实现两套表单。

编辑界面必须从当前已保存记录初始化，而不是从上一次 OCR 解析结果初始化。

## 六、保存与取消

要求：

1. 编辑前读取当前名片。
2. 用户修改内容保存在独立编辑草稿中。
3. 点击取消，不修改数据库。
4. 点击保存，调用现有 CardRepository.update。
5. 不允许通过 insert 创建重复名片。
6. 更新后保留原有 UUID。
7. 更新后详情页立即展示新值。
8. 返回 CardHolder 后列表同步刷新。
9. App 完全退出再启动后，修改依旧存在。
10. 保存失败时显示错误，不能假装成功。
11. 防止重复提交。
12. 不允许编辑一张名片时意外修改另一张。

## 七、数据完整性

编辑现有名片时必须保留：

- 原始图片。
- 处理后图片。
- OCR Raw Text。
- 初始 ParsedContactFields。
- UUID。
- 原有标签 ID。
- 未被用户修改的备注。
- createdAt。

更新成功时合理更新 updatedAt。

人工修改姓名或电话，不能反向覆盖最初的 OCR 和解析结果。

## 八、测试

新增针对编辑逻辑的 Swift Testing 测试。

至少覆盖：

1. 从已有名片正确加载编辑数据。
2. 修改姓名与公司。
3. 修改电话号码及类型。
4. 新增或删除邮箱。
5. 取消编辑不会改变已保存数据。
6. 保存后通过 Repository 回读新值。
7. UUID 和 createdAt 保持不变。
8. OCR、图片和初始解析信息不被覆盖。
9. 修改一张名片不影响另一张。
10. 更新不存在的名片时正确处理错误。

保留所有既有测试及断言。

## 九、严格禁止

- 不修改 OCR 或字段解析算法。
- 不实现删除、搜索、标签管理或 VCF 导出。
- 不实现相机采集。
- 不修改数据库结构。
- 不大规模重构 UI。
- 不添加第三方依赖。
- 不执行 Git 操作。

## 十、执行效率

Codex 只负责必要文件读取、代码修改和归档。

禁止执行：

- xcodebuild
- xcrun
- 模拟器
- 构建和自动化测试
- 安装及清理命令

全部 Xcode 验证由用户亲自进行。

## 十一、执行报告

创建：

`records/P019_response.md`

简要记录：

1. 实际修改文件。
2. 编辑数据与 Repository 的交互方式。
3. 保存和取消如何处理。
4. 新增测试及数量。
5. 已知限制。
6. 构建与测试：NOT_RUN，等待用户验证。
7. 课程 T01～T20：尚未正式验收。

完成后停止，不开始 P020。