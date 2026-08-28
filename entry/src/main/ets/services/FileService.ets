import { fileIo } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { Logger } from '../utils/Logger';
import { CopyResult } from '../models/ShareData';

const TAG = 'FileService';

/**
 * 文件服务
 */
export class FileService {
  private context: common.Context;

  constructor(context: common.Context) {
    this.context = context;
  }

  /**
   * 复制图片到私有目录
   */
  async copyImageToPrivate(uri: string): Promise<CopyResult> {
    const startTime = Date.now();

    try {
      // 生成目标路径
      const timestamp = Date.now();
      const randomHash = Math.random().toString(36).substring(2, 8);
      const fileName = `${this.formatDate(timestamp)}_${randomHash}.jpg`;

      const targetDir = `${this.context.filesDir}/attachments/${this.getYearMonth(timestamp)}`;
      const targetPath = `${targetDir}/${fileName}`;

      // 确保目录存在
      await this.ensureDirectory(targetDir);

      // 复制文件
      Logger.info(TAG, `Copying ${uri} to ${targetPath}`);

      await fileIo.copyFile(uri, targetPath);

      // 验证文件是否复制成功
      const stat = await fileIo.stat(targetPath);
      if (stat.size === 0) {
        throw new Error('Copied file is empty');
      }

      const duration = Date.now() - startTime;
      Logger.info(TAG, `Copy success: ${targetPath}, size: ${stat.size}, duration: ${duration}ms`);

      return {
        success: true,
        localPath: targetPath,
        error: null
      };

    } catch (error) {
      const duration = Date.now() - startTime;
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Copy failed after ${duration}ms: ${errorMessage}`);

      return {
        success: false,
        localPath: null,
        error: errorMessage
      };
    }
  }

  /**
   * 批量复制图片
   */
  async copyMultipleImages(uris: string[]): Promise<CopyResult[]> {
    const results: CopyResult[] = [];

    for (const uri of uris) {
      const result = await this.copyImageToPrivate(uri);
      results.push(result);
    }

    return results;
  }

  /**
   * 确保目录存在
   */
  private async ensureDirectory(dirPath: string): Promise<void> {
    try {
      await fileIo.access(dirPath);
    } catch {
      // 目录不存在，创建
      await fileIo.mkdir(dirPath, true);
      Logger.info(TAG, `Directory created: ${dirPath}`);
    }
  }

  /**
   * 格式化日期为文件名
   */
  private formatDate(timestamp: number): string {
    const date = new Date(timestamp);
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const hour = String(date.getHours()).padStart(2, '0');
    const minute = String(date.getMinutes()).padStart(2, '0');
    const second = String(date.getSeconds()).padStart(2, '0');
    return `${year}${month}${day}_${hour}${minute}${second}`;
  }

  /**
   * 获取年月目录名
   */
  private getYearMonth(timestamp: number): string {
    const date = new Date(timestamp);
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    return `${year}/${month}`;
  }

  /**
   * 获取附件存储目录
   */
  getAttachmentDir(): string {
    return `${this.context.filesDir}/attachments`;
  }

  /**
   * 检查文件是否存在
   */
  async fileExists(path: string): Promise<boolean> {
    try {
      await fileIo.access(path);
      return true;
    } catch {
      return false;
    }
  }

  /**
   * 获取文件大小
   */
  async getFileSize(path: string): Promise<number> {
    try {
      const stat = await fileIo.stat(path);
      return Number(stat.size);
    } catch {
      return 0;
    }
  }
}
