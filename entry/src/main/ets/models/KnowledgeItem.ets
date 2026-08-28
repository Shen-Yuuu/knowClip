/**
 * 处理状态枚举
 */
export enum ProcessingStatus {
  PENDING = 'pending',
  PROCESSING = 'processing',
  COMPLETED = 'completed',
  FAILED = 'failed'
}

/**
 * 来源类型枚举
 */
export enum SourceType {
  SHARE = 'share',
  PICKER = 'picker',
  MANUAL = 'manual'
}

/**
 * 知识条目数据模型
 */
export interface KnowledgeItem {
  id: number;

  // 内容
  title: string | null;
  content: string | null;
  note: string | null;
  keywords: string[];

  // 来源信息
  sourceType: SourceType;
  sourceApp: string | null;
  sourceText: string | null;
  sourceUrl: string | null;

  // 处理状态
  processingStatus: ProcessingStatus;
  ocrConfidence: number | null;
  errorMessage: string | null;
  retryCount: number;

  // 元数据
  isStarred: boolean;
  isArchived: boolean;
  createdAt: number;
  updatedAt: number;
  ocrCompletedAt: number | null;

  // 附件信息
  hasImage: boolean;
  imageCount: number;
}

/**
 * 附件类型枚举
 */
export enum FileType {
  IMAGE = 'image',
  VIDEO = 'video',
  AUDIO = 'audio',
  FILE = 'file'
}

/**
 * 附件数据模型
 */
export interface Attachment {
  id: number;
  knowledgeId: number;

  fileType: FileType;
  mimeType: string | null;
  filePath: string;
  thumbnailPath: string | null;

  originalUri: string | null;
  originalName: string | null;

  fileSize: number | null;
  width: number | null;
  height: number | null;

  createdAt: number;
}