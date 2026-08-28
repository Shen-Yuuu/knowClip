import { ShareExtensionAbility, UIExtensionContentSession, Want } from '@kit.AbilityKit';
import { systemShare } from '@kit.ShareKit';
import { Logger } from '../utils/Logger';
import { ShareData } from '../models/ShareData';
import { ShareSessionService } from '../services/ShareSessionService';

const TAG = 'ShareExtAbility';

/**
 * 系统分享扩展：解析 Share Kit 的强类型数据并加载确认页面。
 */
export default class ShareExtAbility extends ShareExtensionAbility {
  onCreate(): void {
    Logger.info(TAG, 'ShareExtAbility onCreate');
  }

  async onSessionCreate(want: Want, session: UIExtensionContentSession): Promise<void> {
    Logger.info(TAG, 'onSessionCreate');
    ShareSessionService.getInstance().setSession(session);

    const storage = new LocalStorage();
    try {
      const sharedData = await systemShare.getSharedData(want);
      const shareData = this.parseSharedRecords(sharedData.getRecords());
      storage.setOrCreate<ShareData>('currentShareData', shareData);
      Logger.info(TAG, `Parsed ${shareData.images.length} shared files`);
    } catch {
      const emptyData: ShareData = {
        images: [],
        text: null,
        url: null,
        sourceApp: null
      };
      storage.setOrCreate<ShareData>('currentShareData', emptyData);
      Logger.error(TAG, 'Failed to parse shared data');
    }

    try {
      session.loadContent('pages/ShareConfirmPage', storage);
    } catch {
      Logger.error(TAG, 'Failed to load share confirm page');
      await ShareSessionService.getInstance().terminate(systemShare.ShareAbilityResultCode.ERROR);
    }
  }

  private parseSharedRecords(records: Array<systemShare.SharedRecord>): ShareData {
    const images: string[] = [];
    const textParts: string[] = [];

    for (const record of records) {
      if (record.uri) {
        images.push(record.uri);
      }
      if (record.content) {
        textParts.push(record.content);
      }
    }

    const text = textParts.length > 0 ? textParts.join('\n') : null;
    return {
      images: images,
      text: text,
      url: this.extractUrl(text),
      sourceApp: null
    };
  }

  private extractUrl(text: string | null): string | null {
    if (!text) {
      return null;
    }

    const urlPattern = /https?:\/\/[^\s]+/i;
    const match = text.match(urlPattern);
    return match ? match[0] : null;
  }

  onSessionDestroy(session: UIExtensionContentSession): void {
    ShareSessionService.getInstance().clearSession();
    Logger.info(TAG, 'onSessionDestroy');
  }

  onForeground(): void {
    Logger.info(TAG, 'ShareExtAbility onForeground');
  }

  onBackground(): void {
    Logger.info(TAG, 'ShareExtAbility onBackground');
  }

  onDestroy(): void {
    ShareSessionService.getInstance().clearSession();
    Logger.info(TAG, 'ShareExtAbility onDestroy');
  }
}
