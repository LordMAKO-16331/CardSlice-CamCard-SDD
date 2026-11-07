# 07 CamCard 名片数字化与联系人管理 — 架构设计 v0.2

> 日期：2026-11-02  
> 阶段：Week 2 — Architecture Design  
> 历史状态（P003 / 2026-11-02）：架构初稿经人工审阅后修订，当时尚未初始化 Xcode 工程。当前已实现状态见下方 Week 2 同步节。  
> 依据：`docs/spec.md`、`docs/03_reference_tests.md`、`docs/04_traceability.md` 及课程原始要求。

## A. 架构目标与边界

### A.1 项目目标 [COURSE]

采用 SDD + TRAE 完成 CamCard 限定功能切片的黑盒复刻。

业务流程为：

1. 进入 CardHolder 名片夹。
2. 单张拍摄或相册导入名片。
3. 检测名片区域，进行裁剪、透视和方向校正。
4. 执行 OCR 并保留原始文字。
5. 解析结构化联系人字段。
6. 用户人工核验和修改。
7. 本地保存名片。
8. 查看详情，进行搜索、标签管理、备注、编辑和删除。
9. 退出并重启 App 后恢复数据。
10. 导出 VCF/vCard 联系人。

所有确定性功能以 R01～R10、T01～T20 为验收依据。OCR 和字段解析需另行进行 Ground Truth 量化评价。

### A.2 排除功能 [COURSE / DECISION]

不实现注册登录、会员、支付、云同步、CRM、数字名片制作、QR 交换、批量扫描、商业 AI 助手、Contact Log、智能分组或其他非本次功能切片内容。

不复制 CamCard 的 OCR 误分类结果作为正确目标，也不复刻其受版权保护的资源或内部实现。

## B. 技术架构与选型

### B.1 架构模式 [DECISION]

使用 Swift + SwiftUI，以 MVVM 和独立服务层组织项目。

- View：负责界面展示和交互。
- ViewModel：管理页面状态，调用服务与 Repository。
- Service：负责图像处理、OCR、字段解析、导出等独立逻辑。
- Repository：对上层提供统一的数据访问接口。
- Persistence：负责数据真正落盘及重新读取。

ViewModel 不直接操作底层数据库，也不直接实现 OCR 算法。

### B.2 苹果原生框架

| 功能 | 拟采用技术 | 主要职责 |
|---|---|---|
| UI 与导航 | SwiftUI | 页面、列表、表单、导航 |
| 相机 | AVFoundation | 相机预览、授权、单张拍摄 |
| 相册 | PhotosUI / PhotosPicker | 选择并导入单张图片 |
| 名片边界检测 | Vision | 识别矩形区域及位置 |
| 透视校正 | Core Image | 根据检测或人工调整的角点进行变换 |
| OCR | Vision / VNRecognizeTextRequest | 文字识别、原始输出及中英语言设置 |
| 本地存储 | SwiftData | 名片、标签及关联数据持久化 |
| VCF 导出 | Contacts / CNContactVCardSerialization | 生成、解析和验证 vCard |
| 文件分享/保存 | 系统文件分享接口 | 交付真正的 `.vcf` 文件 |
| 单元测试 | XCTest 或当前 Xcode 支持的测试框架 | 模型、Repository、字段映射测试 |

以上均为技术方案 `[DECISION]`，不是教师强制指定的实现框架。

原则上不引入第三方网络 OCR 服务，不要求上传用户名片到远端服务器。

### B.3 需要实际验证的能力 [OPEN]

- 当前安装的 Xcode、SDK 和模拟器版本。
- Vision 在目标环境支持的中英文识别语言。
- SwiftData 在目标 SDK 上的兼容性。
- 真机相机预览、拍摄、旋转及权限处理。
- VCF 在系统联系人中的最终字段解析效果。

## C. 模块划分与依赖

以下为计划结构，不表示必须在 P004 一次创建全部文件。

### C.1 UI 层

