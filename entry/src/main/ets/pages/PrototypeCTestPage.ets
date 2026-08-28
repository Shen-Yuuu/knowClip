import { router } from '@kit.ArkUI';
import { Logger } from '../utils/Logger';
import {
  DatabaseService,
  KnowledgeInsertData,
  SearchRow
} from '../services/DatabaseService';

const TAG = 'PrototypeCTestPage';

interface TestData {
  id: number;
  content: string;
  keywords: string[];
}

/**
 * 原型 C：中文搜索测试页
 */
@Entry
@Component
struct PrototypeCTestPage {
  @State testLogs: string[] = [];
  @State isInitialized: boolean = false;
  @State searchResults: Array<SearchRow> = [];
  @State searchKeyword: string = '';
  @State searchDuration: number = 0;

  @State testDataGenerated: boolean = false;

  async aboutToAppear(): Promise<void> {
    this.addLog('=== 原型 C：中文搜索测试 ===');
    this.addLog('');
    this.addLog('测试步骤：');
    this.addLog('1. 点击"生成测试数据"创建 100 条测试数据');
    this.addLog('2. 输入搜索关键词');
    this.addLog('3. 点击"搜索"查看结果和性能');
    this.addLog('4. 尝试不同关键词测试召回率');
    this.addLog('5. 记录搜索耗时');
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
      this.isInitialized = true;
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

        Text('原型 C：中文搜索测试')
          .fontSize(18)
          .fontColor('#FFFFFF')
          .layoutWeight(1)
          .margin({ left: 10 })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#0F131C')

      // 操作区域
      Column() {
        Button('生成测试数据（100 条）')
          .width('90%')
          .margin({ top: 10 })
          .enabled(this.isInitialized && !this.testDataGenerated)
          .onClick(() => {
            this.generateTestData();
          })

        // 搜索框
        Row() {
          TextInput({ placeholder: '输入搜索关键词' })
            .layoutWeight(1)
            .backgroundColor('#1E2636')
            .fontColor('#FFFFFF')
            .placeholderColor('#666666')
            .onChange((value: string) => {
              this.searchKeyword = value;
            })

          Button('搜索')
            .width(80)
            .margin({ left: 10 })
            .backgroundColor('#38BDF8')
            .enabled(this.testDataGenerated && this.searchKeyword.length > 0)
            .onClick(() => {
              this.performSearch();
            })
        }
        .width('90%')
        .margin({ top: 10 })

        // 快速测试按钮
        if (this.testDataGenerated) {
          Text('快速测试：')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ top: 10 })

          Row() {
            Button('鸿蒙')
              .fontSize(12)
              .height(32)
              .onClick(() => {
                this.quickSearch('鸿蒙');
              })

            Button('HarmonyOS')
              .fontSize(12)
              .height(32)
              .margin({ left: 8 })
              .onClick(() => {
                this.quickSearch('HarmonyOS');
              })

            Button('数据库')
              .fontSize(12)
              .height(32)
              .margin({ left: 8 })
              .onClick(() => {
                this.quickSearch('数据库');
              })

            Button('ArkTS')
              .fontSize(12)
              .height(32)
              .margin({ left: 8 })
              .onClick(() => {
                this.quickSearch('ArkTS');
              })
          }
          .width('90%')
          .margin({ top: 5 })
        }

        Button('查看数据库统计')
          .width('90%')
          .margin({ top: 10 })
          .backgroundColor('#6EE7B7')
          .enabled(this.testDataGenerated)
          .onClick(() => {
            this.checkStats();
          })

