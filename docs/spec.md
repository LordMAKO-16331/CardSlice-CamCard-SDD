# CamCard 名片数字化与联系人管理 — Specification v0.2

> 状态：**P002 修订后人工复核版（2026-11-02）**。本文件是实现与验收的规格基线，不代表功能已经实现或测试通过。课程原文优先于本文件。

## 0. 约束与术语

- `[COURSE]`：课程作业明确要求；`[OBS]`：对参考 App 的实测行为；`[DECISION]`：当前项目拟采用的实现；`[OPEN]`：未定稿/待验证；`[DEV]`：开发环境信息。
- 权威来源：`source/移动应用开发课程作业-v2.docx`；观察记录：`docs/02_observation_log.md`。
- 验收范围：CamCard **指定版本与测试情境**下的“名片数字化与联系人管理”功能切片，不包含完整商业 App。
- 环境差异：
  - `[OBS]` 参考真机：iPhone 15 Plus、iOS 18.7.8、CamCard 8.65.0 English。
  - `[DEV]` 开发环境：Apple M2、16GB RAM、已安装 Xcode、iOS Simulator。
  - `[OPEN]` 教师统一验收环境：参考版本、最新版 iOS 的具体版本、设备规格、语言与登录状态等尚待教师确认。模拟器不自动等价于真实相机环境。

## 1. 用户主流程

`CardHolder（空列表/已有列表） → Single/Album → 采集结果 → 边界检测/裁剪/透视及方向校正 → OCR Raw Text → Structured Fields → Edit Card 人工核验/编辑 → Save → CardHolder → Card Details → Search / Group / Note / Edit / Delete → Kill & Relaunch → Export`

### 关键状态（初版）

- `EmptyHolder`：无已保存名片；真正 CardHolder 空状态尚未实测 `[OPEN]`。禁止凭空编造参考文案；若开发需要占位，须标记 `[DECISION / TEMP]`。
- `HolderList`：有名片、搜索结果或分组过滤结果。
- `Acquiring`：相机预览或相册选择；`CapturePreview`：拍摄/导入后确认或重拍。
- `Cropping`：显示检测边框与可调节裁剪；失败时允许人工调整/重拍 `[COURSE]`。
- `Recognizing`：OCR 处理中；`EditDraft`：结构化字段已生成但尚未保存。
- `SavedDetail`：已保存名片详情；`EditingSaved`：编辑保存或取消修改。
- `Exporting`：从记录生成 vCard、分享/保存或异常反馈。
- `PermissionDenied` / `RecognitionFailed` / `EmptyFields`：异常子状态。

## 2. 功能需求（10 个稳定需求 ID）

### R01 CardHolder 首页与列表

- `[COURSE]` 初次无卡时显示空状态和扫描入口；展示名片列表、图片缩略信息、搜索入口，点击进入详情；新增/删除应及时刷新列表。
- `[OBS]` CardHolder 顶部标题、搜索框、`All Cards` 计数、`Group`、`Manage`、新增 `+`；有卡时列表按日期，行显示缩略图/姓名/职位/公司。
- `[OPEN]` 真正 CardHolder 空列表 UI 文案、无卡时按钮位置。**不可将 Home 页 `My Digital Card` 的 `No cards yet` 作为该状态。** 禁止凭空模拟文案。
- 验收：T01、T02、T12、T13、T17。

### R02 单张采集与相册导入

- `[COURSE]` 相机预览、权限请求、拍照、相册、预览、返回/取消/重拍、权限拒绝和中途退出。
- `[DECISION]` 只实现 Single 和 Album；不实现 Batch/Multiple/QR、会员 High Accuracy。
- `[OBS]` CamCard 单张后续可到 `Edit Card`；Batch 的 `Next/Done` 不作为 Single 精确要求。
- 验收：T02～T05、T20。

### R03 名片区域识别、裁剪与校正

- `[COURSE]` 自动检测名片区域、显示边框、裁剪、透视/方向校正，支持手动调整、确认和重拍；覆盖倾斜/阴影/遮挡/复杂背景。
- `[OPEN]` 边界检测失败时的确切参考交互目前未知。保留课程硬性要求“手动调整、可恢复”；不编造四角还是八角等 UI 细节。
- 验收：T06、T20。