| 模块 | 职责 | 追踪 |
|---|---|---|
| CardHolderView / ViewModel | 列表、空态、搜索入口、刷新 | R01、T01/T12 |
| ScannerView / ViewModel | 相机、单张拍摄、相册入口 | R02、T02～T05 |
| ImageProcessView | 显示检测结果及人工校正界面 | R03、T06 |
| CardEditView / ViewModel | 编辑 OCR 草稿及已保存字段 | R06、T11/T14 |
| CardDetailView | 图片、字段、备注与操作入口 | R07、T13 |
| GroupTagView | 创建、分配、筛选、删除标签 | R08、T16 |
| SearchView / SearchService | 按指定字段搜索 | R08、T15 |

### C.2 服务层

| 模块 | 单一职责 | 追踪 |
|---|---|---|
| ImageProcessor | 检测矩形、裁剪、透视与方向校正 | R03、T06 |
| OCRService | 输出原始识别文字及诊断信息 | R04、T07 |
| FieldParser | 将文字分类为结构化字段 | R05、T08～T10 |
| VCardExporter | 创建 VCF 文件并验证字段映射 | R10、T19 |
| PermissionManager | 相机授权状态及必要的权限引导 | R02、T03 |

### C.3 数据层

| 模块 | 单一职责 | 追踪 |
|---|---|---|
| BusinessCardRecord | 已保存名片的数据实体 | R07/R09 |
| CardDraft | 未保存或正在编辑的临时数据 | R06、T11 |
| ParsedContactFields | OCR 初始结构化结果 | R05、T08～T10 |
| CardRepository | 名片增删改查及查询接口 | R07～R09 |
| SwiftDataStore | Repository 的本地持久化实现 | R09、T18 |
| TagRecord | 标签的稳定标识、名称及关联 | R08、T16 |

### C.4 依赖原则

- View 依赖 ViewModel。
- ViewModel 依赖 Repository 协议和相关 Service 协议。
- Repository 的具体实现依赖 SwiftData。
- FieldParser 不依赖 SwiftUI、数据库或相机。
- OCRService 不负责自动保存联系人。
- VCardExporter 只接收已确认的联系人字段。
- 测试可使用 Mock Repository 替换真实存储。

避免在模块之间直接共享未定义的全局可变状态。

## D. 数据模型与接口契约

### D.1 已保存名片 BusinessCardRecord

| 字段 | 逻辑类型 | 说明 |
|---|---|---|
| id | UUID | 唯一标识 |
| originalImage | 图片数据或持久引用 | 原始名片图 |
| processedImage | 图片数据或持久引用 | 校正后的名片图 |
| ocrRawText | String | 原始 OCR 文字 |
| parsedFields | ParsedContactFields | 自动解析的初始结果 |
| name | String | 最终确认的姓名 |
| company | Optional String | 公司 |
| jobTitle | Optional String | 职位 |
| phones | PhoneEntry 集合 | 所有电话号码及类别 |
| emails | String 集合 | 支持多个 Email |
| website | Optional String | 网站 |
| address | Optional String | 地址 |
| tagIDs | 标签标识集合 | 与标签记录关联 |
| notes | Optional String | 普通文本备注 |
| createdAt | Date | 创建时间 |
| updatedAt | Date | 最近修改时间，方案补充字段 |

此表表示逻辑模型，不强制 SwiftData 必须逐字采用上述字段声明。

### D.2 PhoneEntry：电话号码结构

每个电话号码至少包含：

- `value`：号码原文或人工修正后的值。
- `type`：Mobile、Office、Fax、Other 中的一种。
- `label`：必要时保留原始标签。

单张名片允许存在多个 PhoneEntry，且允许多个号码属于同一类别。

不得只保留一个 Mobile、一个 Office 和一个 Fax 后丢弃其余号码。

### D.3 ParsedContactFields：OCR 初始解析数据

初始解析结果与最终用户确认值必须分开。

解析结果至少覆盖：

- 姓名、公司、职位。
- 电话号码集合及初步分类。
- 多个 Email。
- Website、Address。
- 无法确认的原始文本片段。
- 必要的识别来源及不确定状态。

规则：

1. 没有可靠依据的字段保持空值或不确定状态。
2. 不允许根据常识编造未出现在图片中的网址、号码、公司等。
3. 解析错误允许用户手动更正。
4. 原始 OCR 文本不得因用户编辑而被覆盖。
5. 字段解析结果需要能与 Ground Truth 逐项比较。

