# Self-Review: book-year-onboarding vs prepare-book-year-onboarding

## Must Fix

### 1. Silent failure on `upload_accounting_file` POST — `upload_new_file.svelte` L141–145

```typescript
await FirmApi.postJson(
  'firm/clients/:clientId/upload_accounting_file',
  { bookYear: bookYear.year.json(), gcsLink: url.toString(), fileId, accountingType },
  { clientId: clientId.toString() },
);

notifications.success('Filen har laddats upp och kommer nu bearbetas');
onAfterUpload(bookYear.year);
```

The upload call is not error-checked. If it throws or the server returns an error, the success notification still fires and `onAfterUpload` is still called. The old endpoint had error handling; the refactor dropped it. Needs a try/catch or the same `.isErr()` pattern used for `createBookYear` just above it.

---

### 2. Svelte 4 event syntax in `select_book_year.svelte` L80

```svelte
on:change={({ detail }) => {
```

This is a Svelte 4 event directive on a Carbon `DatePicker`. All new code must use Svelte 5 style (`onchange={...}`). How to migrate depends on what `DatePicker` exposes — check whether it has an `onchange` prop or if the component itself needs updating.

---

## Should Fix

### 3. `reason.years[0]` / `reason.years[1]` — `create_book_years.svelte` L142, L148

```typescript
description: `${reason.years[0].displayFull()} och ${reason.years[1].displayFull()} delar räkenskapsperiod`,
```

`reason.years` is typed as `[Time.BookYear, Time.BookYear]` (a tuple), so both accesses are safe at the TypeScript level. But project convention is `.at()` for all index access. Should be:

```typescript
reason.years.at(0)?.displayFull() ?? ''
```

Applies to both L142 and L148.

---

### 4. Cross-route import in a shared component — `upload_new_file.svelte` L21

```typescript
import { createBookYear } from '../../routes/(authed)/firm/employers/[employer_id]/(clients)/utils';
```

`upload_new_file.svelte` is a shared component under `src/components/`. It should not import from a route-specific `utils.ts`. `createBookYear` should be moved to a shared location (e.g. `$lib/services/`) so the dependency direction is correct.

---

### 5. Hardcoded hex color in `dropzone.svelte` L60

```css
outline: 3px dashed #288375;
```

Should use a CSS custom property token (e.g. `var(--cds-interactive-01)` or the appropriate design token) instead of a raw hex value.

---

## Minor

### 6. `BookYearLedgerStatus` missing serde attributes — `libraries/audit/common/src/models.rs` L99–107

```rust
#[derive(Debug, Serialize)]
pub enum BookYearLedgerStatus {
    HasLedger,
    NoLedger,
}
```

No `#[serde(...)]` annotation. For unit variants Rust serializes them as plain strings (`"HasLedger"`, `"NoLedger"`), which matches the frontend `union('HasLedger', 'NoLedger')` decoder — so it works. But the pattern in this file for other enums is to be explicit. Low priority.

---

## Verified Non-Issues (review agent was wrong)

- **`createBookYear` in `upload_new_file.svelte`**: Error IS handled — `.isErr()` checked at L106, both `OverlappingBookYears` and generic errors produce notifications and `return`.
- **`reason.years[0]`/`[1]`**: Type is `[Time.BookYear, Time.BookYear]` tuple — TypeScript guarantees both exist. Convention issue only, not a bug.
