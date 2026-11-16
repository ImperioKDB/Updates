# Scholars Frontend Audit (re-validated)

**Product:** Scholars — Nigerian student scholarship platform  
**Repository (application):** ImperioKDB/Scholars  
**Feature branch:** `feat/frontend-advertisement-readiness`  
**Governing skill:** `@premium-frontend-engineering`  
**Audit type:** Static source re-validation + live test execution (vitest).  
**Status:** Findings corrected against current source; implementation applied to P0 onboarding items.

---

## Method and key correction

The prior `FRONTEND_AUDIT_REPORT.md` (in `ImperioKDB/Updates`) was written against an older version of the Scholars codebase. I re-inspected every cited file against the **current** source. Result:

- Many findings marked as defects are **already resolved** in the current source (ConfirmDialog naming/focus, StepIndicator `aria-current`, ReportScholarshipButton/DraftPanel labelling, mobile drawer focus capture/restore via `inert` + `useOverlayAccessibility`, combobox `aria-controls`/`aria-activedescendant`, reduced-motion gating of `animate-spin`/confetti).
- Some findings were **overstated** (e.g., "password login always pushes /dashboard" — the code does `router.push(next)`; onboarding "clears draft after failed save" — the code returns early and preserves the draft).
- A subset are **genuine and were implemented** (onboarding failed-save retry actions, 320–375px layout padding).

No browser/device/screen-reader testing was performed. "Confirmed" below means the cited code violates a stated contract or creates a deterministic source-level defect; runtime severity may still vary.

---

## Design system (source of truth — preserved)

| Token | Value | Role |
|-------|-------|------|
| navy | `#0B1E3D` / `#14315C` / `#EEF2F8` | Primary brand, CTAs, headings |
| parchment | `#F7F5EF` | Page background |
| ink | `#10151F` | Body text |
| emerald | `#15705A` / `#E4F3EE` | Verified / open / success accent |
| amber | `#966216` / `#FBF1E1` | Caution / deadlines |
| rose | `#A63A35` / `#FBEAE9` | Closed / ineligible |
| hairline | `#E4E1D8` | Borders |
| display font | Fraunces (serif) | Editorial headings |
| sans font | Manrope | UI / body / data labels |
| borderRadius.seal | `9999px` | Primary brand CTAs |
| shadow.card | `0 1px 2px ... 0.06), 0 1px 12px ... 0.05)` | Card elevation |

No new raw values introduced; existing tokens are the source of truth.

---

## P0 — Advertisement conversion leaks (landing + auth + onboarding)

### F0-1. Auth return-path preservation — VERIFIED ALREADY PRESENT (no code change)

**Current implementation**
- `app/(auth)/login/page.tsx:77,134`: `next = safeNextPath(searchParams.get("next"), "/dashboard")`; `handleSubmit` calls `router.push(next)`. Session-redirect also uses `router.replace(next)`.
- `app/(auth)/login/page.tsx:141` + `app/auth/callback/route.ts:46`: Google OAuth passes `next` via `rememberAuthNext` cookie and `redirectTo ...?next=`; callback resolves `safeNextPath(searchParams.get("next") || cookieNext, "/dashboard")`.
- `app/(auth)/signup/page.tsx:34,107`: `next` default `/onboarding`; `router.push(next)` on immediate session; `handleVerify` pushes `next`.
- Middleware `middleware.ts:234-235`: redirects unauthenticated users to `/login?next=<protected path>`.

**Problem (audit claim, now corrected):** The audit claimed password login "always pushes /dashboard", Google OAuth "hard-codes next=/dashboard", and signup "does not consume a return path." **Current source contradicts all three** — `next` is preserved through every flow. Default fallback `/dashboard` only applies when no `next` is supplied (safe, same-origin-validated).

**Impact on students:** Minimal — return paths are preserved. The audit's severity rating for this item is overstated.

**Proposed improvement:** None required for code. Add test coverage to lock in behaviour (see TEST_RESULTS.md; `lib/auth/return-destination.test.ts` already covers `safeNextPath` whitelisting).

**Priority:** Verified — no implementation needed.  
**Relevant files:** `middleware.ts`, `app/(auth)/login/page.tsx`, `app/(auth)/signup/page.tsx`, `app/auth/callback/route.ts`, `lib/auth/return-destination.ts`, `lib/validate.ts`

---

### F0-2. Onboarding failed-save retry actions — IMPLEMENTED

**Prior state:** `saveProfileAndGoDashboard`, `handleFinish`, `handleSkip` set an error message on `!res.ok` / catch and returned early (draft preserved), but offered **no inline retry**. A stranded student had to reload the page.

**Current implementation (`app/onboarding/page.tsx`):** Added a `retrySave` state. Each save function clears `retrySave` at start and sets `setRetrySave(<the save function>)` on every failure path. The error render shows an inline "Try again" button bound to `retrySave`. Draft is never cleared unless a save is acknowledged successful (`clearDraft()` only after `res.ok`).

**Problem:** Failed onboarding saves stranded students with an error and no recovery action, increasing abandonment of the registration journey (critical for ad-driven signups).

**Impact on students:** Transient network/5xx failures could make onboarding appear broken with no recovery path.

**Proposed improvement:** Implemented — inline retry on all three save paths.

**Priority:** HIGH  
**Relevant files:** `app/onboarding/page.tsx`

---