### D.4 CardDraft：编辑中的草稿

CardDraft 负责保存尚未提交的表单内容。

- 新识别名片进入 Draft，而非直接成为持久记录。
- 保存动作成功后才更新 Repository。
- 用户取消已保存名片的修改时，原记录保持不变。
- 保存失败时保留编辑草稿并显示错误。
- OCR 失败时允许在已采集图像基础上手动补录字段或重新拍摄。

不额外开发独立的数字名片制作系统。

### D.5 本地持久化方案 [DECISION]

优先使用 SwiftData 保存记录、标签、备注、字段以及 OCR 结果。

图片存储的实施建议：

- 优先评估 SwiftData 外部二进制存储选项，而非无条件把所有大图片嵌入普通数据库行。
- 必须同时保留 originalImage 和 processedImage。
- 创建、读取、更新、删除都通过 Repository 完成。
- 删除名片应清理不再引用的图像资源。
- 任何图片存储优化不得造成原图丢失。
- 如实施中改用 App 沙盒文件存储，则必须明确文件引用、写入失败恢复及清理规则，并记录技术决策。

最终通过真实落盘、重新加载和 Kill/Relaunch 测试验证，不能只依赖内存 Mock。

### D.6 标签与备注

- TagRecord 具有稳定 ID 和名称。
- 一张名片可关联多个标签。
- 删除标签时，只删除标签及其关联关系，不删除名片。
- Notes 是普通文本，随名片持久化。
- 搜索至少涵盖姓名、公司、职位、电话、Email。
- 备注搜索可选，不能替代必做字段搜索。

### D.7 Repository 契约

Repository 至少提供以下行为：

- 新增名片。
- 按 ID 读取名片。
- 获取全部名片。
- 更新名片。
- 删除名片。
- 按五类必做字段搜索。
- 创建、列出、分配及删除标签。
- 读取和保存备注。
- 返回明确的存储错误。

所有写操作应有可验证的成功或失败结果。

### D.8 VCF 导出契约

流程：

1. 获取已经人工确认的 BusinessCardRecord。
2. 将联系人字段映射到 Contacts 联系人对象。
3. 生成合法的 vCard 数据。
4. 写出 `.vcf` 文件。
5. 允许用户使用系统文件分享或保存功能。
6. 通过重新解析生成文件，核验字段是否正确保存。

至少验证：

- 姓名。
- 公司。
- 职位。
- Mobile、Office、Fax 及多号码。
- 多个 Email。
- 地址。

姓名拆分不能擅自猜测；应确保中文和英文完整姓名在导出与导入后均能正确保留。

导出失败应返回错误，不得把分享图片视为成功导出联系人。

## E. 页面、状态与异常处理

### E.1 主要导航

CardHolder → Scanner / Album → ImageProcessing → OCR → CardEdit → Save → CardHolder → CardDetail。

CardHolder 同时可进入搜索及标签管理。

CardDetail 可进入编辑、备注、删除及导出操作。

所有页面必须有合理的返回和取消路径。

### E.2 主要状态

| 状态 | 说明 |
|---|---|
| EmptyHolder | 当前没有已保存名片 |
| HolderList | 正常列表或查询结果 |
| Acquiring | 拍摄或相册选择中 |
| CapturePreview | 已获取图片，等待确认或重拍 |
| Cropping | 自动或手动校正中 |
| Recognizing | OCR 执行中 |
| EditDraft | 未保存的字段编辑 |
| SavedDetail | 已保存记录详情 |
| EditingSaved | 已保存名片的编辑状态 |
| Exporting | VCF 生成或导出中 |
| OperationFailed | 操作失败且应提供恢复路径 |

### E.3 异常与恢复原则

**空名片夹**

[OPEN] 未观察到参考 App 真正的 CardHolder 空状态。开发临时界面必须标记 `[DECISION/TEMP]`，不得冒充参考截图。

**相机权限拒绝**

提供原因说明和系统设置入口，不能无限循环申请权限。

**相册操作**

