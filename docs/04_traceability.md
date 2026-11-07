# 04 需求—观察—测试追踪矩阵 v0.1

| 需求 | 课程章节 | 黑盒观察 | 主要测试 | 参考 CamCard 黑盒观察证据（非自身实现进度） |
|---|---|---|---|---|
| R01 名片夹 | 七/7.1 | O01 | T01/T02/T12/T13/T17 | 已见有卡列表；真实空卡夹未知 |
| R02 拍摄导入 | 七/7.2 | O02 | T02/T03/T04/T05/T20 | Single后续大致已见，Batch不计 |
| R03 图像校正 | 七/7.3 | O02 | T06/T20 | 裁剪入口有证据；失败与角点待验证 |
| R04 OCR | 七/7.4、五 | O03 | T07/T08 | A～D错误样例已收集，原始文本仅在复刻App保存 |
| R05 字段结构化 | 七/7.5、八 | O03 | T08/T09/T10 | C/D错分已观察；老师仍要求正确解析/不捏造 |
| R06 人工校正 | 九 | O03 | T11/T12/T14/T20 | 编辑界面、取消行为已观察 |
| R07 详情保存 | 十 | O04 | T12/T13/T14/T17 | 保存详情已见；部分异常待补 |
| R08 搜索/标签/备注 | 十一 | O04 | T15/T16 | Group/Note/搜索实际已操作；持久化待补 |
| R09 持久化 | 十二 | O04 | T18 | 原图/字段重启保留；标签/备注待证 |
| R10 导出 | 十三 | O05 | T19 | 入口已见；写入通讯录未验证；VCF为拟采用方案 |

## 一致性优先级
1. 课程明文规定与T01～T20验收优先。
2. 参考CamCard在**限定范围**内观察到的行为为UI/流程基线。
3. 技术选型与交互补丁为团队设计，必须在文档中注明来源；不可将推测变为事实。
4. 概率识别错误用于评估AI边界；不能复制错误来规避“不虚构字段”要求。


## Week 2 自身 App 实现进度（2026-11-03）

| 需求 | 当前实现状态 | 证据与边界 |
|---|---|---|
| R01 | 部分实现 | 真实仓库列表、计数、加载/空/失败状态、详情导航；缩略图仍占位，搜索和扫描入口未完成 |
| R02 | 部分实现 | PhotosPicker 单选、异步预览及关闭；相机/权限/后续处理未完成 |
| R03 | 未实现 | 检测、手动裁剪及透视/方向校正待开发 |
| R04 | 未实现 | 只有模型字段与合成测试数据，没有真实 OCR |
| R05 | 未实现 | 结构化模型已定义，解析器及准确率评估未实现 |
| R06 | 未实现 | 草稿编辑、人工校正和确认/取消保存流程待开发 |
| R07 | 部分实现 | 只读文本详情、Repository CRUD、DEV 保存；图片仍占位，正式保存/编辑/删除及系统动作未完成 |
| R08 | 未实现用户功能 | 存在标签标识/备注数据字段；搜索、标签及备注管理界面未实现 |
| R09 | 部分实现并有开发验证 | SwiftData、映射、磁盘重建测试和用户确认 DEV 重启恢复；真实图片/人工更正/标签/备注完整端到端验收未完成 |
| R10 | 未实现 | VCF 生成、字段映射、导入核验待开发 |

以上没有任何一项登记为完整课程验收通过。30项开发自动化测试通过为用户人工确认；课程 T01～T20 全部 NOT_RUN。参考观察表保持其黑盒含义，未据自身实现改写。

## Week 6 实现与验证

上方保留参考 CamCard 观察及 Week 2 快照。本表连接 CardSlice 的现有实现和实际证据。测试状态以 [Reference Tests](03_reference_tests.md) 为准。

| 需求 | CardSlice 实现模块 | Reference 状态 | 其他证据与剩余验证 |
|---|---|---|---|
| R01 名片夹 | `CardHolderView`、`CardDetailView`、`CardRepository` | PASS T01、T02。NOT_RUN T12、T13、T17 | 独立空库及扫描入口已确认。列表随保存、删除刷新有历史功能反馈 |
| R02 单张拍摄与导入 | `SingleCardCameraView`、`CardImageImportView`（PhotosPicker） | PASS T02、T04、T05。NOT_RUN T03、T20 | iOS 18 真机实拍及后续扫描已确认。权限拒绝、恢复及取消分项待取证 |
| R03 检测与裁剪 | `CardImagePreparationService`、`CardRectangleDetectionService`、`CardCropEditorView`、`CardPerspectiveCorrectionService` | PASS T06。NOT_RUN T20 | 自动检测和手动裁剪已确认。失败恢复及特殊输入的独立证据待补 |
| R04 OCR | `CardTextRecognitionService`、`CardImageImportView` | NOT_RUN T07、T08、T20 | 正式 JSON 记录 35 张有原文、F31 无文字。界面异常处理及 A/B 的正式记录待补 |
| R05 字段解析 | `CardContactFieldParser`、`BusinessCardRecord` | NOT_RUN T08、T09、T10 | 已有正式逐字段评分。D 缺网站和 C 多联系方式的指定验收记录待补 |
| R06 人工校正 | `CardFieldCorrectionView`、`CardFieldCorrectionDraft`、`CardImageImportView` | NOT_RUN T11、T12、T14、T20 | 用户曾确认人工修改和保存。确认与取消的正式对照待补 |
| R07 保存、详情、编辑、删除 | `CardRecordAssemblyService`、`CardImageImportView`、`CardDetailView`、`SwiftDataCardRepository` | NOT_RUN T12、T13、T14、T17 | 保存、查看、编辑、删除有阶段性反馈。详情双图、电话及邮件系统交互、删除取消待逐项取证 |
| R08 搜索、标签及备注 | `CardHolderView`、`CardSearchService`、`TagManagementView`、`CardTagSelectionView`、`SwiftDataTagRepository`、`CardDetailView` | NOT_RUN T15、T16、T18 | 搜索及标签操作有用户反馈，备注可编辑、搜索。正式搜索分项及同一记录的重启恢复待补 |
| R09 本地持久化 | `SwiftDataCardRepository`、`BusinessCardPersistenceMapper`、`SwiftDataTagRepository` | NOT_RUN T18 | 用户曾确认重启恢复。原图、修正字段、标签、备注的联合取证待补 |
| R10 VCF 导出 | `CardVCardExportService`、`CardDetailView` | NOT_RUN T19 | 用户确认 VCF 导出及多号码保留。接收端实际导入并逐字段比对待取证 |
