# P028-B3 执行报告

- 修改 CardSliceOCRCaptureTests.swift、project.pbxproj、evaluation/README.md 与 evaluation/formal/README.md。新增本轮 Prompt 和 Response。
- 新增 testCaptureFormalOCR()。独立目标资源阶段引用正式 images 文件夹及 dataset_manifest.json，静态核对 F01～F36 共 36 张图片、真值路径和清单哈希全部一致。未纳入六张清晰原版。Xcode 实际资源打包尚待验证。
- 复用先导采集的预处理、Vision、Parser 及 JSON 附件机制。逐张记录失败并继续，输出成功、失败数量及实际临时路径。批次有失败时先保存附件再报告失败。
- Xcode 选 OCR Pilot Capture，单独运行 testCaptureFormalOCR，从 Report Navigator 导出 recognition_results-formal-<batch_id>.json。先导 testCapturePilotOCR 保留原有输入和输出行为。两个方法都属于既有采集 Scheme，运行整个 Scheme 会执行两者。原 Scheme 文件、正式 App、常规回归目标及数据库未改动。
- evaluate.py 已支持 --truth、--results、--split formal，直接指向正式真值及附件即可。
- 静态工程语法与资源隔离检查通过。构建、测试及采集 **NOT_RUN**。
