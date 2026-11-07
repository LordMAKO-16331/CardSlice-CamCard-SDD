# P021 执行报告

- 修改 Views/CardHolderView.swift。新增 Services/CardSearchService.swift、CardSliceTests/CardSearchTests.swift，另归档本轮 Prompt 与报告。
- CardHolder 使用 SwiftUI 原生 searchable。对最新已加载记录实时筛选，编辑、删除和保存后的列表状态继续由原流程更新。详情通过 UUID 从完整列表定位，即使编辑后离开当前匹配集，也能继续显示详情。DEBUG 工具菜单沿用现有布局。
- 姓名、公司、职位和每个邮箱使用忽略大小写的子串匹配。电话号码逐项按数字子串匹配，兼容常见空格、括号和连接符。查询首尾空白会去除，空查询返回原列表。每条名片只判断一次，保持顺序和原始数据。
- 库为空保留既有空态。有记录但无匹配显示「未找到匹配名片」。加载及失败继续使用原有状态。工具栏显示保存总数，搜索区独立显示命中数。
- 新增 13 项 Swift Testing 测试，覆盖空查询、中英文姓名、公司、职位、多电话及格式、多邮箱、无匹配、缺失字段、多字段去重、原数据与顺序、仅最终字段可搜索。测试名称如下。

  - testBlankQueryReturnsAllCards
  - testChineseNameSubstring
  - testEnglishNameIgnoresCase
  - testCompanySubstring
  - testJobTitleSubstring
  - testSearchesEveryPhone
  - testPhoneFormattingDifferences
  - testSearchesAllEmailsByUsernameAndDomain
  - testNoMatchReturnsEmpty
  - testMissingOptionalFieldsAreSafe
  - testMultipleFieldMatchesReturnOneCard
  - testPreservesOrderAndOriginalRecords
  - testOnlyFinalContactFieldsAreSearchable

- 搜索为单关键词子串匹配。搜索框、键盘以及编辑后退出匹配集的导航表现待在 Xcode 人工验证。
- Xcode 构建与测试 NOT_RUN。课程 T01～T20 尚未完成正式验收。
