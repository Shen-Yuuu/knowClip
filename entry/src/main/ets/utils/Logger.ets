import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0001;

export class Logger {
  static info(tag: string, message: string): void {
    hilog.info(DOMAIN, tag, message);
    console.info(`[${tag}] ${message}`);
  }

  static error(tag: string, message: string): void {
    hilog.error(DOMAIN, tag, message);
    console.error(`[${tag}] ${message}`);
  }

  static warn(tag: string, message: string): void {
    hilog.warn(DOMAIN, tag, message);
    console.warn(`[${tag}] ${message}`);
  }

  static debug(tag: string, message: string): void {
    hilog.debug(DOMAIN, tag, message);
    console.debug(`[${tag}] ${message}`);
  }
}