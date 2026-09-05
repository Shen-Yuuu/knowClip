# Prototype A Diagnostic Logging Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add privacy-safe `[原型A]` logs across the complete Gallery-share receive and save path.

**Architecture:** Centralize prefix formatting and URI-scheme redaction in a small logging utility, while retaining the existing `Logger` backend. Instrument the extension boundary, confirmation page, file copy service, and session service without changing their data contracts or control flow.

**Tech Stack:** HarmonyOS NEXT, ArkTS, ArkUI, Share Kit, Core File Kit, Hypium, Hvigor

**Spec:** `docs/plans/2026-09-05-prototype-a-diagnostic-logging-design.md`

## Global Constraints

- Every new diagnostic message starts with `[原型A]`.
- Never log complete URI values, shared text, database content, or complete sandbox paths.
- Do not change the share manifest, UI layout, persistence behavior, or public service return types.
- Keep `ShareDataParser` free of logging side effects.

---

### Task 1: Central diagnostic formatter

**Files:**
- Create: `entry/src/main/ets/utils/PrototypeALog.ets`
- Modify: `entry/src/test/LocalUnit.test.ets`

**Interfaces:**
- Consumes: existing `Logger.info`, `Logger.warn`, and `Logger.error`.
- Produces: `PrototypeALog.info(tag: string, stage: string, message: string)`, matching `warn` and `error` methods, plus `PrototypeALog.uriScheme(uri?: string): string`.

- [ ] Add unit tests asserting `uriScheme(undefined) === 'none'`, `uriScheme('file://media/a.jpg') === 'file'`, and a non-scheme value returns `relative`.
- [ ] Implement all three log levels as `Logger` calls whose message is `[原型A][${stage}] ${message}`.
- [ ] Implement URI redaction by returning only the substring before the first colon; return `none` or `relative` when appropriate.
- [ ] Run `hvigorw test --mode module -p module=entry@default -p product=default --no-daemon` and require no Hypium error lines.

### Task 2: Instrument share receipt and persistence

**Files:**
- Modify: `entry/src/main/ets/shareextensionability/ShareExtAbility.ets`
- Modify: `entry/src/main/ets/pages/ShareConfirmPage.ets`

**Interfaces:**
- Consumes: `PrototypeALog` from Task 1 and existing Share Kit/database contracts.
- Produces: stage logs for extension lifecycle, Want summary, Share Kit parsing, page loading, page input summary, save phases, attachment writes, user cancellation, and final result.

- [ ] Replace existing share-specific `Logger` calls with `PrototypeALog` calls and add logs before and after each asynchronous boundary.
- [ ] Log each record only as index, UTD, `hasUri`, `uriScheme`, `hasContent`, and content length.
- [ ] Log normalized data only as image count, text length, and URL presence.
- [ ] In save errors, record the error class and failing high-level phase without recording error messages that may contain paths or content.
- [ ] Log delayed session termination by explicitly observing and handling the returned promise.

### Task 3: Instrument file and session boundaries

**Files:**
- Modify: `entry/src/main/ets/services/FileService.ets`
- Modify: `entry/src/main/ets/services/ShareSessionService.ets`

**Interfaces:**
- Consumes: unchanged media URI, `CopyResult`, `UIExtensionContentSession`, and result code inputs.
- Produces: logs for batch count, URI scheme, directory readiness, source/target open state, copy completion, size/duration, cleanup, session registration, session absence, close request, close success, and close failure.

- [ ] Track a local copy phase string so a failure reports the exact stage without exposing the URI or target path.
- [ ] Replace existing file-copy messages containing full paths with count, scheme, byte size, duration, and phase metadata.
- [ ] Wrap `terminateSelfWithResult` in logging and rethrow on failure so existing callers preserve their error behavior.
- [ ] Run unit tests, assemble the debug HAP, and run `git diff --check`.
- [ ] On a real device, collect logs by bundle/all-process scope and filter message text for `[原型A]`; do not restrict collection to the original `EntryAbility` PID.
