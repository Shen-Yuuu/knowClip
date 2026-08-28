import { router } from '@kit.ArkUI';
import { systemShare } from '@kit.ShareKit';
import { Logger } from '../utils/Logger';
import { ShareData, CopyResult } from '../models/ShareData';
import {
  AttachmentInsertData,
  DatabaseService,
  KnowledgeInsertData
} from '../services/DatabaseService';
import { FileService } from '../services/FileService';
import { ShareSessionService } from '../services/ShareSessionService';

const TAG = 'ShareConfirmPage';
const sharePageStorage = new LocalStorage();

@Entry(sharePageStorage)
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
    Logger.info(TAG, `Received ${this.shareData.images.length} shared files`);
    if (this.shareData.images.length === 0 && !this.shareData.text) {
      this.statusText = '⚠️ 未解析到可保存的分享内容';
    } else {
      this.statusText = '✅ 分享内容已解析，请确认保存';
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
    Logger.info(TAG, 'User cancelled share');
    const terminated =
      await ShareSessionService.getInstance().terminate(systemShare.ShareAbilityResultCode.BACK);
    if (!terminated) {
      router.back();
    }
  }

  private async handleSave(): Promise<void> {
    this.canSave = false;
    this.statusText = '🔄 正在复制并保存...';

    const context = this.getUIContext().getHostContext();
    if (!context) {
      this.statusText = '❌ 无法获取应用上下文';
      this.canSave = true;
      return;
    }

    try {
      const fileService = new FileService(context);
      const copyResults = await fileService.copyMultipleImages(this.shareData.images);
      const successfulCopies = this.countSuccessfulCopies(copyResults);
      if (this.shareData.images.length > 0 && successfulCopies === 0 && !this.shareData.text) {
        throw new Error('所有分享图片均复制失败');
      }
      const database = DatabaseService.getInstance();
      const initialized = await database.init(context);
      if (!initialized) {
        throw new Error('数据库初始化失败');
      }

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
      await this.saveAttachments(database, fileService, knowledgeId, copyResults);

      if (successfulCopies < this.shareData.images.length) {
        this.statusText =
          `⚠️ 已保存条目，图片成功 ${successfulCopies}/${this.shareData.images.length}`;
      } else {
        this.statusText = '✅ 已保存到本地收件箱';
      }
      Logger.info(TAG, `Share saved as knowledge #${knowledgeId}`);

      setTimeout(() => {
        ShareSessionService.getInstance().terminate(systemShare.ShareAbilityResultCode.CLOSE);
      }, 800);
    } catch {
      this.statusText = '❌ 保存失败，请重试';
      this.canSave = true;
      Logger.error(TAG, 'Failed to persist shared data');
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
        continue;
      }

      const attachmentData: AttachmentInsertData = {
        knowledgeId: knowledgeId,
        fileType: 'image',
        mimeType: 'image/*',
        filePath: result.localPath,
        originalUri: this.shareData.images[index],
        fileSize: await fileService.getFileSize(result.localPath)
      };
      await database.insertAttachment(attachmentData);
    }
  }
}