采用 PhotosPicker 时，用户选择图片通常不需要授予整个相册读取权限。取消选择不得创建名片。

只有未来实际采用需要更广泛相册权限的 API，才需要针对该 API 设计相册授权拒绝流程。

**边界检测失败**

允许用户检查图片、手动调整有效区域或重拍。默认角点样式属于 `[DECISION]`，不得写成已验证的 CamCard 行为。

**OCR 失败或结果为空**

保留图像，显示可恢复状态，允许重新识别、重拍或人工录入已观察到的字段。

**保存失败**

展示错误，保留草稿，不产生只有部分字段或图片的错误记录。

**删除操作**

支持确认和取消；取消不得影响原记录，确认后列表与持久化同步更新。

**模拟器限制**

模拟器验证导航、数据、相册导入、OCR 静态图及大部分数据操作。真实相机拍摄需要支持相机的真机完成验证。

## F. Week 2 最小开发顺序

本节保留 P003 当时拟定的开发顺序；当前进度见 Week 2 同步节，不将此计划视作当前待办。

| 阶段 | 最小任务 | 验收条件 |
|---|---|---|
| W2-1 | Xcode 工程初始化 | SwiftUI App 可以构建并在模拟器启动，记录 Xcode/SDK/目标版本 |
| W2-2 | BusinessCard 逻辑模型及 Mock Data | 模型可表达多电话、多邮箱、缺失字段；基础模型测试通过 |
| W2-3 | CardHolder 空态和有卡列表 | 可在 Mock 数据有无两种情况下切换；T01相关行为可预检 |
| W2-4 | 详情页及页面导航 | 能从列表进入详情、返回，未实现入口不伪装成已完成 |
| W2-5 | Repository 接口及本地实现 | 能新增、读取、修改、删除测试名片，错误路径可测试 |
| W2-6 | 首轮持久化与回归检查 | 重启后能读取测试记录，保留测试日志与失败信息 |

每步只开放必要的文件修改权限，不允许 TRAE 一次性实现全部模块。

Week 2 不提前实施完整 OCR、相机裁剪或批量扫描。

测试结果必须区分单元测试、手工预检和 Reference Test Suite 正式测试。未执行的 T01～T20 仍保持 NOT_RUN。

## G. 风险、数据集与待确认事项

| ID | 风险 | 处理策略 |
|---|---|---|
| Q01 | 教师最终 iOS / 设备环境未确定 | 记录开发环境，正式验收前确认 |
| Q02 | CardHolder 空态未实测 | 保留 OPEN，先用明确标记的临时设计 |
| Q03 | Single 裁剪与失败交互观察不完整 | 后续定点补测 |
| Q04 | 参考 App Group/Note 重启持久化尚未完整验证 | 自身项目仍必须满足课程持久化要求 |
| Q05 | Contacts 写入参考行为未验证 | 采用 VCF 路线并测试映射 |
| Q06 | 30～50张名片及 Ground Truth 未完成 | 自建虚拟开发测试集，区分教师正式验收集 |
| Q07 | OCR 准确率指标尚未最终确定 | 建立统一字段级计分口径 |
| Q08 | Git 与工程备份尚未落实 | 工程初始化阶段完成 |

测试集需要覆盖中文、英文、双语、横竖版、复杂背景、不同质量、多电话、多邮箱、Fax、歧义字段及缺失字段。

所有样本使用虚拟身份和联系方式，不使用未经许可的个人资料。

## H. 验收与变更控制

1. 架构文档通过人工审核后，才允许实现正式工程。
2. 每次 TRAE 修改必须记录实际发送的完整 Prompt。
3. 每次实施后应检查实际文件、构建与测试输出。
4. 不允许把 TRAE 声称的成功当作真实验收。
5. 任何架构变更须说明原因、影响模块、对应 R/T ID。
6. 确定性测试最终要求 T01～T20 全部通过。
7. OCR 与字段抽取须保留原始输出、Ground Truth、错误分析和量化结果。

**P003 时点历史状态（不代表当前进度）：**

- P001：已完成。
- P002：已完成。
- P003：已执行，架构文档经人工修订。
- P004：未执行。
- Xcode 正式工程：未创建。
- T01～T20：全部 NOT_RUN。

