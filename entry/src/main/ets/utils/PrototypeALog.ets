import { Logger } from './Logger';

/**
 * 原型 A 专用诊断日志。统一首字段，并避免输出完整媒体 URI。
 */
export class PrototypeALog {
  static info(tag: string, stage: string, message: string): void {
    Logger.info(tag, `[原型A][${stage}] ${message}`);
  }

  static warn(tag: string, stage: string, message: string): void {
    Logger.warn(tag, `[原型A][${stage}] ${message}`);
  }

  static error(tag: string, stage: string, message: string): void {
    Logger.error(tag, `[原型A][${stage}] ${message}`);
  }

  static uriScheme(uri?: string): string {
    if (!uri) {
      return 'none';
    }
    const separatorIndex = uri.indexOf(':');
    if (separatorIndex <= 0) {
      return 'relative';
    }
    return uri.substring(0, separatorIndex).toLowerCase();
  }
}
