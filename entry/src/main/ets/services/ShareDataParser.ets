import { uniformTypeDescriptor } from '@kit.ArkData';
import { ShareData } from '../models/ShareData';

export interface ShareRecordInput {
  utd: string;
  uri?: string;
  content?: string;
}

/**
 * 将 Share Kit 的不同记录形态归一为页面使用的 ShareData。
 */
export class ShareDataParser {
  parse(records: ShareRecordInput[], fallbackUri?: string): ShareData {
    const images: string[] = [];
    const textParts: string[] = [];

    for (const record of records) {
      if (record.uri) {
        this.appendUnique(images, record.uri);
        continue;
      }

      if (!record.content) {
        continue;
      }

      if (this.isImageType(record.utd)) {
        this.appendUnique(images, record.content);
      } else {
        textParts.push(record.content);
      }
    }

    if (images.length === 0 && textParts.length === 0 && fallbackUri) {
      images.push(fallbackUri);
    }

    const text = textParts.length > 0 ? textParts.join('\n') : null;
    return {
      images: images,
      text: text,
      url: this.extractUrl(text),
      sourceApp: null
    };
  }

  isEmpty(data: ShareData): boolean {
    return data.images.length === 0 && data.text === null;
  }

  private isImageType(utd: string): boolean {
    const knownImageTypes: string[] = [
      uniformTypeDescriptor.UniformDataType.IMAGE,
      uniformTypeDescriptor.UniformDataType.JPEG,
      uniformTypeDescriptor.UniformDataType.PNG,
      uniformTypeDescriptor.UniformDataType.RAW_IMAGE,
      uniformTypeDescriptor.UniformDataType.TIFF,
      uniformTypeDescriptor.UniformDataType.BMP,
      uniformTypeDescriptor.UniformDataType.ICO,
      uniformTypeDescriptor.UniformDataType.GIF
    ];
    if (knownImageTypes.indexOf(utd) !== -1) {
      return true;
    }

    try {
      return uniformTypeDescriptor.getTypeDescriptor(utd)
        .belongsTo(uniformTypeDescriptor.UniformDataType.IMAGE);
    } catch {
      return false;
    }
  }

  private appendUnique(values: string[], value: string): void {
    if (values.indexOf(value) === -1) {
      values.push(value);
    }
  }

  private extractUrl(text: string | null): string | null {
    if (!text) {
      return null;
    }

    const urlPattern = /https?:\/\/[^\s]+/i;
    const match = text.match(urlPattern);
    return match ? match[0] : null;
  }
}
