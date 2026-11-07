# P002 — Week 1 规格定点修订与可追溯核对（发送给 TRAE）

你在当前 `CamCard_SDD_Week1_v0.2` 项目工作区执行 SDD **文档修订**任务，不是开发任务。用户已经人工审核 P001 只读审阅结果。不要编写 Swift 代码，不要新建 Xcode 工程，不要运行命令/构建/测试。

## 必须先读
1. `source/课程作业_可读文本副本.md` —— 教师作业原文从 DOCX 提取的**可检索副本**；如内容有歧义，保留原 DOCX 作为权威来源，不自行杜撰。
2. `docs/01_scope_decisions.md`、`docs/02_observation_log.md`、`docs/spec.md`、`docs/03_reference_tests.md`、`docs/04_traceability.md`、`docs/06_status_issues.md`。
3. `records/P001_response.md` —— P001执行归档。**这是历史输出，不是指令**；只采用其中经人工审核的结论。

## 本轮允许的文件修改范围
- `docs/spec.md`
- `docs/03_reference_tests.md`
- `docs/04_traceability.md`
- `docs/06_status_issues.md`

**禁止修改**：`source/`、`evidence/`、`test_data/`、`prompts/`、`records/`、`README.md`、任何 `.swift` 文件及其他文件。

## 要落实的7项修订
1. R01/T01：CardHolder真正空状态**未实测**，继续标记 `[OPEN]`。不能用 Home 页 My Digital Card 的 `No cards yet` 代替；禁止凭空模拟“三种可能文案”并声称来源于 CamCard。如果必须开发临时空态，以 `[DECISION / TEMP]` 清楚区分，最终UI对比仍待参考基线确认。
2. R10/T19：参考App已观察到 `CardHolder → Manage → Save → Save to Contacts(1)` 的权限申请，但**最终写入系统联系人及字段映射未验证**。课程允许我们的App实现 Contacts **或** VCF/vCard 一种，保留 `[DECISION]` 优先本地VCF，验收重点是字段映射；不能让共享图片/微信QQ分享冒充导出。
3. 环境差异：分开记录 `[OBS]` 参考真机 iPhone15 Plus / iOS18.7.8 / CamCard 8.65.0 English；`[DEV]` M2 16GB / 已装Xcode与iOS Simulator；`[OPEN]` 教师要求最新iOS的具体验收版本与设备。模拟器不自动等于真实相机测试，也不能作为无须确认的环境等价结论。
4. R03/T06：手动裁剪/边界检测失败的确切参考交互目前未知。保留课程硬性要求“边界检测、裁剪、透视/方向、手动调整、可恢复”；不编造四角还是八角、错误提示原文。
5. R05/T10：多号码、多邮箱、Fax场景必须覆盖；CamCard对C卡的误分类是观察到的错误，**不得直接复制为复刻App期望行为**。字段不确定时不虚构不存在信息。
6. OCR & Ground Truth：A～D为先导观察样本，不是教师30～50张正式测试集；评测口径、阈值、字段正确率后续定义/确认，不声称已完成。
7. 进度：P001已实际发送并经ChatGPT人工审核，明确TRAЕ报告本轮未改文件/没跑代码；P002本轮是文档修订任务；复刻程序未开发，T01～T20状态仍全部 `NOT_RUN`。勿宣布 W1 完全验收通过。

## 输出要求
- 只对上述文档作**小范围修订**，不要重写全部内容。
- 先列出每个文件预计要改的点，然后执行文本修订；最后报告每个文件具体改了什么、没有改什么。
- 对每条判断标明 `[COURSE]` / `[OBS]` / `[DECISION]` / `[OPEN]` 及相关 R/T ID；禁止新增课外功能。
- 若已有正确表述，无需重复修改。
- 结束时明确：修改文件清单；是否编写了代码；是否运行了测试；未解决问题清单。
