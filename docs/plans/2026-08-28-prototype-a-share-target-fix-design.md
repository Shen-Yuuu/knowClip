# 原型 A 分享目标匹配修复设计

## 背景

知微已经通过 `ShareExtensionAbility` 实现分享内容解析、确认、图片复制和本地 RDB 入库，但当前 `module.json5` 使用 MIME 类型 `image/*` 与 `text/plain` 注册分享目标。HarmonyOS 6 的 Share Kit 通过 UTD（统一类型描述符）匹配宿主应用与目标应用，导致知微没有出现在图库分享面板中。

## 已确认方案

保留现有分享面板内确认页，不打开完整 App。仅修改 `ShareExtAbility` 的注册信息及其显示名称资源：

- 保留 `type: "share"` 和现有 `ShareExtAbility.ets`。
- 为分享扩展补充知微的名称和图标资源。
- 将 MIME 类型匹配替换为精确 UTD 匹配。
- 支持 `general.image`、`general.plain-text` 和 `general.hyperlink`。
- 为图片声明有限的多文件接收数量，不使用会造成过度匹配的 `general.object`。
- 不修改分享解析、文件复制、数据库写入和原型 B OCR 代码。

## 数据流

图库或其他宿主应用使用 Share Kit 分享内容，系统根据 UTD 找到知微的 `ShareExtAbility`，随后现有扩展读取 `SharedData`，加载 `ShareConfirmPage`，由用户确认后复制附件并写入本地数据库，最后关闭分享面板。

## 验收标准

1. 工程 ArkTS 构建为 0 errors。
2. 重新安装应用后，从模拟器图库分享单张图片时能看到“知微”。
3. 点击“知微”后仍加载现有分享确认页。
4. 取消可返回分享面板，保存可进入现有本地入库流程。
5. 原型 B 的文件与行为没有变化。

## 测试说明

分享目标注册信息可能被系统缓存。修改后应卸载模拟器中的旧版知微，再通过 DevEco Studio 重新安装运行，然后测试图库分享。
