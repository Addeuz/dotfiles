# Plan: Convert CustomSettings.svelte to Callback-Based Props (caseSettings + bookYearSettings)

## Context
`CustomSettings.svelte` currently uses `$bindable()` on four props. The goal is to make `caseSettings` and `bookYearSettings` callback-based (pure, unidirectional) while leaving `auditorResignationFiles` and `resignationNoticeMissing` as `$bindable()`.

---

## Files to Modify

| File | Change |
|---|---|
| `audit/src/components/base_information/CustomSettings.svelte` | Replace `$bindable()` on caseSettings/bookYearSettings with callbacks; replace mutations with callback calls |
| `audit/src/components/base_information/CompanyOperation.svelte` | Replace `bind:caseSettings` and `bind:bookYearSettings` with prop + inline callbacks |

---

## 1. CustomSettings.svelte — Props interface

Remove `$bindable()` from `caseSettings` and `bookYearSettings`. Add two callback props. Leave `auditorResignationFiles` and `resignationNoticeMissing` as `$bindable()`.

**After:**
```ts
interface Props {
  caseSettings: CustomCaseSettings;
  bookYearSettings: BookYearSettings;
  companyType: CompanyType;
  fileStore: FileStore;
  auditorResignationFiles: File[];       // still $bindable
  resignationNoticeMissing: boolean;     // still $bindable
  onCaseSettingsUpdate: (updated: CustomCaseSettings) => void;
  onBookYearSettingsUpdate: (updated: BookYearSettings) => void;
}

let {
  caseSettings,
  bookYearSettings,
  companyType,
  auditorResignationFiles = $bindable(),
  resignationNoticeMissing = $bindable(),
  fileStore,
  onCaseSettingsUpdate,
  onBookYearSettingsUpdate,
}: Props = $props();
```

---

## 2. All `caseSettings` mutations → `onCaseSettingsUpdate` spread calls

Replace every `caseSettings.field = val` with a spread callback. Key patterns:

```ts
// Single-field update
onCaseSettingsUpdate({ ...caseSettings, auditingFramework: 'LCE' })

// Nested engagement replacement (existing on:update handler)
onCaseSettingsUpdate({ ...caseSettings, auditEngagement: { type: detail, date } })

// Nested field update (DatePicker on:change)
onCaseSettingsUpdate({
  ...caseSettings,
  auditEngagement: { ...caseSettings.auditEngagement, date: dateStr },
})

// Nested null-out (auditorResignationFileId in on:check)
onCaseSettingsUpdate({
  ...caseSettings,
  auditEngagement: { ...caseSettings.auditEngagement, auditorResignationFileId: null },
})
```

Applies to all 18 `caseSettings` mutation sites: `auditingFramework`, `isActiveOperation`, `reportIncludesBsAndPnlStatement`, `reportIncludesProfitDistributionStatement`, `reportIncludesResponsibilityStatement`, `reportIncludesComplianceStatement`, `auditEngagement` (type switch, date picker, resignation file id).

The `bind:selected={caseSettings.accountingService}` Select also becomes `selected={caseSettings.accountingService}` + `on:update={({ detail }) => onCaseSettingsUpdate({ ...caseSettings, accountingService: detail })}`.

---

## 3. All `bookYearSettings` mutations → `onBookYearSettingsUpdate` spread calls

Same pattern for all 14 `bookYearSettings` mutation sites: `regulation`, `aaIncludesCashflow`, `hasFirmAsAuditor`, compound updates.

```ts
// Single-field
onBookYearSettingsUpdate({ ...bookYearSettings, regulation: 'K2' })

// Compound (not-small branch sets two fields)
onBookYearSettingsUpdate({ ...bookYearSettings, aaIncludesCashflow: true, regulation: 'K3' })

// Nested vatRegulation field update (on:input)
onBookYearSettingsUpdate({
  ...bookYearSettings,
  vatRegulation: { ...bookYearSettings.vatRegulation, mixture: percent },
})
```

The two `bind:selected` Selects also become event-based:

**accountingSoftware:**
```svelte
selected={bookYearSettings.accountingSoftware}
on:update={({ detail }) =>
  onBookYearSettingsUpdate({ ...bookYearSettings, accountingSoftware: detail })}
```

**vatRegulation.type:**
```svelte
selected={bookYearSettings.vatRegulation.type}
on:update={({ detail }) =>
  onBookYearSettingsUpdate({
    ...bookYearSettings,
    vatRegulation: { ...bookYearSettings.vatRegulation, type: detail },
  })}
```

---

## 4. CompanyOperation.svelte — update the call site

Replace `bind:caseSettings` and `bind:bookYearSettings` with props + inline callbacks. The other two remain as `bind:`.

```svelte
<CustomSettings
  {caseSettings}
  {bookYearSettings}
  bind:auditorResignationFiles
  bind:resignationNoticeMissing
  onCaseSettingsUpdate={(updated) => (caseSettings = updated)}
  onBookYearSettingsUpdate={(updated) => (bookYearSettings = updated)}
  companyType={context.case.company.companyType}
  fileStore={context.files}
/>
```

---

## Verification

1. `pnpm --filter audit check` — no svelte-check type errors
2. `pnpm --filter audit lint` — no ESLint errors
3. Open the Base Information page for a case in the browser and exercise:
   - Toggling all Yes/No buttons
   - Changing accounting software, accounting service, VAT regulation type + mixture %
   - Switching audit engagement types (including resignation file / "Anmälan saknas" checkbox)
   - Picking a date in the date picker
   - Saving the form (confirms CompanyOperation's beforeNavigate diff still detects changes)
