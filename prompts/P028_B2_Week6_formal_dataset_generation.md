# P028-B2 — Week 6：建立 40 张 OCR 合成名片评估数据集

## 一、背景

CardSlice 核心业务已完成。

独立 OCR Pilot Capture 测试目标成功运行，A～D 四张先导样本的 JSON 已取得，evaluate.py 已成功计算准确率。

当前先导评估：

- 字段准确率：56.0%
- 字段值召回率：57.7%
- 自动解析字段主要问题：姓名、公司、地址
- 联系方式字段表现较好

教师没有提供 30～50 张统一名片测试图片。

决定建立可复现的合成名片测试集，用于 Week 6 正式 OCR 及字段解析评估。

## 二、目标

在保留现有 A～D 四张样本的基础上，新增 36 张虚构名片，共计 40 张。

新样本组成：

- 8 张中文名片
- 8 张英文名片
- 8 张中英双语名片
- 6 张竖版或特殊布局名片
- 6 张低清晰度或复杂背景名片

注意：类型可以有交叉特征，但最终应有 36 张唯一图片和 36 份独立真值记录。

样本应覆盖：

- 姓名、公司、职位
- Mobile、Office、Fax
- 多电话号码、多邮箱
- Website、Address
- 缺少邮箱、网站、职位等字段
- 不同文字大小
- 中英文混排
- 特殊排列顺序
- 适度倾斜、模糊、低对比度
- 不同宽高比

## 三、数据要求

使用完全虚构的个人、公司与联系方式。

使用适合测试的虚构域名和电话号码。

不得使用真实个人信息。

生成图片时确保：

1. 名片上的文字与 Ground Truth 一致。
2. 中文字体正确显示，不出现乱码或缺字。
3. 不能把正确答案直接嵌入 OCR 结果。
4. 不使用现有 OCR 或 Parser 自动生成 Ground Truth。
5. 使用固定随机种子，便于复现。
6. 对图像扰动记录生成参数，保留原始清晰版本。
7. 合成数据的局限性必须在 README 中说明。

## 四、文件结构

建议在 evaluation/ 下新增：

- formal/images/
- formal/ground_truth.json
- formal/dataset_manifest.json
- formal/README.md
- tools/generate_formal_cards.py

以项目现有 Schema 为准。

不得覆盖：

- evaluation/ground_truth.json
- evaluation/recognition_results.json
- A～D 先导图片
- 先导 OCR 结果文件
- pilot_report.csv

新 Ground Truth 必须兼容现有 evaluate.py 的数据结构，或者明确报告兼容性差异。

## 五、实施范围

本轮只负责生成数据集以及必要的生成脚本。

禁止修改：

- 全部 App 业务源码
- CardSliceOCRCaptureTests
- Xcode Target、Scheme
- SwiftData
- OCR、Parser、裁剪算法
- evaluate.py
- 原有单元测试
- 现有名片数据库

不要提前把 36 张图片注册到 Xcode Target。

## 六、生成后自检

通过静态或独立文件检查确认：

- 图片数量为 36。
- 真值数量为 36。
- ID 不重复。
- 每张图片均有对应 Ground Truth。
- 所有输出文件存在。
- 中文和英文文字能正确显示。
- 没有真实个人信息。
- 可以通过固定种子重新生成。

如需安装新依赖，先报告，不擅自安装。

不允许运行 Xcode 构建、模拟器、测试、Git 操作或修改数据库。

## 七、自动归档

保存 Prompt：

prompts/P028_B2_Week6_formal_dataset_generation.md

生成 Response：

records/P028_B2_Week6_response.md

报告中说明：

1. 实际生成数量。
2. 文件路径。
3. 数据类型及难度分布。
4. Ground Truth 的生成与校验方式。
5. 是否存在字体或依赖问题。
6. 下一步如何与现有采集工具连接。
7. 明确本轮未运行 OCR 正式评估。

完成后停止，不进入后续开发。
