# 知微 KnowClip - 鸿蒙 API 技术选型

## 一、分享接收

### ShareExtensionAbility + Share Kit + UDMF

**能力说明**：
- 用户在其他应用点击"分享"，选择知微作为目标
- 支持接收图片、文本、链接等标准化数据类型
- 基于 UDMF（统一数据管理框架）传递数据

**关键 API**：
```typescript
// ShareExtensionAbility
import { ShareExtensionAbility } from '@kit.ShareKit';
import { unifiedDataChannel, uniformTypeDescriptor } from '@kit.ArkData';

export default class ShareExtAbility extends ShareExtensionAbility {
  onShare(uris: Array<string>, want: Want): void {
    // 接收分享数据
  }
}
```

**支持的数据类型**：
- `uniformTypeDescriptor.UniformDataType.IMAGE` - 图片
- `uniformTypeDescriptor.UniformDataType.TEXT` - 纯文本
- `uniformTypeDescriptor.UniformDataType.HYPERLINK` - 链接
- `uniformTypeDescriptor.UniformDataType.FILE` - 文件

**验证重点**：
1. ✅ 单图分享
2. ✅ 多图分享
3. ✅ 纯文本分享
4. ✅ 链接分享
5. ✅ 混合内容分享
6. ⚠️ URI 有效性（及时复制到私有目录）
7. ⚠️ 用户取消操作
8. ⚠️ 来源应用信息获取

**权限要求**：
```json5
{
  "requestPermissions": [
    {
      "name": "ohos.permission.READ_IMAGEVIDEO",
      "reason": "$string:permission_read_media_reason"
    }
  ]
}
```

---

## 二、端侧 OCR

### CoreVisionKit

**能力说明**：
- HarmonyOS 系统内置的视觉识别能力
- 完全端侧处理，不依赖网络
- 支持中英文混合识别

**关键 API**：
```typescript
import { textRecognition } from '@kit.CoreVisionKit';
import { image } from '@kit.ImageKit';

// 初始化
let visionInfo: textRecognition.VisionInfo = {
  pixelMap: pixelMap // image.PixelMap
};

// 识别
textRecognition.recognizeText(visionInfo, (error, data) => {
  if (error) {
    // 错误处理
  } else {
    let result = data.value; // string
  }
});
```

**验证重点**：
1. ✅ 中文文本识别
2. ✅ 英文文本识别
3. ✅ 中英混合识别
4. ⚠️ PixelMap 尺寸限制（官方建议 < 8192×8192）
5. ⚠️ 图片方向处理
6. ⚠️ 错误分类：可重试 vs 不可重试
7. ⚠️ 识别耗时与内存占用
8. ⚠️ 空结果处理
9. ⚠️ 生命周期管理（init/release）

**性能考虑**：
- 大图需降采样
- 异步处理，避免阻塞 UI
- 失败重试策略

**错误类型**：
- `1001001001` - 引擎初始化失败（不可重试）
- `1001001002` - 图片格式不支持（不可重试）
- `1001001003` - 内存不足（可重试）
- `1001001004` - 超时（可重试）

---

## 三、中文搜索

### 方案 A：FTS4 + ICU

**能力说明**：
- 关系型数据库内置的全文搜索（Full-Text Search）
- FTS4 支持中文分词（需 ICU tokenizer）
- 高性能，索引自动维护

**关键 SQL**：
```sql
-- 创建 FTS 表
CREATE VIRTUAL TABLE knowledge_fts USING fts4(
  content TEXT,
  tokenize=icu zh_CN
);

-- 搜索
SELECT * FROM knowledge_fts WHERE content MATCH '关键词';
```

**验证重点**：
1. ⚠️ HarmonyOS RDB 是否支持 FTS4
2. ⚠️ ICU tokenizer 是否可用
3. ⚠️ 中文分词效果
4. ✅ 搜索性能（1000 条以内）
5. ✅ 特殊字符处理

**优势**：
- 性能最优
- 自动维护索引
- 支持排序和高亮

**劣势**：
- 依赖 RDB 版本
- 可能不支持或配置复杂

---

### 方案 B：LIKE + 关键词索引

**能力说明**：
- 使用 SQL LIKE 进行模糊匹配
- 预提取关键词建立索引表
- 兜底方案，兼容性最好

**关键 SQL**：
```sql
-- 主表
CREATE TABLE knowledge (
  id INTEGER PRIMARY KEY,
  content TEXT,
  keywords TEXT -- 逗号分隔的关键词
);

-- 搜索（多关键词 OR）
SELECT * FROM knowledge 
WHERE content LIKE '%关键词1%' 
   OR content LIKE '%关键词2%'
   OR keywords LIKE '%关键词1%';

-- 性能优化：关键词索引表
CREATE TABLE knowledge_keywords (
  knowledge_id INTEGER,
  keyword TEXT,
  FOREIGN KEY(knowledge_id) REFERENCES knowledge(id)
);

CREATE INDEX idx_keywords ON knowledge_keywords(keyword);
```

**验证重点**：
1. ✅ 中文关键词召回
2. ✅ 多关键词组合搜索
3. ✅ 特殊字符转义
4. ⚠️ 性能（1000 条数据）
5. ⚠️ 实现复杂度

**优势**：
- 兼容性最好，所有 RDB 版本都支持
- 实现简单，可控性强
- 可自定义分词逻辑

**劣势**：
- 性能不如 FTS
- 需手动维护关键词索引
- LIKE 查询在大数据量下较慢

---

### 推荐决策流程

