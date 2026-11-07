# P025-C1A 执行报告

- 修改 `CardImageImportView.swift`，新增 `CardCropEditorView.swift`，补充 `CardRectangleProcessingTests.swift`。透视服务沿用现有接口。
- 「手动裁剪」从当前自动候选起步。无候选时使用内缩四边形，不登记为自动检测结果。四角可拖动，触摸区域为 44×44 pt。恢复操作会回到候选或手动初始区域。这是本项目的交互设计。
- 预览几何根据 AspectFit 的实际图片范围换算，包含留白偏移、Y 轴翻转和边界限制。按左上、右上、右下、左下重建角点，复用凸性、面积与顺序验证；非法移动保留上一有效区域并提示。
- 「确认裁剪」使用当前可见边界，向既有透视服务提交预处理图，保留原图。待确认的手动裁剪禁止启动 OCR。开始手调、确认裁剪及恢复预处理图时清除失效 OCR、解析与校正状态。换图、重拍和关闭清除角点；检测提交检查请求标识与手动状态，编辑期间不启动自动检测。保存仍由既有入口触发。
- 新增 5 项测试。testLandscapeCropMappingAccountsForVerticalLetterbox、testPortraitCropMappingClampsHorizontalLetterboxAndEdges、testManualCropUsesEditedCornersInServiceOrder、testManualCropRejectsCrossingAndDegenerateMoves、testManualCropWithoutCandidateStartsFresh。
- 测试覆盖几何、初始化隔离和服务调用。页面换图、异步回写和 OCR 状态清除未新增视图级自动化，需在人工流程中核对，拖动可达性及输出效果也待验收。
- Xcode 构建和测试 **NOT_RUN**。T01～T20 尚未统一正式验收。
