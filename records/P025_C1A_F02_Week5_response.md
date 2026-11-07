# P025-C1A-F02 执行报告

五处 `#expect` 直接调用了 `mutating moveCorner(at:to:)`。宏展开会通过不可变参数捕获方法接收者，导致诊断中的 `$0` 无法被修改，即使测试源码里的裁剪草稿已声明为 `var`。

仅修改 `CardRectangleProcessingTests.swift` 的 `testManualCropUsesEditedCornersInServiceOrder`（1 处）、`testManualCropRejectsCrossingAndDegenerateMoves`（3 处）和 `testManualCropWithoutCandidateStartsFresh`（1 处）。在宏外对原有局部可变草稿执行角点修改，再将布尔结果传给原断言。所有测试、断言、预期结果和后续状态检查均保留，生产代码未修改。

Xcode 构建与测试 **NOT_RUN**。测试目标能否通过编译及全量回归结果待用户在 Xcode 验证。
