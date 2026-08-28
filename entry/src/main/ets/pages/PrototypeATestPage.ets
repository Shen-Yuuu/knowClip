import { router } from '@kit.ArkUI';
import { Logger } from '../utils/Logger';
import { DatabaseService } from '../services/DatabaseService';

const TAG = 'PrototypeATestPage';

/**
 * 原型 A：分享接收测试页
 */
@Entry
@Component
struct PrototypeATestPage {
  @State testLogs: string[] = [];

  async aboutToAppear(): Promise<void> {
    this.addLog('=== 原型 A：分享接收测试 ===');
    this.addLog('');
    this.addLog('测试步骤：');
    this.addLog('1. 打开其他应用（如相册、浏览器）');
    this.addLog('2. 选择要分享的内容');
    this.addLog('3. 点击分享按钮');
    this.addLog('4. 选择"知微"应用');
    this.addLog('5. 查看分享确认页');
    this.addLog('6. 点击"保存"按钮');
    this.addLog('7. 返回此页面查看日志');
    this.addLog('');

    // 初始化数据库
    const context = this.getUIContext().getHostContext();
    if (!context) {
      this.addLog('❌ 无法获取应用上下文');
      return;
    }
    const db = DatabaseService.getInstance();
    const success = await db.init(context);

    if (success) {
      this.addLog('✅ 数据库初始化成功');
    } else {
      this.addLog('❌ 数据库初始化失败');
    }
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text('←')
          .fontSize(24)
          .fontColor('#FFFFFF')
          .onClick(() => {
            router.back();
          })

        Text('原型 A：分享接收测试')
          .fontSize(18)
          .fontColor('#FFFFFF')
          .layoutWeight(1)
          .margin({ left: 10 })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#0F131C')

      // 测试日志
      Scroll() {
        Column() {
          ForEach(this.testLogs, (log: string, index: number) => {
            Text(log)
              .fontSize(12)
              .fontColor('#CCCCCC')
              .fontFamily('monospace')
              .width('100%')
              .margin({ bottom: 4 })
          })
        }
        .width('100%')
        .padding(12)
      }
      .layoutWeight(1)
      .backgroundColor('#0A0D12')

      // 操作按钮
      Column() {
        Button('查看数据库统计')
          .width('90%')
          .margin({ bottom: 10 })
          .onClick(() => {
            this.checkDatabaseStats();
          })

        Button('清空测试数据')
          .width('90%')
          .backgroundColor('#F87171')
          .onClick(() => {
            this.clearTestData();
          })
      }
      .width('100%')
      .padding({ top: 10, bottom: 10 })
      .backgroundColor('#0F131C')
    }
    .width('100%')
    .height('100%')
  }

  /**
   * 查看数据库统计
   */
  private async checkDatabaseStats(): Promise<void> {
    try {
      const db = DatabaseService.getInstance();
      const stats = await db.getStats();

      this.addLog('');
      this.addLog('=== 数据库统计 ===');
      this.addLog(`总条目数: ${stats.totalCount}`);
      this.addLog(`待处理: ${stats.pendingCount}`);
      this.addLog(`已完成: ${stats.completedCount}`);
      this.addLog(`失败: ${stats.failedCount}`);

    } catch (error) {
      this.addLog(`❌ 查询失败: ${error}`);
    }
  }

  /**
   * 清空测试数据
   */
  private async clearTestData(): Promise<void> {
    try {
      const db = DatabaseService.getInstance();
      await db.clearAllData();
      this.addLog('');
      this.addLog('✅ 测试数据已清空');
    } catch (error) {
      this.addLog(`❌ 清空失败: ${error}`);
    }
  }

  /**
   * 添加日志
   */
  private addLog(message: string): void {
    const timestamp = new Date().toLocaleTimeString();
    const logMessage = message ? `[${timestamp}] ${message}` : '';
    this.testLogs = [...this.testLogs, logMessage];
    Logger.info(TAG, message);
  }
}
