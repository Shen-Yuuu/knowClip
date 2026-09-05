# 原型 A/B 媒体 URI 兼容修复设计

## 背景

真机验证发现两个相关问题：原型 A 从系统图库分享单张图片到知微后，分享扩展显示“未解析到可保存的分享内容”；原型 B 从图库选择图片执行 OCR 时，图像框架把媒体 URI 当作普通文件路径解析，产生 `path to realpath error` 并无法创建 `ImageSource`。

两个问题的共同原因是图库和系统分享提供的是受系统授权的媒体 URI，而不是应用可直接按文件路径读取的地址；此外，图库分享数据在不同系统版本或入口下可能位于 `SharedData`、`SharedRecord.uri`、`SharedRecord.content` 或 `Want.uri`。

## 目标与范围

本次只修复原型输入解析和本地文件读取，不调整页面布局、数据库结构、OCR 算法或云端能力。原型 A 以“系统图库单张图片 → 分享 → 知微”为主要验收路径，并继续兼容已有文本分享；原型 B 以 Photo Picker 返回的媒体 URI 为输入完成端侧 OCR。

## 方案

### 原型 A：分层解析分享数据

分享扩展优先调用 `systemShare.getSharedData(want)`。解析每条 `SharedRecord` 时，优先读取 `record.uri`；当图片记录没有 `uri` 时，兼容从 `record.content` 取得媒体 URI；普通文本和超链接仍作为文本处理。

如果 `getSharedData` 抛错，或解析后的图片、文本和链接均为空，则回退读取 `want.uri`。图库单张图片分享场景中，将该 URI 作为待保存图片传给分享页面。日志记录读取阶段、错误信息、记录 UTD、是否存在 URI 以及解析数量，不记录完整私人 URI。

### 原型 A：通过文件描述符复制共享图片

保存时先用 `fileIo.open(uri, READ_ONLY)` 打开系统授予访问权的媒体 URI，再将源文件描述符复制到应用沙箱目标文件。无论成功或失败都关闭文件描述符，避免直接把媒体 URI 传给只适合普通路径的文件操作。

### 原型 B：通过文件描述符创建图像源

OCR 服务先用 `fileIo.open(uri, READ_ONLY)` 打开 Photo Picker 返回的媒体 URI，再把文件描述符传给 `image.createImageSource(fd)`。图像解码、PixelMap 创建和 OCR 流程保持不变，并在 `finally` 中依次释放 PixelMap、ImageSource 和源文件描述符。

## 错误处理

分享扩展仅在所有解析入口均未取得内容时展示当前空状态；若主入口失败但 `Want.uri` 可用，则继续展示预览。文件打开、复制、图像解码或 OCR 失败时保留明确阶段日志并向现有 UI 返回失败结果，不新增静默降级或云端调用。

## 验收标准

1. 系统图库选择一张图片并分享到知微后，分享页面显示图片预览，“保存”按钮可用。
2. 点击保存后，图片被复制到应用沙箱并完成现有保存流程。
3. 原型 B 选择图库图片后，不再出现 `path to realpath error` 或 `CreateImageSourceExec error`，能够进入 OCR 识别阶段并显示现有结果或明确的 OCR 引擎错误。
4. 文本分享能力不因本次修改而退化。
5. 项目通过现有 ArkTS 编译检查；若本地命令行环境无法完成签名或设备相关步骤，应明确记录边界并由 DevEco Studio 真机复测。
