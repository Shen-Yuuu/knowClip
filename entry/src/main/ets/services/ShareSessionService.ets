import { UIExtensionContentSession } from '@kit.AbilityKit';

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
  }

  clearSession(): void {
    this.session = null;
  }

  async terminate(resultCode: number): Promise<boolean> {
    if (!this.session) {
      return false;
    }

    const currentSession = this.session;
    this.session = null;
    await currentSession.terminateSelfWithResult({ resultCode: resultCode });
    return true;
  }
}
