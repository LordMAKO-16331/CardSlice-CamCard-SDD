# TRAE 提示词完整使用归档（持续更新）

**归档原则：**区分计划写好的提示词与“用户实际发送给TRAE”的原文；禁止预先记为已用。所有失败/返工/修复Prompt都需要原文与测试结果，不得删除。

| Prompt ID | 所属阶段 | 任务 | 文档原文 | 当前状态 | TRAE回复位置 | 实际修改 | Xcode实测 |
|---|---|---|---|---|---|---|---|
| P001 | W1 | SDD规格只读审阅 | `P001_week1_review_only.md` | **REVIEWED / 已执行并审核** | `../records/P001_response.md` | 未修改（TRAE自报） | 不适用 |

| P002 | W1 | 规格定点修订 | `P002_week1_targeted_spec_revision.md` | **DRAFT / 待发送** | 未收到 | 限定Markdown文件 | 不适用 |

## 使用后追加模板（复制新条目）
```text
Prompt ID：P00x
阶段：Week x / 功能需求Rxx / 测试Txx
目标：
完整实际发送提示词：见 prompts/P00x_*.md（如果发送时改了字，保存实际发送版）
发送日期与时间：
TRAE完整回复：见 records/P00x_response.md（新建后关联）
修改文件清单：
构建方式与实际结果：
测试结果与证据：
缺陷/修复Prompt ID：
人工验收人/结果：
状态：DRAFT / SENT / REVIEWED / PASS / FAIL / BLOCKED
```

**当前真实发送总数：1条（P001）。P002为草稿，尚未发送。**
