# P014 执行报告

- 新增 Services/CardRectangleDetectionService.swift、Services/CardPerspectiveCorrectionService.swift、CardSliceTests/CardRectangleProcessingTests.swift；修改 Views/CardImageImportView.swift。另新增本轮完整Prompt与本报告，均未覆盖旧归档。未修改其他文件或原有37项测试。
- 检测：VNDetectRectanglesRequest读取P013已转正图像；规范化四角、置信度、图像像素尺寸由结果类型返回。无候选时boundary/confidence为nil，isDetected为false，不伪造矩形或认定真实名片。Vision失败包装为明确错误。
- 候选规则：合法候选按面积×置信度降序，其次面积，再按角点坐标稳定排序。阈值minimumConfidence=0.5、minimumSize=0.15、宽高比0.3～1、角度容差30、最多8个候选均为[DECISION/TEMP]，无准确率承诺。
- 几何：检查有限值、0～1范围、角点上下左右关系、面积及严格凸性；拒绝自交/共线/错序。Vision与Core Image均为左下原点，像素坐标为extent原点＋规范化坐标×尺寸；SwiftUI轮廓翻转y，并与aspectFit实际图片区域共享尺寸与居中留白。
- 矫正：CIPerspectiveCorrection以四角输入，检查有限非空extent后CIContext渲染JPEG，方向标记1；临时渲染上限6000像素/1800万像素，质量0.9。输入Data和P013原图/预处理图不被覆盖。
- UI：预处理后主动检测→查看黄色候选四边形与置信度→用户主动应用矫正→恢复预处理图片。开发控件所在区域标记[DECISION/TEMP]；处理禁用重复操作。后台任务返回时检查请求UUID与取消状态；换图/关闭清理检测、矫正与预览状态。同步系统处理可能继续到结束，但旧结果不会提交。
- 新增8项Swift Testing：testEmptyAndInvalidImagesAreRejected、testFeaturelessImageHasSafeDetectionResult、testNormalizedPointsConvertToPixelCoordinates、testInvalidQuadrilateralsAreRejected、testValidPerspectiveCorrectionProducesDecodableImage、testCorrectionPreservesInputData、testOutputDimensionsAreReasonable、testInvalidPixelExtentIsRejected。程序生成PNG，无稳定Vision命中假设。
- 风险：真实名片/复杂背景的检测质量、纵横图aspectFit对齐、矫正方向和各设备性能需用户实测；未实现可拖动角点，极端旋转/倾斜候选可能被保守合法性检查拒绝。新增测试及编译均未验证，先前37项PASS不代表本轮回归通过。
- 构建与测试：NOT_RUN，等待用户在Xcode验证。T01～T20：NOT_RUN。
- 未执行构建、测试、模拟器或Git操作；未实现OCR、相机、正式保存或持久化，未开始P015。
