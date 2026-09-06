import { router } from '@kit.ArkUI';
import { systemShare } from '@kit.ShareKit';
import { ShareData, CopyResult } from '../models/ShareData';
import {
  AttachmentInsertData,
  DatabaseService,
  KnowledgeInsertData
} from '../services/DatabaseService';
import { FileService } from '../services/FileService';
import { ShareSessionService } from '../services/ShareSessionService';
import { PrototypeALog } from '../utils/PrototypeALog';

const TAG = 'ShareConfirmPage';

// ShareExtAbility passes session-scoped data through loadContent().
// Bind this page to that shared LocalStorage instead of creating an empty instance.
@Entry({ useSharedStorage: true })
@Component
struct ShareConfirmPage {
  @LocalStorageLink('currentShareData') shareData: ShareData = {
    images: [],
    text: null,
    url: null,
    sourceApp: null
  };
  @State statusText: string = '⏳ 准备接收...';
  @State canSave: boolean = true;

  aboutToAppear(): void {
    PrototypeALog.info(TAG, '确认页面',
      `aboutToAppear images=${this.shareData.images.length}, ` +
      `textLength=${this.shareData.text?.length ?? 0}, hasUrl=${this.shareData.url !== null}`);
    if (this.shareData.images.length === 0 && !this.shareData.text) {
      this.statusText = '⚠️ 未解析到可保存的分享内容';
      PrototypeALog.warn(TAG, '确认页面', 'received empty share data; save disabled');
    } else {
      this.statusText = '✅ 分享内容已解析，请确认保存';
      PrototypeALog.info(TAG, '确认页面', 'share data ready; save enabled');
    }
  }

