import { fileIo } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { CopyResult } from '../models/ShareData';
import { PrototypeALog } from '../utils/PrototypeALog';

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
    let phase = '准备目标';
    let sourceFile: fileIo.File | null = null;
    let targetFile: fileIo.File | null = null;
    PrototypeALog.info(TAG, '文件复制',
      `single start uriScheme=${PrototypeALog.uriScheme(uri)}`);

    try {
      // 生成目标路径
      const timestamp = Date.now();
      const randomHash = Math.random().toString(36).substring(2, 8);
      const fileName = `${this.formatDate(timestamp)}_${randomHash}.jpg`;

      const targetDir = `${this.context.filesDir}/attachments/${this.getYearMonth(timestamp)}`;
      const targetPath = `${targetDir}/${fileName}`;

      // 确保目录存在。fileIo.access() 在路径不存在时返回 false，而不是必然抛出异常。
      phase = '准备目标目录';
      await this.ensureDirectory(targetDir);
      PrototypeALog.info(TAG, '文件复制', 'target directory ready');

      // 复制文件
      phase = '打开源文件';
      sourceFile = await fileIo.open(uri, fileIo.OpenMode.READ_ONLY);
      PrototypeALog.info(TAG, '文件复制', 'source opened');

      phase = '打开目标文件';
      targetFile = await fileIo.open(targetPath,
        fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.TRUNC);
      PrototypeALog.info(TAG, '文件复制', 'target opened');

      phase = '复制文件内容';
      await fileIo.copyFile(sourceFile.fd, targetFile.fd);
      PrototypeALog.info(TAG, '文件复制', 'copyFile completed');

      // 验证文件是否复制成功
      phase = '校验文件';
      const stat = await fileIo.stat(targetPath);
      if (stat.size === 0) {
        throw new Error('Copied file is empty');
      }

      const duration = Date.now() - startTime;
      PrototypeALog.info(TAG, '文件复制',
        `single success size=${stat.size}, duration=${duration}ms`);

      return {
        success: true,
        localPath: targetPath,
        error: null
      };

    } catch (error) {
      const duration = Date.now() - startTime;
      const businessError = error as BusinessError;
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      const errorName = error instanceof Error ? error.name : 'UnknownError';
      PrototypeALog.error(TAG, '文件复制',
        `single failed phase=${phase}, errorType=${errorName}, ` +
        `errorCode=${businessError.code}, duration=${duration}ms`);

      return {
        success: false,
        localPath: null,
        error: errorMessage
      };
    } finally {
      if (targetFile !== null) {
        try {
          fileIo.closeSync(targetFile);
          PrototypeALog.info(TAG, '资源释放', 'target file closed');
        } catch {
          PrototypeALog.warn(TAG, '资源释放', 'target file close failed');
        }
      }
      if (sourceFile !== null) {
        try {
          fileIo.closeSync(sourceFile);
          PrototypeALog.info(TAG, '资源释放', 'source file closed');
        } catch {
          PrototypeALog.warn(TAG, '资源释放', 'source file close failed');
        }
      }
    }
  }

  /**
   * 批量复制图片
   */
  async copyMultipleImages(uris: string[]): Promise<CopyResult[]> {
    const results: CopyResult[] = [];
    PrototypeALog.info(TAG, '批量复制', `start count=${uris.length}`);

    for (let index = 0; index < uris.length; index++) {
      const uri = uris[index];
      PrototypeALog.info(TAG, '批量复制',
        `item start index=${index}, uriScheme=${PrototypeALog.uriScheme(uri)}`);
      const result = await this.copyImageToPrivate(uri);
      results.push(result);
      PrototypeALog.info(TAG, '批量复制', `item complete index=${index}, success=${result.success}`);
    }

    PrototypeALog.info(TAG, '批量复制', `complete count=${results.length}`);
    return results;
  }

  /**
   * 确保目录存在
   */
  private async ensureDirectory(dirPath: string): Promise<void> {
    const exists = await fileIo.access(dirPath);
    if (exists) {
      PrototypeALog.info(TAG, '文件复制', 'target directory already exists');
      return;
    }

    await fileIo.mkdir(dirPath, true);
    PrototypeALog.info(TAG, '文件复制', 'target directory created');
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