```
1. 尝试 FTS4 + ICU
   ├─ 成功 → 采用方案 A
   └─ 失败 → 采用方案 B（LIKE + 关键词索引）

2. 真机验证（100 条数据）
   ├─ 搜索耗时 < 500ms → 通过
   └─ 搜索耗时 > 500ms → 优化或降级

3. 记录决策理由
```

---

## 四、相册选择

### PhotoAccessHelper (Picker)

**能力说明**：
- 系统相册选择器
- 用户主动选择图片，无需申请持久化权限
- 支持单选和多选

**关键 API**：
```typescript
import { photoAccessHelper } from '@kit.MediaLibraryKit';

let photoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
photoSelectOptions.maxSelectNumber = 10;
photoSelectOptions.mimeType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;

let photoPicker = new photoAccessHelper.PhotoViewPicker();
photoPicker.select(photoSelectOptions).then((result) => {
  let uris = result.photoUris; // string[]
});
```

**验证重点**：
1. ✅ 单选
2. ✅ 多选
3. ✅ 用户取消
4. ⚠️ 重复检测（已存在的图片）

**权限要求**：
- Picker 模式无需权限（临时授权）

---

## 五、本地存储

### 关系型数据库 (RDB)

**能力说明**：
- HarmonyOS 内置的 SQLite 数据库
- 支持事务、索引、外键
- 加密支持（可选）

**关键 API**：
```typescript
import { relationalStore } from '@kit.ArkData';

// 创建数据库
const STORE_CONFIG: relationalStore.StoreConfig = {
  name: 'KnowClipDB.db',
  securityLevel: relationalStore.SecurityLevel.S1
};

relationalStore.getRdbStore(context, STORE_CONFIG, (err, store) => {
  // 使用 store
});
```

**验证重点**：
1. ✅ 数据库创建和迁移
2. ✅ 事务支持
3. ✅ 中文搜索方案验证
4. ✅ 备份和恢复

---

### 文件管理

**私有目录**：
```typescript
import { fileIo } from '@kit.CoreFileKit';

// 获取私有目录
let filesDir = context.filesDir; // /data/storage/el2/base/files
let cacheDir = context.cacheDir; // /data/storage/el2/base/cache

// 附件存储路径建议
let attachmentDir = `${filesDir}/attachments/${year}/${month}`;
```

**验证重点**：
1. ✅ URI 内容复制到私有目录
2. ✅ 缩略图生成
3. ⚠️ 存储空间不足处理

---

## 六、备份与恢复

### 文件压缩

**能力说明**：
- 使用 HarmonyOS 原生压缩能力或第三方库
- 备份内容：数据库 + 附件目录 + manifest.json

**关键 API**：
```typescript
import { zlib } from '@kit.BasicServicesKit';

// 压缩
zlib.compressFile(sourceFile, destFile, (err) => {
  // 处理结果
});

// 解压
zlib.decompressFile(sourceFile, destFile, (err) => {
  // 处理结果
});
```

**验证重点**：
1. ✅ 数据库备份
2. ✅ 附件目录备份
3. ✅ 恢复前校验
4. ⚠️ 大文件压缩性能

---

## 七、不纳入 MVP 的能力

### ❌ 控制中心快捷入口

**原因**：
- 需要 `ControlCenterExtensionAbility`（API 13+）
- 实验性能力，不稳定
- 非 MVP 核心路径

---

### ❌ 智慧识屏

**原因**：
- 需要实现 `InsightIntentExtensionAbility`
- 作为服务提供方，需要系统级权限
- 文档不完整，验证成本高

---

### ❌ 跨应用自动截图

**原因**：
- 无公开 API 支持
- 隐私和安全限制

---

### ❌ Window API 截取其他应用

**能力说明**：
- `window.snapshot()` 只能截取自身窗口
- 不能截取抖音、微信、小红书等其他应用页面

**验证结果**：
- ❌ 不能用于截取其他应用内容
- ✅ 可用于 App 内分享卡片

---

## 八、技术风险评估

| 能力 | 风险等级 | 验证方式 | 备选方案 |
|------|---------|---------|---------|
| 系统分享接收 | 🟢 低 | 真机测试 | 无 |
| 端侧 OCR | 🟡 中 | 真机测试（20 张图片） | 用户手动输入 |
| 中文搜索 FTS4 | 🟡 中 | 真机测试 | 降级 LIKE 方案 |
| 中文搜索 LIKE | 🟢 低 | 真机测试 | 无 |
| 相册 Picker | 🟢 低 | 真机测试 | 无 |
| RDB 数据库 | 🟢 低 | 真机测试 | 无 |

---

## 九、开发环境要求

- **DevEco Studio**: 5.0.0+
- **HarmonyOS SDK**: API 12+
- **真机**: HarmonyOS NEXT (非 OpenHarmony)
- **权限**: READ_IMAGEVIDEO

---

## 十、技术验证清单

### 原型 A：系统分享接收
- [ ] 单图分享
- [ ] 多图分享
- [ ] 纯文本分享
- [ ] 链接分享
- [ ] 混合内容分享
- [ ] URI 及时复制
- [ ] 用户取消处理
- [ ] 来源信息获取

### 原型 B：端侧 OCR
- [ ] CoreVisionKit 初始化
- [ ] 中文文本识别
- [ ] 图片降采样
- [ ] 错误分类
- [ ] 失败重试
- [ ] 20 张真实截图测试
- [ ] 性能与内存记录

### 原型 C：中文搜索
- [ ] FTS4 + ICU 验证
- [ ] LIKE + 关键词索引验证
- [ ] 100 条数据性能测试
- [ ] 中文词语召回对比
- [ ] 特殊字符处理
- [ ] 最终方案选择
