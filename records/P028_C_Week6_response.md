# P028-C 执行记录

- 更新 [Reference Tests](../docs/03_reference_tests.md)、[需求追踪](../docs/04_traceability.md)和[交付台账](../docs/06_status_issues.md)，新增[本轮 Prompt](../prompts/P028_C_Week6_final_sdd_review.md)与本记录。
- T01、T02、T04、T05、T06 为 PASS，共 5 项。其余 15 项为 NOT_RUN，FAIL 与 BLOCKED 均为 0。T04 依据用户确认的 iOS 18 真机实拍及后续扫描主路径，未覆盖未报告的重拍、取消和权限子场景。
- R01～R10 均已关联实现模块、测试 ID 和验证状态。覆盖矩阵完整，逐项正式验收证据仍有缺口。权限拒绝与恢复、电话和邮件系统操作、失败 OCR 的界面恢复、VCF 接收端核验及 Golden 截图仍待取证。
- 正式 OCR 的真值、36 条采集记录和 CSV 齐备。字段准确率 51.5267%，字段值召回率 52.3985%。F31 无文字仍参与评分，独立正式 XCTest 在写出附件后触发失败断言。先导 56.00% 和约 57.69% 来自用户报告，先导 JSON 和 CSV 仍未找到。没有新增证据路径，故保留 [OCR 报告](../docs/12_week6_ocr_evaluation.md)原文。校正后准确率和 CamCard 同批比较未量化。
- 截至本轮，69 份编号任务 Prompt 与 59 份 Response。缺失的十份 Response 对应 P003、P004、P005、P006、P007、P008、P008-F01、P009、P009-F01、P009-F02。另有一对 W2_CLOSEOUT。已区分用户验收、TRAE 原始归档、Codex 协作和归属未知的早期记录。
- 范围外文档后续可加历史快照标识或链接当前记录。`spec.md` 末尾仍有 Week 2 进度，`docs/10_week6_acceptance_log.md` 保留准备状态，`docs/11_week6_final_acceptance_summary.md` 记录 P028-A 时点的 4 项 PASS 和真机待验证。
- 业务代码未修改。构建、测试及评估重跑均为 NOT_RUN。
