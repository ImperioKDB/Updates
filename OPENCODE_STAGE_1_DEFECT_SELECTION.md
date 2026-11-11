# OPENCODE_STAGE_1_DEFECT_SELECTION.md

**Repository:** ImperioKDB/Scholars  
**Stage:** SCHOLARS CONTROLLED ENGINEERING TRIAL — STAGE 1  
**Stage title:** Defect Discovery and Fix Selection  
**Investigation date:** Wed Nov 11 2026  
**Working directory:** /workspaces/Scholars  
**Mode:** Investigation and planning only — no source code modified, no tests added, no commits, no deploys.

---

## Executive Summary

This report documents the first controlled implementation trial on the Scholars codebase. The objective was to identify one genuine, reproducible, low-risk frontend/form defect, confirm it in the current source code, select it over alternatives, and propose a minimal fix — without modifying anything.

**Selected defect:** The `Combobox` component (`components/Combobox.tsx`) prematurely clears its controlled `value` to `""` on the very first keystroke whenever a value is already present, causing the field's committed value to be wiped before the user has entered a replacement. This is a form-behavior / UI state inconsistency defect that affects the onboarding discipline and institution fields (both use `Combobox`).

**Why this defect:** It is clearly reproducible from the source, confirmed in the current code, isolated to a single one-line expression in one file, has low regression risk, can be verified with a new unit test plus manual reproduction, and provides genuine user value (fields no longer lose their value when a user clicks in to edit).

**Execution boundary respected:** No source code was modified, no dependencies installed, no database mutations, no env/secret changes, no Supabase/Vercel changes, no deploy, no commit/push.

---

## Investigation Scope and Method

### In scope (per trial charter)
- Frontend interaction defects
- Onboarding usability and validation
- Form behavior and error handling
- Responsive layout issues
- Accessibility defects
- UI state inconsistencies
- Isolated defects with clear reproduction steps

### Out of scope (avoided)
- Authentication / authorization flows (login, signup, OTP, admin MFA, `lib/auth/*`, `/auth/*`)
- Supabase RLS, database migrations, `supabase/migrations/*`, `supabase/tests/*`
- Payment logic
- Production configuration, secrets, environment variables
- Security-sensitive code (`lib/supabase/service.ts`, `middleware.ts` admin/auth logic)

### Files inspected
- `components/Combobox.tsx` (primary candidate)
- `components/FormField.tsx`
- `components/PasswordField.tsx`
- `components/WaecResultsEditor.tsx`
- `components/MilestoneOnboarding.tsx`
- `app/onboarding/page.tsx` (uses Combobox for discipline + institution)
- `app/settings/page.tsx`
- `app/discover/DiscoverClient.tsx`
- `lib/validate.ts`
- `lib/profile.ts`
- `lib/onboarding-prompts.ts` + `lib/onboarding-prompts.test.ts`

### Test baseline confirmed
`npm test` (`vitest run`): **19 test files, 100 tests, all passed, exit 0** (~7.4s). No existing test covers `Combobox` (grep for `Combobox` across `*.test.ts` returned no matches).

---

## Candidate Defects Documented

Below is the full candidate inventory. Each entry documents what happens, what should happen, reproduction steps, source evidence, existing test coverage, risk, and verifiability.

---

### Candidate 1 — SELECTED: Combobox clears controlled value on first keystroke

**File / function:** `components/Combobox.tsx`, the `<input onChange>` handler (lines 147–152), specifically line 151: `if (value) onChange("");`

**What currently happens:**
- `Combobox` is a controlled search-and-select input. `value` is the prop (controlled value from the parent); `onChange` is the prop callback.
- Internal state `query` tracks what the user has typed.
- When the field already has a value (`value` is truthy) and the user types even one character to modify or search, the handler executes `if (value) onChange("")`, which calls the parent's `onChange` with `""`.
- The parent's committed value is wiped to empty immediately, before the user has typed a replacement or selected anything.

**What should happen:**
- The existing controlled value must be preserved while the user types. The new value should only be committed when the user selects an option, presses Enter, or blurs away — handled already by `commitExactMatch()` / `select()`. If the user cancels (Escape, or tabs away with no match), the original value must remain intact.

**Reproduction steps:**
1. Open onboarding step 0 ("Core details").
2. Use the "Field of study / discipline" Combobox (which uses `allowCustom`) and select an option, e.g. "Computer Science" (so `form.discipline` is non-empty).
3. Click into the same discipline field again and type a single character (e.g. "S" to change to "Software Engineering").
4. Observe: `form.discipline` is immediately set to `""` — the selected value is gone. The input now shows "S" but the committed value is empty.

