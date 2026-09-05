import { ShareExtensionAbility, UIExtensionContentSession, Want } from '@kit.AbilityKit';
import { systemShare } from '@kit.ShareKit';
import { Logger } from '../utils/Logger';
import { ShareData } from '../models/ShareData';
import { ShareDataParser } from '../services/ShareDataParser';
import { ShareSessionService } from '../services/ShareSessionService';

const TAG = 'ShareExtAbility';

/**
 * 系统分享扩展：解析 Share Kit 的强类型数据并加载确认页面。
 */
export default class ShareExtAbility extends ShareExtensionAbility {
  private readonly shareDataParser: ShareDataParser = new ShareDataParser();

  onCreate(): void {
    Logger.info(TAG, 'ShareExtAbility onCreate');
  }

  async onSessionCreate(want: Want, session: UIExtensionContentSession): Promise<void> {
    Logger.info(TAG, 'onSessionCreate');
    ShareSessionService.getInstance().setSession(session);

    const storage = new LocalStorage();
    let shareData: ShareData;
    try {
      const sharedData = await systemShare.getSharedData(want);
      const records = sharedData.getRecords();
      this.logRecordMetadata(records);
      shareData = this.shareDataParser.parse(records, want.uri);
      Logger.info(TAG,
        `Parsed share data: records=${records.length}, images=${shareData.images.length}, ` +
        `hasText=${shareData.text !== null}`);
    } catch (error) {
      const errorName = error instanceof Error ? error.name : 'UnknownError';
      Logger.error(TAG, `getSharedData failed (${errorName}), using Want URI fallback`);
      shareData = this.shareDataParser.parse([], want.uri);
    }
    storage.setOrCreate<ShareData>('currentShareData', shareData);

    if (this.shareDataParser.isEmpty(shareData)) {
      Logger.warn(TAG, `No share content found; hasWantUri=${want.uri !== undefined}`);
    }

    try {
      session.loadContent('pages/ShareConfirmPage', storage);
    } catch {
      Logger.error(TAG, 'Failed to load share confirm page');
      await ShareSessionService.getInstance().terminate(systemShare.ShareAbilityResultCode.ERROR);
    }
  }

  private logRecordMetadata(records: Array<systemShare.SharedRecord>): void {
    for (const record of records) {
      Logger.info(TAG,
        `SharedRecord utd=${record.utd}, hasUri=${record.uri !== undefined}, ` +
        `hasContent=${record.content !== undefined}`);
    }
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
