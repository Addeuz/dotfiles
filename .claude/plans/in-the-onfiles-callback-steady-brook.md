# Plan: Redesign Dropzone children snippet

## Context

The current Dropzone children snippet is placeholder text with raw `<button>` elements. It needs a proper UI: icon, heading, description, and two styled buttons.

## File to modify

`audit/src/routes/(authed)/firm/onboarding/clients/[client_id]/[activity=onboarding_activity]/create_book_years.svelte`

---

## Changes

### 1. Instance script — add `Upload` icon import

```ts
import Upload from 'carbon-icons-svelte/lib/Upload.svelte';
```

### 2. Replace `{#snippet children}` content

Remove the placeholder buttons (including the `clear` button). The `onConfirmWithoutCreate` prop callback is already available in scope:

```svelte
{#snippet children({ clickHiddenInput })}
  <div class="dropzone-content">
    <Upload size={32} />
    <h2 class="header-s">Skapa räkenskapsår</h2>
    <p class="description body-s">
      För att använda Diffinder behöver det finnas räkenskapsår. Släpp eller välj bokföringsfiler
      för att starta skapandet.
    </p>
    <div class="dropzone-actions">
      <Button.Default onClick={clickHiddenInput}>Välj bokföringsfiler</Button.Default>
      <Button.Default variant="tertiary" onClick={async () => {}}>
        Skapa räkenskapsår utan fil
      </Button.Default>
    </div>
  </div>
{/snippet}
```

### 3. Add CSS

Inside the existing `<style>` block, add at the top level (alongside `.container`, `.buttons`):

```css
.dropzone-content {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: var(--space-s);
  text-align: center;

  & .description {
    color: var(--cds-text-02);
  }

  & .dropzone-actions {
    display: flex;
    gap: var(--space-s);
    flex-wrap: wrap;
    justify-content: center;
  }
}
```

Also remove the existing `Button.Async` "Gå vidare utan att skapa räkenskapsår" from the `<div class="buttons">` since that action is now surfaced inside the dropzone. **Wait — keep it**: that button is for when parsedFiles already exist and the user wants to skip. The dropzone button is for the empty state. Both are needed.

---

## Verification

1. `pnpm --filter audit check` — TypeScript compiles cleanly
