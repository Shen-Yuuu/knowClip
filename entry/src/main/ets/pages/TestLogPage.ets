import { router } from '@kit.ArkUI';
import { Logger } from '../utils/Logger';

const TAG = 'TestLogPage';

/**
 * 测试日志页面
 */
@Entry
@Component
struct TestLogPage {
  @State allLogs: string[] = [];

  aboutToAppear(): void {
    this.addLog('=== 测试日志汇总 ===');
    this.addLog('');
    this.addLog('说明：');
    this.addLog('- 此页面汇总所有原型测试日志');
    this.addLog('- 可在各个测试页面中查看详细日志');
    this.addLog('- 真机测试时建议记录以下信息：');
    this.addLog('  * 设备型号');
    this.addLog('  * HarmonyOS 版本');
    this.addLog('  * 测试时间');
    this.addLog('  * 测试结果（通过/失败）');
    this.addLog('  * 性能数据');
    this.addLog('');
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

        Text('测试日志')
          .fontSize(18)
          .fontColor('#FFFFFF')
          .layoutWeight(1)
          .margin({ left: 10 })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#0F131C')

      // 测试信息卡片
      Column() {
        this.InfoCard('设备信息', [
          '设备型号: ________',
          'HarmonyOS 版本: ________',
          'API Level: 12+',
          '测试时间: ________'
        ])

        this.InfoCard('原型 A：分享接收', [
          '测试场景: __/10',
          '通过率: ___%',
          '主要问题: ________',
          '性能: URI 复制耗时 __ms'
        ])

        this.InfoCard('原型 B：OCR 识别', [
          '测试图片: __/20',
          '识别成功: __张',
          '平均耗时: __ms',
          '识别率: ___%',
          '主要问题: ________'
        ])

        this.InfoCard('原型 C：中文搜索', [
          '测试数据: 100 条',
          '搜索耗时: __ms',
          '召回率: ___%',
          '方案选择: FTS4 / LIKE',
          '性能评估: 优秀/良好/需优化'
        ])
      }
      .width('100%')
      .padding(16)
      .layoutWeight(1)

      // 底部操作
      Column() {
        Text('验证结论')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .margin({ bottom: 10 })

        Row() {
          Text('原型 A:')
            .fontSize(14)
            .fontColor('#CCCCCC')
            .width(80)

          Text('□ 通过  □ 失败')
            .fontSize(14)
            .fontColor('#FFFFFF')
        }
        .width('90%')
        .margin({ bottom: 8 })

        Row() {
          Text('原型 B:')
            .fontSize(14)
            .fontColor('#CCCCCC')
            .width(80)

          Text('□ 通过  □ 失败')
            .fontSize(14)
            .fontColor('#FFFFFF')
        }
        .width('90%')
        .margin({ bottom: 8 })

        Row() {
          Text('原型 C:')
            .fontSize(14)
            .fontColor('#CCCCCC')
            .width(80)

          Text('□ 通过  □ 失败')
            .fontSize(14)
            .fontColor('#FFFFFF')
        }
        .width('90%')
        .margin({ bottom: 16 })

        Text('Go/No-Go 决策: □ Go  □ No-Go')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#38BDF8')
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#0F131C')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#0A0D12')
  }

  /**
   * 信息卡片
   */
  @Builder
  InfoCard(title: string, items: string[]) {
    Column() {
      Text(title)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .margin({ bottom: 10 })

      ForEach(items, (item: string) => {
        Text(item)
          .fontSize(13)
          .fontColor('#CCCCCC')
          .fontFamily('monospace')
          .width('100%')
          .margin({ bottom: 6 })
      })
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#1E2636')
    .borderRadius(8)
    .margin({ bottom: 12 })
    .alignItems(HorizontalAlign.Start)
  }

  /**
   * 添加日志
   */
  private addLog(message: string): void {
    this.allLogs.push(message);
    Logger.info(TAG, message);
  }
}