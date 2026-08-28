# KnowClip Prototype Validation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the three HarmonyOS technical prototypes compile and provide honest, executable validation paths for share ingestion, on-device OCR, and local Chinese search.

**Architecture:** Keep the existing Stage-model single-module prototype. Use explicit ArkTS models at service boundaries, `LocalStorage` for UIExtension data, RDB services for persistence, and independent test pages for each technology.

**Tech Stack:** HarmonyOS NEXT API 21, ArkTS, ArkUI, AbilityKit, ArkData RDB, CoreVisionKit, ImageKit, MediaLibraryKit.

**Spec:** `docs/plans/2026-08-28-knowclip-prototype-validation-design.md`

## Global Constraints

- All processing remains local; no cloud APIs or new remote dependencies.
- Use Stage model and strict ArkTS with no `any`, `unknown`, `in` operator, type predicates, or anonymous object type declarations.
- Limit scope to the three technical prototypes and their documentation.
- Run at most three full compilation attempts in this implementation turn.

---

### Task 1: Establish typed share and database contracts

**Files:**
- Modify: `entry/src/main/ets/models/ShareData.ets`
- Modify: `entry/src/main/ets/services/DatabaseService.ets`

**Interfaces:**
- Produces: `ShareData`, `KnowledgeInsertData`, `AttachmentInsertData`, `insertKnowledge(data): Promise<number>`, `insertAttachment(data): Promise<number>`.

- [ ] Define explicit interfaces for every service input and UI storage value.
- [ ] Replace SQL INSERT plus `lastRowId` with `RdbStore.insert()` and `ValuesBucket`.
- [ ] Persist keywords and attachment metadata needed by prototypes A and C.
- [ ] Keep query result interfaces exported where test pages consume them.

### Task 2: Repair and complete the share prototype

**Files:**
- Modify: `entry/src/main/module.json5`
- Modify: `entry/src/main/ets/shareextensionability/ShareExtAbility.ets`
- Modify: `entry/src/main/ets/pages/ShareConfirmPage.ets`
- Modify: `entry/src/main/ets/services/FileService.ets`

**Interfaces:**
- Consumes: `ShareData`, `DatabaseService.insertKnowledge`, `DatabaseService.insertAttachment`.
- Produces: a share extension that passes typed data through `LocalStorage` and terminates explicitly.

- [ ] Change the extension implementation to `ShareExtensionAbility` and the manifest type to `share`.
- [ ] Replace filter type predicates with explicit ArkTS-compatible loops.
- [ ] Pass `ShareData` and the content session through supported storage/state mechanisms.
- [ ] Move all non-component statements out of the ArkUI build DSL.
- [ ] On save, copy shared images, create the knowledge row and attachment rows, then report success/failure.

### Task 3: Repair and complete the OCR prototype

**Files:**
- Modify: `entry/src/main/ets/services/OCRService.ets`
- Modify: `entry/src/main/ets/pages/PrototypeBTestPage.ets`

**Interfaces:**
- Produces: `init(): Promise<void>`, `recognizeText(path): Promise<OCRResult>`, `release(): Promise<void>`.

- [ ] Call the SDK OCR initialization API and reject a false initialization result.
- [ ] Replace unsupported exception inspection with a typed `BusinessError` conversion.
- [ ] Map the current SDK error codes to retryable and non-retryable categories.
- [ ] Release image and OCR resources and use immutable array updates for UI state.

### Task 4: Repair and strengthen the search prototype

**Files:**
- Modify: `entry/src/main/ets/pages/PrototypeCTestPage.ets`
- Modify: `entry/src/main/ets/services/DatabaseService.ets`

**Interfaces:**
- Consumes: `KnowledgeInsertData`, `SearchRow`, `searchKnowledge(keyword)`.

- [ ] Make generated-data state reactive.
- [ ] Insert test keywords alongside content.
- [ ] Use ArkTS-compatible typed objects at every call site.
- [ ] Keep LIKE as the measured baseline and log the tested data volume and duration.

### Task 5: Compile, correct residual errors, and align documentation

**Files:**
- Modify: source files reported by the compiler as needed.
- Modify: `README.md`
- Modify: `docs/05-第0阶段-技术验证原型.md`
- Modify: `docs/07-第0阶段工作总结.md`

**Interfaces:**
- Produces: a buildable debug HAP and accurate prototype status documentation.

- [ ] Run `hvigorw assembleHap` with `DEVECO_SDK_HOME=D:\local\DevEcoStudio\sdk`.
- [ ] Fix compile errors and repeat, stopping after at most three full attempts.
- [ ] Record whether the result is `0 errors` and summarize remaining warnings.
- [ ] Update documentation so implemented code and pending true-device validation are clearly separated.

## Self-review

- Spec coverage: share ingestion, OCR, LIKE search, persistence, error handling, build verification, and documentation alignment are covered.
- Placeholder scan: no implementation placeholders are used as acceptance criteria.
- Type consistency: all cross-file payloads use named interfaces and Promise return types.
