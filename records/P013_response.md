# P013 执行报告

- 新增：Services/CardImagePreparationService.swift、CardSliceTests/CardImagePreparationTests.swift；修改：Views/CardImageImportView.swift。另归档本轮Prompt与本报告；未修改CardHolder、业务模型、数据层、已有测试或工程配置。
- 实现：ImageIO读取原图元数据并使用缩略图解码，按方向元数据旋转/镜像转正，不裁剪、不拉伸、不放大小图；最长边3000像素、JPEG质量0.9均标记[DECISION/TEMP]。输出PreparedCardImage包含原始Data、处理Data、实际像素宽高。服务不依赖SwiftUI或PhotosPicker，处理方法nonisolated，可从后台调用。
- 预览：异步加载原Data后在后台任务预处理，成功后展示处理图及像素尺寸；preparedImage状态完整持有原图与处理结果供后续使用，仅限当前流程。关闭/消失清理状态并使请求标识失效，任务取消/旧请求不提交结果；后台同步ImageIO操作可能执行至结束，但其结果不会覆盖关闭页面或新选择。
- 错误：区分emptyInput、unsupportedOrUndecodable、invalidDimensions、processingOrEncodingFailed，并通过LocalizedError显示中文提示；读取无Data及处理后预览解码失败亦有明确错误。
- 新增7项Swift Testing：testEmptyDataIsRejected、testNonImageDataIsRejected、testProcessedDataCanBeDecoded、testOriginalDataIsPreserved、testLargeImageIsDownsampledWithoutChangingAspectRatio、testSmallImageIsNotUpscaled、testOrientationMetadataIsApplied。测试用代码生成JPEG，不依赖相册；未执行。
- 未验证：用户需在Xcode确认编译与新增测试，并人工检查JPEG/PNG/HEIC、方向/比例、加载失败与关闭取消。方向测试覆盖EXIF6尺寸交换及输出方向；其他旋转/镜像和各种格式尚未逐项测试。尺寸/质量对后续OCR精度的影响未评估。
- Xcode构建和测试：NOT_RUN，等待用户验证；不将此前30项通过视作本轮回归结果。
- 课程参考测试T01～T20：NOT_RUN。未实现边界检测、透视校正、OCR、相机或正式名片保存，未写入SwiftData；未开始P014。
