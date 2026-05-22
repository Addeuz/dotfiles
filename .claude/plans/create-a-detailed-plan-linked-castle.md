# Plan: Generate Terms PDFs and Add Download Links

## Context

The terms pages under `audit/src/routes/(authed)/audit/terms/` contain static Swedish legal documents. Commit 8121c189 ("Revert terms") converted them from markdown-based to hardcoded HTML. The goal is to:

1. Use the current hardcoded-HTML state to generate PDFs (easiest to extract content from)
2. Revert commit 8121c189 (restoring markdown-based pages + breadcrumbs)
3. Add a PDF download link (`<a target="_blank">`) to each restored page

Five sub-pages need PDFs (the index `+page.svelte` is just a nav list, skip it):

| Route | PDF filename |
|---|---|
| `condition` | `condition-{8chars}.pdf` |
| `integrity-policy` | `integrity-policy-{8chars}.pdf` |
| `personal-data-processing` | `personal-data-processing-{8chars}.pdf` |
| `personal-data-service` | `personal-data-service-{8chars}.pdf` |
| `pre-approved-subprocessors` | `pre-approved-subprocessors-{8chars}.pdf` |

The 8-char suffix is generated once at script run time (random alphanumeric) and then hard-coded into each page's download link.

---

## Step 1 — Write a PDF generation script

**File:** `tools/generate_terms_pdfs.mjs`

### What it does

Since all five pages are behind the `(authed)` route group, we cannot point Puppeteer at the live dev server without logging in. Instead the script:

1. Reads each `+page.svelte` file and extracts the inner page content (everything inside `<div class="policy">` / `<ol>` / top-level container).
2. Builds a standalone HTML document that includes:
   - A `<meta charset="utf-8">` and A4 paper sizing via `@page { size: A4; margin: 2cm; }`
   - The ordered-list counter CSS from `+layout.svelte` (copy verbatim)
   - Any table styles needed for `pre-approved-subprocessors`
   - The extracted page content
3. Generates 8 random alphanumeric chars per page (use `crypto.randomBytes` → base36 slice).
4. Writes the PDF to `audit/static/{route}-{8chars}.pdf` using Puppeteer `page.pdf({ format: 'A4', printBackground: true })`.
5. Prints a mapping of route → filename to stdout so we can hard-code the links.

### Dependencies

`puppeteer` needs to be added as a dev dependency:
```
pnpm add -D puppeteer --filter audit
```
(or installed globally; it downloads Chromium on first run)

### Running
```bash
node tools/generate_terms_pdfs.mjs
```
Output example:
```
condition            → audit/static/condition-3f7a2b1c.pdf
integrity-policy     → audit/static/integrity-policy-8d4e9f2a.pdf
...
```

---

## Step 2 — Run the script and note the filenames

```bash
node tools/generate_terms_pdfs.mjs
```

Save the printed filename map — we will hard-code those names into the Svelte pages in Step 4.

---

## Step 3 — Revert commit 8121c189

```bash
git revert 8121c189 --no-edit
```

This restores:
- All five `.md` markdown files (`condition/condition.md`, etc.)
- The old +page.svelte files (markdown imports + minimal wrapper)
- The `breadcrumbs.svelte` component
- The responsive layout widths in `+layout.svelte`

---

## Step 4 — Add download links to each restored +page.svelte

After reverting, each `+page.svelte` will look something like:

```svelte
<script>
  import Content from './condition.md';
</script>

<Content />
```

Add an anchor tag **above** (or below) the `<Content />` render, inside its own `<div class="pdf-download">`:

```svelte
<script>
  import Content from './condition.md';
</script>

<div class="pdf-download">
  <a href="/condition-3f7a2b1c.pdf" target="_blank">Ladda ner som PDF</a>
</div>

<Content />
```

Repeat for all five pages using the filenames from Step 2.

The anchor is a plain `<a>` with `target="_blank"`. No JS needed — SvelteKit serves `audit/static/` files directly at `/`.

Minimal CSS to style the link as a button can go in the page's `<style>` block:

```css
<style>
  .pdf-download {
    margin-bottom: 1.5rem;
  }
  .pdf-download a {
    display: inline-block;
    padding: 0.5rem 1rem;
    background: var(--color-primary, #0052cc);
    color: #fff;
    border-radius: 4px;
    text-decoration: none;
    font-size: 0.875rem;
  }
</style>
```

---

## Critical files

| File | Action |
|---|---|
| `tools/generate_terms_pdfs.mjs` | **Create** — PDF generation script |
| `audit/static/condition-{8}.pdf` | **Create** (script output) |
| `audit/static/integrity-policy-{8}.pdf` | **Create** (script output) |
| `audit/static/personal-data-processing-{8}.pdf` | **Create** (script output) |
| `audit/static/personal-data-service-{8}.pdf` | **Create** (script output) |
| `audit/static/pre-approved-subprocessors-{8}.pdf` | **Create** (script output) |
| `audit/src/routes/(authed)/audit/terms/condition/+page.svelte` | **Edit** (add link) |
| `audit/src/routes/(authed)/audit/terms/integrity-policy/+page.svelte` | **Edit** (add link) |
| `audit/src/routes/(authed)/audit/terms/personal-data-processing/+page.svelte` | **Edit** (add link) |
| `audit/src/routes/(authed)/audit/terms/personal-data-service/+page.svelte` | **Edit** (add link) |
| `audit/src/routes/(authed)/audit/terms/pre-approved-subprocessors/+page.svelte` | **Edit** (add link) |

---

## Verification

1. `node tools/generate_terms_pdfs.mjs` — confirm 5 PDFs are created in `audit/static/`
2. Open each PDF to verify content and formatting look correct
3. `git revert 8121c189 --no-edit` — confirm pages revert to markdown-based
4. Run `pnpm --filter audit check` to confirm no type errors after edits
5. Start dev server (`pnpm --filter audit dev`) and navigate to each terms page — confirm download link appears
6. Click each link — confirm PDF opens in a new browser tab