本版 v0.2 为 ChatGPT 对 TRAE P003 产物的人工审核修订，不应误记为 TRAE 自行生成或新的已发送 Prompt。

## I. Week 2 实际架构同步（2026-11-03）

## Week 2 收尾当前状态（2026-11-03）

P001～P012 及相关修复已执行；当前使用 Codex，早期使用 TRAE。原始需求、参考观察与验收标准不变。

- 已有原生 Xcode 工程、业务模型与 Mock 数据、CardHolder 列表/临时空态、只读详情导航、Repository 协议及内存/SwiftData 实现、持久化实体与映射器。
- 正常启动读取真实 SwiftData；DEBUG 手动保存虚拟名片后重读列表。用户人工确认多张测试名片分别保存、完全退出 App 后恢复。
- 已实现 PhotosPicker 单张相册选择、异步加载、等比例预览和关闭；P012 用户人工验收通过。图片仅用于预览，尚未写入名片数据库。
- P012 后30项自动化回归测试全部通过（模型6、内存仓库9、SwiftData仓库12、UI自动化3），来源为用户人工确认；此前并发警告消失亦由用户确认。本轮未运行测试，未读取对应 Xcode 原始测试报告，项目 records/evidence 目录中未见该报告归档。
- 正式相机、区域检测/透视校正、OCR、字段解析、人工核验/正式保存、完整编辑删除、搜索/标签/备注界面及 VCF 尚未完成。
- 仅完成开发保存与重启恢复验证，不代表完整数字化工作流或完整端到端持久化验收通过。T01～T20 全部 NOT_RUN（0/20）。

详见 [Week 2 总结与执行历史索引](08_week2_summary.md)。

### 实际依赖与生命周期

- CardSliceApp 的 @StateObject AppDatabase 强持有可选 ModelContainer 和 Repository；正式模式创建磁盘容器并将 mainContext 显式注入 SwiftDataCardRepository。初始化失败显示明确错误，不回退 Mock；局部变量处理 do/catch 后统一赋值 let 属性。
- ContentView → CardHolderView → @StateObject CardHolderViewModel → @MainActor CardRepository。ViewModel 负责 loading / loaded（含空数组）/ failed 状态、重试及 DEBUG insert → fetchAll 流程；详情接收 BusinessCardRecord 只读展示。
- CardRepository 目前实际仅提供 fetchAll、fetch(id:)、insert、update、delete。D.7 的搜索和标签管理仍是目标契约，并非已提供接口。当前没有独立 SwiftDataStore 类型，实际实现为 SwiftDataCardRepository。
- BusinessCardRecord、PhoneEntry、ParsedContactFields、TagRecord 是业务数据类型。PersistedBusinessCard 是 SwiftData @Model；图片字段使用 externalStorage，集合/初始解析结果以 JSON Data 经 BusinessCardPersistenceMapper 映射。仅具备字段与存储能力不代表图像工作流已打通。
- 仅 DEBUG 识别 --ui-testing-mock-cards，创建独立 InMemoryCardRepository(initialRecords: MockBusinessCards.samples)，该分支不创建正式容器。UI 测试使用该参数；DEV 按钮在此模式隐藏。正常启动不自动插入 Mock 数据。
- CardHolderView → sheet CardImageImportView → PhotosPicker 单选 → 异步 Data 加载 → UIImage 解码与 scaledToFit 预览。图片保留于当前视图状态，取消/关闭不创建名片；不请求整个相册权限。读取/解码错误有提示，但故障分支的逐项人工验收详情 UNKNOWN。
- 列表缩略图和详情图片仍为临时占位；真实图片未随相册导入落盘。相机、ImageProcessor、OCRService、FieldParser、CardDraft 编辑流程、搜索/分组管理及 VCardExporter 仍待实现。

### 测试隔离与修复

SwiftData 测试使用 TestDatabase 同时持有容器和仓库，并以 defer / withExtendedLifetime 覆盖异步操作；磁盘测试在两个独立作用域重建同路径容器。模型测试套件显式 @MainActor。开发测试30项通过与警告消失来自用户人工确认，不等同 T01～T20 验收。
