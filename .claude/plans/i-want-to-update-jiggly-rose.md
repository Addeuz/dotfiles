# Upgrade carbon-components-svelte 0.98.2 → 0.107.1

## Context

The project currently pins `carbon-components-svelte` at `^0.98.2` (resolved: 0.98.2) in two packages: `audit/` and `libraries/typescript/components/`. The latest release is **v0.107.1** (May 2, 2024). Cross-referencing all breaking changes in releases 0.99.0–0.107.1 against actual usage in the codebase, there is **1 required code fix**, **1 thing to verify**, and several optional improvements.

---

## Step 1 — Bump the version

In both `package.json` files, change:
```json
"carbon-components-svelte": "^0.98.2"
```
to:
```json
"carbon-components-svelte": "^0.107.1"
```

Files:
- `audit/package.json`
- `libraries/typescript/components/package.json`

Then run `pnpm install` from the repo root.

---

## Step 2 — Required code fix (1 file)

**Breaking change (v0.102.0):** DataTable slot `"expanded-row"` renamed to `"expandedRow"`.

File: `audit/src/components/misc/DataTableWithSkeleton.svelte` ~line 111

Change:
```svelte
<svelte:fragment slot="expanded-row" let:row>
```
to:
```svelte
<svelte:fragment slot="expandedRow" let:row>
```

---

## Step 3 — Verify FileUploaderDropContainer `on:add`

Five files use `on:add` on `<FileUploaderDropContainer>`:
- `audit/src/routes/(authed)/analysis/clients/[client_id]/taxes/upload_tax_file.svelte`
- `audit/src/routes/(authed)/analysis/clients/[client_id]/bank/upload_bank_file.svelte`
- `audit/src/components/data/upload_new_file.svelte` (modified on current branch)
- `audit/src/components/documents/upload_files.svelte`
- `audit/src/components/documents/state/upload_signed_letter_modal.svelte`

v0.104.0 added new events (`clear`, `change`, `rejected`) but the release notes do not mention `on:add` being removed. After upgrading, verify these files still work correctly by testing a file upload flow. If `on:add` is gone, migrate to `on:change`.

---

## Step 4 — Optional: migrate SkeletonPlaceholder to new props

v0.104.0 added `width` and `height` props. All current usages pass inline `style="height: ...; width: ...;"`. This is non-breaking (inline style still works), but consider migrating if desired. Affected files:
- `audit/src/components/account_balance/Skeleton.svelte`
- `audit/src/components/risk_assessment/financial-overview/key-figures/Skeleton.svelte`
- `audit/src/components/risk_assessment/financial-overview/overview/Skeleton.svelte`
- `audit/src/components/documents/state/board_auditor.svelte`

---

## Breaking changes confirmed NOT applicable

| Change | Reason |
|---|---|
| DataTable `"cell-header"` → `"cellHeader"` (v0.99.0) | Slot not used in codebase |
| NumberInput `blur` event signature (v0.100.0) | No `on:blur` handlers on NumberInput |
| Tag `click` event behavior (v0.102.0) | Project uses a custom Tag component, not Carbon's |
| Internal `carbon:` context prefix (v0.101.0) | No direct context access in app code |

---

## Verification

1. `pnpm --filter audit check` — svelte-check must pass
2. `pnpm --filter audit lint` — ESLint must pass
3. `pnpm --filter @diffinder/components check` — svelte-check on component library
4. Manual test: open a DataTable with expandable rows and confirm the expanded content renders
5. Manual test: upload a file via FileUploaderDropContainer and confirm the `on:add` handler fires
