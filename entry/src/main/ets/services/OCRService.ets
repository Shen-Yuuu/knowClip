import { textRecognition } from '@kit.CoreVisionKit';
import { image } from '@kit.ImageKit';
import { fileIo } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { Logger } from '../utils/Logger';
import { OCRResult, OCRError } from '../models/OCRResult';

const TAG = 'OCRService';
const MAX_IMAGE_SIZE = 8192;

export class OCRService {
  private isInitialized: boolean = false;

  async init(): Promise<void> {
    if (this.isInitialized) {
      return;
    }

    try {
      const initialized = await textRecognition.init();
      if (!initialized) {
        throw new Error('OCR service returned false during initialization');
      }
      this.isInitialized = true;
      Logger.info(TAG, 'OCR engine initialized');
    } catch {
      this.isInitialized = false;
      Logger.error(TAG, 'OCR engine initialization failed');
      throw new Error('OCR 引擎初始化失败');
    }
  }

  async recognizeText(imageUri: string): Promise<OCRResult> {
    const startTime = Date.now();
    let sourceFile: fileIo.File | null = null;
    let imageSource: image.ImageSource | null = null;
    let pixelMap: image.PixelMap | null = null;

    try {
      if (!this.isInitialized) {
        await this.init();
      }

      sourceFile = await fileIo.open(imageUri, fileIo.OpenMode.READ_ONLY);
      imageSource = image.createImageSource(sourceFile.fd);
      const imageInfo = await imageSource.getImageInfo();
      const needResize =
        imageInfo.size.width > MAX_IMAGE_SIZE || imageInfo.size.height > MAX_IMAGE_SIZE;

      if (needResize) {
        const scale = MAX_IMAGE_SIZE / Math.max(imageInfo.size.width, imageInfo.size.height);
        const decodingOptions: image.DecodingOptions = {
          desiredSize: {
            width: Math.floor(imageInfo.size.width * scale),
            height: Math.floor(imageInfo.size.height * scale)
          },
          desiredPixelFormat: image.PixelMapFormat.RGBA_8888
        };
        pixelMap = await imageSource.createPixelMap(decodingOptions);
      } else {
        pixelMap = await imageSource.createPixelMap();
      }

      const visionInfo: textRecognition.VisionInfo = {
        pixelMap: pixelMap
      };
      const recognitionResult = await textRecognition.recognizeText(visionInfo);
      const duration = Date.now() - startTime;
      const recognizedText =
        recognitionResult.value.length > 0 ? recognitionResult.value : null;

      Logger.info(TAG, `OCR completed in ${duration}ms`);
      return {
        success: true,
        text: recognizedText,
        confidence: null,
        duration: duration,
        error: null
      };
    } catch (error) {
      const err = error as BusinessError;
      const duration = Date.now() - startTime;
      const ocrError = this.parseOCRError(err);
      Logger.error(TAG, `OCR failed with code ${ocrError.code} after ${duration}ms`);
      return {
        success: false,
        text: null,
        confidence: null,
        duration: duration,
        error: ocrError
      };
    } finally {
      if (pixelMap !== null) {
        try {
          await pixelMap.release();
        } catch {
          Logger.warn(TAG, 'Failed to release PixelMap');
        }
      }
      if (imageSource !== null) {
        try {
          await imageSource.release();
        } catch {
          Logger.warn(TAG, 'Failed to release ImageSource');
        }
      }
      if (sourceFile !== null) {
        try {
          fileIo.closeSync(sourceFile);
        } catch {
          Logger.warn(TAG, 'Failed to close OCR source image');
        }
      }
    }
  }

  async recognizeBatch(imagePaths: string[]): Promise<OCRResult[]> {
    const results: OCRResult[] = [];
    for (const path of imagePaths) {
      const result = await this.recognizeText(path);
      results.push(result);
      await this.delay(100);
    }
    return results;
  }

  private parseOCRError(error: BusinessError): OCRError {
    const code = Number(error.code);
    switch (code) {
      case 200:
        return { code: code, message: '识别超时，请稍后重试', retryable: true };
      case 401:
        return { code: code, message: '图片参数不合法', retryable: false };
      case 1001400001:
        return { code: code, message: 'OCR 执行失败，请重试', retryable: true };
      case 1001400002:
        return { code: code, message: 'OCR 服务异常，请稍后重试', retryable: true };
      default:
        return {
          code: Number.isNaN(code) ? -1 : code,
          message: error.message ? error.message : '未知 OCR 错误',
          retryable: true
        };
    }
  }

  private delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  async release(): Promise<void> {
    if (!this.isInitialized) {
      return;
    }

    try {
      await textRecognition.release();
    } finally {
      this.isInitialized = false;
      Logger.info(TAG, 'OCR engine released');
    }
  }
}
