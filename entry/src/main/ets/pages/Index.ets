import { router } from '@kit.ArkUI';

@Entry
@Component
struct Index {
  @State selectedTab: number = 0;

  build() {
    Column() {
      // 顶部标题
      Row() {
        Text('知微 - 原型验证')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
      }
      .width('100%')
      .height(56)
      .backgroundColor('#0F131C')
      .justifyContent(FlexAlign.Center)

      // 导航按钮
      Column() {
        Button('原型 A：分享接收测试')
          .width('90%')
          .height(50)
          .fontSize(16)
          .margin({ top: 20 })
          .onClick(() => {
            router.pushUrl({ url: 'pages/PrototypeATestPage' });
          })

        Button('原型 B：OCR 测试')
          .width('90%')
          .height(50)
          .fontSize(16)
          .margin({ top: 15 })
          .onClick(() => {
            router.pushUrl({ url: 'pages/PrototypeBTestPage' });
          })

        Button('原型 C：中文搜索测试')
          .width('90%')
          .height(50)
          .fontSize(16)
          .margin({ top: 15 })
          .onClick(() => {
            router.pushUrl({ url: 'pages/PrototypeCTestPage' });
          })

        Button('测试日志')
          .width('90%')
          .height(50)
          .fontSize(16)
          .margin({ top: 15 })
          .backgroundColor('#666666')
          .onClick(() => {
            router.pushUrl({ url: 'pages/TestLogPage' });
          })
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Center)

      // 底部说明
      Text('第 0 阶段技术验证')
        .fontSize(12)
        .fontColor('#999999')
        .margin({ bottom: 20 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#0A0D12')
  }
}