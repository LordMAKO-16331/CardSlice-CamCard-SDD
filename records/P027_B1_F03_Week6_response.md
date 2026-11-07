# P027-B1-F03 架构审查报告

## 跳过原因

| 条件 | 静态证据 | 对这次运行的判断 |
| --- | --- | --- |
| isDebug | 项目级 Debug 设置 SWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)"，CardSliceTests 的 Debug 配置未覆盖，仓库共享 Scheme 的 TestAction 选 Debug | 按当前文件应为 true。截图的 Scheme 名称不足以确认实际测试产物，需对照该次日志的 Debug 值 |
| isSimulator | 采集使用编译期 targetEnvironment(simulator)，不读取 UI 中的目标名称 | 模拟器产物预期为 true，实际见 Simulator 日志 |
| SIMULATOR_DEVICE_NAME | 读取测试进程环境变量并与 "NewPhone" 精确比较。SIMULATOR_UDID 只记录日志 | 最可能不满足。Xcode 选中 NewPhone 不能证明变量已注入或值等于自定义名称 |
| enableNewPhonePilotCapture | 当前测试源码的静态值为 true | 若该次日志也打印 true，可排除 |

尚未取得完整的「OCR pilot 环境」日志，无法锁定这次失败字段。检查 Xcode Report Navigator 中该行即可区分条件，无需继续调参数。共享 Scheme 使用自动生成 Test Plan，继承 Launch 的参数与环境。仓库未找到独立 .xctestplan，所见共享 Scheme 未保存启动参数或采集环境变量。用户本机实际选用的配置、UI 修改是否保存和运行时传递情况仍未知。

## 限制来源

早期环境变量用于避免全量回归误跑采集，Mock 参数用于让宿主走内存仓库。F02 将防护改为 Debug、模拟器、名称和临时开关组合。名称检查仅在测试方法内生效，保护不到更早的宿主启动。

CardSliceTests 的 TEST_HOST 在 Debug 和 Release 均指向 CardSlice.app，BUNDLE_LOADER 指向该宿主。CardSliceApp 初始化 AppDatabase 时，只有 Debug 且含 Mock 参数才走内存仓库，否则打开默认 SwiftData ModelContainer。采集函数自身只读 Bundle 图片并调用现有预处理、OCR、Parser，再输出附件。算法无需 App 启动、仓库或 SwiftData。现有测试通过 @testable import CardSlice 使用这些符号，当前链接方式绑定了宿主。

## 方案比较

| | A · 复用当前宿主，最小改动 | B · 独立采集目标 |
| --- | --- | --- |
| 修改范围 | 采集测试、共享采集 Scheme 或 Test Plan、README。共享配置固定 Debug、Mock 参数及采集方法；默认回归仍排除采集。无需新 Target | 工程新增独立采集 XCTest Target 及共享 Scheme，移动采集测试或把其排除于普通目标，复用测试资源。直接编入现有预处理、OCR、Parser 及提供字段类型的 BusinessCardRecord.swift 源文件，不复制实现。采集测试改为使用同目标内类型，更新 README |
| 数据隔离 | 取决于 App 启动前实际收到 Mock 参数，或人工选用独立容器。测试内检查无法为宿主兜底，不能靠方法内去掉门槛保证隔离 | 新目标不链接或启动正式 CardSlice.app，不包含 AppDatabase、Repository 或 SwiftData。优先验证能否用 Xcode 测试运行器；若该 iOS 配置需要宿主，使用不带业务入口或持久化的最小测试宿主 |
| 用户操作 | 选共享采集 Scheme，点 Test，报告中取附件。固定参数由工程维护，无需用户输入，但须先证明传参可靠 | 选 OCR Pilot Capture Scheme 和任意兼容模拟器，点 Test。报告中取 recognition_results-pilot-<batch_id>.json，再交现有计分脚本。无需指定设备名、参数、导入相册或操作正式库 |
| 普通回归 | 不改现有单测断言。需保证普通 Scheme 排除采集，注意共享参数不能泄漏到普通回归 | 默认 CardSlice Scheme 保持原有单测和 UI 测试，采集只在专用 Scheme 执行 |
| 实现成本 | 低，但依赖已出现问题的配置传递，且仍有宿主数据库前置风险 | 中等，一次性设置源文件、资源和测试目标成员。后续随同一源文件更新算法，维护成本低。目标和附件导出需实际 Xcode 验证 |

## 结论与验收口径

A 的改动最少，仍无法从当前证据保证可靠隔离。建议 B，在保持生产 App 与现有回归宿主不变的前提下，新增一个真正独立的采集测试目标。隔离由目标结构提供后，可移除环境开关、Mock 参数、固定模拟器名及临时布尔开关。Debug 和模拟器可以作为专用 Scheme 的默认环境，避免再把它们堆成运行时数据库保护条件。

专用入口默认从 Bundle 读取 A～D，沿用现有 JSON 格式与附件。缺少资源应失败，单样本异常保留错误并继续，先交付可诊断附件再报告该批是否完整。无文字是实际识别结果，环境或引擎错误不能冒充正常采集。输入仍为预处理图，人工更正及参考结果保留 null。

仅新增本轮 Prompt 和报告。Swift、工程、Scheme 及现有数据未修改，等待确认。构建、测试与采集 **NOT_RUN**。
