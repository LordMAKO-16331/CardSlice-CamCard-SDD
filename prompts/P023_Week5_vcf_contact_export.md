# P023 — Week 5：VCF 联系人导出

## 一、项目状态

本项目为基于 SDD 的 CamCard iOS 功能切片。

当前处于 Week 5：名片管理与持久化。

已完成：

- P019 已保存名片编辑。
- P020 名片删除。
- P021 姓名、公司、职位、电话、邮箱及备注搜索。
- P022-A 备注管理。
- P022-B1 标签数据层与持久化。
- P022-B2 标签创建、关联、筛选和删除。

最新人工验收：

- P022-B2 全部8项操作验证通过。
- Xcode 全部自动化回归测试通过。
- 现有名片数据可以在 App 重启后恢复。

本轮目标：实现课程要求的 VCF/vCard 导出功能。

课程规定联系人导出至少实现一种方式。本项目选择 VCF 导出，不额外实现写入系统通讯录的另一套功能。

## 二、自动归档

首先保存本条完整指令：

`prompts/P023_Week5_vcf_contact_export.md`

任务结束后生成：

`records/P023_Week5_response.md`

不得覆盖历史文件。

## 三、执行前阅读

只阅读必要文件：

1. `docs/spec.md`，重点联系人导出要求。
2. `docs/03_reference_tests.md`，重点 T19。
3. `BusinessCardRecord.swift`。
4. `CardDetailView.swift`。
5. 当前详情页的数据更新与 Repository 注入实现。
6. 现有 Swift Testing 测试结构。

必须以实际 BusinessCardRecord 字段定义为准，不得假设所有可选字段都有值。

## 四、允许修改范围

允许新增：

- `app/CardSlice/CardSlice/Services/CardVCardExportService.swift`
- `app/CardSlice/CardSliceTests/CardVCardExportTests.swift`

允许修改：

- `app/CardSlice/CardSlice/Views/CardDetailView.swift`

仅当现有详情页无法安全获得更新后的保存记录时，可在原有 ViewModel 中进行最小修改，并在报告中说明。

不得修改其他 Swift 文件。

禁止修改 Repository、SwiftData Schema、名片模型、OCR、字段解析、搜索、标签及备注数据管理。

如确实需要扩大范围，应停止并报告。

## 五、P023-1：VCF 文件生成

创建独立 CardVCardExportService。

输入为已经保存的 BusinessCardRecord。

输出为可以分享或保存的 `.vcf` 文件。

采用兼容常见通讯录应用的 vCard 3.0 格式。

至少包含：

- BEGIN
- VERSION:3.0
- N
- FN
- ORG
- TITLE
- TEL
- EMAIL
- URL
- ADR
- END

具体映射规则：

| 业务字段        | VCF 字段            |
| ----------- | ----------------- |
| Name        | FN / N            |
| Company     | ORG               |
| Job Title   | TITLE             |
| Mobile      | TEL;TYPE=CELL     |
| Office      | TEL;TYPE=WORK     |
| Fax         | TEL;TYPE=WORK,FAX |
| Other Phone | TEL               |
| Email       | EMAIL             |
| Website     | URL               |
| Address     | ADR               |

Notes 可以映射为 NOTE，作为补充。

要求：

1. 正确编码 UTF-8 中文、英文及特殊字符。
2. 使用规范的 CRLF 行结束符。
3. 正确转义反斜杠、分号、逗号和字段中的换行。
4. 按 vCard 格式规范处理长文本行，避免在 UTF-8 多字节字符中间截断。
5. 对多电话生成多个 TEL 项。
6. 对多邮箱生成多个 EMAIL 项。
7. 正确保留 Fax 类型。
8. 对缺失的可选字段不生成虚假值。
9. 不根据邮箱或公司名称猜测不存在的网站、地址。
10. 对不能可靠拆分姓氏与名字的情况，不得凭空推断；应保留完整姓名用于显示，并生成格式合法的 N 字段。
11. 不得将内部 SwiftData UUID、OCR 调试信息或开发标记错误写入联系人显示字段。
12. 名片没有有效姓名时明确处理错误，不生成伪造联系人。

## 六、P023-2：导出入口

在已经保存的名片详情页增加：

`导出联系人`

要求：

1. 点击后生成当前名片对应的 VCF。
2. 调用 iOS 系统原生分享界面。
3. 用户可以选择保存到「文件」或其他支持 VCF 的目标应用。
4. 不要求 App 取得系统通讯录写入权限。
5. 本轮不直接向系统通讯录插入联系人。
6. 用户取消分享不影响数据库。
7. 生成失败时显示明确错误。
8. 不能导出其他名片的信息。
9. 编辑名片后再次导出，应使用最新保存字段。
10. 不修改原有名片内容。
11. 防止重复点击导致多个重叠分享界面。
12. 临时文件应采用唯一且安全的名称，避免路径冲突和非法文件名字符。
13. 文件在系统分享期间必须保持有效，不得提前删除。
14. 临时文件应在合适时机清理，避免不必要的数据长期残留。
15. 分享入口必须能正常点击，不得被其他按钮或开发工具遮挡。

保留现有详情页的编辑、标签、备注和删除功能。

## 七、P023-3：测试

使用 Swift Testing。

新增独立测试，至少覆盖：

1. 基础姓名导出。
2. 中文姓名 UTF-8 编码。
3. 公司和职位映射。
4. Mobile、Office、Fax 类型映射。
5. 多电话号码完整导出。
6. 多邮箱完整导出。
7. Website 缺失时不虚构 URL。
8. 地址正确导出。
9. 特殊字符与换行正确转义。
10. 长中文文本行正确处理。
11. 缺失可选字段时仍生成合法 VCF。
12. 没有有效姓名时明确拒绝。
13. 修改名片字段后，使用最新数据生成 VCF。
14. 导出过程不改变 BusinessCardRecord。

测试内容使用虚构联系人信息。

保留所有现有测试和断言。

本轮不要求自动化测试调用真实系统分享界面，由用户人工验证分享操作。

## 八、严格禁止

- 不直接写入系统通讯录。
- 不增加 Contacts 写入权限。
- 不修改 SwiftData Schema。
- 不修改 Repository。
- 不修改 OCR 或字段解析。
- 不实现相机。
- 不修改搜索、标签和备注管理。
- 不进行全局 UI 重构或语言统一。
- 不添加第三方依赖。
- 不执行 Git 操作。

## 九、执行效率

Codex 只进行必要代码读取、修改和 Markdown 归档。

禁止执行：

- xcodebuild
- xcrun
- 模拟器
- 自动化测试
- 构建、安装及清理命令
- Git 操作

用户在 Xcode 中自行完成构建、运行及回归测试。

## 十、Response

生成：

`records/P023_Week5_response.md`

简要记录：

1. 实际新增、修改文件。
2. VCF 生成及字段映射方案。
3. 多电话、多邮箱及特殊字符处理方式。
4. 系统分享与临时文件管理方式。
5. 新增测试名称及数量。
6. 已知限制。
7. 构建与测试：NOT_RUN，待用户验收。
8. 课程 T01～T20：尚未完成统一正式验收。

完成后立即停止，不开始 P024。