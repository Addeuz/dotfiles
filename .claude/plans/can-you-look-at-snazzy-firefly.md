# carbon-components-svelte upgrade cleanup: 0.98.2 → 0.107.2

## Context

The project is already on `carbon-components-svelte@0.107.0`. The changelog between 0.98.2 and 0.107.0 includes several targeted bug fixes for components dispatching `on:change`/`on:update`/`on:select` events on mount (a Svelte 5 regression). One explicit TODO workaround was left in the code; several other handlers were silently misfiring on mount and are now fixed by the library. There are also a handful of new props worth adopting.

---

## 1. Remove explicit workaround: TODO#2871

**File**: `audit/src/components/documents/upload_files.svelte`, lines 225–235

**Fix**: `Select` previously fired `on:update` on mount (fixed in v0.106.2), so the code fell back to `on:change` and manually extracts the value from `e.target`. Switch to `on:update`:

```svelte
<!-- Before -->
on:change={(e) => {
  // TODO#2871 (EXTERNAL) Change to on:update when ...
  if (e.target instanceof HTMLSelectElement && isAuditDocumentType(e.target.value)) {
    temporarySelectedType.set(index, [name, e.target.value]);
  }
}}

<!-- After -->
on:update={({ detail }) => {
  if (isAuditDocumentType(detail)) {
    temporarySelectedType.set(index, [name, detail]);
  }
}}
```

Note: `LocalFilesUploadModal.svelte` (lines 166, 182) already uses `on:update` correctly on the same pattern — the fix is consistent with existing usage.

---

## 2. RadioButtonGroup on:change handlers that were silently misfiring on mount

**Fix in library**: v0.107.0 — `RadioButtonGroup` and `ContentSwitcher` no longer dispatch `on:change` on mount.

These handlers had **no guard conditions**, so they were firing on mount and may have caused subtle bugs. No code changes are needed now (the library fixed the dispatch), but each should be verified manually:

### Potentially harmful mount-fires (review carefully):

| File | Line | Handler | Mount-fire effect |
|------|------|---------|-------------------|
| `audit/src/components/risk_assessment/material-accounts/RiskSummary.svelte` | 172 | `riskLevelSummary = { detail: 'OnlyLevel', level }` | Could have overwritten a `WithMotivation` variant (losing the motivation text) on every mount |
| `audit/src/components/exporter/accounting_data_sample_configurator.svelte` | ~246 | `statisticalBasis = undefined` | Was resetting `statisticalBasis` to `undefined` on every mount |
| `audit/src/components/documents/upload_files.svelte` | 205 | `temporarySelectedType.set(index, [name, detail])` | Was spuriously overwriting `temporarySelectedType` on mount |
| `audit/src/components/documents/upload_files.svelte` | 137 | `temporarySelectedType.delete(index)` | Was deleting from `temporarySelectedType` on mount |

### Low-risk / effectively no-ops:

| File | Line | Why benign |
|------|------|-----------|
| `BugReport.svelte` | 93 | Re-sets `bugReport.bugType` to its current value |
| `graphs.svelte` | 51, 70 | Re-confirms already-selected key figure |
| `+page.svelte` (audit_report) | 823 | Complex but condition guards against empty state |
| `LocalFilesUploadModal.svelte` | 136, 158 | Re-sets `file.documentType` to its current value |

---

## 3. Select on:update handlers that were silently misfiring on mount

**Fix in library**: v0.106.2 — `Select` no longer dispatches `on:update` on mount.

These all use `on:update` directly (no workaround), so they compiled fine but would fire on mount:

| File | Lines | Risk |
|------|-------|------|
| `audit/src/components/misc/DateFilter.svelte` | 117, 141 | Could have incorrectly reset date filter state on mount |
| `audit/src/components/risk_assessment/ProcedureFilter.svelte` | 57, 103, 137 | Could have reset filter selections on mount |
| `audit/src/components/exporter/financial_statements_export_configurator.svelte` | 38 | Re-sets `format` to current value — benign |
| `audit/src/components/exporter/control_activity_per_month_export_configurator.svelte` | 41, 89 | Likely benign re-sets |
| `audit/src/components/risk_assessment/financial-overview/financial_overview.svelte` | 458, 511 | Worth checking |
| `audit/src/components/risk_assessment/financial-overview/multi-year/multi_year_overview.svelte` | 139, 180 | Worth checking |

No code changes needed — the library fix applies automatically. Manual verification that filters/overviews behave correctly after mount.

---

## 4. New features worth adopting

### 4a. `preventDuplicates` on FileUploaderDropContainer (v0.104.0)

Files that could benefit:
- `audit/src/components/documents/upload_files.svelte` line 101
- `audit/src/components/documents/state/upload_signed_letter_modal.svelte` line 55
- `audit/src/components/base_information/confirm_modal.svelte` line 356
- `audit/src/routes/(authed)/analysis/clients/[client_id]/taxes/upload_tax_file.svelte` line 25
- `audit/src/routes/(authed)/analysis/clients/[client_id]/bank/upload_bank_file.svelte` line 30

Add `preventDuplicates` to each `<FileUploaderDropContainer>` to block the same file being added twice.

### 4b. Portal menus (v0.101.0)

`portalMenu` prop added to `ComboBox`, `Dropdown`, `MultiSelect`, `DatePicker`, `OverflowMenu`. Useful when these components appear inside modals or `overflow: hidden` containers (prevents clipping). Audit the 3 `MultiSelect`, 1 `ComboBox`, 3 `DatePicker` usages and add `portalMenu` where the dropdown is visually clipped.

### 4c. ComboBox `openOnClear` (v0.106.0)

One `ComboBox` in the codebase. If UX should re-open the dropdown after clearing the input, add `openOnClear`.

---

## Verification

1. **Item 1** (`upload_files.svelte` Select): Upload a file, expand it, and use the "Välj annan typ" dropdown — the document type should update correctly without needing to interact with the native `<select>` element directly.
2. **Items 2–3** (silent fixes): Exercise `RiskSummary`, `DateFilter`, `ProcedureFilter`, and `accounting_data_sample_configurator` — confirm selection state is correct immediately after those components mount (no spurious resets).
3. **Item 4a** (preventDuplicates): Drag the same file twice into each uploader — it should be rejected after the first add.
4. Run `pnpm --filter audit check` and `pnpm --filter audit lint` after changes.
