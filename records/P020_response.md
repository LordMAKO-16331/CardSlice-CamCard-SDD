# P020 执行报告

- 修改 CardDetailView.swift、CardHolderView.swift、CardHolderViewModel.swift。新增 Services/CardDeletionCoordinator.swift、CardSliceTests/CardSavedRecordDeletionTests.swift 和本轮归档。
- 从列表进入已保存名片的详情后，可通过危险样式按钮发起删除。系统对话框明确指出当前名片，取消清除待确认状态。确认后锁定重复提交，异步调用注入仓库的 delete(id:)。
- 成功后退出详情，并从已加载列表移除同 UUID 的记录，计数随列表同步。最后一条删除后进入现有空态。失败时展示仓库错误，保留详情和列表，允许重新发起。
- 新增4项测试：testDeletesOnlyConfirmedUUIDAndRejectsRepeat、testCancellingConfirmationLeavesRepositoryUnchanged、testMissingRecordReportsErrorAndAllowsRetry、testDeletingLastRecordPersistsEmptyListAfterReopen。覆盖同名记录隔离、取消、缺失记录、防重复和重开磁盘后的空列表。
- 当前局限：实机导航、交互及退出重启仍待验收。现有 SwiftData 仓库在 save 抛错后没有回滚上下文的接口，UI 仅在 delete 成功返回后移除记录。存储层失败后的上下文恢复仍是已知限制。
- Xcode 构建与测试 NOT_RUN。课程 T01～T20 尚未完成正式验收。
