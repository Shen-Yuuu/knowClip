/**
 * OCR 错误信息
 */
export interface OCRError {
  code: number;
  message: string;
  retryable: boolean;
}

/**
 * OCR 识别结果
 */
export interface OCRResult {
  success: boolean;
  text: string | null;
  confidence: number | null;
  duration: number;
  error: OCRError | null;
}