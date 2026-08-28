import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { Logger } from '../utils/Logger';
import { OCRService } from '../services/OCRService';
import { OCRResult } from '../models/OCRResult';

const TAG = 'PrototypeBTestPage';

/**
 * 原型 B：OCR 测试页
 */
@Entry
@Component
struct PrototypeBTestPage {
  @State testLogs: string[] = [];
  @State testResults: OCRResult[] = [];
  @State isRunning: boolean = false;
  @State selectedImages: string[] = [];

  private ocrService: OCRService = new OCRService();

  aboutToAppear(): void {
    this.addLog('=== 原型 B：OCR 测试 ===');
    this.addLog('');
    this.addLog('测试步骤：');
    this.addLog('1. 点击"选择图片"按钮');
    this.addLog('2. 从相册选择包含文字的图片');
    this.addLog('3. 点击"开始识别"进行单张测试');
    this.addLog('4. 或选择多张图片进行批量测试');
    this.addLog('5. 查看识别结果和性能数据');
    this.addLog('');
  }

  aboutToDisappear(): void {
    this.ocrService.release();
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text('←')
          .fontSize(24)
          .fontColor('#FFFFFF')
          .onClick(() => {
            router.back();
          })

        Text('原型 B：OCR 测试')
          .fontSize(18)
          .fontColor('#FFFFFF')
          .layoutWeight(1)
          .margin({ left: 10 })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#0F131C')

      // 操作按钮区
      Column() {
        Button('选择图片（单张）')
          .width('90%')
          .margin({ top: 10 })
          .enabled(!this.isRunning)
          .onClick(() => {
            this.pickSingleImage();
          })

        Button('选择多张图片（批量测试）')
          .width('90%')
          .margin({ top: 10 })
          .enabled(!this.isRunning)
          .onClick(() => {
            this.pickMultipleImages();
          })

        if (this.selectedImages.length > 0) {
          Text(`已选择 ${this.selectedImages.length} 张图片`)
            .fontSize(14)
            .fontColor('#38BDF8')
            .margin({ top: 10 })

          Button('开始识别')
            .width('90%')
            .margin({ top: 10 })
            .backgroundColor('#38BDF8')
            .enabled(!this.isRunning)
            .onClick(() => {
              this.startOCR();
            })
        }

        if (this.testResults.length > 0) {
          Button('查看统计信息')
            .width('90%')
            .margin({ top: 10 })
            .backgroundColor('#6EE7B7')
            .onClick(() => {
              this.showStatistics();
            })
        }
      }
      .width('100%')
      .backgroundColor('#0F131C')
      .padding({ bottom: 10 })

      // 测试日志
      Scroll() {
        Column() {
          ForEach(this.testLogs, (log: string, index: number) => {
            Text(log)
              .fontSize(12)
              .fontColor('#CCCCCC')
              .fontFamily('monospace')
              .width('100%')
              .margin({ bottom: 4 })
          })

          // 显示测试结果
          if (this.testResults.length > 0) {
            Text('')
              .margin({ top: 10, bottom: 10 })

            ForEach(this.testResults, (result: OCRResult, index: number) => {
              this.ResultCard(result, index + 1)
            })
          }
        }
        .width('100%')
        .padding(12)
      }
      .layoutWeight(1)
      .backgroundColor('#0A0D12')
    }
    .width('100%')
    .height('100%')
  }

  /**
   * 结果卡片
   */
  @Builder
  ResultCard(result: OCRResult, index: number) {
    Column() {
      Row() {
        Text(`#${index}`)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')

        Text(result.success ? '✅ 成功' : '❌ 失败')
          .fontSize(14)
          .fontColor(result.success ? '#6EE7B7' : '#F87171')
          .margin({ left: 10 })

        Blank()

        Text(`${result.duration}ms`)
          .fontSize(12)
          .fontColor('#999999')
      }
      .width('100%')

      if (result.text) {
        Text(`识别文本: ${result.text.substring(0, 100)}${result.text.length > 100 ? '...' : ''}`)
          .fontSize(12)
          .fontColor('#CCCCCC')
          .margin({ top: 8 })
          .width('100%')
      } else if (result.success) {
        Text('识别结果为空')
          .fontSize(12)
          .fontColor('#FCD34D')
          .margin({ top: 8 })
      }

      if (result.error) {
        Text(`错误: ${result.error.message}`)
          .fontSize(12)
          .fontColor('#F87171')
          .margin({ top: 8 })

        Text(`可重试: ${result.error.retryable ? '是' : '否'}`)
          .fontSize(12)
          .fontColor('#999999')
          .margin({ top: 4 })
      }
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#1E2636')
    .borderRadius(8)
    .margin({ bottom: 10 })
  }

  /**
   * 选择单张图片
   */
  private async pickSingleImage(): Promise<void> {
    try {
      const photoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
      photoSelectOptions.maxSelectNumber = 1;
      photoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;

      const photoPicker = new photoAccessHelper.PhotoViewPicker();
      const result = await photoPicker.select(photoSelectOptions);

      if (result.photoUris && result.photoUris.length > 0) {
        this.selectedImages = result.photoUris;
        this.addLog(`✅ 已选择图片: ${result.photoUris[0]}`);
      } else {
        this.addLog('⚠️ 用户取消选择');
      }
    } catch (error) {
      this.addLog(`❌ 选择图片失败: ${error}`);
    }
  }

  /**
   * 选择多张图片
   */
  private async pickMultipleImages(): Promise<void> {
    try {
      const photoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
      photoSelectOptions.maxSelectNumber = 20;
      photoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;

      const photoPicker = new photoAccessHelper.PhotoViewPicker();
      const result = await photoPicker.select(photoSelectOptions);

      if (result.photoUris && result.photoUris.length > 0) {
        this.selectedImages = result.photoUris;
        this.addLog(`✅ 已选择 ${result.photoUris.length} 张图片`);
      } else {
        this.addLog('⚠️ 用户取消选择');
      }
    } catch (error) {
      this.addLog(`❌ 选择图片失败: ${error}`);
    }
  }

  /**
   * 开始 OCR 识别
   */
  private async startOCR(): Promise<void> {
    if (this.selectedImages.length === 0) {
      this.addLog('⚠️ 请先选择图片');
      return;
    }

    this.isRunning = true;
    this.testResults = [];
    this.addLog('');
    this.addLog('=== 开始 OCR 识别 ===');

    try {
      // 初始化 OCR 服务
      await this.ocrService.init();
      this.addLog('✅ OCR 引擎初始化成功');

      // 逐个识别
      for (let i = 0; i < this.selectedImages.length; i++) {
        const uri = this.selectedImages[i];
        this.addLog(`正在识别 ${i + 1}/${this.selectedImages.length}...`);

        const result = await this.ocrService.recognizeText(uri);
        this.testResults = [...this.testResults, result];

        if (result.success) {
          if (result.text) {
            this.addLog(`✅ #${i + 1} 成功: ${result.text.length} 字符, ${result.duration}ms`);
          } else {
            this.addLog(`⚠️ #${i + 1} 成功但无内容, ${result.duration}ms`);
          }
        } else {
          this.addLog(`❌ #${i + 1} 失败: ${result.error?.message}, ${result.duration}ms`);
        }
      }

      this.addLog('');
      this.addLog('✅ OCR 识别完成');

    } catch (error) {
      this.addLog(`❌ OCR 识别出错: ${error}`);
    } finally {
      this.isRunning = false;
    }
  }

  /**
   * 显示统计信息
   */
  private showStatistics(): void {
    const total = this.testResults.length;
    const success = this.testResults.filter(r => r.success).length;
    const empty = this.testResults.filter(r => r.success && !r.text).length;
    const failed = this.testResults.filter(r => !r.success).length;

    const durations = this.testResults.map(r => r.duration);
    const avgDuration = durations.reduce((sum, d) => sum + d, 0) / total;
    const minDuration = Math.min(...durations);
    const maxDuration = Math.max(...durations);

    this.addLog('');
    this.addLog('=== 统计信息 ===');
    this.addLog(`总数: ${total}`);
    this.addLog(`成功: ${success} (${(success / total * 100).toFixed(1)}%)`);
    this.addLog(`空结果: ${empty} (${(empty / total * 100).toFixed(1)}%)`);
    this.addLog(`失败: ${failed} (${(failed / total * 100).toFixed(1)}%)`);
    this.addLog('');
    this.addLog(`平均耗时: ${avgDuration.toFixed(0)}ms`);
    this.addLog(`最快: ${minDuration}ms`);
    this.addLog(`最慢: ${maxDuration}ms`);

    // 错误分类统计
    const retryableErrors = this.testResults.filter(r => r.error && r.error.retryable).length;
    const nonRetryableErrors = this.testResults.filter(r => r.error && !r.error.retryable).length;

    if (failed > 0) {
      this.addLog('');
      this.addLog('错误分类:');
      this.addLog(`可重试错误: ${retryableErrors}`);
      this.addLog(`不可重试错误: ${nonRetryableErrors}`);
    }
  }

  /**
   * 添加日志
   */
  private addLog(message: string): void {
    const timestamp = new Date().toLocaleTimeString();
    const logMessage = message ? `[${timestamp}] ${message}` : '';
    this.testLogs = [...this.testLogs, logMessage];
    Logger.info(TAG, message);
  }
}
