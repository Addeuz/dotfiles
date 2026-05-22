# Plan: create_book_year_without_file_modal + select_book_year components

## Context

The "Skapa räkenskapsår utan fil" button in `create_book_years.svelte` now opens an inline `DataModal` with `AdaptiveLoader`. The goal is to extract this into a standalone `create_book_year_without_file_modal.svelte` component, and to build a `select_book_year.svelte` child that lets the user pick a book year — using `Selectable` tiles instead of Carbon buttons for the suggested years. The modal tracks `selectedBookYear: Time.BookYear | undefined` and exposes a disabled "Skapa räkenskapsår" button.

## Files to create

| File | Purpose |
|---|---|
| `…/[activity=onboarding_activity]/select_book_year.svelte` | Book year picker with Selectable tiles + DatePicker |
| `…/[activity=onboarding_activity]/create_book_year_without_file_modal.svelte` | DataModal shell, AdaptiveLoader, selectedBookYear state |

## File to modify

- `…/[activity=onboarding_activity]/create_book_years.svelte` — replace inline `DataModal`/`AdaptiveLoader` block with `<CreateBookYearWithoutFileModal>`

---

## `select_book_year.svelte`

**Props:**
```ts
interface Props {
  data: ValidCompanySearch;   // from '$types/company.type'
  onSelect: (bookYear: Time.BookYear) => void;
}
```

**Internal state:**
```ts
let selectedBookYear: Time.BookYear | undefined = $state(undefined);
let invalidBookYear = $state(false);
```

**Suggested years section** (rendered when `data.financialYear` is defined):
- Two `<Selectable>` tiles (from `$components/selectable`), one for `current` and one for `other` from `data.financialYear`
- `checked={selectedBookYear?.equals(year) ?? false}` for each
- `onChange`: if `checked`, call `selectYear(year)`; if unchecked and currently selected, clear `selectedBookYear`
- Clicking one auto-unchecks the other because `selectedBookYear` changes and the other tile's `checked` prop becomes false

**Custom date range section:**
- `DatePicker` + two `DatePickerInput` from `carbon-components-svelte`, locale `Swedish` from flatpickr
- `on:change`: parse `detail.dateStr.from` / `.to` via `Time.BookYear.fromBookYearDto`, log errors with `logError`, set `invalidBookYear`, call `selectYear` on success
- Selecting a date range does NOT check either Selectable tile (selectedBookYear won't equal current or other unless it happens to match)

**Helper:**
```ts
function selectYear(year: Time.BookYear) {
  selectedBookYear = year;
  onSelect(year);
}
```

**No navigation buttons** (those live in the modal's `actions` snippet).

**Style:** plain CSS, `--space-*` tokens, typography classes (`label` for headings). No SCSS.

---

## `create_book_year_without_file_modal.svelte`

**Props:**
```ts
interface Props {
  value: DataModalType<Promise<Result<CompanySearch, never>>>;
}
let { value = $bindable() }: Props = $props();
```

**Internal state:**
```ts
let selectedBookYear: Time.BookYear | undefined = $state(undefined);
```

**Template outline:**
```svelte
<DataModal
  bind:value
  heading={() => 'Skapa räkenskapsår utan fil'}
  size="s"
  afterClose={() => (selectedBookYear = undefined)}
>
  {#snippet open(promise)}
    <AdaptiveLoader {promise}>
      {#snippet children(result)}
        {#if result.type === 'Company'}
          <SelectBookYear data={result} onSelect={(year) => (selectedBookYear = year)} />
        {:else}
          <p>Företaget hittades inte</p>
        {/if}
      {/snippet}
    </AdaptiveLoader>
  {/snippet}
  {#snippet actions()}
    <Button.Default disabled={selectedBookYear === undefined} onClick={() => {}}>
      Skapa räkenskapsår
    </Button.Default>
  {/snippet}
</DataModal>
```

Imports: `AdaptiveLoader`, `Button`, `DataModal`/`DataModalType`, `CompanySearch`/`ValidCompanySearch`, `Time`, `Result` from neverthrow, `SelectBookYear`.

---

## Changes in `create_book_years.svelte`

1. Remove: `AdaptiveLoader` import, `UserApi` import, `ok`/`Result` imports, `CompanySearch` type import, `withoutFileModal` state, the `DataModal`/`AdaptiveLoader` block at the bottom.
2. Add: `import CreateBookYearWithoutFileModal from './create_book_year_without_file_modal.svelte'`
3. Add state: `let withoutFileModal: DataModalType<Promise<Result<CompanySearch, never>>> = $state({ type: 'Closed' })`  
   (keep the type so the button onClick can still fire `UserApi.getJson(...).then(ok)`)  
   — OR move `UserApi`/`ok`/`Result`/`CompanySearch` imports into the modal component and change the prop type to something simpler. Since `UserApi.getJson` lives in `create_book_years.svelte` (it builds the promise on button click), keep `UserApi`, `ok`, `Result`, `CompanySearch` imports there.
4. Replace the `<DataModal>…</DataModal>` block with:
   ```svelte
   <CreateBookYearWithoutFileModal bind:value={withoutFileModal} />
   ```

---

## Key reused utilities

| Utility | Path |
|---|---|
| `Selectable` | `$components/selectable` |
| `AdaptiveLoader` | `$components/analysis/loader/adaptive_loader.svelte` |
| `DataModal`, `DataModalType` | `$components/modal` |
| `Button` | `$components/button` |
| `logError` | `$lib/log_error` |
| `Time`, `definedNotNull`, `isErr` | `@df/common` |
| `ValidCompanySearch`, `CompanySearch` | `$types/company.type` |
| `UserApi` | `$lib/services/api` |
| `ok`, `Result` (neverthrow) | `neverthrow` |

---

## Verification

1. `pnpm --filter audit check` and `pnpm --filter audit lint` — no type errors
2. In the UI: click "Skapa räkenskapsår utan fil" → modal opens, `AdaptiveLoader` shows progress bar while fetching
3. When loaded: if company found, see `select_book_year` with Selectable tiles and date range picker
4. Selecting a Selectable tile highlights it and enables the "Skapa räkenskapsår" button
5. Picking a date range also enables the button; selecting a tile afterwards switches the selection
6. Closing the modal resets `selectedBookYear` (button re-disabled on next open)
