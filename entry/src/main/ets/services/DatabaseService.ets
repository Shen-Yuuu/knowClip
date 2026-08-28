import { relationalStore } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { Logger } from '../utils/Logger';

const TAG = 'DatabaseService';
const DB_NAME = 'KnowClipTest.db';
const DB_VERSION = 1;

export interface KnowledgeRow {
  id: number;
  content: string;
  sourceType: string;
  processingStatus: string;
  createdAt: number;
}

export interface SearchRow {
  id: number;
  content: string;
  processingStatus: string;
  createdAt: number;
}

export interface StatsResult {
  totalCount: number;
  pendingCount: number;
  completedCount: number;
  failedCount: number;
}

export interface KnowledgeInsertData {
  content: string | null;
  keywords: string[];
  sourceType: string;
  sourceApp: string | null;
  sourceText: string | null;
  sourceUrl: string | null;
  hasImage: boolean;
  imageCount: number;
}

export interface AttachmentInsertData {
  knowledgeId: number;
  fileType: string;
  mimeType: string | null;
  filePath: string;
  originalUri: string | null;
  fileSize: number | null;
}

/**
 * 数据库服务（简化版，仅用于原型验证）
 */
export class DatabaseService {
  private store: relationalStore.RdbStore | null = null;
  private static instance: DatabaseService;

  private constructor() {}

  static getInstance(): DatabaseService {
    if (!DatabaseService.instance) {
      DatabaseService.instance = new DatabaseService();
    }
    return DatabaseService.instance;
  }

  /**
   * 初始化数据库
   */
  async init(context: common.Context): Promise<boolean> {
    try {
      const config: relationalStore.StoreConfig = {
        name: DB_NAME,
        securityLevel: relationalStore.SecurityLevel.S1
      };

      this.store = await relationalStore.getRdbStore(context, config);
      Logger.info(TAG, 'Database initialized');

      // 创建表
      await this.createTables();

      return true;
    } catch (error) {
      Logger.error(TAG, `Database init failed: ${JSON.stringify(error)}`);
      return false;
    }
  }

  /**
   * 创建表结构
   */
  private async createTables(): Promise<void> {
    if (!this.store) {
      throw new Error('Store not initialized');
    }

    // knowledge 表
    const createKnowledgeTable = `
      CREATE TABLE IF NOT EXISTS knowledge (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        content TEXT,
        note TEXT,
        keywords TEXT,
        source_type TEXT NOT NULL,
        source_app TEXT,
        source_text TEXT,
        source_url TEXT,
        processing_status TEXT NOT NULL DEFAULT 'pending',
        ocr_confidence REAL,
        error_message TEXT,
        retry_count INTEGER DEFAULT 0,
        is_starred INTEGER DEFAULT 0,
        is_archived INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        ocr_completed_at INTEGER,
        has_image INTEGER DEFAULT 0,
        image_count INTEGER DEFAULT 0
      )
    `;

    await this.store.executeSql(createKnowledgeTable);
    Logger.info(TAG, 'Table knowledge created');

    // attachments 表
    const createAttachmentsTable = `
      CREATE TABLE IF NOT EXISTS attachments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        knowledge_id INTEGER NOT NULL,
        file_type TEXT NOT NULL,
        mime_type TEXT,
        file_path TEXT NOT NULL,
        thumbnail_path TEXT,
        original_uri TEXT,
        original_name TEXT,
        file_size INTEGER,
        width INTEGER,
        height INTEGER,
        created_at INTEGER NOT NULL,
        FOREIGN KEY(knowledge_id) REFERENCES knowledge(id) ON DELETE CASCADE
      )
    `;

    await this.store.executeSql(createAttachmentsTable);
    Logger.info(TAG, 'Table attachments created');

    // 创建索引
    await this.store.executeSql('CREATE INDEX IF NOT EXISTS idx_created_at ON knowledge(created_at DESC)');
    await this.store.executeSql('CREATE INDEX IF NOT EXISTS idx_processing_status ON knowledge(processing_status)');
    await this.store.executeSql('CREATE INDEX IF NOT EXISTS idx_knowledge_id ON attachments(knowledge_id)');

    Logger.info(TAG, 'Indexes created');
  }

  /**
   * 插入知识条目
   */
  async insertKnowledge(data: KnowledgeInsertData): Promise<number> {
    if (!this.store) {
      throw new Error('Store not initialized');
    }

    const now = Date.now();
    const values: relationalStore.ValuesBucket = {
      'content': data.content,
      'keywords': data.keywords.join(','),
      'source_type': data.sourceType,
      'source_app': data.sourceApp,
      'source_text': data.sourceText,
      'source_url': data.sourceUrl,
      'processing_status': 'pending',
      'created_at': now,
      'updated_at': now,
      'has_image': data.hasImage ? 1 : 0,
      'image_count': data.imageCount
    };

    const insertId = await this.store.insert('knowledge', values);
    Logger.info(TAG, `Knowledge inserted with id: ${insertId}`);
    return insertId;
  }

  /**
   * 插入附件记录
   */
  async insertAttachment(data: AttachmentInsertData): Promise<number> {
    if (!this.store) {
      throw new Error('Store not initialized');
    }

    const values: relationalStore.ValuesBucket = {
      'knowledge_id': data.knowledgeId,
      'file_type': data.fileType,
      'mime_type': data.mimeType,
      'file_path': data.filePath,
      'original_uri': data.originalUri,
      'file_size': data.fileSize,
      'created_at': Date.now()
    };

    const insertId = await this.store.insert('attachments', values);
    Logger.info(TAG, `Attachment inserted with id: ${insertId}`);
    return insertId;
  }

