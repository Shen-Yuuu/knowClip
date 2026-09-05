import { ShareExtensionAbility, UIExtensionContentSession, Want } from '@kit.AbilityKit';
import { systemShare } from '@kit.ShareKit';
import { ShareData } from '../models/ShareData';
import { ShareDataParser } from '../services/ShareDataParser';
import { ShareSessionService } from '../services/ShareSessionService';
import { PrototypeALog } from '../utils/PrototypeALog';

const TAG = 'ShareExtAbility';

/**
 * 系统分享扩展：解析 Share Kit 的强类型数据并加载确认页面。
 */
export default class ShareExtAbility extends ShareExtensionAbility {
  private readonly shareDataParser: ShareDataParser = new ShareDataParser();

  onCreate(): void {
    PrototypeALog.info(TAG, '扩展生命周期', 'onCreate');
  }

  async onSessionCreate(want: Want, session: UIExtensionContentSession): Promise<void> {
    PrototypeALog.info(TAG, '会话创建',
      `onSessionCreate action=${want.action ? want.action : 'none'}, ` +
      `hasWantUri=${want.uri !== undefined}, uriScheme=${PrototypeALog.uriScheme(want.uri)}`);
    ShareSessionService.getInstance().setSession(session);

    const storage = new LocalStorage();
    let shareData: ShareData;
    try {
      PrototypeALog.info(TAG, 'Share Kit', 'getSharedData start');
      const sharedData = await systemShare.getSharedData(want);
      const records = sharedData.getRecords();
      PrototypeALog.info(TAG, 'Share Kit', `getSharedData success records=${records.length}`);
      this.logRecordMetadata(records);
      shareData = this.shareDataParser.parse(records, want.uri);
      PrototypeALog.info(TAG, '分享解析', this.describeShareData(shareData));
    } catch (error) {
      const errorName = error instanceof Error ? error.name : 'UnknownError';
      PrototypeALog.error(TAG, 'Share Kit',
        `getSharedData failed errorType=${errorName}; use Want URI fallback`);
      shareData = this.shareDataParser.parse([], want.uri);
      PrototypeALog.info(TAG, '分享解析', `fallback result ${this.describeShareData(shareData)}`);
    }
    storage.setOrCreate<ShareData>('currentShareData', shareData);
    PrototypeALog.info(TAG, '状态传递', `LocalStorage ready ${this.describeShareData(shareData)}`);

    if (this.shareDataParser.isEmpty(shareData)) {
      PrototypeALog.warn(TAG, '分享解析',
        `no content; hasWantUri=${want.uri !== undefined}, uriScheme=${PrototypeALog.uriScheme(want.uri)}`);
    }

    try {
      PrototypeALog.info(TAG, '页面加载', 'ShareConfirmPage load start');
      session.loadContent('pages/ShareConfirmPage', storage);
      PrototypeALog.info(TAG, '页面加载', 'ShareConfirmPage load requested');
    } catch (error) {
      const errorName = error instanceof Error ? error.name : 'UnknownError';
      PrototypeALog.error(TAG, '页面加载', `load failed errorType=${errorName}`);
      await ShareSessionService.getInstance().terminate(systemShare.ShareAbilityResultCode.ERROR);
    }
  }

  private logRecordMetadata(records: Array<systemShare.SharedRecord>): void {
    for (let index = 0; index < records.length; index++) {
      const record = records[index];
      PrototypeALog.info(TAG, '分享记录',
        `index=${index}, utd=${record.utd}, hasUri=${record.uri !== undefined}, ` +
        `uriScheme=${PrototypeALog.uriScheme(record.uri)}, ` +
        `hasContent=${record.content !== undefined}, contentLength=${record.content?.length ?? 0}`);
    }
  }

  private describeShareData(data: ShareData): string {
    return `images=${data.images.length}, textLength=${data.text?.length ?? 0}, hasUrl=${data.url !== null}`;
  }

  onSessionDestroy(session: UIExtensionContentSession): void {
    ShareSessionService.getInstance().clearSession();
    PrototypeALog.info(TAG, '扩展生命周期', 'onSessionDestroy');
  }

  onForeground(): void {
    PrototypeALog.info(TAG, '扩展生命周期', 'onForeground');
  }

  onBackground(): void {
    PrototypeALog.info(TAG, '扩展生命周期', 'onBackground');
  }

  onDestroy(): void {
    ShareSessionService.getInstance().clearSession();
    PrototypeALog.info(TAG, '扩展生命周期', 'onDestroy');
  }
}
