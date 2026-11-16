# Scholars Test Results

**Product:** Scholars — Nigerian student scholarship platform  
**Repository (application):** ImperioKDB/Scholars  
**Feature branch:** `feat/frontend-advertisement-readiness-clean`  
**Pull request:** https://github.com/ImperioKDB/Scholars/pull/36  
**Governing skill:** `@premium-frontend-engineering` (Premium Frontend Engineering)  
**Status:** PR updated with strengthened retry regression tests. Not merged, not deployed.

---

## Tests actually performed

### 1. Unit / integration suite (vitest)

**Command:** `cd /workspaces/Scholars && npx vitest run`  
**Result: PASSED**

```
Test Files  30 passed (30)
   Tests  201 passed (201)
Duration  64.47s
```

This includes **7 onboarding retry regression tests** in `app/onboarding/page.test.tsx`:

| Test | What it verifies |
|------|-----------------|
| "does not execute retry callback automatically; clicking Try again triggers second save" | After failed save, `fetch` called exactly once (proving `setRetrySave(() => fn)` stores the callback rather than executing it as a state updater). Clicking Try again triggers a second save. |
| "failed profile save then successful retry navigates to dashboard" | Failed profile save → retry succeeds → navigates to `/dashboard`. |
| "handleFinish failure then successful retry" | Final onboarding save failure → retry succeeds → navigates to `/dashboard`. |
| "handleSkip failure then successful retry" | Skip save failure → retry succeeds → navigates to `/dashboard`. |
| "draft preserved on failed save, cleared only after successful completion" | `localStorage.removeItem` (clearDraft) NOT called on failed save; IS called after successful save. |
| "retry button unavailable while a retry request is in flight" | Retry button present before click; disappears while retry in flight (`retrySave` set to null at save start). Uses a deferred Promise to hold the retry request pending, then resolves it and verifies navigation. |
| "successful retry navigation and save endpoints called correctly" | Both save calls are POST to `/api/profile` with `full_name` in body; navigation to `/dashboard` occurs. |

**Test files exercised (30):**
All original test files plus `app/onboarding/page.test.tsx` (7 tests). Original test files include `lib/auth/return-destination.test.ts` (12 — `safeNextPath` whitelisting), `app/sitemap.test.ts` (18 — SEO sitemap correctness), `components/Combobox.test.tsx` (11 — combobox behaviour), and others.

---

### 2. TypeScript typecheck

**Command:** `cd /workspaces/Scholars && npx tsc --noEmit`  
**Result: PASSED** (exit 0, no output).  
Typechecks the onboarding fix (`() => fn` callback wrappers), the test file, and all application source.

### 3. ESLint

Not run — no ESLint configuration exists in the repository (running `next lint` prompts for interactive setup).

### 4. Production build (`next build`)

**Result: NOT COMPLETABLE — environment limitation.**

`NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`, `NEXT_PUBLIC_APP_URL` are empty in `.env.local`. Prerendering fails with `supabaseUrl is required`. Configuration/environment prerequisite, not a code defect.

---

## Tests NOT performed

| Area | Specific check | Why not performed |
|------|----------------|-------------------|
| Browser rendering | 320/360/375/390/430px | No browser automation tooling |
| Device testing | iOS Safari / Android Chrome | No device/emulator access |
| Screen reader | VoiceOver / NVDA / TalkBack | No assistive-technology environment |
| Keyboard-only traversal | Full Tab-order walk | Requires live browser |
| Reduced motion | `prefers-reduced-motion` behaviour | Requires live browser + OS setting |
| Touch targets | 44px verification, safe-area insets | Requires physical/emulated devices |
| Performance | Lighthouse / Web Vitals / trace | No production build available |
| SEO crawl | Search-engine rendering | Requires live deployment |
| E2E user journeys | Ad-click → register → onboard → match | No E2E suite configured |
| Visual regression | Screenshot comparison | No visual-regression tooling |

---

## Honest statement

All code changes (`app/onboarding/page.tsx`, `app/onboarding/page.test.tsx`) pass `tsc --noEmit` and the full vitest suite (30 files / 201 tests passed). No screenshot, Lighthouse score, Web Vital, frame-trace, or screen-reader result is included because none was measured. Advertisement readiness is functionally supported but cannot be fully claimed until `next build` completes with real Supabase credentials and browser/device/accessibility verification runs on the deployed build.

---

## PR details

| Field | Value |
|-------|-------|
| PR number | 36 |
| PR URL | https://github.com/ImperioKDB/Scholars/pull/36 |
| Head branch | `feat/frontend-advertisement-readiness-clean` |
| Head commit SHA | `503cbda...` |
| Base branch | `main` |
| Mergeable | True |
| Commits | 3 |
| Additions | 412 |
| Deletions | 9 |
| Changed files | 2 |

---

## CI status (as reported by GitHub)

| Check | Status |
|-------|--------|
| Build | `in_progress` |
| Vercel Preview Comments | `completed / success` |
| Vercel | `pending` |

Build check and Vercel status pending on GitHub — not claimed as passed.

---

## In-flight retry test verification

The deferred Promise approach genuinely holds the retry request pending:

1. `failPostProfileCount` is set to 2 (tracking POST consumes 1, save POST consumes 1)
2. On page load, the tracking POST to `/api/profile` fires and fails (consuming 1 failure)
3. After `fillStep0AndSubmit()`, the save POST to `/api/profile` fails (consuming the 2nd failure)
4. The retry button appears
5. Before clicking retry, `deferredResolve` is set to a Promise resolve function
6. Clicking retry triggers `saveProfileAndGoDashboard()`, which calls `setRetrySave(null)` then `fetch("/api/profile", { method: "POST" })`
7. The fetch mock checks `if (deferredResolve)` — truthy — and returns a new pending Promise, storing the resolve function
8. The retry button disappears (because `setRetrySave(null)` was called synchronously before the fetch)
9. The saving state is visible
10. The test calls `deferredResolve({ ok: true, ... })`, resolving the fetch promise
11. `saveProfileAndGoDashboard` continues, navigates to `/dashboard`

This proves the retry callback is stored in state (not executed immediately as a React state updater would), and the button correctly disappears while the request is in flight.