### R04 OCR 识别与可审计输出

- `[COURSE]` 支持中英双语、横竖版、不同字体/背景/多字段；保存原始图、OCR Raw Text、后续结构化字段与人工更正结果，支持错误分析。
- `[OBS]` `Recognition Languages / Change` 可选择识别语言；A 卡较好，B/C/D 有错字、漏字或字段误判。
- `[DECISION]` OCR 结果任何时候都不能未经人工确认直接当作可靠联系人记录。
- 验收：T07、T08 及固定测试集的字段级准确率统计。

### R05 结构化联系人解析

- `[COURSE]` 最少字段：Name、Company、Job Title、Mobile Phone、Office Phone、Email、Website、Address。多电话/多 Email、歧义和空字段应覆盖；T10 必须测试 Mobile / Office / Fax 情境（Fax 是课程允许的可选存储字段，但其分类处理必须接受测试）。
- `[COURSE]` 未出现的信息不得猜测或自动补全；不确定应保留空字段/未确定状态。
- `[OBS]` CamCard 曾将 C 卡 Office/Fax 归为 Mobile，D 卡 Company 与 Job Title 错分。这是差异分析案例，**不得直接复制为复刻 App 的期望正确结果**。
- 验收：T08、T09、T10。

### R06 Human-in-the-Loop 人工确认与更正

- `[COURSE]` 用户在保存前可修改姓名、公司、职位、手机、电话、Email、网站、地址；能处理空值、OCR 错字、多电话、多 Email、取消修改。
- `[OBS]` Edit Card 提供手动编辑，Full Name 有 First Name/Last Name/Phonetic 等输入，但**课程不要求复刻所有额外联系人字段**。
- `[DECISION]` 明确区分识别原值、用户编辑草稿、最终确认值；取消不污染已保存数据。
- 验收：T11、T12、T14、T20。

### R07 保存、详情与修改删除

- `[COURSE]` 本地保存 originalImage、processedImage、name、company、jobTitle、mobile、phone、email、website、address、tags、notes、createdAt；详情可看原图/字段，编辑、保存、删除、返回，电话/邮箱/网址可发起系统原生动作。
- `[OBS]` `Edit Card → Save → Card Saved → CardHolder / All Cards`；详情 `Card Details` 提供电话、地址、备注、编辑等功能。
- `[DECISION]` 对外链接使用系统功能，可在测试前确认意图，避免测试触发真实电话和邮件。
- 验收：T12、T13、T14、T17。

### R08 搜索、分组/标签、备注

- `[COURSE]` 按姓名/公司/职位/电话/Email 搜索；标签创建/分配/查看/删除；文本备注。
- `[OBS]` CardHolder `Group` 界面具有 `New a Group`、`Ungrouped`、手动分组；用户报告创建/分配/筛选/删除正常。`Note` 存在并且用户测试备注可被搜索。
- `[DECISION]` 使用可测的本地 Tag/Group 功能满足教师标签操作；**不实现**智能分组、Contact Log。
- `[OPEN]` 备注搜索是扩展于老师的五类查询字段，不作为必达标准；可以支持但不能替代老师五类字段搜索。
- 验收：T15、T16、T20。

### R09 本地持久化

- `[COURSE]` Kill App → Relaunch 后仍能查看原图、人工更正字段、标签、备注；禁止只用内存伪存储。
- `[OBS]` 用户已见原图和修改字段在重启后仍在；标签、备注持久化尚需验证。
- 验收：T18。

### R10 联系人导出

- `[COURSE]` 至少实现写入系统 Contacts **或**导出 VCF/vCard 一种。姓名、公司、职位、电话、Email、地址映射正确。
- `[OBS]` 参考 App 已观察到 `Save to Contacts(1)` 入口和权限申请；**但最终写入系统联系人及字段映射未验证**。
- `[DECISION]` 我们的 App **优先本地 VCF/vCard 导出**，不读取/上传用户通讯录，不开发会员 Export、云备份。验收重点是字段映射；不能让共享图片/微信 QQ 分享冒充导出。
- 验收：T19。

