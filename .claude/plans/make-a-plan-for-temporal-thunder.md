# Plan: Migrate `voucher_modal.svelte` to `DataModalType` pattern

## Context

`voucher_modal.svelte` currently manages its open/closed state via `voucherId: VoucherId | undefined` — `undefined` means closed, a value means open. This is an ad-hoc pattern that uses a `$state(false)` + `$effect` combo (with ESLint suppression) to derive `modalOpen` from `voucherId`.

The codebase has a canonical pattern for this: `DataModalType<TData>` from `$components/modal`. For complex modals that can't use `DataModal` directly (e.g. the heading uses async snippet rendering, not a string), CLAUDE.md specifies using `value: DataModalType<YourData>` as a bindable prop with `let isOpen = $derived(value.type === 'Open')`.

The heading in `voucher_modal.svelte` uses `VoucherQuery` (async) to render a `<Link>` + `<h6>`, so it cannot be a plain `(data) => string` function — we cannot use `DataModal` directly and must implement the dedicated-component pattern.

## Critical Files

- `audit/src/components/recipes/voucher_modal.svelte` — component to refactor
- `audit/src/components/modal/data_modal.svelte` — pattern reference
- `audit/src/components/modal/index.ts` — exports `DataModal`, `DataModalType`
- 8 callsites (see below)

## Changes

### 1. `voucher_modal.svelte`

Add a module script to export a convenience type alias:

```svelte
<script lang="ts" module>
  import type { DataModalType } from '$components/modal';
  import type { VoucherId } from '@df/common';
  export type VoucherModalValue = DataModalType<VoucherId>;
</script>
```

In the instance script:
- Import `DataModalType` from `$components/modal`
- Remove `definedNotNull` from imports (replaced by `value.type === 'Open'` checks)
- Change prop: `voucherId: VoucherId | undefined` → `value: DataModalType<VoucherId>` (bindable)
- Remove `let modalOpen = $state(false)` + the `$effect` block + the `eslint-disable-next-line` comment
- Add `let isOpen = $derived(value.type === 'Open')`
- Change `bind:open={modalOpen}` → `bind:open={isOpen}`
- Change `onClose={() => { voucherId = undefined; }}` → `onClose={() => { value = { type: 'Closed' }; }}`
- Replace both `{#if definedNotNull(voucherId)}` guards with `{#if value.type === 'Open'}`
- Replace `id: voucherId` (×2, inside VoucherQuery selectors) with `id: value.data`

### 2. Six straightforward callsites

Files: `account_entry_table.svelte`, `explore_entry_table.svelte`, `taxes/vat/+page.svelte`, `taxes/tax-account/+page.svelte`, `taxes/paye/+page.svelte`, `bank/+page.svelte`

Pattern for each:
- Import `type { VoucherModalValue } from '$components/recipes/voucher_modal.svelte'` (or inline `DataModalType<VoucherId>`)
- Change state: `let showVoucherId: VoucherId | undefined = undefined` → `let showVoucherModal: VoucherModalValue = $state({ type: 'Closed' })`
- Change assignment: `showVoucherId = row.voucherId.id` → `showVoucherModal = { type: 'Open', data: row.voucherId.id }`
- Change bind: `bind:voucherId={showVoucherId}` → `bind:value={showVoucherModal}`
- Note: `markRow` callbacks referencing `showVoucherEntryId` (vat, paye) are unchanged — `showVoucherEntryId` remains a separate `$state` variable

### 3. `search/+page.svelte`

This callsite uses `{#if showVoucherId && voucherContext}` because `voucherContext` is derived from a per-row `voucherBookYear`. The `showVoucherId` part of the guard is eliminated by the DataModal pattern; the `voucherContext` guard can stay:

```svelte
{#if voucherContext}
  <VoucherModal bind:value={showVoucherModal} context={voucherContext} ... />
{/if}
```

State variables change:
- `showVoucherId: VoucherId | undefined` → `showVoucherModal: VoucherModalValue = $state({ type: 'Closed' })`
- `voucherBookYear` remains as-is (used to construct `voucherContext`)
- `onRowClick`: `showVoucherId = row.voucherId.id` → `showVoucherModal = { type: 'Open', data: row.voucherId.id }`

### 4. `accrual_view.svelte`

Same structure: `{#if showVoucherId && voucherContext}` with per-row context.

```svelte
{#if voucherContext}
  <VoucherModal bind:value={showVoucherModal} context={voucherContext} ... />
{/if}
```

State:
- `showVoucherId: VoucherId | undefined` → `showVoucherModal: VoucherModalValue = $state({ type: 'Closed' })`
- `onRowClick`: `showVoucherId = row.voucherId.id` → `showVoucherModal = { type: 'Open', data: row.voucherId.id }`

## Verification

1. `pnpm --filter audit check` — svelte-check should pass with no new type errors
2. `pnpm --filter audit lint` — ESLint should pass (the `svelte/prefer-writable-derived` suppression comment is removed along with the `$state(false)` + `$effect`)
3. Manual: open any analysis page, click a row that triggers a voucher modal — modal should open, show the voucher heading + entry table, and close correctly (ESC, backdrop, or X button)
4. Manual: in vat/paye pages, verify the `markRow` highlight still works correctly
