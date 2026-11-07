# P022-A 执行报告

- 修改 CardDetailView.swift、CardFieldCorrectionView.swift、CardSavedRecordEditor.swift 和 CardSavedRecordEditingTests.swift，另归档本轮完整指令。
- 已保存名片编辑使用多行 TextEditor。备注输入作为独立表单状态，取消走原有丢弃确认。提交时通过现有编辑器和 Repository.update 更新同一 UUID。空白输入清除备注，其他输入原样保留换行。成功后详情立即显示更新值，失败沿用表单错误提示。
- 详情页在可滚动列表中显示完整非空备注。已保存名片的备注与联系人字段一起提交，OCR 人工校正仍沿用原入口。
- 新增 testNoteEditsAndClearingPersistAcrossDiskReopens，覆盖新增、修改、清空、中英文多行回读、重开磁盘容器、原始数据保留和另一张名片隔离。现有 testDiscardingDraftDoesNotWrite 覆盖取消的无写入路径。备注专属的取消交互需在 Xcode 人工验收。
- 构建与测试 NOT_RUN，等待用户验证。课程 T01～T20 尚未完成统一正式验收。
