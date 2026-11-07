# P025-B1 执行报告

| 修改文件 | 文案调整 |
| --- | --- |
| `CardHolderView.swift` | 名片夹标题、名片总数、空状态、图片导入和开发工具文案 |
| `CardDetailView.swift` | 名片详情标题、字段标签、电话类型和弹窗确认 |
| `CardFieldCorrectionView.swift` | 电话类别和 OCR 原文标签，提供共用的电话类型显示文案 |
| `CardImageImportView.swift` | 从相册导入、重拍和电话类型摘要 |
| `SingleCardCameraView.swift` | 无相机或无法访问时的相册导入提示 |
| `TagManagementView.swift`、`CardTagSelectionView.swift` | 统一标签加载失败后的重试文案，使用「名片夹」指代入口 |
| `CardSliceUITests.swift` | 同步更新导航测试的两处标题断言，保留原有覆盖 |

保留 OCR、VCF 等缩写、SDD 临时标记 `[DECISION/TEMP]` 和识别语言代码。用户字段、OCR 原文、测试数据和 VCF 协议原值保持原样。系统选择器、系统分享及底层错误详情仍可能随系统语言显示英文。

Xcode 构建与测试 **NOT_RUN**。T01～T20 尚未统一正式验收。
