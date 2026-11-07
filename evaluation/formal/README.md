# CardSlice 合成名片正式评估集

正式集包含 F01～F36 共 36 张独立输入。原 A～D 四张先导图及真值单独保留，合计 40 张。先导与正式结果应分开报告。本轮未采集正式 OCR 或计算准确率。

| 样本 | 类别 | 数量 | 说明 |
| --- | --- | ---: | --- |
| F01～F08 | 中文 | 8 | 中文身份及字段标签，使用虚构联系资料 |
| F09～F16 | 英文 | 8 | 英文身份及标签，含公司优先排列 |
| F17～F24 | 中英双语 | 8 | 同一字段可在卡面并列两种写法 |
| F25～F30 | 竖版或特殊布局 | 6 | 4 张竖版、2 张双列 |
| F31～F36 | 低清晰度或复杂背景 | 6 | 降采样、轻度旋转、盒式模糊和降对比，部分带点状纹理 |

36 张中 30 张为清晰输入，6 张为扰动输入。30 张含多个号码，9 张含多个邮箱。分别有 6 张无邮箱、9 张无网站、7 张无职位。另有 Mobile、Office、Fax、Other 分类及地址缺失场景。

## 文件与计分口径

- [images/](images/) 是唯一的正式输入目录。[clear/](clear/) 的六张图是扰动样本的清晰原版，用于诊断或成对对比，同一评估批次中不另计样本。
- [ground_truth.json](ground_truth.json) 使用现有 samples 结构。image 为项目根相对路径，split 为 formal，所有字段值用数组，空数组代表卡面明确缺失。双语字段保留完整卡面写法，包括分隔斜线，沿用现有严格比较口径。
- [dataset_manifest.json](dataset_manifest.json) 记录种子、字体、系统、布局、字体大小、配色索引、联系方式顺序、分辨率、哈希及每张扰动参数。模糊半径单位为输出像素，盒式核边长为半径的两倍加一。挑战卡片在画布上缩至记录的比例后再旋转。
- 名字、公司和地址为合成文本，邮箱和网站使用 .example，电话使用 +1 区域的 555-0100～0199 虚构号码段。排版和值字段共用同一份源数据。无 OCR 或 Parser 参与真值生成，也没有将字段内容写入 PNG 文本元数据。

## 复现

从项目根目录，使用 macOS 现有 Swift 工具链与系统字体运行。生成器拒绝已有目标目录。

```sh
dev=/Applications/Xcode.app/Contents/Developer
out=$(mktemp -d)
"$dev/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift" \
  -sdk "$dev/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk" \
  -module-cache-path "$out/modules" \
  evaluation/tools/generate_formal_cards.swift "$out/formal"
```

固定种子为 20261106。当前环境两次生成的 42 张 PNG 和 2 份 JSON 逐字节一致。其他 macOS、字体或渲染器版本可能改变像素或编码哈希，真值和布局参数由相同源数据及种子决定。

## 后续采集

在 Xcode 选择 **OCR Pilot Capture** 和兼容的 iOS 模拟器。在 **Test Navigator** 单独运行 `CardSliceOCRCaptureTests.testCaptureFormalOCR()`。同一 Scheme 包含先导与正式两个方法，运行整个 Scheme 会执行两者。先导方法仍只处理 A～D。

正式入口从测试 Bundle 读取 `dataset_manifest.json` 与 `images/`，检查 F01～F36 的 ID 和对应路径。真值用于事后计分。六张清晰原版不纳入采集。每张图片的失败单独记录，批次仍会继续。无文字结果保留空解析，其他采集故障保留 null，两者都会计入正式采集失败数量，并在输出附件后让该测试报告失败。

在 **Report Navigator** 打开本轮测试，展开正式采集方法并导出 `recognition_results-formal-<batch_id>.json`。控制台同时打印路径和成功、失败数量。取得附件后在项目根目录交给现有计分工具：

```sh
python3 evaluation/evaluate.py --truth evaluation/formal/ground_truth.json \
  --results /实际导出路径/recognition_results-formal-批次ID.json --split formal
```

先导数据及报告独立保留。Xcode 资源打包、运行和正式附件交付待用户验证。

## 局限

合成样本采用有限字体、可控标签、数字格式和布局模板。复杂样本模拟平面旋转、低分辨率、模糊、低对比及纹理，覆盖不了实拍反光、遮挡、纸张弯曲、透视、复杂环境或国际号码分布。正式结果应标为合成集表现，并区分清晰与扰动子集。与 CamCard 对照时需使用同一图片版本和一致字段口径。
