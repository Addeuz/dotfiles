# Plan: Implement `get_employers` via `client_roles`

## Context

`employers.rs` has a stubbed-out `get_employers(account_id)` that returns an empty body. The goal is to implement it by:

1. Creating a new SQL stored procedure `get_employers` that finds all employers an account has access to — via the `client_roles` table (explicit access) and `case_staff` (implicit access), mirroring the structure of `get_client_roles.sql`.
2. Filling in the Rust body in `employers.rs` to call that procedure and return `Vec<EmployerInfo>`.
3. Adding `df_accounting` as a dependency (needed for `CorporateId` in the `DbResponse`).

## Files to modify

| File | Change |
|---|---|
| `libraries/audit/sql/stored_procedures/20221216_get_employers.sql` | **Create** new stored procedure |
| `libraries/firm/employer/src/repository/employers.rs` | Fill in the stub body |
| `libraries/firm/employer/Cargo.toml` | Add `df_accounting = { workspace = true }` |

## SQL Stored Procedure

**File:** `libraries/audit/sql/stored_procedures/20221216_get_employers.sql`

Mirrors the structure of `20220941_get_client_roles.sql` — two CTEs (explicit via `client_roles`, implicit via `case_staff`) joined with FULL OUTER JOIN, then enriched with employer info from `company_custom_info`.

```sql
DROP FUNCTION IF EXISTS get_employers;
CREATE FUNCTION get_employers(
    account_uuid UUID
)
RETURNS TABLE (
    employer_id UUID,
    corporate_id BIGINT,
    employer_name VARCHAR(100)
)
AS
$$
DECLARE
    _account_id INTEGER;
    _sql_state TEXT;
    _message TEXT;
    _detail TEXT;
    _hint TEXT;
    _context TEXT;
BEGIN
    SELECT id INTO STRICT _account_id FROM account WHERE uuid = account_uuid;

    RETURN QUERY
    WITH explicit_employers AS (
        SELECT DISTINCT e.uuid AS employer_id
        FROM client_roles cr
        INNER JOIN client c ON cr.client_id = c.id
        INNER JOIN employer e ON c.employer_id = e.id
        WHERE cr.account_id = _account_id
    ),
    case_employers AS (
        SELECT DISTINCT e.uuid AS employer_id
        FROM case_staff cs
        INNER JOIN case_info ci ON cs.case_id = ci.id
        INNER JOIN client c ON ci.client_id = c.id
        INNER JOIN employer e ON c.employer_id = e.id
        WHERE cs.account_id = _account_id
    )
    SELECT
        COALESCE(ee.employer_id, ce.employer_id) AS employer_id,
        cci.corporate_id,
        cci.company_name AS employer_name
    FROM explicit_employers ee
    FULL OUTER JOIN case_employers ce ON ee.employer_id = ce.employer_id
    INNER JOIN employer e ON e.uuid = COALESCE(ee.employer_id, ce.employer_id)
    INNER JOIN company_custom_info cci ON cci.corporate_id = e.corporate_id;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE NOTICE 'account_uuid = % does not exists in account', account_uuid;
            INSERT INTO exception_log (sql_state, message, detail, hint, context)
            VALUES ('P0002', CONCAT('account_uuid = ', account_uuid, ' does not exists in account'), '', '', 'PL/pgSQL function get_employers(UUID)');
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sql_state := RETURNED_SQLSTATE,
                _message := MESSAGE_TEXT,
                _detail := PG_EXCEPTION_DETAIL,
                _hint := PG_EXCEPTION_HINT,
                _context := PG_EXCEPTION_CONTEXT;
            INSERT INTO exception_log (sql_state, message, detail, hint, context)
            VALUES (_sql_state, _message, _detail, _hint, _context);
            RAISE NOTICE '%', CONCAT(_message, ', ', _detail);
END;
$$ LANGUAGE plpgsql;
```

## Rust Implementation

**File:** `libraries/firm/employer/src/repository/employers.rs`

Pattern comes directly from `get_account_employer_info` in `libraries/firm/client/src/sql/employees.rs:90-118`.

```rust
use df_accounting::CorporateId;
use common::models::EmployerInfo;
use df_id::{AccountId, EmployerId};
use super::{Repository, Result};

impl Repository {
    #[tracing::instrument(err(Debug), skip(self))]
    pub(crate) async fn get_employers(&self, account_id: AccountId) -> Result<Vec<EmployerInfo>> {
        #[derive(sqlx::FromRow)]
        struct DbResponse {
            employer_id: EmployerId,
            corporate_id: CorporateId,
            employer_name: String,
        }
        // Signature: get_employers(
        //   account_uuid UUID
        // )
        Ok(
            sqlx::query_as::<_, DbResponse>("SELECT * FROM get_employers($1)")
                .bind(account_id)
                .fetch_all(&self.pool)
                .await?
                .into_iter()
                .map(|DbResponse { employer_id, corporate_id, employer_name }| {
                    EmployerInfo::new(employer_id, corporate_id, employer_name)
                })
                .collect(),
        )
    }
}
```

## Cargo.toml change

Add to `[dependencies]` in `libraries/firm/employer/Cargo.toml`:
```toml
df_accounting = { workspace = true }
```

## Verification

```bash
cargo clippy -p employer
cargo fmt -p employer
```
