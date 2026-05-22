# Plan: Wire export DataModal in audit_exporter.svelte

## Context

Selection refactor is complete. Sub-components fire `onSelect(selected: DefinedKeys<ExportType>)`, modal passes it out. `audit_exporter.svelte` currently drops the selection (`_selected`). `getInitialText` and `onExport` props are unused.

Goal: add a `DataModal` to `audit_exporter.svelte` that shows `export_data_to_audit.svelte`, builds and sends the PUT, and calls `onExport`. The PUT logic must live in `audit_exporter.svelte` (not in sub-components). Sub-components pass up the raw data needed to build the PUT (their loaded procedures list).

**Why sub-components must pass procedures**: The PUT endpoint (`Set<AuditProcedureResponseData>`) is full-replacement. `getAuditProcedureData` needs the full procedures list to emit `NotUpdated` entries for all unchanged procedures. Sub-components already have this list from their fetch; `audit_exporter.svelte` does not.

## Design

### New type `ExportPutData` (add to `export.ts`)

```ts
import type { AuditProcedureStatusResponse, AuditProcedureStatuses } from '$types/risk-handling.type';

type ExportPutData =
  | { type: 'Detailed'; procedures: AuditProcedureStatuses }
  | { type: 'OtherGroups'; procedures: AuditProcedureStatusResponse[] }
  | { type: 'FocusArea'; procedures: AuditProcedureStatusResponse[] }
  | { type: 'Management'; procedures: AuditProcedureStatusResponse[] };
```

Export it alongside the other types.

### `onSelect` signature change (3 sub-components + modal)

Change from:
```ts
onSelect: (selected: DefinedKeys<ExportType>) => void
```
To:
```ts
onSelect: (selected: DefinedKeys<ExportType>, putData: ExportPutData) => void
```

### Sub-components: pass `putData` in `onSelect`

Each sub-component builds and passes `ExportPutData` when it calls `onSelect`. The procedures come from the already-loaded data in scope.

**`export_to_procedure.svelte`** — inside `{#snippet children(procedures, group)}`:
```ts
onSelect({ type: 'Detailed', group, procedure }, { type: 'Detailed', procedures })
```

**`export_to_other_groups_procedure.svelte`** — in both click handlers, inside `{#snippet children(nonMaterialData)}`:
- Regular group click: `procedures = [procedure]` (the single group procedure)
- Summary sentinel click: `procedures = [nonMaterialData.summaryProcedure]`
```ts
onSelect({ type: 'OtherGroups', group, procedure }, { type: 'OtherGroups', procedures: [procedure] })
onSelect({ type: 'OtherGroups', group: SUMMARY_SENTINEL, procedure: nonMaterialData.summaryProcedure }, { type: 'OtherGroups', procedures: [nonMaterialData.summaryProcedure] })
```

**`export_to_administrative_procedure.svelte`** — inside `{#snippet children(procedures)}`:
```ts
// selectedType is either 'FocusArea' or 'Management'
onSelect({ type: selectedType, ...rest, procedure }, { type: selectedType, procedures })
```
(`procedures` here is `AdministrationAuditProcedureStatuses['selectedProcedures']` which is `AuditProcedureStatusResponse[]`)

### `export_to_audit_procedure_modal.svelte`

Change prop + forward both args:
```ts
onSelect: (selected: DefinedKeys<ExportType>, putData: ExportPutData) => void
```
```svelte
onSelect={(s, putData) => { onSelect(s, putData); open = false; }}
```
Import `ExportPutData` from `./export`.

### `audit_exporter.svelte`

1. Add `DataModal` imports and state:
```ts
import { DataModal, type DataModalType } from '$components/modal';
import ExportDataToAudit from '$components/analysis/export_to_audit/export_data_to_audit.svelte';
import { type ExportPutData, makeAuditFileConnectionRef, sendAuditProcedureAction } from '$components/analysis/export_to_audit/export';
import { getAuditProcedureData } from '$lib/risk-handling/data';
import { AuditFileConnectionReference } from '$lib/file_connection';
import { automaticResponseToUserResponse } from '$types/automatic-responses.type';

type ModalData = { selected: DefinedKeys<ExportType>; putData: ExportPutData };
let exportData: DataModalType<ModalData> = $state({ type: 'Closed' });
```

2. Change `onSelect` on the selection modal:
```svelte
onSelect={(selected, putData) => {
  exportData = { type: 'Open', data: { selected, putData } };
}}
```
Remove the `_` prefix from `getInitialText` and `onExport`.

3. Add DataModal with `ExportDataToAudit`. The `onSubmit` callback:
   - Builds the PUT action via `getAuditProcedureData` (switch on `data.putData.type` / `data.selected.type`)
   - Calls `sendAuditProcedureAction(action, caseId)`
   - Makes the file connection reference via `makeAuditFileConnectionRef` (type-based: Detailed → `procedureReferenceType(...)`, OtherGroups → `'DetailedAuditProcedure'`, FocusArea/Management → `'AdministrationAuditProcedure'`)
   - Calls `await onExport(reference, exportContext)`
   - Sets `exportData = { type: 'Closed' }`

```svelte
<DataModal heading={(d) => d.selected.procedure.description} bind:value={exportData}>
  {#snippet open(data)}
    <ExportDataToAudit
      selected={data.selected}
      initialText={getInitialText(data.selected.procedure)}
      onSubmit={async (text) => {
        // build and send PUT
        // build reference
        // call onExport
        exportData = { type: 'Closed' };
      }}
    />
  {/snippet}
</DataModal>
```

The PUT building logic uses the `AuditProcedureResponseSource` variant matching `putData.type`:
- `'Detailed'` → source `{ type: 'Group', group: (selected as DefinedKeys<ExportDetailedType>).group }`
- `'OtherGroups'` → source `{ type: 'NonMaterial' }`
- `'FocusArea'` → source `{ type: 'FocusArea', category: (selected as DefinedKeys<ExportFocusAreaType>).category }`
- `'Management'` → source `{ type: 'Management', section: (selected as DefinedKeys<ExportManagementType>).section }`

The `as` casts are acceptable here: this is the one place that correlates `selected.type` with `putData.type` and TypeScript cannot narrow both from a single discriminant check on a non-combined union.

## Files to change

| File | Change |
|---|---|
| `export.ts` | Add `ExportPutData` type, export it |
| `export_to_procedure.svelte` | Pass `ExportPutData` in `onSelect` call |
| `export_to_other_groups_procedure.svelte` | Same |
| `export_to_administrative_procedure.svelte` | Same |
| `export_to_audit_procedure_modal.svelte` | Extend `onSelect` sig, forward `putData` |
| `audit_exporter.svelte` | Add DataModal + ExportDataToAudit, wire PUT + onExport |

No changes to `select_procedure.svelte`, `select_administrative_procedure.svelte`, `export_auth.svelte`, or tab/class:hidden structure.

## Verification

- `pnpm --filter audit check` — 0 errors
- `pnpm --filter audit lint` — 0 errors
