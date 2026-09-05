import { UIExtensionContentSession } from '@kit.AbilityKit';
import { PrototypeALog } from '../utils/PrototypeALog';

const TAG = 'ShareSessionService';

/**
 * 保存当前分享扩展会话，让确认页可以正确关闭系统分享面板。
 */
export class ShareSessionService {
  private static instance: ShareSessionService;
  private session: UIExtensionContentSession | null = null;

  private constructor() {}

  static getInstance(): ShareSessionService {
    if (!ShareSessionService.instance) {
      ShareSessionService.instance = new ShareSessionService();
    }
    return ShareSessionService.instance;
  }

  setSession(session: UIExtensionContentSession): void {
    this.session = session;
    PrototypeALog.info(TAG, '会话状态', 'session registered');
  }

  clearSession(): void {
    const hadSession = this.session !== null;
    this.session = null;
    PrototypeALog.info(TAG, '会话状态', `session cleared hadSession=${hadSession}`);
  }

  async terminate(resultCode: number): Promise<boolean> {
    PrototypeALog.info(TAG, '会话关闭', `terminate requested resultCode=${resultCode}`);
    if (!this.session) {
      PrototypeALog.warn(TAG, '会话关闭', 'terminate skipped; no active session');
      return false;
    }

    const currentSession = this.session;
    this.session = null;
    try {
      await currentSession.terminateSelfWithResult({ resultCode: resultCode });
      PrototypeALog.info(TAG, '会话关闭', 'terminate success');
      return true;
    } catch (error) {
      const errorName = error instanceof Error ? error.name : 'UnknownError';
      PrototypeALog.error(TAG, '会话关闭', `terminate failed errorType=${errorName}`);
      throw new Error(errorName);
    }
  }
}
