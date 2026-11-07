# P028-B4 执行记录

- 新增 [完整 Prompt](../prompts/P028_B4_Week6_ocr_evaluation_analysis.md)、[OCR 评估与能力边界报告](../docs/12_week6_ocr_evaluation.md)及本记录。
- 核对了 [先导真值](../evaluation/ground_truth.json)、[正式真值](../evaluation/formal/ground_truth.json)、[正式采集 JSON](../evaluation/4373F066-3A8B-483B-BAED-7E227482407E.json)及[正式报告 CSV](../evaluation/formal/formal_report.csv)，并阅读[计分规则](../evaluation/evaluate.py)、采集说明及[参考 App 黑盒记录](../docs/02_observation_log.md)。
- 先导 A～D 的字段准确率 56.00%、字段值召回率约 57.69% 来自用户报告。当前工程未找到先导采集 JSON 或 `pilot_report.csv`。
- 正式 F01～F36 的字段准确率为 51.5267%（135/262），字段值召回率为 52.3985%（142/271）。正式 CSV、采集数据和真值未发现不一致。F31 无文字的结果计入评分。
- F01、F09、F17 显示姓名或公司漏提取。F01、F06、F20、F33、F34 显示字符或联系方式误读。F17 存在严格匹配格式差异。F35 同时出现误读及电话类型偏差。
- 校正后结果未批量采集，参考 CamCard 尚无同批字段级量化对照。
- 本轮仅新增文档。业务代码、真值、识别结果及计分产物保持原样。构建、测试和评估重跑均为 NOT_RUN。
