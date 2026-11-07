# P003 — Week 2 / SDD 架构设计（仅创建架构文档）

## 角色与边界
你正在当前打开的 CamCard SDD 项目工作区执行 **Week 2 的第一项：架构设计**。这不是实现指令。

**本轮唯一允许新建/修改的文件：`docs/07_architecture.md`**。如文件存在，先检查其内容，避免覆盖已完成且有效的信息。不得修改 `docs/spec.md`、其余 `docs/` 文件、`source/`、`evidence/`、`prompts/`、`records/`、`test_data/`、README 或任何源代码。

**禁止**创建 Xcode 工程、生成 `.swift` 文件、编写实现代码、运行终端命令、Git 命令、构建或测试；不得声称已运行测试。T01～T20 仍全部 `NOT_RUN`。

## 第一阶段：恢复上下文并核验 P002（必须先完成）
逐一阅读：
1. `source/课程作业_可读文本副本.md`（课程原文转换件；若同原 DOCX 存在歧义，以教师原文为准）；
2. `docs/01_scope_decisions.md`、`docs/02_observation_log.md`；
3. `docs/spec.md`、`docs/03_reference_tests.md`、`docs/04_traceability.md`、`docs/05_sdd_workflow.md`、`docs/06_status_issues.md`；
4. `records/P001_response.md`、`records/P002_response.md`。

在准备任何架构设计前，**只读检查** P002 报告中声称的四份文件是否确有相应修订，至少核对：
- `[OBS] / [DEV] / [OPEN]` 环境差异；
- R01/T01 真正 CardHolder 空态待验证，不能把 Home 的 My Digital Card 空态作为参考；
- R03/T06 未凭空指定裁剪点数与错误文案；
- R05/T10 处理 Mobile、Office、Fax、多邮箱，参考 App 的错误不是预期正确行为；
- R10/T19 允许本地 VCF 或系统 Contacts 至少一种，参考 App Contacts 最终写入尚未验证；
- 正式 30～50 张测试集和 Ground Truth 尚未给出；T01～T20 全是 `NOT_RUN`。

若发现**关键缺失、矛盾或指定文件不存在**：**停止本轮，不创建架构文档**，只回复具体文件、章节、缺口、建议；不可自行修改旧规格。

## 第二阶段：只设计 Week 2 架构
如上述核验通过，新增 `docs/07_architecture.md`，用中文编写结构清晰、可审阅的架构方案，至少包括：

### A. 目标及明确不做的功能
- 只围绕课程 R01～R10 和 T01～T20。
- 核心流程：CardHolder → Single/Album → 检测/校正 → OCR → 字段解析 → 人工核验 → 本地保存 → 详情/搜索/分组/备注 → 重启保留 → 本地 VCF 导出。
- 不实现数字名片创建、Batch/Multiple/QR、High Accuracy会员、Contact Log、AI助手、智能分组、云同步/CRM、会员/支付、会议功能、额外导出服务。

### B. 技术选型（提出明确建议与理由，但不得冒充教师硬性要求）
- Swift + SwiftUI 是否适用，MVVM 或其他更简单架构如何划分职责；
- 相机/照片导入、图像区域检测与透视校正、OCR、数据持久化、VCF 导出分别拟使用哪些苹果系统框架；
- 是否需要外部依赖，优先避免不必要的第三方服务与网络传输；
- 每项用 `[COURSE]` / `[OBS]` / `[DECISION]` / `[OPEN]` 标记依据；
- 不得编造 Xcode 版本、已安装 SDK、模拟器机型或真机设备能力。若需实际环境信息，列为验收前检查事项。

### C. 模块划分与文件结构（仅设计，不落地）
建议列出每个模块的单一职责、预期文件名、依赖关系和对应 R/T ID，至少涵盖：
CardHolder、Capture/Album、ImageProcessing、OCR、FieldParser、Edit/Review、BusinessCardModel、Repository/Persistence、Search、Group/Tag、Note、VCardExport、Permissions、Tests。

### D. 数据模型与接口契约（只用字段表/接口描述或简短伪代码，不写 Swift）
- 原始图、处理图、OCR Raw Text、初次解析字段、最终人工确认字段必须可区分且可追溯；
- 姓名、公司、职位、Mobile、Office、Fax、多电话、多邮箱、网站、地址、Tags、Notes、CreatedAt；
- 哪些字段允许空值、哪些支持多个值；不确定字段不得自动臆造；
- 数据落盘后 Kill/Relaunch 能恢复原图、修改后字段、Group 和 Note；
- VCF 导出必须支持课程指定字段，并定义可独立检验的映射。

### E. 页面/状态设计及异常路径
- 只设计限定功能切片页面；把已实测 UI 与未实测 UI 严格分开；
- 首次 CardHolder 空态、权限拒绝、相册取消、裁剪失败、OCR 失败、字段缺失、保存与删除取消、导出失败如何处理；
- 模拟器可以验证的行为与需要真机相机验证的行为分开。

### F. Week 2 最小开发顺序和验收门槛
按小步安排，明确每步要完成的文件、关联 R/T、验收检查点：
1. 工程初始化与最小可运行 SwiftUI App；
2. BusinessCard Model + 只读 Mock Data；
3. CardHolder 列表/空态临时设计（标注 `[DECISION/TEMP]`）；
4. 详情页及导航；
5. Repository 接口与对应单元测试；
6. 首批构建与回归记录。
- Week 2 不提前做 OCR 或批量扫描。
- 只提出顺序，本轮不执行。

### G. 风险和待确认事项
至少包含：Q01 最新 iOS 验收环境、Q02 真实空态、Q03 裁剪/失败交互、Q05 Contacts参考验证/VCF差异、Q06 Ground Truth、照片权限差异、模拟器不具备实拍相机。

## 最终汇报（发在对话中）
1. P002 核验结果：四份文件逐一 PASS / 具体差异；
2. 是否创建 `docs/07_architecture.md`，其主要章节与选型建议；
3. 本轮真实修改文件清单（应当最多 1 个）；
4. 是否创建代码、运行命令、执行测试（应全部为“否”）；
5. 下一步最小实现任务及验收条件，**不要擅自开始**。