**Evidence from source (`components/Combobox.tsx`):**
```tsx
147:        onChange={(e) => {
148:          setQuery(e.target.value);
149:          setOpen(true);
150:          setHighlighted(0);
151:          if (value) onChange("");
152:        }}
```
- `value` (line 151) = the Combobox `value` prop (controlled value from parent).
- `onChange` (line 151) = the Combobox `onChange` prop callback.
- When `value` is truthy and the user types, `onChange("")` clears the parent's value on the first keystroke.

The same defect affects the institution Combobox in `app/onboarding/page.tsx` (line 483), which calls `selectInstitution("")` — clearing both `institution_name` and `institution_type`.

**Existing test coverage:** None. `grep Combobox` across `*.test.ts` → no matches. No unit test exercises the Combobox input handler.

**Estimated implementation risk:** Low. The fix is removing a single line (`if (value) onChange("");`). The `commitExactMatch()` blur/Enter logic already handles committing or resetting correctly.

**How the fix can be verified:**
- Add a unit test for `Combobox` covering: (a) with a pre-existing value, typing does not clear the value; (b) typing then pressing Enter/selecting commits the new value; (c) typing then blurring with an exact match commits the match; (d) typing then pressing Escape leaves the value unchanged.
- Manual: onboarding step 0, select a discipline, click in, type, confirm value is retained.
- Run `npm test` (100 tests) before and after to confirm no regression.

---

### Candidate 2 — Onboarding step 0 does not require discipline

**File / function:** `app/onboarding/page.tsx`, `validateStep()` (lines 318–332)

**What currently happens:** `validateStep()` for `step === 0` requires `full_name`, `institution_name`, `institution_type` (when manual), and `year_of_study`. It does **not** require `discipline`, even though the module comment states step 0 collects "exactly the fields the matching engine gates on: name, course, institution (+type), year of study."

**What should happen:** Either discipline should be required in `validateStep()` (consistent with the comment), or the comment should be updated to reflect that discipline is optional.

**Reproduction steps:**
1. Open onboarding step 0.
2. Fill name, institution, year of study; leave discipline blank.
3. Click "See my provisional matches" → proceeds without discipline.

**Evidence:** `validateStep()` lines 319–327 check name/institution/year but not discipline.

**Existing test coverage:** None for `validateStep()` (it is not exported; `app/onboarding/page.tsx` has no test file).

**Risk:** Low-medium (behavior change could affect onboarding flow; requires deciding whether discipline is truly required).

**Why not selected:** Whether discipline should be required is a product decision, not a clear-cut code defect; the comment may describe intent rather than a hard requirement. Less reproducible as a "defect" than Candidate 1.

---

### Candidate 3 — Settings page has no editable form (read-only display)

**File / function:** `app/settings/page.tsx`

**What currently happens:** Settings is a read-only profile overview. All personal/academic fields render as `<dl>`/`<Row>` display text; the only edit path is a link back to `/onboarding`.

**What should happen:** Not a defect — this is documented by design ("Read-only overview of the profile ... with one clear path back into onboarding to change anything").

**Existing test coverage:** None (no test file for `app/settings/page.tsx`).

**Why not selected:** No defect; it's intentional design.

---

## Selected Defect

**Candidate 1 — Combobox prematurely clears controlled value on first keystroke.**

### Selection rationale (vs. alternatives)

| Criterion | Candidate 1 (Combobox) | Candidate 2 (discipline required) | Candidate 3 (settings read-only) |
|---|---|---|---|
| Clearly reproducible | ✅ Yes — single line, deterministic | ⚠️ Depends on product intent | ❌ Not a defect |
| Confirmed in current code | ✅ Yes — line 151 | ✅ Yes | ✅ Yes (by design) |
| Isolated to few files | ✅ One file, one line | ⚠️ One function, but product decision | ❌ N/A |
| Low regression risk | ✅ Yes — removing one line | ⚠️ Changes onboarding flow | ❌ N/A |
| Practical way to test | ✅ Unit test + manual | ⚠️ Manual only, no test file | ❌ N/A |
| Genuine user value | ✅ Fields retain value when editing | ⚠️ Debatable | ❌ N/A |

**Selected:** Candidate 1. It is the only candidate that is simultaneously a confirmed code defect, clearly reproducible, isolated, low-risk, and testable with genuine user value.

---

## Proposed Implementation

**Note:** This is a proposal only. No code will be modified until explicit approval.

### Exact files expected to change
1. `components/Combobox.tsx` — remove the premature value-clearing line.
2. `components/Combobox.test.ts` (new) — unit tests for the fix.

### Proposed technical solution

Remove line 151 (`if (value) onChange("");`) from the `<input onChange>` handler in `Combobox.tsx`.

