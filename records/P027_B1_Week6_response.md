# P027-B1 执行报告

- 新增 CardOCRBatchCaptureTests.swift，修改 CardSliceTests 的资源注册与 evaluation/README.md，并归档 Prompt、Response。生产代码、真值和原结果文件保持原样。
- 测试目标从 bundle 读取项目现有真值清单及 test_data 目录。A～D 按样本 ID 逐张运行现有预处理、Vision 和 Parser。失败保留行并继续。OCR 输入为预处理图，无透视裁剪。
- 输出符合 P027-A 的结果数组、字段数组、来源与环境信息。人工更正及参考结果为 null。按批次写测试进程临时目录并附到 XCTest 报告，取得文件后通过 --results 传给计分工具。
- Debug 采集需显式开关及既有内存宿主参数。采集代码不创建名片、不访问仓库。附件导出和模拟器备用路径待验证。
- 新增一项显式启用的集成采集测试及一项确定性字段映射测试。测试与采集 **NOT_RUN**，正式准确率评估尚未开始。
