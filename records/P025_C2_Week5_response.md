# P025-C2 执行报告

- 修改 `CardDetailView.swift`，新增 `CardDetailActionsTests.swift`。电话号码、邮箱、网站使用 SwiftUI 的系统 URL 打开操作，并区分无效输入与系统拒绝。显示值仍来自名片原字段。
- 电话仅允许数字、常见分隔符和前导国际加号；邮箱验证基本地址结构并编码特殊字符；网址仅允许 HTTP/HTTPS，裸域名默认 HTTPS，拒绝自定义协议及含用户凭据的目标。
- 原始图片和处理后图片各有独立全屏入口，分别解码当前记录对应数据，按原比例适配屏幕。缺失和解码失败有不同提示。
- 新增 10 项测试。testLocalTelephoneTarget、testInternationalTelephoneTarget、testInvalidTelephoneTargetsAreRejected、testEmailTargetEscapesAddressWithoutAddingHeaders、testInvalidEmailTargetsAreRejected、testExplicitWebSchemesAndPathsArePreserved、testBareWebDomainUsesHTTPS、testInvalidWebTargetsAndOtherSchemesAreRejected、testOriginalAndProcessedImagesUseDistinctStoredData、testMissingAndUnreadableImagesAreDistinguished。
- 拨号分机及服务代码不提交，网址使用常见 ASCII 域名格式，邮箱支持常见未引号地址。模拟器可能无电话或邮件处理程序，实际系统启动与预览效果待人工检查，拨号需真机。
- Xcode 构建与测试 **NOT_RUN**。T01～T20 尚未统一正式验收。
