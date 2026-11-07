# P025-C1A-F02 — Week 5：修复手动裁剪单元测试的编译错误

## 一、问题背景

P025-C1A 手动裁剪功能开发完成。

用户已通过 Xcode 验证：

- App Build 成功。
- App 正常运行。
- 手动裁剪功能正常。

但执行全部单元测试时，测试目标编译失败。

Xcode 报告：

文件：\
`CardRectangleProcessingTests.swift`

共 5 个错误，均为：

`Cannot use mutating member on immutable value: '$0' is immutable`

当前不需要修复 App 业务代码。

## 二、自动归档

保存完整 Prompt：

`prompts/P025_C1A_F02_Week5_test_compile_fix.md`

完成后生成：

`records/P025_C1A_F02_Week5_response.md`

不得覆盖已有文件。

## 三、执行任务

只检查：

`app/CardSlice/CardSliceTests/CardRectangleProcessingTests.swift`

以实际测试文件路径为准。

定位五处编译错误。

重点检查：

- 闭包中对 `$0` 调用 mutating 方法。
- 对不可变值直接执行角点修改。
- 测试辅助函数中存在的值类型可变性问题。

采用最小修复方式。

如果测试确实需要修改某个值类型对象，应先创建局部可变副本，再调用 mutating 方法，并使用修改后的结果继续测试。

不得为了通过编译而删除修改操作。

## 四、测试完整性要求

必须保留原有测试意图，特别是：

1. 手动调整角点。
2. 四边形有效性验证。
3. 越界处理。
4. 坐标转换。
5. 裁剪区域状态变化。

要求：

- 不删除任何测试。
- 不删除或弱化断言。
- 不改变预期测试结果。
- 不将有效性检查改为永远通过。
- 不跳过测试。
- 不将失败测试标记为已通过。

如果发现测试中的实际调用方式与当前 API 不一致，可以按真实接口调整测试调用，但必须保持测试验证的行为不变。

## 五、修改范围

仅允许修改：

`CardRectangleProcessingTests.swift`

禁止修改：

- CardImageImportView\.swift
- 裁剪组件
- 裁剪几何算法
- OCR 服务
- Repository
- SwiftData
- 其他单元测试
- Xcode 工程配置

如发现错误确实来自生产代码，请停止并报告原因，不擅自扩大范围。

## 六、执行限制

Codex 不得执行：

- xcodebuild
- xcrun
- 模拟器
- 自动化测试
- Git 操作
- 工程清理或重置

由用户在 Xcode 中执行测试。

## 七、执行报告

说明：

1. 五处错误的实际原因。
2. 具体修改位置。
3. 是否保留所有原有测试和断言。
4. 是否修改了生产代码。
5. 构建与测试：NOT_RUN。
6. 尚未解决的问题。

完成后停止，不开始 P025-C1B。
