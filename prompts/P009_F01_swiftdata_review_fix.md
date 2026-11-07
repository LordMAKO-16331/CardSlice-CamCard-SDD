# P009-F01 — SwiftData 持久化层定点修复与测试补全

## 一、任务背景

CamCard SDD + TRAE 课程项目已经完成 P001～P008、P008-F01。

此前实际通过18项自动化测试。

P009 已建立：
- PersistedBusinessCard
- BusinessCardPersistenceMapper
- SwiftDataCardRepository
- SwiftDataCardRepositoryTests

但 P009 尚未经过 Xcode 构建验收。人工代码审核发现编译错误和测试覆盖不足。

本轮只修复 P009 中已经确定的问题，不开始 P010。

## 二、执行前阅读

请先阅读：

1. `docs/spec.md` 中 R07、R09。
2. `docs/07_architecture.md` v0.2。
3. `app/CardSlice/CardSlice/Models/BusinessCardRecord.swift`。
4. `app/CardSlice/CardSlice/Data/PersistedBusinessCard.swift`。
5. `app/CardSlice/CardSlice/Data/BusinessCardPersistenceMapper.swift`。
6. `app/CardSlice/CardSlice/Data/SwiftDataCardRepository.swift`。
7. `app/CardSlice/CardSliceTests/SwiftDataCardRepositoryTests.swift`。

必须先核对实际路径和代码，不得假设此前聊天上下文存在。

## 三、允许修改范围

仅允许修改：

- `BusinessCardPersistenceMapper.swift`
- `SwiftDataCardRepositoryTests.swift`

禁止修改：
- BusinessCardRecord.swift
- PersistedBusinessCard.swift
- CardRepository.swift
- InMemoryCardRepository.swift
- SwiftDataCardRepository.swift
- 已有模型测试和内存仓库测试
- SwiftUI 页面、App 入口及 Xcode 工程配置
- docs、records、prompts 和其他文件

如确实需要扩大范围，请停止并报告，不得自行实施。

## 四、修复任务

### F01-1：修复初始化参数顺序

当前 `testComplexFieldsPersistence` 在 BusinessCardRecord 初始化时，将 `originalImageData` 放在 `notes` 后面。

按照现有初始化器的真实参数顺序修改测试代码。

不得为了配合错误的测试而修改 BusinessCardRecord 初始化器。

### F01-2：修复必要集合数据的缺失处理

当前 `mapToRecord` 对以下存储字段为 nil 时返回空集合：

- phonesData
- emailsData
- tagIDsData

这些字段由现有 `mapToPersisted` 在正常保存时进行 JSON 编码，即使是空集合也会生成编码数据。

因此，对于当前 P009 的持久化格式，缺少这些编码数据应视为异常，而非自动解释成空集合。

要求：

1. 明确区分合法的空集合和缺失的编码数据。
2. 缺失必要编码数据时抛出可识别错误。
3. JSON 损坏或解码失败时传播错误，不静默丢弃字段。
4. parsedFieldsData 可以为 nil，因为初始解析结果本身是可选字段。
5. 不改变已有逻辑模型字段定义。

### F01-3：避免编码过程中的部分修改

当前 `updatePersisted` 在编码完成之前已开始修改持久化实体。

要求先完成所有可能失败的编码操作，确认成功后再赋值到 PersistedBusinessCard。

不得在编码失败时留下部分字段已修改、部分字段未修改的状态。

本轮只处理映射器内部的赋值顺序，不扩大到 Repository 的事务重构。

### F01-4：补全 P009 单元测试

P009 原任务要求至少10项基础测试，并增加一项真正的磁盘持久化验证。

当前只有8项，包括磁盘验证，因此必须补全。

保留所有已有有效测试，修正后至少达到11项测试。

重点覆盖：

1. OCR 原始文本、初始 ParsedContactFields、最终人工确认字段能够分别保存和读取，彼此不覆盖。
2. originalImageData 和 processedImageData 均可恢复。
3. 缺失 Website 时仍为 nil。
4. Mobile、Office、Fax 和多个 Email 能完整恢复。
5. Tag UUID 集合、Notes、createdAt、updatedAt 正确恢复。
6. 缺失必要编码集合时抛出错误。
7. JSON 内容损坏时抛出解码错误。
8. 磁盘测试至少验证姓名及部分关键字段，并使用相同数据库位置重新创建容器读取，不能仅用内存数据库冒充。

对于 Date 精度，使用合理的比较方法，不因持久化浮点精度造成无意义失败。

磁盘测试要使用独立临时目录，并确保测试结束或抛出错误时尽可能清理资源。

所有测试数据使用虚拟信息。

## 五、严格要求

- 不修改 UI。
- 不接入正式 App 数据库。
- 不新增第三方依赖。
- 不调整已经通过测试的 BusinessCardRecord。
- 不修改既有有效测试的目标来掩盖实现错误。
- 不执行未经授权的 Git 操作。
- 中文注释清晰、必要即可。
- 不将没有实际运行的测试报告为 PASS。

如果实际 SDK 编译问题要求修改禁止范围内的文件，请先报告。

## 六、交付报告

请报告：

1. 两个文件的具体修改内容。
2. 原有编译参数顺序错误如何修复。
3. 映射器如何区分合法空集合与缺失或损坏的数据。
4. 新增测试名称、覆盖范围与总数。
5. 是否实际构建和执行测试。
6. 是否修改了范围外文件。
7. 仍存在的风险。

修改完成后停止，不开始 P010。

课程 Reference Test Suite T01～T20 全部保持 NOT_RUN。