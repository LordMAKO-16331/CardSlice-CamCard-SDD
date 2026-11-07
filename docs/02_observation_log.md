# 02 CamCard 黑盒观察记录（v0.1）

> 真实来源：用户 iPhone 15 Plus 上 CamCard 8.65.0（English）的文字记录和截图。标记为 `[OBS]` 才代表**观察到参考 App 的行为**，不是我们的 App 已经实现/测试通过。`[GAP]` 为不足，`[COURSE]` 为老师要求。

## O01 Home ≠ CardHolder
- [OBS] Home底部导航 `Home | CardHolder | [紫色相机] | Tools | Settings`，其中 Home 内部的 `My Digital Card`、`Create New Card` 是数字名片制作；空状态 `No cards yet. Create a new one!` **发生在该模块，不得当成 CardHolder 的空名片夹基准**。
- [OBS] 真正的 `CardHolder` 独立显示 `Search`、`All Cards 3`、`Group`、`Manage`、右上角 `+`；列表按日期组织，行含图片缩略图、姓名、职位、公司和 `...`。
- [GAP] CardHolder 的真实首次空状态没有截图/验证。
- 证据：`../evidence/4201264cdfee698a1586d3687d55ca13.jpg`、`../evidence/IMG_0645.png`。

## O02 扫描、导入与图像处理
- [OBS] 扫描页包含 `Basic` 与 `High Accuracy`；Basic 中有 `Single`、`Batch` 等；屏幕下方有 `Album`、快门。高精度受登录或会员限制。
- [OBS] Single相册导入和Single相机拍摄后续流程相近，进入 `Edit Card`，上方 `Retake`、`Save`，有名片图片及右下角裁剪图标。
- [OBS] 采集到了 `Retake`/`Next`/`Done` 的流程图，但**这张来自 Batch，不能作为 Single 逐步行为**。
- [OBS] 参考 App 自动裁剪，提供重新裁剪入口。
- [GAP] 自动边界失败时的具体提示、手动四角点/透视/方向校正细节仍待验证；相机及相册权限拒绝具体文本未归档。
- 证据：`../evidence/aadd4fd438ae34e26b11403fe7feccb6.jpg`、`../evidence/6972b4ca895f2adb6395ffe539bc1d6d.jpg`、`../evidence/ddb2b436bc5864b73ba07c7fdbee4e2a.jpg`。

## O03 OCR、字段与人工修改
- [OBS] `Edit Card` 含 `Recognition Languages`、`Change`、`Full Name`、联系方式、Company、Job Title、`Edit More Info` 等；低置信/缺失字段常呈空白。
- [OBS] A 卡用户报告识别较完整。
- [OBS] B 中英混合卡：在界面设置为 English 时出现姓名与职位乱码；用户称切换中文识别语言后能够识别中文。
- [OBS] C 多电话名片：截图中3个不同用途号码都显示为 `Mobile`，多邮箱与公司/网址存在漏字/错分现象；**参考 App 的错误不构成我们可以忽略课程 T10 的理由**。
- [OBS] D 缺失字段名片：`Liu Wei` 姓名正确，`Sunrise Trading` 一度被识别成职位，Company 出现无意义字符串。
- [OBS] 可以手动编辑姓名的 First/Last Name，出现键盘与 More Options；取消后编辑不保留（用户反馈）。
- [GAP] 当前是拍摄屏幕含边缘/其他卡片的样张，不宜直接据此计算官方 OCR 准确率；需要独立清晰卡片图和Ground Truth。
- 证据：`../evidence/8e4d890a6b656c8728472b29d58f4980.jpg`、`../evidence/6a891eac67ebcf2dbe8642bc3d7a564c.jpg`、`../evidence/12ada9e2e3db6e1a026cc92b676f9935.jpg`。

## O04 保存、详情、搜索、Group、Note
- [OBS] 保存后提示 `Card Saved`，随后进入 `CardHolder / All Cards`，列表同步显示新卡；详情页标题 `Card Details`，可查看原图与字段，`Phone`、`Address`、`Note`、`Edit`等操作入口。
- [OBS] `CardHolder` 具有搜索栏；用户报告姓名/公司/职位/电话/邮箱可搜索，**按确认/提交后**出结果；未找到结果时出现英文无结果提示。用户截图验证 Note 内容如 `799` 可被搜索。
- [OBS] 用户实测 Group 的创建/添加/筛选/删除流程正常；截图有 `New a Group`、`Group`、`325 (1)`、`Ungrouped`，另有不需复刻的智能分组。
- [OBS] Note 按钮存在，点击显示 `Normal Memo`、`Contact Log`，课程仅要求普通文字备注；用户实测 Note 可搜索。
- [GAP] 分组删除后是否保留名片，备注与分组在**强制关闭后重启**是否保持，未得到逐项截图确认。原图和人工修改字段重启保持已有用户反馈。
- 证据：`../evidence/aca9278336c94030b863a9b2df53d0ed.jpg`、`../evidence/IMG_0645.png`、`../evidence/IMG_0646.png`、`../evidence/IMG_0647.png`、`../evidence/IMG_0648.png`、`../evidence/IMG_0649.png`。

## O05 系统联系人导出：入口已观察，不等于最终成功
- [OBS] `CardHolder → Manage → Save → 勾选名片 → Save to Contacts(1)`。
- [OBS] 随后出现 CamCard 申请访问联系人弹窗。提示其可以读取联系人、向通讯录保存名片，并说明仅当用户选择云备份时才可能上传可访问联系人数据。截图未显示用户已授权。
- [GAP] **是否实际写入系统Contacts，以及姓名、公司、电话等字段映射是否正确，还没有观察结果。**
- [COURSE] Contacts 与 VCF/vCard 二选一即可；[DECISION] 我们的 App 优先提供 VCF 本地导出，必须验证字段映射。
- 证据：`../evidence/IMG_0650.png`、`../evidence/IMG_0651.png`、`../evidence/IMG_0652.png`。

## O06 异常/删除
- [OBS] 用户报告返回、取消、部分权限或异常状态会出现提示，但缺少提示原文及条件细节。
- [GAP] T03/T06/T20 的精确参考行为仍不完全确定；正式规格和测试中标为待验证，不用反复全面重扫，只按失败用例定点补测。

## 证据的使用纪律
1. 用户截图用于分析页面元素、状态和流程，不能用于拷贝 CamCard 的美术、Logo 或受保护素材进我们的项目。
2. 已观察事实、课程要求和技术决策必须分开写。
3. **不允许凭空补全**未知弹窗、缺失UI、OCR文本和真实测试结果。
4. 后续新截图按 `evidence/` 新文件加入，并在该文档追加观察ID和版本；避免覆盖旧结论。
