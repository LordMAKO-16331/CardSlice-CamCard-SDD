# P022-A-F02 Week 5 执行报告

- 修改 CardDetailView.swift、CardSearchService.swift、CardSearchTests.swift，另归档完整 Prompt。
- 原先整个备注区位于非空备注条件内，因此空备注时连区域和入口都不渲染。现在始终声明备注区，已有内容仍完整显示，空白时提供「添加备注」。按钮沿用 openEditor 与原编辑、取消和更新回调。清空后重新显示入口。
- 搜索对已保存 notes 复用大小写不敏感的子串匹配。原五类字段与单次列表筛选继续生效。CardHolder 已通过保存回调更新完整列表，搜索直接基于最新记录计算，因此无需调整 CardHolder。
- 新增 5 项测试：testChineseNoteSubstring、testEnglishNoteSubstringIgnoresCase、testMissingAndEmptyNotesAreSafe、testSearchReflectsUpdatedAndClearedNotes、testNameAndNoteMatchOnlyOnce。旧测试中排除备注的期望与新需求冲突，改为断言备注命中，保留排除 OCR 和初始候选的断言及原五字段测试。
- 添加入口和保存后的搜索刷新待模拟器人工验收。中英文混用与关键词高亮列入 Week 5 UI Golden Test 待处理项。
- Xcode 构建与测试 NOT_RUN。T01～T20 尚未统一正式验收。
