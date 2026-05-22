# Add `BookYear` Onboarding Step

## Context

A new `BookYear` step needs to be added as the third onboarding activity, after `NaturalPersons`. The enum and type plumbing need wiring; the step's UI content component will be filled in separately.

Assumed order: `BaseInformation` → `NaturalPersons` → `BookYear` → exit to company-information.

## Changes

### 1. Rust enum — `libraries/audit/common/src/models.rs:118`

```rust
pub enum OnboardingActivity {
    BaseInformation,
    NaturalPersons,
    BookYear,
}
```

`EnumSet::all()` in `init_client.rs` picks up the new variant automatically for new clients. No SQL migration needed — column is already `SMALLINT` and the new variant uses bit 2 (value 4), which doesn't collide with existing stored values.

### 2. TypeScript union — `audit/src/types/clients.type.ts:58`

```typescript
const onboardingActivities = ['BaseInformation', 'NaturalPersons', 'BookYear'] as const;
```

`onboardingActivityDecoder`, `isOnboardingActivity`, and the route param matcher (`audit/src/params/onboarding_activity.ts`) all derive from this array and update automatically.

### 3. Step type — `audit/src/routes/(authed)/firm/onboarding/clients/[client_id]/[activity=onboarding_activity]/types.ts`

Add a `BookYearStep` type and include it in the union:

```typescript
type BookYearStep = {
  type: 'BookYear';
};

type OnboardingStep = BaseInformationStep | NaturalPersonsStep | BookYearStep;
```

(No `data` field for now — the content component will add it later.)

### 4. Page load — `+page.ts`

Add a `BookYear` branch to the `if`/`else` chain so the step is recognised:

```typescript
if (activity === 'BaseInformation') {
  ...
} else if (activity === 'NaturalPersons') {
  ...
} else {
  currentStep = { type: 'BookYear' };
}
```

### 5. Finalization navigation — `+page.svelte`

Update the `switch` so `NaturalPersons` routes to `BookYear` and `BookYear` exits onboarding:

```typescript
case 'NaturalPersons': {
  goto(`/firm/onboarding/clients/${clientId}/BookYear`);
  break;
}
case 'BookYear': {
  goto(`/firm/clients/${clientId}/company-information`);
  break;
}
```

### 6. Progress indicator — `onboarding.svelte`

- Add a third `{ label: 'Räkenskapsår', ... }` entry to each `getXxxSteps()` helper and to `getLoadingSteps()`.
- Add an `{:else if currentStep.type === 'BookYear'}` block (structure only, content to be filled in).

## Verification

- `cargo clippy -p df_audit_common` — no errors
- `pnpm --filter audit check` — no type errors
- Existing in-flight clients are unaffected (stored bitset won't have bit 2 set)
- New clients get all three activities via `EnumSet::all()`