## 3. 统一数据草案（逻辑 Schema，尚非 Swift 代码）

```text
BusinessCardRecord
├─ id: 唯一标识（建议）
├─ originalImage: 原始图片
├─ processedImage: 校正/裁剪图片
├─ ocrRawText: OCR原始文字（课程可审计要求）
├─ parsedFields: OCR初始结构化结果（供差异分析）
├─ name: 最终姓名
├─ company: 公司
├─ jobTitle: 职位
├─ mobile: 手机号码（主）
├─ phone: 办公号码（主）
├─ emails: 邮箱（支持多个，课程要求多Email）
├─ website: 网站
├─ address: 地址
├─ fax: 可选，T10覆盖
├─ tags: 标签/分组关联
├─ notes: 普通文本备注
└─ createdAt: 创建时间
```

`[DECISION]` 多电话/多邮箱的实际存储结构（单项+数组、子记录等）在 Week 2 架构时确定，需同时满足老师的基础字段、T10 及 VCF 导出；此处只是逻辑要求，不应擅自作为代码接口强制让 TRAE 实现。

## 4. 验收总原则与测试数据集

- `[COURSE]` T01～T20 在限定范围内执行；确定性测试须 100% 通过。
- `[COURSE]` OCR/字段抽取具有概率性，不要求任意图片逐字与 CamCard 一致；须保存原始输出、字段解析、Ground Truth 对比、字段级准确率、参考结果比较及错误分析。
- `[COURSE]` **Week 1 工作清单要求建立 30～50 张测试名片和相应的 Ground Truth。** 课程第十四节同时**建议教师提供**统一测试集。这两点并不互斥：若尚未拿到教师统一数据，项目组需要自行准备可复现的虚拟/合成名片及真值，不应把任务无限期挂起。
- `[OPEN]` A～D 是先导观察样本；目前只有 4 张，**不能冒充已完成的 30～50 张数据集**。后续若教师提供统一数据集，应单独标注来源与版本，并用于正式比对。
- `[OPEN]` 字段正确率计算口径（缺失字段、多值匹配、号码归一化、姓名拆分等）和教师评分阈值尚待定义/确认；不得自称达标。
- `[OPEN]` 教师尚未给出精确 UI 对比容差；以正式要求补充。
- **历史快照（P002 / 2026-11-02）：当时代码完成度为0，T01～T20 全部 `NOT_RUN`，通过数0/20；该代码进度不代表当前状态。**

## 5. 未解决问题与变更控制

见 `docs/06_status_issues.md`。未经实测或老师说明，不可以把 `[OPEN]` 改成 `[OBS]`；任何规格变更同步更新追踪表与测试，再启动代码修改和回归。


## Week 2 收尾当前状态（2026-11-03）

P001～P012 及相关修复已执行；当前使用 Codex，早期使用 TRAE。原始需求、参考观察与验收标准不变。

- 已有原生 Xcode 工程、业务模型与 Mock 数据、CardHolder 列表/临时空态、只读详情导航、Repository 协议及内存/SwiftData 实现、持久化实体与映射器。
- 正常启动读取真实 SwiftData；DEBUG 手动保存虚拟名片后重读列表。用户人工确认多张测试名片分别保存、完全退出 App 后恢复。
- 已实现 PhotosPicker 单张相册选择、异步加载、等比例预览和关闭；P012 用户人工验收通过。图片仅用于预览，尚未写入名片数据库。
- P012 后30项自动化回归测试全部通过（模型6、内存仓库9、SwiftData仓库12、UI自动化3），来源为用户人工确认；此前并发警告消失亦由用户确认。本轮未运行测试，未读取对应 Xcode 原始测试报告，项目 records/evidence 目录中未见该报告归档。
- 正式相机、区域检测/透视校正、OCR、字段解析、人工核验/正式保存、完整编辑删除、搜索/标签/备注界面及 VCF 尚未完成。
- 仅完成开发保存与重启恢复验证，不代表完整数字化工作流或完整端到端持久化验收通过。T01～T20 全部 NOT_RUN（0/20）。

详见 [Week 2 总结与执行历史索引](08_week2_summary.md)。
