# P007 — Week 2：CardHolder 名片详情页与页面导航

## 一、项目上下文

当前项目为基于 SDD + TRAE 的 CamCard 限定功能切片复刻。

P001～P006 已执行。P005 完成 BusinessCard 数据模型和 Mock Data；P006 已实现 CardHolder 三张名片列表及临时空状态切换，并在 iPhone 17 / iOS 27.0 模拟器完成手动 UI 检查。

本轮只实现：从名片列表进入只读详情页，以及从详情页返回列表。

不实现编辑、删除、搜索、拍照、OCR、数据库或导出。

## 二、执行前阅读

1. `docs/spec.md`：R01、R07。
2. `docs/03_reference_tests.md`：T12、T13。
3. `docs/07_architecture.md`：当前 v0.2。
4. `app/CardSlice/CardSlice/Models/BusinessCardRecord.swift`
5. `app/CardSlice/CardSlice/Mocks/MockBusinessCards.swift`
6. `app/CardSlice/CardSlice/Views/CardHolderView.swift`
7. `app/CardSlice/CardSlice/ContentView.swift`
8. 现有 `CardSliceUITests.swift`。

先确认实际路径，不能创建重复工程或重复类型。

## 三、允许修改的文件

仅允许：

- 修改 `app/CardSlice/CardSlice/Views/CardHolderView.swift`。
- 新建 `app/CardSlice/CardSlice/Views/CardDetailView.swift`。
- 修改现有 `CardSliceUITests.swift`，增加导航测试。

禁止修改数据模型、Mock 数据、App 入口、ContentView、项目配置、其他测试以及全部 SDD 文档。

如果必须扩大文件修改范围，请停止并报告原因。

## 四、功能要求

### A. 列表导航

1. 将现有 CardHolder 的导航容器改成 `NavigationStack`。
2. 点击任意名片行进入对应的 `CardDetailView`。
3. 返回后仍可看到原有三张名片。
4. 不得破坏 P006 的 Toggle 与空状态切换。
5. `All Cards` 数量仍由数据源动态计算。

### B. 详情页

从选中的 `BusinessCardRecord` 读取并展示：

- 姓名。
- 公司与职位。
- 电话号码及类型（Mobile、Office、Fax、Other）。
- 全部 Email。
- 网站与地址。
- 普通文本备注（有值时显示）。

支持多电话号码和多 Email。

对于 nil 或空字符串字段，不显示 `Optional(...)`、`nil` 等程序内部内容，也不虚构联系人信息。

没有真实图片时，只显示明确标记为临时设计的缩略图占位，不伪装成已经完成图像识别。

### C. 交互限制

详情页本轮只读。

不得创建无法正常使用的编辑、删除、拨号、邮件、导出或扫描按钮。

页面可以通过系统原生返回按钮回到 CardHolder。

不得增加与当前课程范围无关的功能。

### D. 参考界面约束

当前为 Week 2 Mock UI 骨架，并非正式 CamCard UI Golden Test。

所有没有参考观察证据的 UI 设计均属于 `[DECISION/TEMP]`，不得宣称与参考 App 完全一致。

## 五、自动化测试

在现有 UI 测试文件中新增至少一项测试：

1. 启动 CardSlice。
2. 找到 John Doe 的列表行。
3. 点击后确认进入详情页。
4. 确认能看到 John Doe 对应的公司、至少一个 Email。
5. 返回 CardHolder。
6. 确认列表重新可见。

优先使用稳定的可访问性标识或可检索文本，不依赖屏幕绝对坐标。

不得删除或修改已有有效测试。

## 六、构建与回归

修改后报告：

- 实际修改的文件。
- 是否运行构建与测试。
- 是否存在编译错误。
- 新增 UI 测试的执行情况。
- 现有8项测试是否出现回归。

用户将在 Xcode 中使用：

- `⌘ + B` 构建。
- `⌘ + R` 验证导航与返回。
- `⌘ + U` 执行自动化测试。

未实际运行的测试必须标记为未运行。

T01～T20 继续保持 NOT_RUN，因为当前仍基于 Mock 数据。

## 七、交付报告

请以中文报告：

1. 新建和修改的完整文件路径。
2. 导航结构与详情页展示字段。
3. 新增的自动化测试。
4. 是否修改了允许范围外的文件。
5. 实际构建与测试结果。
6. 下一步最小开发建议。

完成后停止，不得自行开始 P008。