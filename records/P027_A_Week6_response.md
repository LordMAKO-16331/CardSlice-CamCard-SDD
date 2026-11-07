# P027-A 执行报告

- 新增 evaluation/README.md、ground_truth.json、recognition_results.json、evaluate.py 和 test_evaluate.py，另归档本轮 Prompt 与 Response。
- 目视核对 A～D 四张卡面并录入先导真值。正式集 0 张，正式采集结果 0 条。后续需 30～50 张虚构或获授权图像及逐字段人工真值，涵盖双语、版式、缺失字段和多联系方式。
- 默认仅计 formal。字段级准确率以已采集且非空的已核对真值字段为分母，要求多值完全匹配，另报告逐值召回、漏值、多余值、空字段错误填充和疑似错分。输出 JSON 或 CSV，自动、人工确认和参考 App 独立统计。
- 优先从已有记录只读批量提取 OCR 原文、初始解析和最终字段。README 记录 Xcode 调试采集方案和字段映射。批量 App 导出或新采集入口本轮未接入。
- 提供 7 项确定性虚构测试，不计入正式评估。构建、测试及正式评估 **NOT_RUN**。
