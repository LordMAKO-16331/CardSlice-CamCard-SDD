# P005 — Week 2：BusinessCard 数据模型、Mock Data 与首批单元测试

## 一、任务背景

本项目使用 SDD + TRAE，复刻 CamCard 限定的名片数字化与联系人管理功能切片。

当前已完成 P001～P004 的规格、架构和最小 SwiftUI 工程工作。用户需先确认 P004 修改后的 App 在 iPhone 模拟器中运行正常。

本轮只实现 BusinessCard 逻辑模型、只读 Mock Data 和针对模型的基础单元测试。

不实现真实持久化、OCR、相机、名片列表 UI 或导出。

## 二、执行前必须阅读

1. `docs/spec.md`
2. `docs/03_reference_tests.md`
3. `docs/07_architecture.md`
4. `docs/06_status_issues.md`
5. `app/CardSlice/CardSlice/ContentView.swift`

同时检查现有 `CardSliceTests` 测试目录和测试文件结构。

必须以实际工程为准，不得假设文件路径或测试目标存在。

## 三、允许修改的文件

原则上仅允许：

1. 新建 `app/CardSlice/CardSlice/Models/BusinessCardRecord.swift`
2. 新建 `app/CardSlice/CardSlice/Mocks/MockBusinessCards.swift`
3. 修改 `app/CardSlice/CardSliceTests/` 中已有的单元测试 Swift 文件

可以新建上述 `Models`、`Mocks` 文件夹。

如果工程采用不同的文件结构，应先报告实际路径，再按相同职责放置文件。不得创建重复类型或重复工程。

禁止修改：

- `ContentView.swift`
- App 入口
- `.xcodeproj` 配置
- 其他 Swift 文件
- `docs/`、`prompts/`、`records/`、`source/` 等项目文档目录

如果发现必须修改这些禁止范围内的文件才能继续，先停止并说明原因。

## 四、数据模型要求

以 `docs/07_architecture.md` v0.2 为依据。

### 1. BusinessCardRecord

表示已保存名片的逻辑数据，应包含：

- id：UUID
- originalImageData：原始图片数据，可选
- processedImageData：处理后图片数据，可选
- ocrRawText：OCR 原始文字，可选
- parsedFields：初次解析结构化结果，可选
- name：最终姓名
- company：公司，可选
- jobTitle：职位，可选
- phones：电话号码集合
- emails：电子邮箱集合
- website：网站，可选
- address：地址，可选
- tagIDs：标签标识集合
- notes：普通文本备注，可选
- createdAt：创建时间
- updatedAt：更新时间

图片字段暂时允许 Mock Data 为 nil；这不代表正式扫描保存时可以丢失图片。

本轮使用普通 Swift 数据类型，不引入 SwiftData `@Model`，后续通过 Repository 和持久化映射处理。

### 2. 电话号码类型

定义 PhoneEntry，至少支持：

- Mobile
- Office
- Fax
- Other

每条记录包含号码、类别和可选原始标签。

一张名片必须可以保存多个电话号码，允许多个号码属于同一类别，不得仅用三个字符串字段代替电话号码集合。

### 3. ParsedContactFields

定义独立的初始解析结果类型，支持：

- 可选姓名、公司、职位
- 多个电话号码
- 多个电子邮箱
- 可选网站和地址
- 无法明确分类的文字片段

初始解析结果和最终人工确认结果必须是两份可区分的数据。

无法确认的字段用 nil 或空集合表示，不得凭空补充信息。

### 4. TagRecord

定义最小标签模型，具有稳定 UUID 和名称。暂不实现标签 UI 或数据库操作。

## 五、Mock Data

建立只读样例集合，至少包含三条虚拟名片：

1. 英文标准名片。
2. 中英混合名片。
3. 同时有 Mobile、Office、Fax、多个 Email 且 Website 缺失的名片。

所有姓名、公司、电话、Email 均使用明确的虚构测试信息。邮箱建议使用 example.com 等测试域名。

Mock Data 应能直接用于后续 CardHolder 列表开发，但本轮不得修改 ContentView 显示它们。

不要把 Mock 数据写成真实 OCR 已识别结果，也不要把它们标记为教师正式 Ground Truth。

## 六、基础单元测试

先检查工程实际采用 Swift Testing 还是 XCTest。

在现有单元测试目标中增加针对模型的测试，至少覆盖：

1. 能创建一条 BusinessCardRecord。
2. 能保留多个 PhoneEntry，包括 Mobile、Office、Fax。
3. 能保留多个 Email。
4. 缺失 Website 时保持 nil，不自动填充。
5. OCR 原始文字、初始解析字段和最终字段互不覆盖。
6. 标签具有稳定标识。

不允许删除已有有效测试或为了让测试通过而篡改断言。

如需用户在 Xcode 中手动运行测试，明确给出操作步骤。

不得将未运行测试报告为 PASS。

## 七、禁止事项

- 不修改 UI。
- 不实现 SwiftData 或 Repository。
- 不实现 OCR、AI 解析、相机、导出。
- 不添加第三方依赖。
- 不增加课程以外的功能。
- 不擅自重构项目其他模块。
- 不执行未经授权的 Git 操作。

代码应当清晰、可维护，必要注释使用中文。

## 八、交付报告

完成后用中文报告：

1. 实际新增和修改的文件路径。
2. 数据模型的关键类型及用途。
3. Mock Data 的数量及覆盖情境。
4. 增加了哪些单元测试。
5. 是否实际执行构建与测试，以及真实结果。
6. 是否修改了允许范围之外的文件。
7. 与 R05/R07/R09、T08/T10/T12/T18 的对应关系。
8. 下一步最小任务建议。

本轮不得把 Reference Test Suite T01～T20 标记为 PASS。

完成后停止，等待人工审核。