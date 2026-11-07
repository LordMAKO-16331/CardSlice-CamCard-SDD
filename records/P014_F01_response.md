# P014-F01 执行报告

- 修改：Services/CardRectangleDetectionService.swift、Views/CardImageImportView.swift、CardSliceTests/CardRectangleProcessingTests.swift；另新增本轮完整Prompt与本报告，未覆盖旧记录或修改其他文件，OCR服务保持不变。
- 多候选：Vision最多返回16项，结果保留所有合法候选的独立四角、置信度、相对多边形面积、像素空间边长比及贴边标记。检查有限值、规范化范围、严格凸性/角点顺序、面积及置信度范围。原首候选摘要保留以兼容已有断言，UI矫正不使用默认首项。
- 排序：[DECISION/TEMP] 面积>=85%且四边均接近2%图像边缘的候选标记为疑似外框，排在内部候选后但不删除；组内按sqrt(面积)×置信度降序，再依面积、置信度和角点坐标确定性排序。保留原有临时Vision阈值，候选上限改为16。规则不是名片分类器，不宣称置信度等于名片概率。
- UI：显示候选总数、当前编号、置信度/面积/比例和外框警示；上一个/下一个切换黄色轮廓。需明确点击确认使用当前候选后才启用矫正，切换取消确认。矫正函数通过同一selectedBoundary选择校验取得当前边界。空列表/单候选/越界均安全；矫正后可恢复预处理图。
- 状态：换图、恢复、关闭清理候选索引与确认状态，同时清理OCR；切换候选也清除OCR。原请求UUID及取消校验保留，旧后台结果不提交至新图片。
- 新增7项测试，保留原有8项及全部断言：testCandidateRankingIsDeterministic、testInternalCandidatePrecedesBorderWithoutDiscardingBorder、testCandidateMetadataAndCornersStayTogether、testOnlyConfirmedSelectedCandidateIsUsedForCorrection、testEmptyCandidatesAndInvalidSelectionAreSafe、testSingleBorderCandidateRemainsSelectable、testInvalidCandidateConfidenceIsRejected。选择校验与UI使用相同接口，并验证选中候选交给矫正服务；没有新增UI自动化测试。
- 限制：Vision可能漏掉内部名片，返回候选数量受系统影响；内部其他矩形仍可能排前，贴边真实名片可能排后；需用户人工判断，不支持自由拖角。实际复杂背景、候选切换和小屏布局需Xcode人工验证。
- 构建与测试：NOT_RUN；课程T01～T20：NOT_RUN。未执行构建、测试、模拟器或Git操作，未开始其他任务。
