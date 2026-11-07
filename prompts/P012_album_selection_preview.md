# P012 — 名片图片相册选择与预览

## 一、任务背景

当前 CamCard SDD iOS 项目已完成 P001～P011。

最新人工验证：

- 30项自动化测试全部 PASS。
- P011 已通过实际 SwiftData 保存及 App 完全退出后的恢复验证。
- 目前 DEV 按钮可以保存测试名片。
- 正式的图片采集和 OCR 尚未实现。
- 课程 T01～T20 全部 NOT_RUN。

本轮开始实现 R02 中的相册选择功能，但不实现拍照、OCR 和真实名片保存。

## 二、自动保存 Prompt

将本条完整任务保存至：

`prompts/P012_album_selection_preview.md`

## 三、允许修改范围

优先仅修改：

- `app/CardSlice/CardSlice/Views/CardHolderView.swift`

允许新建：

- `app/CardSlice/CardSlice/Views/CardImageImportView.swift`

不得修改 SwiftData Repository、持久化实体、业务模型、Mapper、App 入口和已有测试文件。

如现有结构需要扩大范围，请先说明原因，不得自行修改。

## 四、功能要求

1. 在 CardHolder 中增加一个临时图片导入入口，标记 `[DECISION/TEMP]`。
2. 使用系统 PhotosPicker 选择单张图片。
3. 用户选择后，异步加载图片数据。
4. 在 App 中显示图片预览，保持图片比例，不应变形。
5. 用户可以取消选择、关闭预览。
6. 未选中图片或取消操作时，不应生成记录。
7. 图片读取失败、格式无法解码时，应展示明确错误。
8. 加载过程应有合理反馈，避免重复触发。
9. 图片仅在当前预览流程中使用，本轮不写入 SwiftData。
10. 预览界面明确说明当前尚未执行 OCR 或保存。
11. 保留现有 CardHolder 列表、详情导航、加载状态、空状态和 DEV 持久化验证入口。
12. 不要求申请整个相册的读取权限，优先使用 PhotosPicker 的系统选择机制。

## 五、禁止事项

- 不实现相机拍照。
- 不实现 OCR 或字段解析。
- 不将图片自动保存为名片。
- 不创建虚假的 OCR 数据。
- 不修改数据库结构。
- 不修改既有测试。
- 不添加第三方依赖。
- 不执行 Git 操作。

## 六、执行效率

Codex 只读取必要文件并完成代码修改。

禁止运行 xcodebuild、xcrun、模拟器和任何自动化测试。

所有构建、测试、模拟器验收由用户亲自在 Xcode 中执行。

## 七、自动生成 Response

完成后创建：

`records/P012_response.md`

简要报告：

- 实际修改的文件。
- 图片选择和预览实现方式。
- 图片加载失败与取消时的处理。
- 尚未实现的功能。
- Xcode 构建、测试状态：NOT_RUN。
- 课程 T01～T20：NOT_RUN。

完成后停止，不自动开始 P013。