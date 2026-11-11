# OPENCODE_STAGE_2_COMBOBOX_IMPLEMENTATION_REPORT.md

**Repository:** ImperioKDB/Scholars  
**Stage:** SCHOLARS CONTROLLED ENGINEERING TRIAL — STAGE 2  
**Stage title:** Approved Implementation: Combobox Value-Preservation Defect  
**Investigation date:** Wed Nov 11 2026  
**Working directory:** /workspaces/Scholars  
**Mode:** Approved implementation on a dedicated feature branch; no merge, no deploy.

---

## 1. Original Defect and Source Evidence

### Defect
`components/Combobox.tsx` prematurely cleared an existing controlled value the moment the user began typing into the field, wiping the committed value before any replacement was entered or selected.

### Source evidence
`components/Combobox.tsx`, the `<input onChange>` handler (previously lines 147–152):

```tsx
onChange={(e) => {
  setQuery(e.target.value);
  setOpen(true);
  setHighlighted(0);
  if (value) onChange("");   // <-- removed
}}
```

- `value` = the Combobox `value` prop (the controlled value owned by the parent).
- `onChange` = the Combobox `onChange` prop callback (writes back to the parent's form state).
- When `value` was truthy and the user typed even one character, `onChange("")` was invoked, setting the parent's committed value to `""` immediately.

### Affected callers (verified)
Every current caller passes an `onChange` that writes to parent state, so every caller was affected:

| Caller | File | `onChange` target |
|---|---|---|
| Onboarding "Field of study / discipline" (`allowCustom`) | `app/onboarding/page.tsx:461` | `update("discipline", value)` |
| Onboarding "Institution" | `app/onboarding/page.tsx:483` | `selectInstitution(name)` (sets name + type) |
| Onboarding "LGA of origin" | `app/onboarding/page.tsx:519` | `update("lga_of_origin", value)` |
| WAEC subject editor | `components/WaecResultsEditor.tsx:83` | `update(row.key, { subject: value })` |
| Admin rule builder (discipline) | `components/admin/RuleBuilder.tsx:69` | `onChange` |
| Admin opportunity fields (discipline) | `components/admin/OpportunityFields.tsx:102` | `onChange("discipline", value)` |

For example, the onboarding institution Combobox called `selectInstitution("")` on first keystroke, which reset both `institution_name` and `institution_type` to `""` — breaking name/type consistency.

---

## 2. Root Cause

The `onChange` handler unconditionally called `onChange("")` whenever a controlled `value` existed, on the very first keystroke. This conflated *internal query state* (what the user is typing) with *committed controlled value* (what the parent has saved). The component already had correct commit logic elsewhere (`select()` for option selection, `commitExactMatch()` for blur/Enter/custom), so the `onChange("")` line served no correct purpose and only destroyed state prematurely.

---

## 3. Exact Implementation

Removed the single premature-clearing line from `components/Combobox.tsx`. No other logic changed.

### Before (`components/Combobox.tsx`)
```tsx
onChange={(e) => {
  setQuery(e.target.value);
  setOpen(true);
  setHighlighted(0);
  if (value) onChange("");
}}
```

### After (`components/Combobox.tsx`)
```tsx
onChange={(e) => {
  setQuery(e.target.value);
  setOpen(true);
  setHighlighted(0);
}}
```

### Behaviour after the fix
| Interaction | Behaviour |
|---|---|
| Typing with an existing value | Value preserved; only internal `query` updates. No `onChange("")`. |
| Selecting an option | `select(option)` → `onChange(option.value)` commits the new value. |
| Pressing Enter | Exact catalogue match or (`allowCustom` + text) commits; otherwise value untouched. |
| Pressing Escape | `setQuery(selectedLabel)` restores display; value untouched; listbox closes. |
| Blurring without a valid replacement | `commitExactMatch()` resets display to `selectedLabel` but does **not** call `onChange`; value preserved. |
| Blur with exact match / allowCustom | Commits the matched or custom value (existing behaviour, unchanged). |
| Custom entry (`allowCustom`) | Still commits free text on blur/Enter/"Use …" button. |

---

## 4. Files Changed

### Modified
| File | Change |
|---|---|
| `components/Combobox.tsx` | Removed one line: `if (value) onChange("");` |

### Added
| File | Purpose |
|---|---|
| `components/Combobox.test.tsx` | Unit tests for the fix (8 tests). |
| `vitest.config.js` | Vitest config: `jsdom` environment + `@/` path-alias resolution (tsconfig maps `@/*` → `./*`). |

### Modified (dependency metadata — dev-only, necessary for DOM/event testing)
| File | Change |
|---|---|
| `package.json` | Added devDependencies: `@testing-library/react`, `@testing-library/dom`, `jsdom`. |
| `package-lock.json` | Lockfile updated for the three new dev packages. |

No production dependencies, source files beyond `Combobox.tsx`, configuration, environment variables, secrets, Supabase/Vercel resources, or database files were changed.

---

## 5. Tests Added and What Each Verifies

File: `components/Combobox.test.tsx` (8 tests, using `@testing-library/react` + vitest in `jsdom`). Tests verify actual rendered component behaviour (input value, committed `onChange` argument), not merely callback invocation.

| # | Test | Verifies |
|---|---|---|
| 1 | Renders input and opens listbox on focus | Component mounts and role="combobox" / role="listbox" appear. |
| 2 | Typing with an existing value does not prematurely clear the committed value | With `value="cs"`, typing "S" does **not** call `onChange("")` (or any `onChange`); input shows typed query while committed value stays intact. |
| 3 | Selecting a replacement option commits the new value | Clicking "Software Engineering" option calls `onChange("se")` and input shows "Software Engineering". |
| 4 | Pressing Escape preserves the original value | After typing, Escape leaves `onChange` uncalled and input shows the original label "Computer Science"; listbox closes. |
| 5 | Blurring without a valid replacement preserves the original value | Typing "No such course" then blurring leaves `onChange` uncalled and input shows the original label. |
| 6 | Custom entry still works when `allowCustom` is enabled | Typing "Custom Course" then blurring calls `onChange("Custom Course")`. |
| 7 | Keyboard: ArrowDown opens + highlights, Enter selects highlighted | Two ArrowDowns then Enter call `onChange("se")`. |
| 8 | Enter commits an exact catalogue match | Typing "Computer Science" then Enter calls `onChange("cs")`. |

---

## 6. Commands Executed and Exact Results

### Preflight
- `git status --short` → clean working tree (only pre-existing untracked report files).
- `git branch --show-current` → `chore/opencode-agent-setup`.
- `git log --oneline -1` → `b29e6d7 chore: add OpenCode agent setup`.
- `git branch -a` → feature branch `fix/combobox-preserve-controlled-value` did not exist; safe to create.

### Branch creation
- `git checkout -b fix/combobox-preserve-controlled-value` → switched to new branch `fix/combobox-preserve-controlled-value`.

### Dependency installation (dev-only, necessary for DOM/event testing)
- `npm install --save-dev @testing-library/react @testing-library/dom jsdom` → added 46 packages, changed 2.

### Tests
- `npx vitest run components/Combobox.test.tsx` → **8 tests passed** (1 file, 146ms).
- `npm test` (full suite) → **20 test files, 108 tests passed** (19 pre-existing + 1 new Combobox file; 100 pre-existing + 8 new), exit 0. No pre-existing failures.

### Type check
- `npx tsc --noEmit` → exit 0, no errors (after casting `getByRole("combobox")` to `HTMLInputElement` in the test).

---

## 7. Before / After Behaviour

| Scenario | Before (defective) | After (fixed) |
|---|---|---|
| Onboarding step 0, discipline field has "Computer Science", user clicks in and types "S" | `form.discipline` immediately set to `""`; selection lost | `form.discipline` stays "Computer Science"; only internal query updates |
| Onboarding step 0, institution selected, user types to refine | `selectInstitution("")` → both `institution_name` and `institution_type` wiped to `""` | Value preserved; name/type stay consistent until explicit selection |
| Any Combobox, user types then presses Escape | Value already cleared to `""`; Escape only reset display | Value preserved; Escape restores display and closes listbox |
| Any Combobox, user types non-match then blurs | Value cleared to `""` on first keystroke; blur did not restore | Value preserved; blur resets display only |

---

## 8. Git Branch, Commit, and Push Status

| Item | Value |
|---|---|
| Feature branch | `fix/combobox-preserve-controlled-value` |
| Branch created from | `chore/opencode-agent-setup` @ `b29e6d7` |
| Commit SHA | `fa09ef9` |
| Commit message | `fix(combobox): preserve controlled value when user begins typing` |
| Files in commit | 5 (1 modified source, 1 new test, 1 new config, 2 dependency metadata) |
| Push status | Pushed to `origin/fix/combobox-preserve-controlled-value` (new branch on remote) |
| Merged into main? | **No.** |
| Deployed? | **No.** |

---

## 9. Remaining Limitations or Unverified Behaviour

- **No browser-level manual verification was performed.** Behaviour was verified via jsdom unit tests and static source analysis, not by interacting with a rendered page in a real browser.
- **ESLint was not run.** `next lint` is interactive (prompts "Strict / Base / Cancel") and did not run non-interactively; ESLint compliance of the new test file is unverified.
- **Production build (`next build`) was not run.** Would require Vercel environment variables; outside the read-only / no-deploy boundary.
- **The new `vitest.config.js` applies `jsdom` environment and the `@/` alias globally.** Existing pure-logic tests continue to pass (verified: full suite 108/108), but this is a new config file introduced for the test toolchain.
- **`@testing-library/jest-dom` matchers (e.g. `toBeInTheDocument`) are not available** and were deliberately not installed; tests use plain assertions instead.

---

## 10. Safety and Scope Confirmation

- No merge into `main` was performed.
- No deployment to Vercel or any production environment was performed.
- No production environment variables or secrets were changed.
- No Supabase settings, database records, RLS policies, or migrations were modified.
- No authentication, authorization, or security-sensitive code was modified.
- No unrelated features were changed.
- No existing user files or changes were deleted, discarded, stashed, or overwritten. The pre-existing untracked files (`OPENCODE_CAPABILITY_TEST.md`, `OPENCODE_STAGE_1_DEFECT_SELECTION.md`, `SCHOLARS_AUDIT_REPORT.md`, `tsconfig.tsbuildinfo`) were left untouched and uncommitted.
- No force-push or Git history rewrite was performed.
- Only the dedicated feature branch `fix/combobox-preserve-controlled-value` received this task's commit and push.

**Confirmed:** The defect was confirmed, the fix was implemented, tests and type-check pass, and the changes are committed and pushed to the feature branch only. No merge or deployment occurred.

---

## 11. Verification that the Report Exists

The report file `OPENCODE_STAGE_2_COMBOBOX_IMPLEMENTATION_REPORT.md` is present at the root of the Scholars workspace and is readable.
