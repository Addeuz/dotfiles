# Plan: Trim unused design tokens from marketing-dark.css and app.css

## Context

`marketing-dark.css` was written as a generic shared semantic vocabulary (mirroring `app-light.css`), so it carries many tokens that `audit_landing` never actually uses — state colours (danger, warning, success, info), hover/disabled/link variants, and several typography helpers. The `@theme inline` shim in `app.css` forwards some of those unused tokens into Tailwind as dead utilities. The goal is to make both files contain only what the landing app actually consumes.

---

## Audit results

### Variables confirmed NOT used anywhere in audit_landing

**In `marketing-dark.css`** (no `var()` reference in any `.svelte`/`.ts`/`.css` file, and no Tailwind utility stem that resolves to them):

| Variable | Reason |
|---|---|
| `--color-brand-10` | No `bg-brand-10` / `text-brand-10` anywhere |
| `--color-brand-light` | No `bg-brand-light` anywhere |
| `--color-primary-hover` | Never forward-referenced; `--color-surface-selected` (the only consumer) is also removed |
| `--color-primary-disabled` | Not referenced anywhere |
| `--color-danger` | Not referenced anywhere |
| `--color-danger-hover` | Not referenced anywhere |
| `--color-warning` | Not referenced anywhere |
| `--color-success` | Not referenced anywhere |
| `--color-info` | Not referenced anywhere |
| `--color-surface-sunken` | Not in @theme shim, not used via var() |
| `--color-surface-hover` | Not in @theme shim, not used via var() |
| `--color-surface-selected` | Not in @theme shim, not used via var() |
| `--color-text-disabled` | Not in @theme shim, not used via var() |
| `--color-text-on-primary` | Not in @theme shim, not used via var() |
| `--color-text-link` | Not in @theme shim, not used via var() |
| `--color-accent-hover` | No `hover:bg-accent-hover` etc. anywhere |
| `--color-accent-10` | No `bg-accent-10` anywhere |
| `--color-accent-25` | No `bg-accent-25` anywhere |
| `--color-platform-hover` | No `hover:bg-platform-hover` anywhere |
| `--heading-font-family` | Not referenced anywhere |
| `--action-font-family` | Not referenced anywhere |
| `--table-font-family` | Not referenced anywhere |
| `--fluid-scale` | Not referenced anywhere |
| `--letter-spacing-base` | Not referenced anywhere |
| `--letter-spacing-multiplier` | Not referenced anywhere |

**In app.css `@theme inline`** (forwarded tokens with no Tailwind utility usage in markup):

| Entry | Reason |
|---|---|
| `--color-brand-light` | No `bg-brand-light` / `text-brand-light` |
| `--color-brand-10` | No `bg-brand-10` |
| `--color-accent-hover` | No `hover:bg-accent-hover` etc. |
| `--color-accent-10` | No `bg-accent-10` |
| `--color-accent-25` | No `bg-accent-25` |
| `--color-platform-hover` | No `hover:bg-platform-hover` |

### Tokens that ARE used (keep)

**Direct `var()` usage in non-app.css source:**
- `--color-brand` → `small_diffinder_icon.svelte`, `main_header.svelte`
- `--color-bg`, `--color-default` → `main_header.svelte`

**Via app.css `@layer base/components`:**
- `--color-brand`, `--color-brand-hover`, `--color-bg`, `--color-surface`, `--color-accent`, `--color-platform`, `--color-default`

**Via Tailwind utility stems used in markup:**
- brand, brand-hover, brand-active, brand-subtle, brand-bg, brand-25
- accent, accent-subtle, accent-bg
- platform, platform-subtle
- surface, surface-raised, bg, nav-bg
- default, muted, subtle
- border, border-strong

**Dependency chain for `brand-active`:**
`--color-brand-active` (shim) → `--color-primary-active` → `--color-primary` (all in marketing-dark.css, all kept)

---

## Changes

### 1. `libraries/typescript/ui/src/lib/tokens/themes/marketing-dark.css`

Delete the entire "Shared semantic vocabulary" section and replace with only the variables that are actually needed. Final file:

```css
/* Semantic tokens for the audit_landing/ dark theme.
   See docs/adr/0004-design-tokens.md. */

:root {
  /* === Shared semantic vocabulary === */

  --color-brand: var(--teal-500);
  --color-brand-hover: oklch(from var(--color-brand) calc(l - 0.06) c h);
  --color-brand-bg: oklch(from var(--teal-500) l c h / 0.07);
  --color-brand-subtle: oklch(from var(--teal-500) l c h / 0.12);
  --color-brand-25: oklch(from var(--teal-500) l c h / 0.25);

  /* --color-primary backs --color-primary-active which the @theme shim
     exposes as the brand-active Tailwind utility. */
  --color-primary: var(--teal-500);
  --color-primary-active: oklch(from var(--color-primary) calc(l - 0.08) c h);

  --color-surface: oklch(0.27 0.005 175); /* #272e2c — dark teal-tinted */
  --color-surface-raised: oklch(0.3 0.005 175); /* #2e3634 */

  --color-border: oklch(from #f5f2ee l c h / 0.08);
  --color-border-strong: oklch(from #f5f2ee l c h / 0.16);

  --color-text: #f5f2ee;
  --color-text-muted: oklch(from #f5f2ee l c h / 0.65);
  --color-text-subtle: oklch(from #f5f2ee l c h / 0.25);

  /* === Theme-local roles === */

  --color-accent: oklch(0.61 0.1 30); /* #c6665c — terracotta */
  --color-accent-bg: oklch(from var(--color-accent) l c h / 0.07);
  --color-accent-subtle: oklch(from var(--color-accent) l c h / 0.12);

  --color-platform: oklch(0.82 0.06 60); /* #e1c4a9 — sand */
  --color-platform-subtle: oklch(from var(--color-platform) l c h / 0.12);

  --color-bg: oklch(0.23 0.005 175); /* #1e2221 — page background */
  --color-nav-bg: oklch(from var(--color-bg) l c h / 0.92);

  /* === Typography === */
  --primary-font-family: 'DM Sans', sans-serif;
}
```

### 2. `audit_landing/src/lib/styles/app.css` — `@theme inline` block

Remove 6 entries from the `@theme inline` block:

```diff
   /* Brand */
   --color-brand: var(--color-brand);
   --color-brand-hover: var(--color-brand-hover);
   --color-brand-active: var(--color-primary-active);
   --color-brand-bg: var(--color-brand-bg);
   --color-brand-subtle: var(--color-brand-subtle);
-  --color-brand-light: var(--color-brand-light);
-  --color-brand-10: var(--color-brand-10);
   --color-brand-25: var(--color-brand-25);

   /* Accent */
   --color-accent: var(--color-accent);
-  --color-accent-hover: var(--color-accent-hover);
   --color-accent-bg: var(--color-accent-bg);
   --color-accent-subtle: var(--color-accent-subtle);
-  --color-accent-10: var(--color-accent-10);
-  --color-accent-25: var(--color-accent-25);

   /* Platform */
   --color-platform: var(--color-platform);
-  --color-platform-hover: var(--color-platform-hover);
   --color-platform-subtle: var(--color-platform-subtle);
```

---

## Files to modify

1. `libraries/typescript/ui/src/lib/tokens/themes/marketing-dark.css`
2. `audit_landing/src/lib/styles/app.css`

## Verification

```bash
# Stylelint (semantic-token rule catches orphaned literals)
cd audit_landing && pnpm lint

# Type-check + Svelte component validation
pnpm check

# Build — ensures no Tailwind utility references a now-missing theme key
pnpm build
```
