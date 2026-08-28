# Prototype A Share Target Fix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make “知微” appear as a Share Kit target for gallery images while preserving the existing in-panel confirmation and local-save flow.

**Architecture:** Keep the existing Stage-model `ShareExtensionAbility` and all ArkTS processing code unchanged. Replace MIME-based target declarations with HarmonyOS UTD declarations in the module profile, then validate the packaged profile and debug HAP build.

**Tech Stack:** HarmonyOS 6.0.1(21), Stage model, Share Kit, `ShareExtensionAbility`, UTD, Hvigor.

**Spec:** `docs/plans/2026-08-28-prototype-a-share-target-fix-design.md`

## Global Constraints

- Keep the current share-panel confirmation UI; do not open the full application.
- Do not modify `OCRService.ets` or any Prototype B behavior.
- Do not add cloud services, dependencies, permissions, or broad `general.object` matching.
- Continue to use the existing `ShareExtAbility.ets`, `ShareConfirmPage.ets`, file-copy service, and RDB flow.
- The project directory is not a Git repository, so commit steps are not applicable.

---

### Task 1: Register precise Share Kit UTD targets

**Files:**
- Modify: `entry/src/main/module.json5`
- Modify: `entry/src/main/resources/base/element/string.json`

**Interfaces:**
- Consumes: Share Kit target matching for action `ohos.want.action.sendData`.
- Produces: A `ShareExtAbility` target supporting `general.image`, `general.plain-text`, and `general.hyperlink` while continuing to load `pages/ShareConfirmPage` through the existing ArkTS class.

- [x] **Step 1: Capture the current failing configuration**

Confirm that the packaged profile contains MIME declarations and no UTD declarations:

```powershell
Select-String -LiteralPath 'entry/build/default/intermediates/package/default/module.json' -Pattern 'image/\*|general.image'
```

Expected before the change: output contains `image/*` and does not contain `general.image`.

- [x] **Step 2: Replace the share extension registration**

Set the `ShareExtAbility` entry to the following configuration while leaving the other module fields unchanged:

```json5
{
  "name": "ShareExtAbility",
  "srcEntry": "./ets/shareextensionability/ShareExtAbility.ets",
  "type": "share",
  "exported": true,
  "icon": "$media:layered_image",
  "label": "$string:ShareExtAbility_label",
  "skills": [
    {
      "actions": [
        "ohos.want.action.sendData"
      ],
      "uris": [
        {
          "scheme": "file",
          "utd": "general.image",
          "maxFileSupported": 20
        },
        {
          "scheme": "file",
          "utd": "general.plain-text",
          "maxFileSupported": 1
        },
        {
          "scheme": "https",
          "utd": "general.hyperlink",
          "maxFileSupported": 1
        }
      ]
    }
  ]
}
```

Add the following localized label resource to `entry/src/main/resources/base/element/string.json`:

```json
{
  "name": "ShareExtAbility_label",
  "value": "知微"
}
```

- [x] **Step 3: Build the debug HAP**

Run:

```powershell
$env:DEVECO_SDK_HOME='D:\local\DevEcoStudio\sdk'
& 'D:\local\DevEcoStudio\tools\hvigor\bin\hvigorw.bat' --mode module -p product=default -p module=entry@default -p buildMode=debug assembleHap
```

Expected: `BUILD SUCCESSFUL` and `0 errors`.

- [x] **Step 4: Verify the packaged module profile**

Run:

```powershell
Select-String -LiteralPath 'entry/build/default/intermediates/package/default/module.json' -Pattern 'general.image|general.plain-text|general.hyperlink|maxFileSupported'
```

Expected: the packaged profile contains all three UTD values and their file-count declarations; it does not contain `image/*` or `text/plain` in `ShareExtAbility.skills`.

- [x] **Step 5: Confirm Prototype B was untouched**

Read `entry/src/main/ets/services/OCRService.ets` and confirm no edit was made during this task. Since the project has no Git metadata, compare the file contents and modification timestamp observed before implementation rather than using `git diff`.

### Task 2: Validate the share target in the emulator

**Files:**
- No source changes.

**Interfaces:**
- Consumes: The rebuilt HAP containing the corrected Share Kit UTD target profile.
- Produces: Manual evidence that the system lists and launches the existing share extension.

- [ ] **Step 1: Remove the previously installed application**

In DevEco Studio Device Manager or the emulator settings, uninstall `com.example.knowclip`. This refreshes the system's cached share-target registration.

- [ ] **Step 2: Reinstall and launch the rebuilt application**

Use DevEco Studio Run for the `entry` module and confirm the prototype home screen opens.

- [ ] **Step 3: Validate gallery image sharing**

Open Gallery, select one image, choose Share, and confirm that “知微” is listed. Select it and confirm the existing `ShareConfirmPage` appears inside the share flow.

- [ ] **Step 4: Validate cancel and save paths**

Use Cancel once and verify the system returns to the share panel. Repeat the share, select Save, and verify the page reports that the item was saved locally.

- [ ] **Step 5: Record the result**

Record the emulator system version, whether “知微” appeared, whether the confirmation page opened, and any `ShareExtAbility` or `ShareConfirmPage` logs. Prototype B OCR is excluded from this emulator run.
