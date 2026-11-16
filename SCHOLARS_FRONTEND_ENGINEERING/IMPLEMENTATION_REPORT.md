# Scholars Frontend Advertisement Readiness — Clean Implementation Report

**Product:** Scholars — Nigerian student scholarship platform  
**Repository (application):** ImperioKDB/Scholars  
**Repository (this report):** ImperioKDB/Updates → `SCHOLARS_FRONTEND_ENGINEERING/`  
**Pull request:** https://github.com/ImperioKDB/Scholars/pull/36  
**Feature branch:** `feat/frontend-advertisement-readiness-clean`  
**Governing skill:** `@premium-frontend-engineering` (Premium Frontend Engineering)  
**Status:** Clean PR created, not merged, not deployed.

---

## Purpose

This report documents the clean implementation of the highest-priority frontend improvements for Scholars advertisement readiness. It replaces the earlier PR #35, which inadvertently included unrelated Resource Centre reports and SQL files. PR #36 contains **only** the intended advertisement-readiness frontend change.

---

## What was implemented

**One file changed:** `app/onboarding/page.tsx` (+22/−9)

### 1. Onboarding failed-save retry actions (P0)

Added inline "Try again" buttons on all three failed save paths:

| Save function | Failure path | Retry behavior |
|---------------|-------------|----------------|
| `saveProfileAndGoDashboard` | `!res.ok` or catch | `setRetrySave(saveProfileAndGoDashboard)` |
| `handleFinish` | Profile `!res.ok`, WAEC `!res.ok`, or catch | `setRetrySave(handleFinish)` |
| `handleSkip` | `!res.ok` or catch | `setRetrySave(handleSkip)` |

Each save function clears `retrySave` at start (`setRetrySave(null)`), then sets it on every failure path. The error render shows an inline "Try again" button bound to `retrySave` when available.

### 2. Onboarding draft preservation (P0)

Verified and locked in: `clearDraft()` runs **only** after an acknowledged successful save (`res.ok`). All failure paths return early and preserve the local draft. No student work is discarded on transient network or server failure.

### 3. Mobile onboarding layout (320–375px) (P0)

Reduced card padding from `p-5 sm:p-8` to `p-4 sm:p-5` so the two primary step-0 actions and form fields are not cramped on small phones. Step-0 actions already stacked full-width on mobile (`flex flex-col-reverse sm:flex-row` with `w-full sm:w-auto`).

---

## What was NOT changed (and why)

| Item | Reason |
|------|--------|
| `vitest.config.js` | Already fixed on `main` (`import { defineConfig } from "vitest/config";`). No change needed. |
| Auth return-paths (`next`) | Verified already correct across password login, Google OAuth, signup, and callback. `router.push(next)` is used; `/dashboard` is only the safe fallback. No code change required. |
| P1 accessibility items | Re-inspected all targets — already implemented in current source (ConfirmDialog naming/focus, StepIndicator `aria-current`, Report/Draft form labelling, mobile drawer focus capture/restore, combobox semantics, reduced-motion gating). No new code required. |
| P2 visual consistency | Design system tokens already applied consistently. Preserved navy/parchment/emerald palette, Fraunces/Manrope typography, `rounded-seal`, `shadow-card`. No generic SaaS styling introduced. |
| Resource Centre reports / SQL | Not part of this task. Preserved on their own branch. |
| Database, auth, matching algorithms | Not touched, per safety boundaries. |

---

## Verification results

| Check | Command | Result |
|-------|---------|--------|
| TypeScript typecheck | `npx tsc --noEmit` | ✅ exit 0 (pass) |
| Unit/integration tests | `npx vitest run` | ✅ 29 files, 194 tests passed |
| Production build (`next build`) | `npx next build` | ❌ Not completable — `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`, `NEXT_PUBLIC_APP_URL` empty in `.env.local` (environment prerequisite, not a code defect) |
| CI (GitHub) | PR #36 | Build check `in_progress`; Vercel `pending`; preview comments ✅ success |

> The build check and Vercel status are pending on GitHub. They are not claimed as passed.

---

## PR details

| Field | Value |
|-------|-------|
| PR number | 36 |
| PR URL | https://github.com/ImperioKDB/Scholars/pull/36 |
| Title | `feat(frontend): improve Scholars advertisement readiness` |
| Head branch | `feat/frontend-advertisement-readiness-clean` |
| Head commit SHA | `d312b04989718527efff20d8daca91bf0cd997e8` |
| Base branch | `main` (142146a67cb21eeec8d74832bc326c1fcd5dd5f4) |
| Mergeable | True |
| Commits | 1 |
| Additions | 22 |
| Deletions | 9 |
| Changed files | 1 (`app/onboarding/page.tsx`) |
| Draft | No |
| Merged | No |

---

## Safety boundaries honoured

- No production database schema changes; no migrations.
- No Supabase authentication behaviour changes.
- No scholarship matching / eligibility algorithm changes.
- No security controls bypassed.
- No credentials exposed or printed.
- Nothing deployed to production.
- PR #35 (the earlier unclean PR) left open, not closed, not merged.
- Existing Resource Centre work preserved on its own branch.

---

## Outstanding limitations

- Browser/device testing (320px, 360px, 375px, 390px, 430px) — not performed (no browser automation tooling)
- Screen-reader sessions (VoiceOver/NVDA) — not performed
- Reduced-motion verification — not performed
- Lighthouse / performance trace / bundle analysis — not performed (build blocked by missing env vars)
- End-to-end user-journey tests — not performed (no E2E suite configured)

---

## Related documents

- [README.md](./README.md) — report overview
- [FRONTEND_AUDIT.md](./FRONTEND_AUDIT.md) — re-validated audit findings
- [IMPLEMENTATION_REPORT.md](./IMPLEMENTATION_REPORT.md) — this report
- [TEST_RESULTS.md](./TEST_RESULTS.md) — detailed test results
