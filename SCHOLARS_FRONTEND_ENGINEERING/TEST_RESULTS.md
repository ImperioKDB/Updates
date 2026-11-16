# Scholars Test Results

**Product:** Scholars — Nigerian student scholarship platform  
**Repository (application):** ImperioKDB/Scholars  
**Feature branch:** `feat/frontend-advertisement-readiness-clean`  
**Pull request:** https://github.com/ImperioKDB/Scholars/pull/36  
**Governing skill:** `@premium-frontend-engineering` (Premium Frontend Engineering)  
**Status:** Actual results only; no results invented. Tests not performed are explicitly listed.

---

## Tests actually performed

### 1. Unit / integration suite (vitest)

**Command:** `cd /workspaces/Scholars && npx vitest run`  
**Prerequisite:** The committed `vitest.config.js` was previously corrupted (line 1 read `opencodeimport { ... }`). It is **already fixed on `main`** (`import { defineConfig } from "vitest/config";`). No config change was included in this PR.

**Result: PASSED**

```
Test Files  30 passed (30)
   Tests  197 passed (197)
Start at  13:27:08
Duration  76.74s (transform 914ms, setup 0ms, collect 2.11s, tests 35.12s, environment 29.88s, prepare 2.74s)
```

This includes **3 new regression tests** in `app/onboarding/page.test.tsx` covering the retry bug fix:

| Test | What it verifies |
|------|-----------------|
| "does not execute the retry callback automatically; retry calls save again on click" | After a failed profile save, `fetch` is called exactly once (proving `setRetrySave(() => fn)` stores the callback rather than executing it as a state updater). |
| "preserves the draft on failed save (clearDraft not called on failure)" | On failed save, `localStorage.removeItem` (clearDraft) is NOT called — the draft survives. |
| "redirects to login on HTTP 401 during save" | On HTTP 401, `router.replace` is called with a `/login` path. |

**Test files exercised (30):**
All 29 original test files plus the new `app/onboarding/page.test.tsx` (3 tests). The original 29 files include `lib/auth/return-destination.test.ts` (12 — covers `safeNextPath` same-origin whitelisting underpinning auth return paths), `app/sitemap.test.ts` (18 — SEO sitemap correctness), `components/Combobox.test.tsx` (11 — combobox behaviour), and others.

**Interpretation:** The full unit/integration suite is green. The `return-destination` tests validate the `safeNextPath` whitelist (same-origin relative paths only; blocks `//evil.com`, backslash tricks, control characters) that guards auth return-path redirects.

---

### 2. TypeScript typecheck

**Command:** `cd /workspaces/Scholars && npx tsc --noEmit`  
**Result: PASSED** (exit 0, no output).  
This typechecks the onboarding fix (`() => fn` callback wrappers, `retrySave` state type `(() => void) | null`), the new test file, and all other application source.

---

### 3. Production build (`next build`)

**Command:** `cd /workspaces/Scholars && npx next build`  
**Result: NOT COMPLETABLE — environment limitation, not a code defect.**

**Error observed:** `Error: supabaseUrl is required.` during prerendering of `/`, `/login`, `/signup`, `/onboarding`, `/reset-password`, `/resources`, `/legal/*`, etc. The build generated 96/96 static pages but reported export errors on Supabase-dependent routes.

**Cause:** `.env.local` defines `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`, `NEXT_PUBLIC_APP_URL` but they are **empty** (only `VERCEL_OIDC_TOKEN` has a value). Server components that call `createClient()` cannot prerender without Supabase credentials. `.env.example` confirms these are required public config.

**Conclusion:** A production build requires the deployment environment to supply `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`, and `NEXT_PUBLIC_APP_URL`. No credentials were requested, printed, or stored. This is a deployment-readiness prerequisite, not a source-code defect.

---

## Tests NOT performed

The following Premium Frontend Engineering verification steps were **not** performed in this session; no results are claimed:

| Area | Specific check | Why not performed |
|------|----------------|-------------------|
| Browser rendering | 320 / 360 / 375 / 390 / 414 / 430 / 768 / 1024 / 1280 / 1440 px | No browser automation tooling (Playwright etc.) configured; requires live browser session |
| Device testing | iOS Safari / Android Chrome at small breakpoints | No device/emulator access |
| Screen reader | VoiceOver, NVDA, TalkBack sessions | No assistive-technology environment |
| Keyboard-only traversal | Full Tab-order walk of landing/auth/onboarding/dashboard/drawer | Requires live browser |
| Reduced motion | `prefers-reduced-motion: reduce` behaviour for spinners/confetti/drawer | Requires live browser + OS setting |
| Touch targets | 44px touch-target verification, safe-area insets | Requires physical/emulated devices |
| Performance | Lighthouse, Web Vitals, Chrome trace, bundle size, hydration | No production build available (see build limitation); no Lighthouse tooling |
| SEO crawl | Search-engine rendering, structured-data validation | Requires live deployment |
| E2E user journeys | Ad-click → register → onboard → match flow | No E2E suite (Playwright/Cypress) configured |
| Visual regression | Screenshot comparison across breakpoints | No screenshots captured; no visual-regression tooling |

---

## Honest statement

All code changes (`app/onboarding/page.tsx`, `app/onboarding/page.test.tsx`) pass `tsc --noEmit` and the full vitest suite (30 files / 197 tests passed). No screenshot, Lighthouse score, Web Vital, frame-trace, or screen-reader result is included because none was measured. Advertisement readiness is **functionally supported** by the implementation but **cannot be fully claimed** until `next build` completes with real Supabase credentials and browser/device/accessibility verification is run on the deployed build.
