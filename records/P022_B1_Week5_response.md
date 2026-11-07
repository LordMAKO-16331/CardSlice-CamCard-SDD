# P022-B1 Week 5 执行报告

- 新增 Models/PersistedTag.swift、Data/TagRepository.swift、Data/SwiftDataTagRepository.swift、CardSliceTests/TagRepositoryTests.swift，修改 CardSliceApp.swift 的正式容器注册，另归档完整指令。
- 复用 TagRecord 作为业务值类型，使用已有 tagIDs 及其 JSON 字段建立关联。名称去除首尾空白，按固定 locale 做大小写折叠并检查唯一键。仓库提供创建、查询、设置关联、按标签查询名片和删除，区分无效名称、重复、标签或名片不存在、读写失败。
- 标签和关联清理在同一 ModelContext 内一次 save。预先解码所有名片关联，清除目标 ID 后仅删除标签实体。若写入失败回滚本次操作。共享上下文已有未提交变更时拒绝写入，避免连带提交或回滚其他修改。
- 正式容器在原默认存储位置注册新增实体，原名片实体保持原样。依赖 SwiftData 自动迁移，初始化异常沿用现有错误展示路径。DEBUG Mock 分支仍使用隔离的内存仓库。
- 新增 6 项测试：testCreatesAndReadsTrimmedTags、testRejectsBlankAndCaseInsensitiveDuplicates、testSharedAndMultipleTagsAndDeletionCleanup、testMissingTagAndCardDoNotChangeAssociations、testCorruptAssociationAbortsDelete、testExistingDiskStoreUpgradeAndTagRoundTrip。最后一项从旧单模型临时磁盘库升级，检查原记录与图片等数据并回读标签和关联。
- 待验证实际 iOS 环境的旧库自动迁移与重启回读。关联查询和删除需扫描名片的 JSON 集合，遇损坏关联时明确报错。标签功能目前通过仓库接口提供，尚无界面入口。
- Xcode 构建与测试 NOT_RUN。课程 T01～T20 尚未完成统一正式验收。
