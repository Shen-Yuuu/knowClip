# Prototype A/B Media URI Compatibility Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Prototype A receive and persist a single image shared from HarmonyOS Gallery, and make Prototype B decode a Photo Picker media URI before running on-device OCR.

**Architecture:** Add one pure parser at the Share Kit boundary so record variants and `Want.uri` fallback can be tested independently. Keep the existing pages and services, but open system media URIs through `fileIo` and pass file descriptors to image decoding and file copying APIs; every opened descriptor and image resource is released in `finally`.

**Tech Stack:** HarmonyOS NEXT Stage model, ArkTS, ArkUI, Share Kit, Core File Kit, Image Kit, Core Vision Kit, Hypium, Hvigor

**Spec:** `docs/plans/2026-08-28-prototype-media-uri-compatibility-design.md`

## Global Constraints

- Keep all OCR, parsing, and persistence on device; add no cloud API or dependency.
- Do not change page layout, database schema, OCR algorithm, or sharing target declarations.
- Prototype A acceptance path is one image selected in system Gallery and shared to 知微.
- Prototype B input remains the URI returned by `PhotoViewPicker`.
- Never log a complete private media URI.

---

### Task 1: Parse Share Kit records and Gallery fallback URI

**Files:**
- Create: `entry/src/main/ets/services/ShareDataParser.ets`
- Modify: `entry/src/main/ets/shareextensionability/ShareExtAbility.ets`
- Modify: `entry/src/test/LocalUnit.test.ets`

**Interfaces:**
- Consumes: `ShareData` from `entry/src/main/ets/models/ShareData.ets`; structurally compatible records containing `utd: string`, optional `uri`, and optional `content`.
- Produces: `ShareDataParser.parse(records: ShareRecordInput[], fallbackUri?: string): ShareData` and `ShareDataParser.isEmpty(data: ShareData): boolean`.

- [ ] **Step 1: Add failing parser tests**

Add Hypium cases that assert: `record.uri` becomes an image; an image UTD whose URI is stored in `record.content` becomes an image without also becoming text; plain text and hyperlinks remain text and yield a URL; empty records use the supplied Gallery fallback URI.

```ts
const parser = new ShareDataParser();
expect(parser.parse([{ utd: 'general.jpeg', uri: 'file://gallery/a.jpg' }]).images[0])
  .assertEqual('file://gallery/a.jpg');
expect(parser.parse([{ utd: 'general.jpeg', content: 'file://gallery/b.jpg' }]).text)
  .assertNull();
expect(parser.parse([{ utd: 'general.plain-text', content: '参考 https://example.com/a' }]).url)
  .assertEqual('https://example.com/a');
expect(parser.parse([], 'file://gallery/fallback.jpg').images[0])
  .assertEqual('file://gallery/fallback.jpg');
```

- [ ] **Step 2: Run the local unit test and confirm it fails before implementation**

Run the DevEco Studio `entry` local test configuration for `LocalUnit.test.ets`. Expected: compilation fails because `ShareDataParser` does not exist.

- [ ] **Step 3: Implement the pure parser**

Create `ShareRecordInput` and `ShareDataParser`. For every record, treat `record.uri` as a shared image reference; when no `uri` exists, use `uniformTypeDescriptor.getTypeDescriptor(record.utd).belongsTo(UniformDataType.IMAGE)` to decide whether `record.content` is an image URI. Catch unknown UTD lookup errors and classify their content as text. Join text fragments with newlines, extract the first HTTP(S) URL, deduplicate image references, and use `fallbackUri` only when no record produced an image or text.

```ts
export interface ShareRecordInput {
  utd: string;
  uri?: string;
  content?: string;
}

export class ShareDataParser {
  parse(records: ShareRecordInput[], fallbackUri?: string): ShareData;
  isEmpty(data: ShareData): boolean;
}
```

- [ ] **Step 4: Connect the parser to the share extension**

In `onSessionCreate`, parse `sharedData.getRecords()` with `want.uri` as fallback. If `getSharedData` throws, parse an empty record array with `want.uri`. Log the failure message, record count, UTD and field-presence metadata without logging URI values. Keep loading `ShareConfirmPage` with `currentShareData` in both paths.

- [ ] **Step 5: Run parser tests and build the HAP**

Run the local unit tests; expected: all four parser cases pass. Then run:

```powershell
& 'D:\local\DevEcoStudio\tools\hvigor\bin\hvigorw.bat' --mode module -p product=default -p module=entry@default -p buildMode=debug assembleHap
```

Expected: `BUILD SUCCESSFUL` and no ArkTS compiler errors.

- [ ] **Step 6: Commit Task 1**

```powershell
git add entry/src/main/ets/services/ShareDataParser.ets entry/src/main/ets/shareextensionability/ShareExtAbility.ets entry/src/test/LocalUnit.test.ets
git commit -m "fix: parse gallery share media uri"
```

