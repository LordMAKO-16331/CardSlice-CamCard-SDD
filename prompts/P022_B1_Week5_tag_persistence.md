# P022-B1 — Week 5：标签数据管理与持久化

## 一、项目背景

CamCard SDD iOS 课程项目当前进入 Week 5 名片管理阶段。

已完成：

- P021 名片搜索。
- P021-F01B 电话、邮箱动态字段删除修复。
- P022-A 备注管理。
- P022-A-F02 空备注入口及备注搜索修复。
- 最新 Xcode 自动化回归测试全部通过。

当前尚未实现完整的标签分组管理。

本轮只处理标签的数据管理与持久化，不开发标签 UI。

对应课程要求：

- 创建标签。
- 为名片关联标签。
- 按标签查看名片。
- 删除标签。
- App 重启后恢复标签及关联关系。

## 二、自动归档

保存本条完整任务：

`prompts/P022_B1_Week5_tag_persistence.md`

完成后生成：

`records/P022_B1_Week5_response.md`

不得覆盖已有文件。

## 三、执行前阅读

仅阅读必要文件：

1. docs/spec.md 中标签管理与持久化需求。
2. docs/07_architecture.md。
3. BusinessCardRecord.swift。
4. MockBusinessCards.swift。
5. PersistedBusinessCard.swift。
6. BusinessCardPersistenceMapper.swift。
7. CardRepository.swift。
8. SwiftDataCardRepository.swift。
9. InMemoryCardRepository.swift。
10. CardSliceApp.swift。
11. 当前相关 Repository 单元测试。

首先确认实际存在的 TagRecord、tagIDs、SwiftData 模型及 ModelContainer 初始化方式。

不得假设标签目前完全没有实现。

如已有持久化标签实现，应复用，不重复创建第二套系统。

## 四、数据设计要求

使用现有名片模型中的 tagIDs 作为名片与标签之间的关联。

要求：

1. 标签拥有稳定的 UUID。
2. 标签包含名称。
3. 标签名称不能为空白。
4. 统一处理名称首尾多余空格。
5. 同一标签名称不应因大小写差异而重复创建。
6. 不同名片可关联同一标签。
7. 同一名片可关联多个标签。
8. 名片 tagIDs 与标签实体保持一致。
9. 不得修改已有 BusinessCardRecord 的字段定义。
10. 不得使用只存在于 MockBusinessCards 的标签充当正式持久化标签。

优先使用独立的标签 Repository。

## 五、SwiftData 持久化

如果现有工程尚无持久化标签实体：

允许新增独立的 SwiftData 标签实体，并在正式 ModelContainer 中注册。

要求：

1. 标签数据真正保存到本地磁盘。
2. App 完全退出后重新启动仍可读取。
3. 不能因为增加标签实体而删除或重置已有名片数据库。
4. 保留既有名片、原始图片、OCR、备注及编辑结果。
5. 若出现数据库模型兼容问题，应明确报告。
6. 不得通过删除持久化文件、重装 App 或清空旧记录来使新结构运行。
7. 不得使用 try! 掩盖数据库错误。
8. 保留当前测试使用的内存数据库隔离方式。

特别注意：当前 App 已保存了用户人工测试的真实名片，不允许破坏这些数据。

## 六、标签 Repository

提供必要的数据操作：

- 创建标签。
- 获取全部标签。
- 根据 ID 获取标签。
- 删除标签。
- 查询某标签关联的名片，或提供可供后续筛选使用的数据接口。

明确区分：

- 标签不存在。
- 标签名称无效。
- 标签重复。
- 数据库读写失败。

删除标签时必须保证：

1. 只删除该标签。
2. 不删除任何 BusinessCardRecord。
3. 清理所有名片中对应的 tagID。
4. 其他标签关联保持不变。
5. 尽可能使用现有 SwiftData 事务机制保证一致性。
6. 不得出现标签删除后，名片仍保留无法解析的旧 tagID。

如果现有架构无法安全实现标签删除与关联清理的一致性，请报告具体阻碍，不要实现一个只删除标签实体的半成品。

## 七、允许修改范围

允许新增：

- `app/CardSlice/CardSlice/Models/PersistedTag.swift`
- `app/CardSlice/CardSlice/Data/TagRepository.swift`
- `app/CardSlice/CardSlice/Data/SwiftDataTagRepository.swift`
- `app/CardSlice/CardSliceTests/TagRepositoryTests.swift`

以上为建议路径，以项目实际目录结构为准。

仅在必要时允许修改：

- CardSliceApp.swift：注册标签持久化模型。
- 现有标签定义所在文件：仅在当前类型无法满足最小需求时，说明原因后进行必要调整。

不得修改：

- 名片业务模型已有字段。
- SwiftDataCardRepository 的现有 CRUD 行为。
- 图片处理、OCR、字段解析。
- CardHolderView。
- CardDetailView。
- 名片编辑表单。
- 搜索功能。
- 既有测试及断言。

如果实现要求必须扩大范围，请停止并报告，不擅自修改。

## 八、自动化测试

使用 Swift Testing。

至少覆盖：

1. 创建标签。
2. 重复名称检查。
3. 空白名称拒绝。
4. 多标签创建与查询。
5. 同一标签关联多张名片。
6. 同一名片关联多个标签。
7. 删除标签后，关联名片仍然存在。
8. 删除标签后，其关联 ID 正确移除。
9. 其他标签关联不受影响。
10. 磁盘数据库重开后，标签及关联关系保持。
11. 重复删除或删除不存在标签时，正确处理错误。

测试必须使用隔离数据库。

不得修改正式用户数据。

不得删除或弱化既有测试。

## 九、执行限制

Codex 只负责必要文件读取、代码修改和自动归档。

禁止执行：

- xcodebuild
- xcrun
- 模拟器。
- 自动化测试。
- 构建、安装与清理操作。
- Git 操作。

由用户自行在 Xcode 中执行构建及测试。

不要进行冗长分析。

## 十、执行报告

创建：

`records/P022_B1_Week5_response.md`

简要报告：

1. 实际新增和修改的文件。
2. 是否复用了已有 TagRecord。
3. 标签持久化方案。
4. 删除标签时如何处理关联名片。
5. 如何避免影响已有数据库。
6. 新增测试名称及数量。
7. 尚未解决的问题。
8. Xcode 构建与测试：NOT_RUN。
9. T01～T20：尚未完成统一正式验收。

完成后停止，不开始 P022-B2。