# CamCard SDD + TRAE 课程项目 — Week 1 基线包 v0.2

> 更新时间：2026-11-02 ｜阶段：Week 1（黑盒观察后首次规格整理）｜性质：**工作基线草案，不是已验收成果**。

## 项目目标
依据《移动应用开发课程作业-v2》使用 SDD + TRAE，对 CamCard（名片全能王）“名片数字化与联系人管理”功能切片进行限定范围内的黑盒复刻；交付可运行 iOS 工程、完整 TRAE 提示词及过程文档。禁止直接用一个提示词生成整个 App。

## 来源与证据
- `source/移动应用开发课程作业-v2.docx`：**唯一课程范围与验收规则来源**。
- `source/任务11：搜索名片.md`：用户的原始手写观察笔记（含失效的 Windows 本地图片路径，原文件保留作历史记录）。
- `evidence/`：用户提供的 CamCard 真实操作截图；**只能作观察证据，不能作为需要复制到复刻 App 的受保护素材**。
- `test_data/CamCard_TestCard_*.png`：首轮虚拟名片 A～D，**不是**30～50 张教师测试集，也不等于自动确认的 OCR Ground Truth；应按可见卡面逐项复核。

## 阅读顺序
1. `docs/01_scope_decisions.md` — 范围与禁止扩张清单。
2. `docs/02_observation_log.md` — 已观察行为、截图依据、待验证内容。
3. `docs/spec.md` — SDD 需求规格（v0.1 草案）。
4. `docs/03_reference_tests.md` — T01～T20 可执行测试计划（**均未标为通过**）。
5. `docs/04_traceability.md` — 需求、观察、测试的追踪关系。
6. `docs/05_sdd_workflow.md` — 6周工作流、TRAE 与 Xcode 职责及质量门槛。
7. `docs/06_status_issues.md` — 进度台账与剩余问题。
8. `prompts/P001_week1_review_only.md` — 已执行的第一条只读审阅提示词。
9. `records/P001_response.md` — P001 TRAE回复及人工审核归档。
10. `source/课程作业_可读文本副本.md` — 原课程DOCX自动提取的可检索副本，仅辅助AI读取。
11. `prompts/P002_week1_targeted_spec_revision.md` — 下一条待发送的规格定点修订提示词。
12. `prompts/prompt_log.md` — 完整提示词实际使用状态。

## 下一步
1. 将 v0.2 解压到 Mac 的项目目录，**保留 v0.1 作为原始备份**。
2. 在 TRAE 使用 `File → Open Folder...` 打开 **v0.2 整个文件夹**。
3. 查看 `records/P001_response.md` 与 `source/课程作业_可读文本副本.md`；确认存在即可。
4. 发送 `prompts/P002_week1_targeted_spec_revision.md` 全文，这一轮**仅修订指定Markdown规格**，不准写代码。
5. 将TRAЕ回复完整交给ChatGPT审核。

## 测试环境差异
参考观察：iPhone 15 Plus、iOS 18.7.8、CamCard 8.65.0、English；开发 Mac：Apple M2、16GB、Xcode + TRAE，新版 iOS Simulator 已安装。课程要求“最新版 iOS”，目前由模拟器承担新版测试；这不自动等于真机完全一致，最终统一验收环境仍要确认。

## 交付归档要求
持续保留三大类别：（1）可运行最终工程，（2）**所有实际发给 TRAE 的提示词**及执行结果，（3）各种规格、架构、测试、差异分析、回归与 AI 协作记录。不能事后依赖记忆补录。
