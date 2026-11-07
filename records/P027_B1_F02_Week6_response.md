# P027-B1-F02 执行报告

- 仅修改 `CardOCRBatchCaptureTests.swift` 并新增本轮归档。宿主仍为 CardSlice.app，A～D 按清单读取测试 Bundle。采集代码不创建名片，不调用 Repository 或执行数据库写入、删除与重置。
- 在 Xcode 选择 NewPhone 后直接运行 testCaptureOCRBatch。只在 Debug、模拟器、系统提供的 SIMULATOR_DEVICE_NAME 精确等于 NewPhone 且临时开关为 true 时采集。系统名称缺失或不匹配则跳过。日志打印实际名称、UDID、iOS 版本及各门槛状态。宿主启动仍可能先初始化其容器，测试方法的门槛无法阻止宿主启动，因此应选定 NewPhone 后再运行。
- 保留 A～D 断言、识别错误、现有服务调用及附件机制。到 Xcode Report Navigator 展开 testCaptureOCRBatch，取出 recognition_results-pilot-<batch_id>.json。控制台也打印测试进程临时路径。
- 取得附件后把 enableNewPhonePilotCapture 改回 false。开启期间，符合条件的 Debug 全量测试也会运行采集。此开关不会在运行后自动关闭。
- 构建、测试和采集 **NOT_RUN**。NewPhone 名称是否由测试进程收到及附件交付均待 Xcode 验证。
