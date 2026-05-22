# Plan: Rename AddLedgerOutcome → CreateBookYearOutcome, move overlap logic into create_book_year

## Context

`AddLedgerOutcome` was originally the return type of `add_external_ledger()`, but since book year creation is now a separate dedicated endpoint, the overlap check belongs in `create_book_year()`. The type should be renamed to reflect its actual meaning. Concurrently, `SubRecordOutcome::OverlappingBookYears` becomes dead code once the overlap check moves, so `SubRecordOutcome` can be removed entirely — `add_sub_record` reduces to returning a `RecordId`.

A merge conflict residue (commented-out markers in `external.rs` lines 108–135) is also cleaned up as part of this work.

---

## Files to change

### 1. `libraries/audit/ledger/src/models/add_ledger_outcome.rs` → `create_book_year_outcome.rs`

Rename the file. Rename the enum and update its doc comment:

```rust
/// Outcome of attempting to create a book year for a client.
#[derive(Debug, Serialize)]
#[serde(tag = "type")]
pub enum CreateBookYearOutcome {
    Accepted,
    OverlappingBookYears {
        uploaded: BookYear,
        overlapping: Vec<BookYear>,
    },
}
```

Both fields are `BookYear`. Need to add `use df_common_business::BookYear;` to the file.

### 2. `libraries/audit/ledger/src/models/mod.rs`

- `mod add_ledger_outcome;` → `mod create_book_year_outcome;`
- `pub use self::add_ledger_outcome::AddLedgerOutcome;` → `pub use self::create_book_year_outcome::CreateBookYearOutcome;`

### 3. `libraries/audit/ledger/src/lib.rs`

Update the crate-level re-export: `AddLedgerOutcome` → `CreateBookYearOutcome`.

### 4. `libraries/audit/ledger/src/service/book_year.rs` — main change

Change `create_book_year`:
- Keep `account_mapping_year_reuse: Option<BookYear>` parameter — caller (controller) still computes the adjacent year and passes it
- Change return type: `Result<(), ServiceError>` → `Result<CreateBookYearOutcome, ServiceError>`
- Import `CreateBookYearOutcome` from `crate::models`

Add overlap check at the top of the function body (before any DB work):
```rust
let available_book_years = self.get_diffinder_book_years(client_id).await?;
let overlapping: Vec<BookYear> = available_book_years
    .iter()
    .filter(|existing| existing.is_overlapping(&book_year))
    .copied()
    .collect();
if !overlapping.is_empty() {
    return Ok(CreateBookYearOutcome::OverlappingBookYears {
        uploaded: book_year,
        overlapping,
    });
}
```

Replace `Ok(())` at the end with `Ok(CreateBookYearOutcome::Accepted)`.

### 5. `libraries/audit/ledger/src/service/external.rs`

**Remove `SubRecordOutcome`** (lines 41–47) — no longer needed.

**Simplify `add_sub_record`**:
- Return type: `Result<SubRecordOutcome>` → `Result<RecordId>` (just returns `id`)
- Remove the `available_book_years` fetch and the `SubRecordOutcome::OverlappingBookYears` branch (book year is now guaranteed to exist before upload)
- Remove the entire commented-out merge conflict block (lines 108–135)
- Return `Ok(id)` at the end

**Simplify `add_external_ledger`**:
- Return type: `Result<AddLedgerOutcome>` → `Result<(), ServiceError>`
- Remove the `match outcome { ... }` block; replace with a direct call using the returned `RecordId`
- Remove `AddLedgerOutcome` import

### 6. `services/audit/src/controller/sie.rs`

**`create_book_year` handler**:
- Controller keeps its `get_diffinder_book_years` call and `adjacent_book_year` computation (used to pass `account_mapping_year_reuse` to the service)
- Capture the returned `CreateBookYearOutcome` and respond with it: `HttpSuccess::respond(VersionlessData(outcome))`
- Import `CreateBookYearOutcome` instead of `AddLedgerOutcome`

**`upload_accounting_file` handler**:
- `add_external_ledger` now returns `Result<()>` — drop the `outcome` binding

---

## Callers of `create_book_year` outside the controller

`services/audit/src/controller/firm/clients.rs` line 197 also calls `create_book_year`. It currently ignores the return value (`?` propagates errors). With the new `CreateBookYearOutcome` return, use `let _ = service.create_book_year(...).await?;` or just `service.create_book_year(...).await?;` — the outcome is intentionally discarded in the case creation flow.

---

### 7. `audit/src/types/accounting.type.ts`

Add `CreateBookYearOutcome` type and decoder. Both fields use `bookYearDecoder` (Rust `BookYear` serializes as `{startDate, endDate}` struct, not as a string):

```typescript
export type CreateBookYearOutcome = decodeType<typeof createBookYearOutcomeDecoder>;
export const createBookYearOutcomeDecoder = union(
  { type: literal('Accepted') },
  {
    type: literal('OverlappingBookYears'),
    uploaded: bookYearDecoder,
    overlapping: array(bookYearDecoder),
  },
);

export type CreateBookYearOverlappingError = Extract<
  CreateBookYearOutcome,
  { type: 'OverlappingBookYears' }
>;
```

### 8. `audit/src/lib/services/api/firm/interfaces.ts`

Two changes:
- `upload_accounting_file`: `response: UploadAccountingResult` → `response: null` (decoder is already `nil`; the interface was wrong)
- `book_years`: `response: null` → `response: CreateBookYearOutcome`

Remove `UploadAccountingResult` import if it becomes unused.
Add import for `CreateBookYearOutcome` from `$types/accounting.type`.

### 9. `audit/src/lib/services/api/firm/decoders.ts`

- `book_years`: `uploadAccountingResultDecoder` → `createBookYearOutcomeDecoder`

Remove `uploadAccountingResultDecoder` import if unused.
Add import for `createBookYearOutcomeDecoder` from `$types/accounting.type`.

### 10. `audit/src/routes/(authed)/firm/employers/[employer_id]/(clients)/utils.ts`

Update `createBookYear` to use the typed response from `FirmApi` and propagate `OverlappingBookYears`:

```typescript
async function createBookYear(
  clientId: ClientId,
  bookYear: Time.BookYear,
): Promise<Result<Time.BookYear, FetchError | CreateBookYearOverlappingError>> {
  let outcome: CreateBookYearOutcome;
  try {
    outcome = await FirmApi.postJson(
      'firm/clients/:clientId/book_years',
      { bookYear: bookYear.json() },
      { clientId: clientId.stringId() },
    );
  } catch (e) {
    return err({ type: 'CommonError', message: JSON.stringify(e) } satisfies FetchError);
  }
  if (outcome.type === 'OverlappingBookYears') {
    return err(outcome);
  }
  return ok(bookYear);
}
```

Update import: `OverlappingBookYearsError` → `CreateBookYearOverlappingError` (or keep the old name as a type alias if it's used elsewhere).

---

## Verification

```bash
cargo clippy -p ledger
cargo fmt -p ledger
cargo clippy -p audit    # service crate
cargo fmt -p audit

pnpm --filter audit check
pnpm --filter audit lint
```
