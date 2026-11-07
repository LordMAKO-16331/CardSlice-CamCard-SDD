# P028-C — Week 6：最终 SDD、Reference Tests 与交付状态整理

## 一、任务背景

项目：CardSlice，CamCard 名片数字化功能黑盒复刻。

当前状态：

- App 核心功能已实现并经过阶段性手动验证。
- iOS 18 真机拍照已成功验证。
- 独立 OCR 批量采集工具已运行。
- A～D 四张先导名片已完成评估。
- F01～F36 三十六张合成名片已完成评估。
- OCR 评估及 AI 能力边界报告已生成：\
  `docs/12_week6_ocr_evaluation.md`

本轮目标：整理最终 SDD、测试追踪关系、验收状态和 AI 协作记录，为课程演示与交付做准备。

不再进行 App 开发。

## 二、首先进行只读审查

检查现有：

- docs/spec.md
- docs/01_scope_decisions.md
- docs/02_observation_log.md
- docs/03_reference_tests.md
- docs/04_traceability.md
- docs/06_status_issues.md
- docs/12_week6_ocr_evaluation.md
- evaluation/ 下的评估文件
- prompts/ 下的实际 Prompt
- records/ 下的实际执行记录

根据实际存在的文件进行审查，不假定所有历史文件均已保存。

## 三、整理 Reference Tests

检查 T01～T20 的实际记录。

区分以下状态：

- PASS：有明确测试证据。
- FAIL：测试确实失败。
- NOT_RUN：未执行。
- BLOCKED：受到环境限制而无法验证。

如果已有文件使用另一套状态定义，应先遵守既有规范，不擅自混用。

要求：

1. 只根据现有执行记录和用户已经确认的操作更新。
2. 不得仅因为功能已实现就标记 PASS。
3. 真机相机拍照成功可以如实记录。
4. 模拟器不支持真实相机不能直接认定 App 功能失败。
5. 电话、邮件、权限拒绝、强制识别失败等特殊路径，不得虚构测试结果。
6. F31 的 OCR 识别失败必须保留。
7. 独立正式 OCR 测试因 F31 报错的事实必须保留，不得写成整个 XCTest 全部 PASS。

没有明确证据的项目保留待验证状态。

## 四、整理需求追踪关系

审查：

`docs/04_traceability.md`

确保：

需求 → 实现模块 → 测试编号 → 实际验证状态

之间的对应关系一致。

核对现有功能：

- CardHolder 列表
- 单张相机拍摄
- 相册导入
- 名片检测与裁剪
- OCR 识别
- 字段解析与人工编辑
- 保存与详情
- 搜索、分组、备注
- 删除
- 联系人或 vCard 导出

不得增加原始课程范围之外的新要求。

不得修改需求编号或历史范围决策。

## 五、归档 OCR 评估

检查最终报告是否准确记录：

- 先导 A～D：字段准确率 56.00%，召回率约 57.69%。
- 正式 F01～F36：字段准确率 51.5267%，召回率 52.3985%。
- F31：未识别出文字。
- 正式测试为自行生成的合成数据。
- 人工校正后的准确率尚未量化。
- 参考 CamCard 尚无同批字段级量化对照。

如果当前工程已经存在先导 JSON 和 pilot_report.csv，可核对并更新相关证据路径。

如果仍不存在，维持“来自用户提供的评估结果”的说明，不得伪造文件。

不计算未经脚本验证的 40 张总体准确率。

## 六、整理 AI 协作记录

核查：

- prompts/
- records/

要求：

1. 检查已有 Prompt 与执行记录能否相互对应。
2. 标出缺失或不完整的记录。
3. 不得伪造历史 Prompt 或 Codex 执行结果。
4. 不得把人工编写和 AI 辅助编写混为一谈。
5. 已有 AI 能力边界报告不重复撰写。
6. 保持现有文件命名及目录规范。

## 七、更新交付状态

更新：

`docs/06_status_issues.md`

明确区分：

**已完成**

- 已实现并有证据支持的功能。
- 已完成的 OCR 自动评估。
- 已归档的 SDD 与协作材料。

**尚未量化或尚未验证**

- 参考 App 同批准确率对照。
- 人工校正后的批量准确率。
- 缺少明确证据的特殊测试路径。
- 其他确实存在的遗留问题。

不为了使状态表全部显示 PASS 而删除问题。

## 八、修改范围

允许按需修改：

- docs/03_reference_tests.md
- docs/04_traceability.md
- docs/06_status_issues.md
- docs/12_week6_ocr_evaluation.md（仅在新增实际证据需要修订引用时）

以及新增本轮 Prompt 和执行记录。

如发现 spec.md 或其他文件需要调整，先在执行报告中指出，不直接修改。

禁止修改：

- 全部 Swift 源码
- Xcode Target、Scheme
- OCR 和 Parser 算法
- 数据库
- Ground Truth
- 测试图片
- OCR 采集 JSON
- evaluate.py
- CSV 评估结果
- 既有 Prompt 原文及历史执行记录

禁止运行构建、测试、模拟器、Python 评估和 Git 操作。

## 九、自动归档

保存：

`prompts/P028_C_Week6_final_sdd_review.md`

`records/P028_C_Week6_response.md`

执行记录需包含：

1. 实际修改的文件。
2. T01～T20 的状态分布。
3. 需求追踪关系是否完整。
4. OCR 评估证据是否齐全。
5. Prompt 与 Response 是否存在缺失。
6. 尚未验证的事项。
7. 本轮是否修改业务代码：否。
8. 构建和测试：NOT_RUN。

完成后停止，不自动进行新一轮开发。
