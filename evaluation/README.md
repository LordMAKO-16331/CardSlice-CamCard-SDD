# OCR 与字段解析评估

本目录独立于 App。当前有 A～D 四张经卡面目视核对的先导真值，正式样本与采集结果均为 0。B 的姓名、公司和职位采用卡面双语完整写法，C 保留姓名中的 Dr.。这是事先声明的严格口径。若课程允许另一套双语或头衔口径，应在正式计分前固定并留档。

## 输入

- ground_truth.json 的 samples 项记录 sample_id、image（项目根相对路径）、card_type、split（pilot/formal/demo）、verified 和 fields。字段键见样例，全部用数组，确认未印刷用空数组，未知用 null。verified 为 false 的整张卡不计分。未核对字段单独跳过。
- recognition_results.json 的 results 每个 sample_id 仅一项。ocr_raw_text 保留原样（无文字可用空字符串），parsed_fields 保存自动结果，corrected_fields 保存人工确认值，可另填 reference_parsed_fields 做同口径参考 App 对比。未采集的阶段用 null 或省略，已执行但整阶段无输出用空对象并在 capture_error 备注。阶段对象内未出现的字段视为未输出。建议另记 build、device、os、source_image、input_variant、captured_at、capture_error 和 reference_version。禁止填写界面占位词。
- 例子为 JSON 结构说明，结果文件目前为空。单元测试的虚构数据只使用 demo 分组。

```json
{
  "sample_id": "样本ID",
  "ocr_raw_text": "原始多行文字",
  "parsed_fields": {"name": ["自动姓名"], "mobile": ["+86 138-0000-0000"]},
  "corrected_fields": {"name": ["确认姓名"], "mobile": ["+86 138-0000-0000"]},
  "reference_parsed_fields": null
}
```

## 尽量复用已保存结果

现有 BusinessCardRecord 保留 ocrRawText、parsedFields 及最终联系人字段，也持有原图和处理图。现有 VCF 只含最终字段，无法恢复自动结果。若已有先导记录，优先按原图和样本 ID 人工建立一次映射，然后在 Xcode 调试会话从已加载的记录只读提取业务模型的 Codable 字段，批量复制结构化结果。无需重新导入已验证名片或逐张抄 OCR。Swift 的 jobTitle 映射到 job_title，emails 映射到 email，phones 按 PhoneEntry.type 分入 mobile/office/fax/other_phone，保留各 value。不确定的样本对应关系先标待核。只导出评估所需字段和虚构或获授权记录。

源码未见可以直接批量输出这三层结果的业务入口。上述只读调试提取方案本轮未实施或验证；对文件样本的独立采集入口见下节。参考 App 应单独记录实际观察值，保留版本和证据。没有参考记录时留空。

## Xcode 批量采集

1. 在 Xcode 选择共享 Scheme **OCR Pilot Capture**，选择兼容 iOS 27.0 的模拟器，再点 **Product → Test**（⌘U）。在 Test Navigator 单独运行 `CardSliceOCRCaptureTests.testCapturePilotOCR()` 可仅采集先导样本。运行整个 Scheme 会执行先导和正式采集。正式流程见 [正式数据集说明](formal/README.md#后续采集)。无需设置启动参数、环境变量或模拟器名称，也无需导入相册。原 CardSlice Scheme 继续用于业务回归。
2. 测试从自己的 Bundle 读取仓库现有 `test_data/` 和 `evaluation/ground_truth.json`，检查 pilot 恰好包含 A～D。该目标直接编译现有预处理、OCR、Parser 和字段模型源码，无正式 App 宿主或仓库依赖。送进 OCR 的是预处理图，未做透视校正。无文字保留为空自动结果；读取、预处理、引擎或解析故障保留错误并继续。出现这些故障时先附上部分 JSON，再报告失败。
3. 在 **Report Navigator** 打开该次测试，展开采集方法的测试活动，导出附件 `recognition_results-pilot-<batch_id>.json`。控制台同时打印测试进程的临时路径。附件可导出性与无宿主运行待当前 Xcode 验证。若 Xcode 要求 App 宿主，停止并记录诊断，保持正式 App 配置。
4. 保留原始批次，检查每条的 capture_error 和语言，将文件直接交给 `python3 evaluation/evaluate.py --split pilot --results <导出的JSON路径>`。采集不会覆盖项目内现有结果。人工更正和参考字段为 null。后续合并时按 sample_id 另存，并注明来源批次。

## 计分与导出

在项目根目录运行：

```sh
python3 evaluation/evaluate.py --split pilot --csv pilot_report.csv
python3 evaluation/evaluate.py --csv formal_report.csv
python3 -m unittest discover -s evaluation -p 'test_evaluate.py'
```

- 主指标为字段级准确率。分母是有已核对且非空真值、并已采集该阶段的「样本×字段」数，分子要求该字段的全部值与真值完全一致。汇总是按字段实例微平均。已确认空字段不计入主分母，错误填充单独报告，同时提供含已知空字段的 exact_fields/evaluated_fields。未采集样本单列。零分母输出 null，无可计分结果会提示。
- 多值按无序多重集合逐值比较，重复输出计多余。值召回率为匹配值数除以真值总数，多值仅部分匹配不会成为整字段正确。漏值与多余值分列，错值可同时贡献漏值和多余值。原本为空却被填充单列。身份字段间和各电话类别间以未匹配值配对标记疑似错分，配对只是诊断，不从漏值或多余值中扣除。substitution_fields 表示同一字段既缺值又多值，这些计数可以重叠。
- 中文及英文文本使用 Unicode NFC、首尾去空白、合并空白与大小写折叠。电话只统一全角数字及常用符号、移除格式分隔符，保留所有数字、前导零、国际前缀和分机内容。邮箱保留本地部分大小写，仅折叠域名大小写。网站默认裸域为 HTTPS，折叠协议/主机大小写并统一根路径，保留显式 HTTP、路径及查询差异。规范化只用于比较，源数据保持原样。
- JSON 输出含每样本、每字段及整体统计，CSV 提供相同三级明细。自动解析、人工确认和参考 App 分开计算，各自分母和未采集数可见。此指标是字段准确率，OCR 字符准确率需独立逐字真值和对齐工具。正式比较时使用相同样本及可比图像，记录裁剪版本，冻结真值和计分规则。