**Before:**
```tsx
onChange={(e) => {
  setQuery(e.target.value);
  setOpen(true);
  setHighlighted(0);
  if (value) onChange("");
}}
```

**After:**
```tsx
onChange={(e) => {
  setQuery(e.target.value);
  setOpen(true);
  setHighlighted(0);
}}
```

**Why this is correct:**
- While the user types, `query` (internal display state) updates; the controlled `value` prop from the parent is untouched.
- Commit/reset is already handled elsewhere:
  - Selecting an option → `select(option)` calls `onChange(option.value)` ✓
  - Pressing Enter → exact match or custom text committed via `commitExactMatch()` ✓
  - Blurring away → `commitExactMatch()` commits exact match / custom text, or resets the *display* (`setQuery(selectedLabel)`) without touching the value ✓
  - Pressing Escape → `setOpen(false); setQuery(selectedLabel)` — value unchanged ✓
- Removing the line eliminates the UI state inconsistency where Escape/cancel left the display showing the old label while the value was already `""`.

### Tests to add
New file `components/Combobox.test.ts` with vitest cases:
1. **Typing does not clear an existing value:** render with `value="Computer Science"`, type "S" into the input, assert `onChange` was NOT called with `""` (value retained).
2. **Selecting an option commits its value:** select an option from the list, assert `onChange` called with that option's value.
3. **Typing an exact label then blurring commits it:** type an option's full label, blur, assert `onChange` called with that option's value.
4. **Typing then pressing Escape leaves value unchanged:** type, press Escape, assert `onChange` not called with `""`; value retained.
5. **allowCustom: typing custom text then blurring commits the custom text.**

Use `@testing-library/react` if available, otherwise render the component directly and fire input/change/blur/keyDown events. Check package.json for testing-library availability before finalizing the test approach.

### Existing tests that should be run
- `npm test` (full vitest suite: 19 files, 100 tests) — must remain all-pass.
- `npx tsc --noEmit` — type-check must remain exit 0.
- `npm run test:discovery` (subset) — optional quick check.

### Potential regression risks
- **None identified as likely.** The removed line only caused harm (premature clearing). All commit paths (`select`, Enter, blur via `commitExactMatch`) are unchanged.
- One behavioral nuance: with `allowCustom`, previously typing one character cleared the value and then blur committed the typed custom text anyway (same end result); now the value is retained until blur, then committed. End state is identical for completed entries; only cancel/abort behavior improves (value no longer lost).
- Non-`allowCustom` Comboboxes (e.g., institution) previously cleared on first keystroke; now they retain until a selection/blur. Blur with no exact match resets display but keeps value — correct cancel behavior.

### Rollback approach
- Re-add line 151 (`if (value) onChange("");`) exactly as it was.
- No database, migration, env, or deploy changes are involved, so rollback is a single source-line revert in `components/Combobox.tsx`.
- The change is not deployed anywhere, so there is no production rollback needed.

---

## Verification Plan (post-approval)

1. Run `npm test` → expect 19 files / 100 tests passed (new Combobox tests added).
2. Run `npx tsc --noEmit` → expect exit 0.
3. Manual reproduction on onboarding step 0: select discipline → click in → type → confirm value retained.
4. Inspect final diff (should be limited to `Combobox.tsx` removal + new `Combobox.test.ts`).

---

## Statement of Execution vs. Inference

**Actually executed (verified by running commands / reading source):**
- Read `components/Combobox.tsx`, `components/FormField.tsx`, `components/PasswordField.tsx`, `components/WaecResultsEditor.tsx`, `components/MilestoneOnboarding.tsx`, `app/onboarding/page.tsx`, `app/settings/page.tsx`, `app/discover/DiscoverClient.tsx`, `lib/validate.ts`, `lib/profile.ts`, `lib/onboarding-prompts.ts`.
- Confirmed no existing `Combobox` test (grep across `*.test.ts`).
- `npm test` → 19 files / 100 tests passed, exit 0.
- Confirmed line 151 `if (value) onChange("");` exists in `components/Combobox.tsx`.

**Inferred (not executed):**
- The exact DOM/event behavior in a real browser (manual verification needed post-fix).
- Whether `@testing-library/react` is available for the new test (to be checked before writing the test).
- Product intent on whether discipline should be required (Candidate 2).

---

## Conclusion

The selected defect is a one-line form-behavior bug in `components/Combobox.tsx` (line 151) that wipes a field's committed value the moment a user with an existing selection starts typing to edit it. It affects onboarding's discipline and institution fields. The fix (remove that line) is isolated, low-risk, and fully testable. No code has been modified. Awaiting explicit approval before implementing.

**File location:** `/workspaces/Scholars/OPENCODE_STAGE_1_DEFECT_SELECTION.md`
