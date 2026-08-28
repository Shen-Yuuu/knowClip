/**
 * 分享数据模型
 */
export interface ShareData {
  images: string[];
  text: string | null;
  url: string | null;
  sourceApp: string | null;
}

/**
 * 文件复制结果
 */
export interface CopyResult {
  success: boolean;
  localPath: string | null;
  error: string | null;
}