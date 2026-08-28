# 知微 KnowClip

知微是一款面向 HarmonyOS NEXT 的本地知识采集应用原型，目标是把短视频、文章和聊天中值得保留的截图、文本与链接快速沉淀为可搜索的本地知识条目。内容处理与存储均在设备端完成。

## 当前阶段

项目目前处于“第 0 阶段：技术验证原型”，不是完整 MVP。

截至 2026-08-28：

- ✅ Hvigor 调试构建通过，ArkTS 为 0 errors
- ✅ 原型 A 已实现系统分享解析、确认、图片复制及 RDB 入库
- ✅ 原型 B 已接入 CoreVisionKit 初始化、识别、错误分类和资源释放
- ✅ 原型 C 已实现 100 条测试数据生成及中文/英文 LIKE 搜索
- ⏳ 三个原型仍需在 HarmonyOS NEXT 真机完成验证和记录
- ⏳ FTS4/ICU、自动关键词生成和完整知识库 UI 尚未实现

## 三个技术验证原型

### 原型 A：系统分享接收

通过 ShareExtensionAbility 接收 Share Kit 的 SharedData，在分享扩展存活期间将图片复制到应用私有目录，并把文本、链接及附件记录写入本地 RDB。

需要真机验证：

- 分享面板能否显示“知微”
- 单图、多图、纯文本和链接分享
- 不同来源应用的 URI 兼容性
- 分享扩展结束后的本地文件可访问性

### 原型 B：端侧 OCR

通过 Photo Picker 选择一张或多张截图，再调用 CoreVisionKit 进行端侧文字识别。测试页记录成功、空结果、失败类型和单张耗时。

需要真机验证：

- CoreVisionKit 在目标设备上的可用性
- 中文及中英文混排识别效果
- 20 张连续识别的性能和稳定性
- 超大图片降采样效果

### 原型 C：中文搜索

向 RDB 写入 100 条带关键词的测试数据，使用参数化 LIKE 查询内容、关键词和笔记字段，并记录结果数量和查询耗时。LIKE 是当前确定可运行的基线方案，FTS4/ICU 需要另行验证。

## 环境要求

- DevEco Studio 5.0 或更高版本
- HarmonyOS NEXT SDK API 12 或更高版本
- 当前工程配置：6.0.1(21)
- CoreVisionKit 需要 HMS SDK 和支持该能力的 HarmonyOS NEXT 真机

## 构建

推荐直接使用 DevEco Studio 打开工程并执行 Build。

命令行构建时需要保证 DEVECO_SDK_HOME 指向 DevEco SDK 根目录。例如本机：

~~~powershell
$env:DEVECO_SDK_HOME='D:\local\DevEcoStudio\sdk'
& 'D:\local\DevEcoStudio\tools\hvigor\bin\hvigorw.bat' --mode module -p product=default -p module=entry@default -p buildMode=debug assembleHap
~~~

当前工程没有提交签名配置。真机运行前，请在 DevEco Studio 中配置自动签名，不要把个人证书和密钥提交到版本库。

## 真机验证顺序

1. 配置自动签名并连接 HarmonyOS NEXT 真机。
2. 安装并启动应用，确认三个原型页面均可进入。
3. 先测试原型 C，确认 RDB 建表、写入和查询正常。
4. 再测试原型 B，准备 20 张不同场景截图并记录识别结果。
5. 最后测试原型 A，从相册、浏览器和文本应用执行系统分享。
6. 将设备型号、系统版本、成功率、耗时及失败日志写入验证报告。

## 项目结构

~~~text
entry/src/main/ets/
├── entryability/                 # 主入口
├── shareextensionability/        # 系统分享扩展
├── pages/                        # 原型导航与测试页面
├── services/                     # RDB、文件、OCR、分享会话服务
├── models/                       # 显式 ArkTS 数据模型
└── utils/                        # 日志工具
~~~

## 文档

- [项目总览](docs/00-项目总览.md)
- [产品需求文档](docs/01-产品需求文档-PRD.md)
- [鸿蒙 API 技术选型](docs/02-鸿蒙API技术选型.md)
- [开发实施计划](docs/03-开发实施计划.md)
- [数据结构设计](docs/04-数据结构设计.md)
- [第 0 阶段技术验证](docs/05-第0阶段-技术验证原型.md)
- [低保真页面设计](docs/06-低保真页面设计.md)
- [第 0 阶段工作总结](docs/07-第0阶段工作总结.md)
- [本轮完善设计](docs/plans/2026-08-28-knowclip-prototype-validation-design.md)

## 当前非目标

- 完整首页、知识详情编辑、文件夹和标签
- 自动 NLP 关键词提取
- FTS4/ICU 全文搜索
- 本地备份与恢复
- 控制中心入口、智慧识屏和跨应用自动截图
- 云端同步或云端 AI

完成三个真机原型的验证报告并作出 Go/No-Go 决策后，再进入最小纵向闭环开发。