        Button('清空测试数据')
          .width('90%')
          .margin({ top: 10 })
          .backgroundColor('#F87171')
          .enabled(this.testDataGenerated)
          .onClick(() => {
            this.clearData();
          })
      }
      .width('100%')
      .padding({ bottom: 10 })
      .backgroundColor('#0F131C')

      // 搜索结果和日志
      Scroll() {
        Column() {
          // 搜索结果
          if (this.searchResults.length > 0) {
            Text(`找到 ${this.searchResults.length} 条结果，耗时 ${this.searchDuration}ms`)
              .fontSize(14)
              .fontColor('#6EE7B7')
              .margin({ bottom: 10 })

            ForEach(this.searchResults, (item: SearchRow, index: number) => {
              Column() {
                Text(`#${item.id}`)
                  .fontSize(12)
                  .fontColor('#999999')

                Text(item.content)
                  .fontSize(14)
                  .fontColor('#FFFFFF')
                  .margin({ top: 4 })
                  .maxLines(3)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })

                Text(`状态: ${item.processingStatus}`)
                  .fontSize(12)
                  .fontColor('#666666')
                  .margin({ top: 4 })
              }
              .width('100%')
              .padding(10)
              .backgroundColor('#1E2636')
              .borderRadius(8)
              .margin({ bottom: 8 })
              .alignItems(HorizontalAlign.Start)
            })

            Text('')
              .height(20)
          }

          // 测试日志
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
    }
    .width('100%')
    .height('100%')
  }

  /**
   * 生成测试数据
   */
  private async generateTestData(): Promise<void> {
    this.addLog('');
    this.addLog('=== 生成测试数据 ===');

    try {
      const db = DatabaseService.getInstance();
      const testData = this.getTestDataSet();

      this.addLog(`开始插入 ${testData.length} 条数据...`);

      for (let i = 0; i < testData.length; i++) {
        const item = testData[i];
        const insertData: KnowledgeInsertData = {
          content: item.content,
          keywords: item.keywords,
          sourceType: 'manual',
          sourceApp: null,
          sourceText: null,
          sourceUrl: null,
          hasImage: false,
          imageCount: 0
        };
        await db.insertKnowledge(insertData);

        if ((i + 1) % 20 === 0) {
          this.addLog(`已插入 ${i + 1}/${testData.length}...`);
        }
      }

      this.addLog('✅ 测试数据生成完成');
      this.testDataGenerated = true;

    } catch (error) {
      this.addLog(`❌ 生成失败: ${error}`);
    }
  }

  /**
   * 获取测试数据集
   */
  private getTestDataSet(): TestData[] {
    const data: TestData[] = [];

    // 鸿蒙相关
    data.push({ id: 1, content: '如何在鸿蒙系统中实现本地数据库？使用关系型数据库 RDB 可以轻松完成。', keywords: ['鸿蒙', '数据库', 'RDB'] });
    data.push({ id: 2, content: 'HarmonyOS NEXT 的分布式能力非常强大，支持跨设备协同。', keywords: ['HarmonyOS', '分布式', '跨设备'] });
    data.push({ id: 3, content: 'ArkTS 是鸿蒙生态的主力开发语言，基于 TypeScript 扩展。', keywords: ['ArkTS', 'TypeScript', '开发语言'] });
    data.push({ id: 4, content: '鸿蒙开发者可以使用 DevEco Studio 进行应用开发。', keywords: ['鸿蒙', 'DevEco Studio', '开发'] });
    data.push({ id: 5, content: 'HarmonyOS 的 ArkUI 框架提供了声明式 UI 开发能力。', keywords: ['HarmonyOS', 'ArkUI', '框架'] });

    // 技术相关
    data.push({ id: 6, content: 'TypeScript 提供了强类型系统，减少运行时错误。', keywords: ['TypeScript', '类型系统'] });
    data.push({ id: 7, content: '数据库索引可以大幅提升查询性能，但会增加写入开销。', keywords: ['数据库', '索引', '性能'] });
    data.push({ id: 8, content: 'OCR 技术可以识别图片中的文字，广泛应用于文档扫描。', keywords: ['OCR', '文字识别'] });
    data.push({ id: 9, content: '全文搜索引擎如 FTS4 提供了高效的中文分词能力。', keywords: ['全文搜索', 'FTS4', '中文分词'] });
    data.push({ id: 10, content: 'RESTful API 是目前最流行的 Web 服务架构风格。', keywords: ['REST', 'API', 'Web'] });

    // 填充到 100 条
    for (let i = 11; i <= 100; i++) {
      const templates = [
        `这是第 ${i} 条测试数据，包含鸿蒙开发相关内容。`,
        `HarmonyOS 应用开发测试数据 #${i}。`,
        `ArkTS 语言特性示例 ${i}：支持类型推断和泛型。`,
        `数据库查询优化技巧 ${i}：使用索引和缓存。`,
        `中文搜索测试文本 ${i}：验证关键词匹配。`
      ];

      data.push({
        id: i,
        content: templates[i % templates.length],
        keywords: ['测试', '数据', `编号${i}`]
      });
    }

    return data;
  }

  /**
   * 执行搜索
   */
  private async performSearch(): Promise<void> {
    if (!this.searchKeyword) {
      this.addLog('⚠️ 请输入搜索关键词');
      return;
    }

    this.addLog('');
    this.addLog(`=== 搜索: "${this.searchKeyword}" ===`);

    try {
      const db = DatabaseService.getInstance();
      const startTime = Date.now();

      this.searchResults = await db.searchKnowledge(this.searchKeyword);

      this.searchDuration = Date.now() - startTime;

      this.addLog(`✅ 找到 ${this.searchResults.length} 条结果`);
      this.addLog(`⏱️ 搜索耗时: ${this.searchDuration}ms`);

      if (this.searchDuration < 100) {
        this.addLog('🚀 性能: 优秀 (< 100ms)');
      } else if (this.searchDuration < 500) {
        this.addLog('✅ 性能: 良好 (< 500ms)');
      } else {
        this.addLog('⚠️ 性能: 需要优化 (> 500ms)');
      }

    } catch (error) {
      this.addLog(`❌ 搜索失败: ${error}`);
      this.searchResults = [];
    }
  }

  /**
   * 快速搜索
   */
  private quickSearch(keyword: string): void {
    this.searchKeyword = keyword;
    this.performSearch();
  }

  /**
   * 查看统计
   */
  private async checkStats(): Promise<void> {
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
   * 清空数据
   */
  private async clearData(): Promise<void> {
    try {
      const db = DatabaseService.getInstance();
      await db.clearAllData();

      this.addLog('');
      this.addLog('✅ 测试数据已清空');
      this.testDataGenerated = false;
      this.searchResults = [];

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
