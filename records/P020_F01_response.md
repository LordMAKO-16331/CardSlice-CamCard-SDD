# P020-F01 执行报告

- 修改 CardHolderView.swift、CardDetailView.swift、CardImageImportView.swift、CardFieldCorrectionView.swift，并归档本轮完整指令。
- 详情删除入口原本位于 List 末尾。CardHolder 的 DEBUG 底栏通过整个 NavigationStack 外层的 safeAreaInset 持续占据底部区域，详情也受到影响。现将 DEBUG 保存、进度和结果移至列表页的开发工具菜单。删除仍位于详情列表内，使用全宽危险操作行及至少 44 点点击高度。
- 图片预览使用单一外层 ScrollView。图片处理默认展开，文字识别与字段处理可折叠。原文和结果随页面滚动，图像预览采用随宽度调整的视口并保留等比轮廓。分区只控制显示，状态和处理任务仍由原页面管理。
- 相册入口和进度位于折叠区外，正式保存仍在预览页底部安全区域。关闭按钮和标题沿用系统导航栏，说明文字进入滚动内容并可换行。人工校正和编辑表单使用行内标题，保留 Form 滚动、键盘交互和提交操作。
- 保留导入、预处理、候选与矫正、OCR、解析、校正、正式保存、详情编辑、删除确认及失败处理、持久化和 DEBUG 保存。
- iPhone 17 / iOS 27.0 上的遮挡、键盘和滚动交互待人工复验。正式 CamCard 样式对齐留待后续验收。
- Xcode 构建与测试 NOT_RUN。课程 T01～T20 尚未完成正式验收。