### Task 2: Copy a shared image through file descriptors

**Files:**
- Modify: `entry/src/main/ets/services/FileService.ets`

**Interfaces:**
- Consumes: the image URI in `ShareData.images` and the existing `copyImageToPrivate(uri: string): Promise<CopyResult>` API.
- Produces: the same `CopyResult` contract and private attachment path; no caller changes.

- [ ] **Step 1: Replace path-based copying with descriptor-based copying**

Declare nullable `fileIo.File` handles outside the `try`. After creating the destination directory, open the source with `fileIo.open(uri, fileIo.OpenMode.READ_ONLY)`, open the target with `CREATE | READ_WRITE | TRUNC`, and invoke `fileIo.copyFile(source.fd, target.fd)`. Log only destination path, byte count, and duration.

```ts
let sourceFile: fileIo.File | null = null;
let targetFile: fileIo.File | null = null;
sourceFile = await fileIo.open(uri, fileIo.OpenMode.READ_ONLY);
targetFile = await fileIo.open(targetPath,
  fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.TRUNC);
await fileIo.copyFile(sourceFile.fd, targetFile.fd);
```

- [ ] **Step 2: Close both descriptors in `finally`**

Close each non-null handle with `fileIo.closeSync(handle)` inside its own guarded block, and log a generic warning if cleanup fails. Preserve the existing non-empty file verification and `CopyResult` error handling.

- [ ] **Step 3: Build the HAP**

Run the same `assembleHap` command from Task 1. Expected: `BUILD SUCCESSFUL`; in particular, the SDK accepts the `File` and `OpenMode` types without ArkTS errors.

- [ ] **Step 4: Commit Task 2**

```powershell
git add entry/src/main/ets/services/FileService.ets
git commit -m "fix: copy shared image from media uri"
```

### Task 3: Decode Prototype B media URI through a file descriptor

**Files:**
- Modify: `entry/src/main/ets/services/OCRService.ets`

**Interfaces:**
- Consumes: the unchanged `recognizeText(imageUri: string): Promise<OCRResult>` call used by `PrototypeBTestPage`.
- Produces: the unchanged `OCRResult`; image loading now accepts a Photo Picker media URI.

- [ ] **Step 1: Open the picker URI before creating `ImageSource`**

Import `fileIo` from `@kit.CoreFileKit`, rename the parameter to `imageUri`, declare a nullable source `fileIo.File`, open it read-only, and call `image.createImageSource(sourceFile.fd)`. Keep resizing and recognition behavior unchanged.

```ts
let sourceFile: fileIo.File | null = null;
sourceFile = await fileIo.open(imageUri, fileIo.OpenMode.READ_ONLY);
imageSource = image.createImageSource(sourceFile.fd);
```

- [ ] **Step 2: Release the source descriptor in `finally`**

After releasing `PixelMap` and `ImageSource`, close the file handle with `fileIo.closeSync(sourceFile)` in a guarded block. Ensure every success and error branch reaches this cleanup.

- [ ] **Step 3: Build the HAP and inspect the diff**

Run `assembleHap`; expected: `BUILD SUCCESSFUL`. Run `git diff --check`; expected: no whitespace errors. Review `git diff` to confirm no UI, database, manifest, or OCR algorithm changes were introduced.

- [ ] **Step 4: Commit Task 3**

```powershell
git add entry/src/main/ets/services/OCRService.ets
git commit -m "fix: decode picker media uri for ocr"
```

### Task 4: Real-device acceptance

**Files:**
- Modify: `docs/09-原型验证使用说明.md` only if the observed device behavior or required steps differ from its current instructions.

**Interfaces:**
- Consumes: the debug HAP produced by Tasks 1–3.
- Produces: verified Prototype A and B results on a HarmonyOS device.

- [ ] **Step 1: Verify Prototype A receive and save**

Install the debug HAP, choose one image in system Gallery, select `分享 → 知微`, and verify the confirmation page lists one image and enables Save. Tap Save and verify `✅ 已保存到本地收件箱` rather than the empty-content or all-copies-failed message.

- [ ] **Step 2: Verify Prototype B OCR**

Open Prototype B, choose the same image, and start OCR. Verify logs contain neither `path to realpath error` nor `CreateImageSourceExec error`; accept either recognized text or a genuine Core Vision OCR service error with its code.

- [ ] **Step 3: Verify text sharing regression**

Share a plain-text snippet containing an HTTP(S) URL to 知微 and verify both text and URL appear and can be saved.

- [ ] **Step 4: Record only material instruction changes**

If the device procedure differs, update `docs/09-原型验证使用说明.md`, rerun `git diff --check`, and commit with:

```powershell
git add docs/09-原型验证使用说明.md
git commit -m "docs: update prototype media uri verification"
```
