# Plan: Move create_book_years components to recipes/

## Context

`create_book_years.svelte` and its private sub-components live inside a SvelteKit route directory, but they're a reusable recipe used from two places (`create_book_years_onboarding.svelte` and the firm book-years page). Moving them to `src/components/recipes/create_book_years/` makes the component discoverable and independent of the route tree.

---

## What moves, what stays

**Move** (all four go to the recipe folder):
- `create_book_years.svelte`
- `create_book_year_without_file_modal.svelte`
- `create_book_years_progress.svelte`
- `configuration.ts` — also used by `accounting_file_parse_error.svelte`, but only for `ErrorFile`; update that one import rather than leave the file behind

**Stay**:
- `accounting_file_parse_error.svelte` (user confirmed)

---

## Step-by-step

### 1. `git mv` the four files

```bash
mkdir audit/src/components/recipes/create_book_years

git mv \
  "audit/src/routes/(authed)/firm/onboarding/clients/[client_id]/[activity=onboarding_activity]/create_book_years.svelte" \
  audit/src/components/recipes/create_book_years/

git mv \
  "audit/src/routes/(authed)/firm/onboarding/clients/[client_id]/[activity=onboarding_activity]/create_book_year_without_file_modal.svelte" \
  audit/src/components/recipes/create_book_years/

git mv \
  "audit/src/routes/(authed)/firm/onboarding/clients/[client_id]/[activity=onboarding_activity]/create_book_years_progress.svelte" \
  audit/src/components/recipes/create_book_years/

git mv \
  "audit/src/routes/(authed)/firm/onboarding/clients/[client_id]/[activity=onboarding_activity]/configuration.ts" \
  audit/src/components/recipes/create_book_years/
```

### 2. Add barrel `index.ts`

Re-exports the default so consumers can use a default import:

```ts
// audit/src/components/recipes/create_book_years/index.ts
export { default } from './create_book_years.svelte';
```

### 3. Fix imports in the moved files

All `./configuration` imports are already relative and unchanged (same folder).  
All imports between the three moved `.svelte` files are already relative and unchanged.

Only one import needs updating — the path to `accounting_file_parse_error.svelte` which stayed behind:

| File | Import | New value |
|---|---|---|
| `create_book_years.svelte` | `./accounting_file_parse_error.svelte` | `../../../routes/(authed)/firm/onboarding/clients/[client_id]/[activity=onboarding_activity]/accounting_file_parse_error.svelte` |
| `create_book_years.svelte` | `../../../../employers/[employer_id]/(clients)/utils` | `../../../routes/(authed)/firm/employers/[employer_id]/(clients)/utils` |

### 4. Fix import in `accounting_file_parse_error.svelte`

```ts
// Before
import type { ErrorFile } from './configuration';
// After
import type { ErrorFile } from '$components/recipes/create_book_years/configuration';
```

### 5. Fix imports in the two consumers

Both switch to a default import via the barrel:

| File | Old import | New import |
|---|---|---|
| `create_book_years_onboarding.svelte` | `import CreateBookYears from './create_book_years.svelte'` | `import CreateBookYears from '$components/recipes/create_book_years'` |
| `firm/clients/[client_id]/(base)/book-years/+page.svelte` | `import CreateBookYears from '../../../../onboarding/...'` | `import CreateBookYears from '$components/recipes/create_book_years'` |

---

## Verification

1. `pnpm --filter audit check` — no type errors
2. `pnpm --filter audit lint` — no lint errors
3. Start dev server, open book-years page, click "Skapa räkenskapsår" → verify modal renders and file upload works
4. Open onboarding flow → verify create book years step still works
