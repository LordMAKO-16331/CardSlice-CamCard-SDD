# P027-B1-F04 执行报告

- 新增 `CardSliceOCRCaptureTests.swift`、共享 `OCR Pilot Capture.xcscheme` 及本轮归档。修改 `project.pbxproj` 和 `evaluation/README.md`。
- `CardSliceOCRCaptureTests` 是只面向 iOS 模拟器的 XCTest 单元测试 Bundle，无 `TEST_HOST`、`BUNDLE_LOADER` 或 App Target 依赖。只直接编译原有图片预处理、Vision OCR、字段解析文件及提供字段类型的 `BusinessCardRecord.swift`。采集不构造名片记录，目标没有 AppDatabase、Repository、SwiftData 或正式 UI。
- 工程原有配置仅追加新对象与新引用。静态检查确认新增块去除后原工程内容逐字节一致，原 CardSlice Scheme 不引用新目标，且新 Scheme 仅引用该测试目标。原采集文件与常规测试未修改。工程 plist 语法和静态引用检查通过。
- 选择 **OCR Pilot Capture** 与兼容 iOS 模拟器，点 Product → Test。方法 `testCapturePilotOCR()` 从测试 Bundle 读取原有真值清单及 A～D 图片，使用预处理图执行真实 Vision 与 Parser，无需启动参数。单张错误留存并继续。若有不可计分的采集故障，附加部分结果后将该测试标为失败。
- Xcode Report Navigator 展开测试活动，导出 `recognition_results-pilot-<batch_id>.json`。控制台同时打印测试进程临时路径。人工更正和参考字段保留 null，现有项目结果文件不覆盖。
- Apple 的归档指南描述了模拟器逻辑测试的无宿主配置。当前 Xcode/iOS 组合的实际启动及附件仍待验证。如果 Xcode 明确要求 App 宿主，停止采集并保留启动诊断，待用户确认后续方案。未新增替代宿主。[Apple 逻辑测试配置](https://developer.apple.com/library/archive/documentation/DeveloperTools/Conceptual/UnitTesting/02-Setting_Up_Unit_Tests_in_a_Project/setting_up.html)
- 构建、测试与采集 **NOT_RUN**。
