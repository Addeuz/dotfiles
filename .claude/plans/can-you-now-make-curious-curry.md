# Plan: Separate Select Logic from Export in `export_to_audit/`

## Context

After renaming `Export*` types to `Select*`, the `export_to_audit/` folder is conceptually split between two concerns:
1. **Select** — UI for choosing which audit procedure to export to
2. **Export** — actually performing the file export and PUT actions

Currently both concerns live in the same folder and the same `export.ts` file. This plan moves all select-related files into a dedicated `select_procedure/` folder and splits `export.ts` into two files.

---

## Final folder structure

**New folder:** `audit/src/components/analysis/select_procedure/`

| New filename | Source |
|---|---|
| `select.ts` | Split from `export.ts` (select types + config function) |
| `select_procedure_modal.svelte` | Renamed from `export_to_audit_procedure_modal.svelte` |
| `select_auth.svelte` | Renamed from `export_auth.svelte` |
| `select_detailed_procedure.svelte` | Renamed from `export_to_procedure.svelte` |
| `select_administration_flow.svelte` | Renamed from `export_to_administrative_procedure.svelte` |
| `select_other_groups_procedure.svelte` | Renamed from `export_to_other_groups_procedure.svelte` |
| `select_administrative_procedure.svelte` | Moved (no rename — already correct) |
| `select_category.svelte` | Moved (no rename) |
| `select_group.svelte` | Moved (no rename) |
| `select_procedure.svelte` | Moved (no rename) |
| `select_section.svelte` | Moved (no rename) |
| `select_variant.svelte` | Moved (no rename) |

**Remaining in `export_to_audit/`:**

| File | Change |
|---|---|
| `export.ts` | Remove select types and `exportProcedureConfiguration`; keep only export functions |
| `export_data_to_audit.svelte` | No change |

---

## Step-by-step

### 1. Create `select_procedure/select.ts`

Move from `export.ts` into this new file:
- Types: `SelectDetailedType`, `SelectFocusAreaType`, `SelectManagementType`, `SelectOtherGroupsType`, `SelectProcedureType`, `SelectProcedureTab`
- Rename `ExportProcedureContext` → `SelectProcedureContext`
- Rename `exportProcedureConfiguration` → `selectProcedureConfiguration`
- Move the internal helper `getOtherGroups` alongside `selectProcedureConfiguration`

Imports needed in `select.ts`: same as current `export.ts` except those only used by export functions.

### 2. Trim `export_to_audit/export.ts`

Remove everything moved to `select.ts`. Remaining exports:
- `exportToAudit`
- `exportSampleToAudit`
- `exportExportableFilesToAudit` (marked TODO: unused — leave as-is)
- `makeAuditFileConnectionRef`
- `sendAuditProcedureAction`
- `sendExportedFileToAudit`

### 3. Create the renamed Svelte files in `select_procedure/`

For each file below, copy content and update all internal imports:

| Old path | New path | Internal import changes |
|---|---|---|
| `export_to_audit_procedure_modal.svelte` | `select_procedure_modal.svelte` | `./export_auth` → `./select_auth`; `./export_to_administrative_procedure` → `./select_administration_flow`; `./export_to_other_groups_procedure` → `./select_other_groups_procedure`; `./export_to_procedure` → `./select_detailed_procedure`; types from `./export` → `./select` |
| `export_auth.svelte` | `select_auth.svelte` | No internal imports from export.ts |
| `export_to_procedure.svelte` | `select_detailed_procedure.svelte` | `./select_group`, `./select_procedure` → relative (same folder); type from `./export` → `./select`; `exportProcedureConfiguration` is now gone (it lives in `./select` and is used by `select_procedure.svelte` directly) |
| `export_to_administrative_procedure.svelte` | `select_administration_flow.svelte` | `./select_*` → relative (same folder); types from `./export` → `./select` |
| `export_to_other_groups_procedure.svelte` | `select_other_groups_procedure.svelte` | `./select_group` → relative; type from `./export` → `./select` |
| `select_procedure.svelte` | `select_procedure.svelte` | `exportProcedureConfiguration` → `selectProcedureConfiguration` from `./select` |
| `select_administrative_procedure.svelte` | `select_administrative_procedure.svelte` | `exportProcedureConfiguration` → `selectProcedureConfiguration` from `./select` |
| `select_group.svelte`, `select_category.svelte`, `select_section.svelte`, `select_variant.svelte` | same names | No imports from `export.ts` — no changes needed |

### 4. Update consumers outside the folder

| File | Change |
|---|---|
| `audit/src/components/exporter/audit_exporter.svelte` | Import `SelectProcedureType` types from `$components/analysis/select_procedure/select`; import `SelectProcedureModal` from `$components/analysis/select_procedure/select_procedure_modal.svelte` (was `ExportToAuditProcedureModal`) |
| `audit/src/components/exporter/export_modal.svelte` | Import `SelectProcedureType` from `$components/analysis/select_procedure/select` |
| `audit/src/components/exporter/voucher_entry_exporter.svelte` | No change (uses `exportToAudit` which stays in `export.ts`) |
| `sampling/.../+page.svelte` | No change (uses `exportSampleToAudit` which stays) |

### 5. Move files with `git mv`

Use `git mv` to rename/move each file (preserves history). After moving, update internal imports before running the type-check:

```bash
cd audit/src/components/analysis
mkdir select_procedure

# Rename export_to_ → select_ files
git mv export_to_audit/export_to_audit_procedure_modal.svelte select_procedure/select_procedure_modal.svelte
git mv export_to_audit/export_auth.svelte                     select_procedure/select_auth.svelte
git mv export_to_audit/export_to_procedure.svelte             select_procedure/select_detailed_procedure.svelte
git mv export_to_audit/export_to_administrative_procedure.svelte select_procedure/select_administration_flow.svelte
git mv export_to_audit/export_to_other_groups_procedure.svelte   select_procedure/select_other_groups_procedure.svelte

# Move already-correctly-named select_ files
git mv export_to_audit/select_administrative_procedure.svelte select_procedure/
git mv export_to_audit/select_category.svelte                 select_procedure/
git mv export_to_audit/select_group.svelte                    select_procedure/
git mv export_to_audit/select_procedure.svelte                select_procedure/
git mv export_to_audit/select_section.svelte                  select_procedure/
git mv export_to_audit/select_variant.svelte                  select_procedure/
```

`select.ts` is a new file (no git mv needed — create it directly).

---

## Critical files

- `audit/src/components/analysis/export_to_audit/export.ts` — split source
- `audit/src/components/analysis/select_procedure/select.ts` — new file (create)
- `audit/src/components/exporter/audit_exporter.svelte` — only external consumer of the modal + types
- `audit/src/components/exporter/export_modal.svelte` — imports `SelectProcedureType['type']`

---

## Naming conflict resolution

Two existing `select_*.svelte` filenames would conflict if we simply stripped `export_to_`:
- `export_to_procedure.svelte` (flow/wizard) vs `select_procedure.svelte` (leaf list) → resolved by naming the flow `select_detailed_procedure.svelte`
- `export_to_administrative_procedure.svelte` (flow) vs `select_administrative_procedure.svelte` (leaf list) → resolved by naming the flow `select_administration_flow.svelte`

---

## Verification

```
pnpm --filter audit check   # 0 errors
pnpm --filter audit lint
```

Manually confirm:
- No remaining imports of the old paths under `export_to_audit/select_*` or `export_to_audit/export_to_*` from outside the folder
- `export_to_audit/` contains only `export.ts` and `export_data_to_audit.svelte`
- `select_procedure/` contains all 12 files listed above
