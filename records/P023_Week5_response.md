# P023 Week 5 执行报告

- 新增 CardVCardExportService.swift、CardVCardExportTests.swift，修改 CardDetailView.swift。另归档本轮完整指令。
- 生成 vCard 3.0 的 UTF-8 数据和 CRLF 行。FN 使用完整姓名，N 将完整姓名置于一个分量，ADR 保留完整地址于街道分量。导出公司、职位、网站和各条电话、邮箱。电话类型按 CELL、WORK、WORK,FAX 或无类型映射。空白姓名报错，空白可选字段略过。
- 文本转义反斜杠、分号、逗号及换行。URL 保留 URI 分隔符并编码不适合直接写入 URI 的字符。长行按 75 字节折叠，保持 Unicode 标量完整，续行带空格。备注作为可选字段本轮省略，以避免随 DEBUG 备注输出开发标记。
- 详情导出时按当前 UUID 回读已保存记录，以 UIActivityViewController 分享独立目录内的随机文件名。生成及分享期间限制重复操作。分享结束或取消后清理临时文件，错误在详情显示。
- 新增 9 项测试：testRequiredPropertiesAndMissingOptionalFields、testChineseNameUsesUTF8WithoutSplittingName、testCompanyTitleAndAllPhoneTypes、testMultipleEmailsWebsiteAndStructuredAddress、testEscapesSpecialCharactersAndEveryNewlineStyle、testLongUTF8LineFoldsAndUnfoldsWithoutDataLoss、testBlankNameIsRejected、testUsesLatestValuesAndLeavesInputUnchanged、testTemporaryFilesAreUniqueAndContainVCFData。
- 已知限制：系统分享、保存到文件及目标通讯录导入行为待人工验收。进程被强制终止时，系统临时目录可能暂时保留文件，正常分享完成或取消时会尝试清理。
- Xcode 构建与测试 NOT_RUN。课程 T01～T20 尚未完成统一正式验收。