  /**
   * 更新知识条目的 OCR 结果
   */
  async updateOCRResult(id: number, ocrText: string, confidence: number | null): Promise<void> {
    if (!this.store) {
      throw new Error('Store not initialized');
    }

    const now = Date.now();
    const sql = `
      UPDATE knowledge
      SET content = ?,
          ocr_confidence = ?,
          processing_status = 'completed',
          ocr_completed_at = ?,
          updated_at = ?
      WHERE id = ?
    `;

    await this.store.executeSql(sql, [ocrText, confidence, now, now, id]);
    Logger.info(TAG, `Knowledge ${id} updated with OCR result`);
  }

  /**
   * 更新知识条目失败状态
   */
  async updateOCRFailed(id: number, errorMessage: string, retryCount: number): Promise<void> {
    if (!this.store) {
      throw new Error('Store not initialized');
    }

    const now = Date.now();
    const sql = `
      UPDATE knowledge
      SET processing_status = 'failed',
          error_message = ?,
          retry_count = ?,
          updated_at = ?
      WHERE id = ?
    `;

    await this.store.executeSql(sql, [errorMessage, retryCount, now, id]);
    Logger.info(TAG, `Knowledge ${id} marked as failed`);
  }

  /**
   * 查询所有知识条目（用于测试）
   */
  async queryAllKnowledge(): Promise<Array<KnowledgeRow>> {
    if (!this.store) {
      throw new Error('Store not initialized');
    }

    const sql = 'SELECT * FROM knowledge ORDER BY created_at DESC';
    const resultSet = await this.store.querySql(sql);

    const results: Array<KnowledgeRow> = [];
    while (resultSet.goToNextRow()) {
      const row: KnowledgeRow = {
        id: resultSet.getLong(resultSet.getColumnIndex('id')),
        content: resultSet.getString(resultSet.getColumnIndex('content')),
        sourceType: resultSet.getString(resultSet.getColumnIndex('source_type')),
        processingStatus: resultSet.getString(resultSet.getColumnIndex('processing_status')),
        createdAt: resultSet.getLong(resultSet.getColumnIndex('created_at'))
      };
      results.push(row);
    }

    resultSet.close();
    return results;
  }

  /**
   * 搜索知识条目（LIKE 方案）
   */
  async searchKnowledge(keyword: string): Promise<Array<SearchRow>> {
    if (!this.store) {
      throw new Error('Store not initialized');
    }

    const sql = `
      SELECT * FROM knowledge
      WHERE content LIKE ? OR keywords LIKE ? OR note LIKE ?
      ORDER BY created_at DESC
    `;

    const pattern = `%${keyword}%`;
    const resultSet = await this.store.querySql(sql, [pattern, pattern, pattern]);

    const results: Array<SearchRow> = [];
    while (resultSet.goToNextRow()) {
      const row: SearchRow = {
        id: resultSet.getLong(resultSet.getColumnIndex('id')),
        content: resultSet.getString(resultSet.getColumnIndex('content')),
        processingStatus: resultSet.getString(resultSet.getColumnIndex('processing_status')),
        createdAt: resultSet.getLong(resultSet.getColumnIndex('created_at'))
      };
      results.push(row);
    }

    resultSet.close();
    Logger.info(TAG, `Search found ${results.length} results for keyword: ${keyword}`);
    return results;
  }

  /**
   * 清空数据库（测试用）
   */
  async clearAllData(): Promise<void> {
    if (!this.store) {
      throw new Error('Store not initialized');
    }

    await this.store.executeSql('DELETE FROM attachments');
    await this.store.executeSql('DELETE FROM knowledge');
    Logger.info(TAG, 'All data cleared');
  }

  /**
   * 获取数据库统计信息
   */
  async getStats(): Promise<StatsResult> {
    if (!this.store) {
      throw new Error('Store not initialized');
    }

    const totalResult = await this.store.querySql('SELECT COUNT(*) as count FROM knowledge');
    totalResult.goToFirstRow();
    const totalCount = totalResult.getLong(0);
    totalResult.close();

    const pendingResult = await this.store.querySql(
      'SELECT COUNT(*) as count FROM knowledge WHERE processing_status = ?',
      ['pending']
    );
    pendingResult.goToFirstRow();
    const pendingCount = pendingResult.getLong(0);
    pendingResult.close();

    const completedResult = await this.store.querySql(
      'SELECT COUNT(*) as count FROM knowledge WHERE processing_status = ?',
      ['completed']
    );
    completedResult.goToFirstRow();
    const completedCount = completedResult.getLong(0);
    completedResult.close();

    const failedResult = await this.store.querySql(
      'SELECT COUNT(*) as count FROM knowledge WHERE processing_status = ?',
      ['failed']
    );
    failedResult.goToFirstRow();
    const failedCount = failedResult.getLong(0);
    failedResult.close();

    const result: StatsResult = {
      totalCount: Number(totalCount),
      pendingCount: Number(pendingCount),
      completedCount: Number(completedCount),
      failedCount: Number(failedCount)
    };

    return result;
  }
}