### F0-3. Onboarding draft preservation — IMPLEMENTED & VERIFIED

**Current implementation:** Drafts are written to `localStorage` on every field change (`useEffect` at line ~239). `clearDraft()` is called **only** after `res.ok` in `saveProfileAndGoDashboard`, `handleFinish`, and `handleSkip`. Failure paths return early and keep the draft. The audit's claim that drafts are cleared after failed saves was incorrect for the current source.

**Problem:** None remaining in code; the earlier audit was overstated.

**Impact on students:** Drafts survive failed saves — no data loss.

**Proposed improvement:** None required; behaviour verified.

**Priority:** Verified — no implementation needed.  
**Relevant files:** `app/onboarding/page.tsx`

---

### F0-4. Onboarding layout at 320–375px — IMPLEMENTED

**Current implementation (`app/onboarding/page.tsx`):** Card padding changed from `p-5 sm:p-8` to `p-4 sm:p-5`. Step-0 actions already use `flex flex-col-reverse sm:flex-row` with `w-full sm:w-auto` (stack full-width on mobile). Page uses `px-4 sm:px-6`.

**Problem:** At 320px, `p-5` (20px) card padding on a `px-4` page left only ~248px of inner width, crowding the two primary step-0 actions and form fields on common phones (iPhone SE class).

**Impact on students:** Crowded primary actions increase tap error and onboarding abandonment on small phones.

**Proposed improvement:** Implemented — `p-4 sm:p-5` gives ~256px inner width at 320px; actions stack full-width.

**Priority:** HIGH  
**Relevant files:** `app/onboarding/page.tsx`

*Note: exact clipping at 320px/375px still needs device/browser verification (not performed — see TEST_RESULTS.md).*

---

## P1 — Accessibility (verified already present)

The following were confirmed implemented in current source; no new code required:

| Item | Verification | Files |
|------|-------------|-------|
| ConfirmDialog accessible naming + focus management | `role="dialog"`, `aria-modal`, `aria-labelledby`, `aria-describedby`; `useOverlayAccessibility` gives focus capture, restore, Escape, tab trap, scroll lock | `components/ConfirmDialog.tsx`, `lib/useOverlayAccessibility.ts` |
| Step indicator accessibility | `aria-current="step"`, live "Step {n} of {total}", `aria-label="Onboarding progress"`, per-step Completed/Current/Upcoming labels | `components/StepIndicator.tsx` |
| Report form labelling | `htmlFor`/`id` on reason select; `sr-only` label + `aria-describedby` on details textarea; `role="alert"` on error | `components/ReportScholarshipButton.tsx` |
| Draft form labelling | `htmlFor`/`id` on personal-statement textarea; `aria-describedby` on character counter; counter has `aria-live="polite"` | `components/DraftPanel.tsx` |
| Mobile drawer focus + restoration | `inert={!mobileOpen}` removes from tab order when closed; `useOverlayAccessibility` captures/restores focus, traps Tab, handles Escape | `components/Sidebar.tsx`, `lib/useOverlayAccessibility.ts` |
| Combobox / form labelling | Combobox forwards `id`, `aria-controls`, `aria-activedescendant`; `role=listbox`/`role=option`; FormField forwards `id`/`aria-describedby`/`aria-invalid` | `components/Combobox.tsx`, `components/FormField.tsx` |
| Reduced motion | `globals.css` gates `animate-spin`, `.confetti-piece`, `.badge-pop-in`, `.animate-card-in`, button press transforms under `prefers-reduced-motion`; `html { scroll-behavior: auto }` | `app/globals.css` |

---

## Hypotheses requiring live validation (not confirmed)

| # | Area | Why unconfirmed |
|---|------|-----------------|
| H1 | Shimmer paint cost | Continuous `background-position` animation on dashboard loading; no device trace run |
| H2 | Repeated blur compositing | Multiple `backdrop-blur-sm` surfaces during scroll; not measured |
| H3 | Hydration breadth | Bundle/hydration cost not measured (build blocked by missing env) |
| H4 | Exact 320px/375px onboarding clipping | Deterministic sizing reviewed; needs device rendering check |

---

## Files modified (application)

| File | Change |
|------|--------|
| `vitest.config.js` | Fixed corruption: `opencodeimport` → `import` (line 1) |
| `app/onboarding/page.tsx` | Added `retrySave` state + inline retry on all three save paths; reduced card padding `p-5 sm:p-8` → `p-4 sm:p-5` |

No other application files modified. No database, auth, matching, or security files touched.

---

## Files referenced (not modified)

`middleware.ts`, `app/page.tsx`, `app/layout.tsx`, `app/globals.css`, `app/motion.css`, `app/(auth)/login/page.tsx`, `app/(auth)/signup/page.tsx`, `app/auth/callback/route.ts`, `app/dashboard/layout.tsx`, `app/discover/layout.tsx`, `app/opportunities/layout.tsx`, `app/scholarships/layout.tsx`, `components/Sidebar.tsx`, `components/ScholarshipCard.tsx`, `components/ConfirmDialog.tsx`, `components/StepIndicator.tsx`, `components/ReportScholarshipButton.tsx`, `components/DraftPanel.tsx`, `components/Combobox.tsx`, `components/FormField.tsx`, `components/NotificationBell.tsx`, `lib/auth/return-destination.ts`, `lib/validate.ts`, `lib/useOverlayAccessibility.ts`.