  build() {
    Column() {
      Row() {
        Text('← 分享到知微')
          .fontSize(18)
          .fontColor('#FFFFFF')
          .layoutWeight(1)
          .onClick(() => {
            this.handleCancel();
          })

        Text('✕')
          .fontSize(20)
          .fontColor('#FFFFFF')
          .onClick(() => {
            this.handleCancel();
          })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#0F131C')

      Scroll() {
        Column() {
          Text(this.shareData.sourceApp ? `来源：${this.shareData.sourceApp}` : '来源：系统分享')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ top: 16, bottom: 16 })

          ForEach(this.shareData.images, (uri: string, index: number) => {
            Column() {
              Text(`图片 ${index + 1}`)
                .fontSize(14)
                .fontColor('#CCCCCC')
              Text(uri)
                .fontSize(12)
                .fontColor('#666666')
                .margin({ top: 5 })
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .width('100%')
            .padding(12)
            .backgroundColor('#1E2636')
            .borderRadius(8)
            .margin({ bottom: 10 })
            .alignItems(HorizontalAlign.Start)
          })

          if (this.shareData.text) {
            Column() {
              Text('分享文本')
                .fontSize(14)
                .fontColor('#CCCCCC')
                .margin({ bottom: 5 })
              Text(this.shareData.text)
                .fontSize(14)
                .fontColor('#FFFFFF')
                .maxLines(5)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .width('100%')
            .padding(12)
            .backgroundColor('#1E2636')
            .borderRadius(8)
            .margin({ bottom: 10 })
            .alignItems(HorizontalAlign.Start)
          }

          if (this.shareData.url) {
            Column() {
              Text('链接')
                .fontSize(14)
                .fontColor('#CCCCCC')
                .margin({ bottom: 5 })
              Text(this.shareData.url)
                .fontSize(14)
                .fontColor('#38BDF8')
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .width('100%')
            .padding(12)
            .backgroundColor('#1E2636')
            .borderRadius(8)
            .margin({ bottom: 10 })
            .alignItems(HorizontalAlign.Start)
          }

          Text(this.statusText)
            .fontSize(14)
            .fontColor(this.statusText.includes('✅') ? '#6EE7B7' : '#FFFFFF')
            .margin({ top: 20, bottom: 20 })
        }
        .width('100%')
        .padding(16)
      }
      .layoutWeight(1)

      Row() {
        Button('取消')
          .width('45%')
          .backgroundColor('#666666')
          .onClick(() => {
            this.handleCancel();
          })

        Button('保存')
          .width('45%')
          .backgroundColor('#38BDF8')
          .enabled(this.canSave &&
            (this.shareData.images.length > 0 || this.shareData.text !== null))
          .onClick(() => {
            this.handleSave();
          })
      }
      .width('100%')
      .height(64)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#0A0D12')
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#0A0D12')
  }

  private async handleCancel(): Promise<void> {
    PrototypeALog.info(TAG, '用户操作', 'cancel requested');
    const terminated =
      await ShareSessionService.getInstance().terminate(systemShare.ShareAbilityResultCode.BACK);
    PrototypeALog.info(TAG, '用户操作', `cancel result sessionTerminated=${terminated}`);
    if (!terminated) {
      PrototypeALog.warn(TAG, '会话关闭', 'no extension session; use router.back fallback');
      router.back();
    }
  }

  private async handleSave(): Promise<void> {
    let phase = '开始保存';
    this.canSave = false;
    this.statusText = '🔄 正在复制并保存...';
    PrototypeALog.info(TAG, '用户操作',
      `save requested images=${this.shareData.images.length}, ` +
      `textLength=${this.shareData.text?.length ?? 0}`);

    const context = this.getUIContext().getHostContext();
    if (!context) {
      this.statusText = '❌ 无法获取应用上下文';
      this.canSave = true;
      PrototypeALog.error(TAG, '应用上下文', 'host context unavailable');
      return;
    }
    PrototypeALog.info(TAG, '应用上下文', 'host context ready');

    try {
      phase = '复制图片';
      PrototypeALog.info(TAG, '文件复制', `batch start count=${this.shareData.images.length}`);
      const fileService = new FileService(context);
      const copyResults = await fileService.copyMultipleImages(this.shareData.images);
      const successfulCopies = this.countSuccessfulCopies(copyResults);
      PrototypeALog.info(TAG, '文件复制',
        `batch complete success=${successfulCopies}, total=${copyResults.length}`);
      if (this.shareData.images.length > 0 && successfulCopies === 0 && !this.shareData.text) {
        throw new Error('所有分享图片均复制失败');
      }

      phase = '初始化数据库';
      PrototypeALog.info(TAG, '数据库保存', 'database init start');
      const database = DatabaseService.getInstance();
      const initialized = await database.init(context);
      if (!initialized) {
        throw new Error('数据库初始化失败');
      }
      PrototypeALog.info(TAG, '数据库保存', 'database init success');

      phase = '写入知识条目';
      const knowledgeData: KnowledgeInsertData = {
        content: this.shareData.text,
        keywords: [],
        sourceType: 'share',
        sourceApp: this.shareData.sourceApp,
        sourceText: this.shareData.text,
        sourceUrl: this.shareData.url,
        hasImage: successfulCopies > 0,
        imageCount: successfulCopies
      };
      const knowledgeId = await database.insertKnowledge(knowledgeData);
      PrototypeALog.info(TAG, '数据库保存', `knowledge inserted id=${knowledgeId}`);

      phase = '写入附件';
      await this.saveAttachments(database, fileService, knowledgeId, copyResults);
      PrototypeALog.info(TAG, '数据库保存',
        `attachments complete knowledgeId=${knowledgeId}, count=${successfulCopies}`);

      phase = '完成保存';
      if (successfulCopies < this.shareData.images.length) {
        this.statusText =
          `⚠️ 已保存条目，图片成功 ${successfulCopies}/${this.shareData.images.length}`;
      } else {
        this.statusText = '✅ 已保存到本地收件箱';
      }
      PrototypeALog.info(TAG, '保存结果',
        `success knowledgeId=${knowledgeId}, images=${successfulCopies}/${this.shareData.images.length}`);

      setTimeout(() => {
        this.terminateAfterSave();
      }, 800);
    } catch (error) {
      this.statusText = '❌ 保存失败，请重试';
      this.canSave = true;
      const errorName = error instanceof Error ? error.name : 'UnknownError';
      PrototypeALog.error(TAG, '保存结果', `failed phase=${phase}, errorType=${errorName}`);
    }
  }

  private async terminateAfterSave(): Promise<void> {
    try {
      PrototypeALog.info(TAG, '会话关闭', 'delayed close requested');
      const terminated =
        await ShareSessionService.getInstance().terminate(systemShare.ShareAbilityResultCode.CLOSE);
      PrototypeALog.info(TAG, '会话关闭', `delayed close result sessionTerminated=${terminated}`);
    } catch (error) {
      const errorName = error instanceof Error ? error.name : 'UnknownError';
      PrototypeALog.error(TAG, '会话关闭', `delayed close failed errorType=${errorName}`);
    }
  }

  private countSuccessfulCopies(results: CopyResult[]): number {
    let count = 0;
    for (const result of results) {
      if (result.success && result.localPath !== null) {
        count++;
      }
    }
    return count;
  }

  private async saveAttachments(database: DatabaseService, fileService: FileService,
    knowledgeId: number, results: CopyResult[]): Promise<void> {
    for (let index = 0; index < results.length; index++) {
      const result = results[index];
      if (!result.success || result.localPath === null) {
        PrototypeALog.warn(TAG, '附件写入', `skip index=${index}, copySuccess=${result.success}`);
        continue;
      }

      PrototypeALog.info(TAG, '附件写入', `insert start index=${index}`);
      const attachmentData: AttachmentInsertData = {
        knowledgeId: knowledgeId,
        fileType: 'image',
        mimeType: 'image/*',
        filePath: result.localPath,
        originalUri: this.shareData.images[index],
        fileSize: await fileService.getFileSize(result.localPath)
      };
      await database.insertAttachment(attachmentData);
      PrototypeALog.info(TAG, '附件写入', `insert success index=${index}`);
    }
  }
}
