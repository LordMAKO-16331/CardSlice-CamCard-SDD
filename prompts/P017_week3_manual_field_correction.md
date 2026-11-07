# P017 — Week 3：名片字段人工校正

## 一、项目背景

本项目是基于 SDD 的 CamCard iOS 功能切片。

当前已完成：

- P013 图片预处理。
- P014 名片边界检测、透视矫正。
- P014-F01 多矩形候选选择。
- P015 中英文 OCR。
- P016 名片字段自动解析。

用户在模拟器中验证：

- OCR 能正常识别文字。
- P016 能正确分类部分姓名、公司、电话、邮箱等字段。
- 部分字段存在漏识别、错分类现象。

本轮实现人工校正功能，让用户能够修正解析结果。

课程参考测试 T01～T20 仍为 NOT_RUN。

## 二、自动归档

将本条完整指令保存至：

`prompts/P017_week3_manual_field_correction.md`

完成后生成：

`records/P017_response.md`

不得覆盖旧文件。

## 三、执行前阅读

只阅读必要文件：

1. docs/spec.md，重点 R05、R06、R07。
2. docs/07_architecture.md。
3. BusinessCardRecord.swift。
4. CardContactFieldParser.swift。
5. CardTextRecognitionService.swift。
6. CardImageImportView\.swift。
7. 相关现有测试。

先确认实际的 ParsedContactFields、PhoneEntry、PhoneType 以及 P016 解析结果类型。

不得根据旧对话猜测模型字段。

## 四、允许修改范围

允许新建：

- `app/CardSlice/CardSlice/Views/CardFieldCorrectionView.swift`
- `app/CardSlice/CardSlice/Models/CardFieldCorrectionDraft.swift`
- `app/CardSlice/CardSliceTests/CardFieldCorrectionTests.swift`

允许修改：

- `app/CardSlice/CardSlice/Views/CardImageImportView.swift`

禁止修改：

- BusinessCardRecord.swift
- CardContactFieldParser.swift
- CardTextRecognitionService.swift
- SwiftData Repository 及持久化模型
- App 入口
- 其他既有测试
- Xcode 工程配置

如实际依赖无法支持这些修改范围，请停止并说明原因。

## 五、P017-1：人工校正表单

在 P016 的解析结果界面增加：

`人工校正`

进入后显示可编辑的名片字段：

1. 姓名
2. 公司
3. 职位
4. 多个电话号码及其类型
5. 多个邮箱地址
6. 网站
7. 地址

要求：

- 已解析字段自动填入。
- 未解析字段保持空白。
- 所有字段允许人工修正。
- 电话支持新增、删除以及类型切换。
- 邮箱支持新增、删除。
- 电话类型复用现有 PhoneType 枚举。
- 保留号码中的国际区号、空格等有效信息。
- 不得自动推测或填充不存在的联系方式。
- 使用适合对应字段的输入方式，例如邮箱键盘。
- 确保页面可滚动，键盘弹出时仍可使用。

当前 UI 标记为 [DECISION/TEMP]，不声称已经复刻真实 CamCard 编辑界面。

## 六、P017-2：校正数据模型

创建独立的 CardFieldCorrectionDraft，用于保存本轮临时编辑状态。

要求：

1. 从 P016 的实际解析结果构造 Draft。
2. 保留用户修改后的所有字段。
3. 支持多个电话、多个邮箱。
4. 支持缺失字段。
5. 允许对 Draft 进行测试，不强依赖 SwiftUI。
6. 不直接修改 OCR 原始文本。
7. 不覆盖初始解析结果。
8. 不直接写入 SwiftData。
9. 明确区分原始识别、初始解析和人工确认数据。

如果解析结果中存在未分类行或歧义提示，允许用户在校正界面查看，以帮助判断信息。

## 七、P017-3：确认流程

校正页增加：

- 取消
- 确认校正

要求：

1. 点击确认后，生成当前已确认的字段结果。
2. 返回图片处理界面并展示已确认字段摘要。
3. 当前阶段只在内存中保留结果。
4. 不创建正式 BusinessCardRecord 数据库记录。
5. 不将“确认校正”写成“永久保存名片”。
6. 用户重新打开校正界面时，保留本次会话已经修改的字段。
7. 用户更换图片或重新执行 OCR、重新解析时，旧校正结果不得错误关联新图片。
8. 如果已经有尚未处理的人工修改，切换图像前应避免静默丢弃。
9. 页面关闭后不要求跨 App 重启恢复，此功能属于 P018。

确认结果应当能够供后续 P018 正式名片保存流程使用。

## 八、P017-4：基础校验

添加必要但不过度严格的校验：

- 姓名允许中文和英文。
- 可选字段允许为空。
- 邮箱明显不符合基本结构时给予提示。
- 电话允许国际区号和常见分隔符。
- 不强制所有电话必须符合中国大陆手机号格式。
- 空电话或空邮箱条目不能冒充有效联系方式。
- 校验失败时不得静默丢失用户输入。

不要实现复杂的全球电话号码验证框架。

## 九、P017-5：单元测试

使用 Swift Testing。

至少覆盖：

1. 正确初始化解析结果。
2. 修改姓名、公司、职位。
3. 原本缺失的字段能够手动补充。
4. 多电话新增及删除。
5. 电话类型修改。
6. 多邮箱新增及删除。
7. 用户修改后原始 OCR 内容不变。
8. 人工校正不会覆盖初始解析数据。
9. 空字段正确处理。
10. 确认结果与用户编辑的内容一致。

测试应使用虚构联系人数据。

保留之前所有测试，不删除或弱化断言。

## 十、禁止事项

- 不修改 OCR 识别算法。
- 不重新设计字段解析算法。
- 不实现正式名片数据库保存。
- 不修改 SwiftData Schema。
- 不实现相机拍照。
- 不实现 VCF 导出。
- 不实现名片搜索。
- 不添加第三方依赖。
- 不执行 Git 操作。

## 十一、执行效率

Codex 只进行必要的代码读取、修改与文档归档。

禁止执行：

- xcodebuild
- xcrun
- 模拟器
- 构建或自动化测试
- 安装和清理命令

全部测试由用户在 Xcode 中执行。

不需要生成冗长分析报告。

## 十二、自动生成 Response

创建：

`records/P017_response.md`

简要说明：

1. 实际新增及修改的文件。
2. 校正表单与数据流。
3. Draft 与原始 OCR、初始解析结果的关系。
4. 新增测试数量及名称。
5. 尚未解决的问题。
6. 构建和测试状态：NOT_RUN。
7. T01～T20：NOT_RUN。

完成后停止，不开始 P018。