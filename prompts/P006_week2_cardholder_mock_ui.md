# P006 — Week 2：CardHolder Mock 列表与空状态

## 一、任务背景

当前项目是基于 SDD + TRAE 的 CamCard 限定功能切片黑盒复刻。

P001～P005 已执行；P004 的 SwiftUI 启动页已经在 iPhone 17 / iOS 27.0 模拟器运行成功；P005 的模型已通过人工代码审核。

用户在 Xcode 中实际执行并确认：
- CardSliceTests：6/6 PASS。
- CardSliceUITests：2/2 PASS。
- 合计8/8 PASS。
- 课程 T01～T20 仍全部 NOT_RUN。

本轮只实现 CardHolder 的 Mock 列表与空状态切换。

## 二、执行前阅读

1. `docs/spec.md`（重点 R01）
2. `docs/03_reference_tests.md`（重点 T01、T12、T13）
3. `docs/07_architecture.md` v0.2
4. `app/CardSlice/CardSlice/ContentView.swift`
5. `app/CardSlice/CardSlice/Models/BusinessCardRecord.swift`
6. `app/CardSlice/CardSlice/Mocks/MockBusinessCards.swift`

先确认文件真实路径及现有类型，禁止假设工程结构。

## 三、本轮允许修改范围

仅允许：

1. 新建 `app/CardSlice/CardSlice/Views/CardHolderView.swift`。
2. 修改现有 `app/CardSlice/CardSlice/ContentView.swift`，使其显示 CardHolderView。

可新建 `Views` 文件夹。

如新文件没有自动加入 Xcode App Target，不得擅自大范围修改工程配置；应报告问题，由用户在 Xcode 中处理。

禁止修改 BusinessCardRecord、MockBusinessCards、现有测试、App 入口及其他工程文件。

禁止修改 docs、prompts、records、source 和 test_data。

## 四、功能要求

### A. 有名片列表

直接读取 `MockBusinessCards.samples`，展示三条名片。

每条至少显示：

- 姓名。
- 公司。
- 职位。

如果字段为空，应有合理的布局处理，不能显示 `Optional(...)` 或 `nil` 等代码内部文本。

顶部显示 CardHolder 标题。

可显示基于当前 Mock 数据计算的 `All Cards` 数量，但不能写死为3。

列表应使用 SwiftUI 原生组件，并保证在 iPhone 17 模拟器中正常滚动及展示。

本轮不使用真实名片图片。可以使用明确为临时设计的通用缩略图占位符，不得复制参考 App 的受保护资源。

### B. 空状态

通过一个仅用于开发调试的 Toggle，在以下两种数据源状态之间切换：

1. 显示 MockBusinessCards.samples。
2. 显示空集合。

切换仅改变界面展示，不删除任何原始 Mock 数据。

空状态必须可见，并明确标记 `[DECISION/TEMP]`。

当前尚未实测参考 CamCard 真正的 CardHolder 空状态，因此不能声称临时文案与 CamCard 完全一致。

### C. UI 范围

这只是 Week 2 的界面骨架，不是最终 UI Golden Test。

界面样式尽量简洁、稳定。

不必现在制作搜索、分组、详情、扫描入口或复杂交互。

列表行暂时不可点击也可以，但不能放置看似能工作、实际没有实现的假按钮。

## 五、工程约束

- 采用 SwiftUI。
- 遵循现有 MVVM 架构规划，但本轮不必为静态 Mock 列表强行创建额外 ViewModel。
- 不引入 SwiftData。
- 不修改 P005 模型或 Mock 数据。
- 不添加第三方依赖。
- 不实现持久化、OCR、相机、字段解析、导出。
- 不使用网络请求。
- 不得创建第二个 Xcode 工程。

注释优先使用中文。

## 六、验收要求

完成后由用户在 Xcode 中执行：

1. `⌘ + B`：确认工程构建成功。
2. `⌘ + R`：确认模拟器能够显示三张 Mock 名片。
3. 切换开发用 Toggle：确认空状态能正常显示。
4. 再次切换 Toggle：确认三张 Mock 名片重新出现。
5. `⌘ + U`：运行现有测试，确认未产生回归。

如用户允许 TRAE 使用构建工具，可以执行必要的验证；否则仅报告静态检查结果，交由用户手动验证。

不得将未实际执行的测试标记为 PASS。

T01～T20 仍维持 NOT_RUN，因为这里只是 Mock UI 预检，不是正式业务流程测试。

## 七、交付报告

使用中文报告：

1. 实际新建或修改的文件路径。
2. 列表与空状态的实现方式。
3. 是否复用了 P005 的原始 Mock 数据。
4. 是否引入未经证实的参考 App 界面。
5. 是否执行构建及测试，给出真实结果。
6. 是否修改范围外文件。
7. 下一步最小任务建议。

完成后停止，不得直接开始 P007。