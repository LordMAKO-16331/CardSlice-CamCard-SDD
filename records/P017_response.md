# P017 执行报告

- 新增 Views/CardFieldCorrectionView.swift、Models/CardFieldCorrectionDraft.swift、CardSliceTests/CardFieldCorrectionTests.swift；修改 Views/CardImageImportView.swift。另归档本轮完整Prompt及本报告；未修改其他文件或既有测试。
- 数据流：初始解析结果构造独立值类型Draft，表单编辑本地副本；确认时基础校验后生成ParsedContactFields，回调父预览保存Draft与确认结果并显示摘要。再次打开沿用已确认Draft；取消不覆盖上次确认，未确认修改取消前有丢弃提示，禁止直接下滑丢弃表单。
- 表单：可滚动Form，姓名/公司/职位/网站/多行地址均可编辑；电话与邮箱使用稳定UUID条目，支持新增及滑动删除，电话类型复用PhoneType，采用电话/邮箱/URL键盘，邮箱禁自动大写和纠错；可查看OCR原文、未分类行和歧义提示。UI注明DECISION/TEMP与非永久保存。
- 来源隔离：Draft.original不可变，包含原始OCR和初始解析；编辑不会改写它们。确认结果仅存内存，不创建BusinessCardRecord或写入SwiftData，可供后续P018使用。
- 校验：姓名及可选字段允许空，空白单值转nil；空电话/邮箱行必须填写或删除，电话至少包含数字、不限定大陆格式；邮箱基本结构校验失败保留全部输入并显示原因。不删改有效电话格式。
- 会话保护：重新OCR、重新解析、换图、切换候选、矫正、恢复或关闭前，如已有确认结果，先提示丢弃再继续；用户取消则保留。换图使用受控PhotosPicker入口；用户同意丢弃后若取消系统选图，先前校正已按明确同意清除。父预览有确认结果时禁手势关闭；清OCR同时清Draft与确认结果，原请求UUID校验保留。
- 新增12项测试：testInitializesFromParsedResult、testEditsIdentityFields、testMissingFieldsCanBeAdded、testAddsAndRemovesPhones、testChangesPhoneType、testAddsAndRemovesEmails、testOriginalOCRIsUnchanged、testInitialParsingIsNotOverwritten、testEmptyOptionalFieldsRemainMissing、testConfirmedFieldsMatchUserEdits、testInvalidEmailPreservesInput、testEmptyContactRowsMustBeFilledOrDeleted。
- 未验证：Xcode编译、键盘/滚动/删除交互、嵌套sheet、取消/丢弃保护和会话重开流程需用户验收。邮箱仅基础验证，不承诺完整RFC或全球号码验证；页面关闭后不跨重启恢复。
- 构建与测试：NOT_RUN；课程T01～T20：NOT_RUN。未运行构建、测试、模拟器、安装清理或Git操作，未开始P018。
