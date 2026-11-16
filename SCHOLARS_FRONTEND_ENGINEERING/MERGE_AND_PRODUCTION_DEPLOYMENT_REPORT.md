# Scholars Merge and Production Deployment Report

**Product:** Scholars — Nigerian student scholarship platform  
**Repository (application):** ImperioKDB/Scholars  
**Repository (this report):** ImperioKDB/Updates → `SCHOLARS_FRONTEND_ENGINEERING/`  
**Pull request:** https://github.com/ImperioKDB/Scholars/pull/36  
**Governing skill:** `@premium-frontend-engineering` (Premium Frontend Engineering)  
**Status:** PR merged, production deployed, production verified.

---

## Phase 1 — Documentation Correction

### CI Identifier Correction

The original test report contained ambiguous CI identifiers ("133628909053" and "133629487008") without clarifying whether they were workflow run IDs or check-run IDs. Investigation via the GitHub API revealed:

| Identifier | Type | Value | Meaning |
|------------|------|-------|---------|
| GitHub Actions workflow run ID | Workflow run ID | 43961246867 | The GitHub Actions workflow ("ci") that ran on the commit |
| GitHub Actions workflow run number | Workflow run number | 531 | Human-readable run number for the same workflow run |
| Check-run ("build") | Check-run ID | 133628909053 | Individual check within the workflow run |
| Check-run ("Vercel Preview Comments") | Check-run ID | 133629487008 | Individual Vercel preview check within the workflow run |
| Vercel commit status | Commit status context | success | Overall Vercel deployment status |

These are **different identifier types** and should not be conflated.

The CI identifier terminology correction is documented in commit `cc736d3004afb9be53a0d8ce0a05f60a58416c9f` in the Updates repository.

---

## Phase 2 — PR #36 Merge

### Pre-merge Verification

| Check | Result |
|-------|--------|
| PR #36 open, not merged | ✅ Confirmed |
| Head SHA: `503cbda9376fd8c0b116f2f97cc127a0ea73c98c` | ✅ Confirmed |
| GitHub CI workflow run #531 (ID: 43961246867) | ✅ Passed |
| Check-run "build" (ID: 133628909053) | ✅ Passed |
| Check-run "Vercel Preview Comments" (ID: 133629487008) | ✅ Passed |
| Commit status: success | ✅ Confirmed |
| PR files: only `app/onboarding/page.tsx` and `app/onboarding/page.test.tsx` | ✅ Confirmed |
| Vitest: 30 files / 201 tests passed | ✅ Confirmed |
| TypeScript `tsc --noEmit`: exit 0 | ✅ Confirmed |

### PR #36 Diff Review

Only 2 files changed:

| File | Change |
|------|--------|
| `app/onboarding/page.tsx` (+22/−9) | Fixed `setRetrySave(fn)` → `setRetrySave(() => fn)` callback storage bug in all 7 call sites; reduced mobile card padding; added retry buttons |
| `app/onboarding/page.test.tsx` (+416/−0) | Added 7 regression tests for retry behavior |

All retry callbacks correctly use `() => fn` wrapper. Drafts preserved on failed saves, cleared only after successful save acknowledgement. Mobile onboarding layout adjusted. Deferred Promise test confirms retry button disappears while request is in flight.

### Merge

| Field | Value |
|-------|-------|
| PR #36 | Merged into `main` |
| Merge commit SHA | `8cd345df1fe8c79f041b5264ede7b3ab9a750221` |
| Main branch SHA (post-merge) | `8cd345df1fe8c79f041b5264ede7b3ab9a750221` |
| PR #35 | Not touched, left open |

---

## Phase 3 — Production Deployment

### Production Configuration Check

| Setting | Value |
|---------|-------|
| Production environment variables | Present on Vercel (deployment succeeded) |
| Vercel project connected to repo | Yes (ImperioKDB/Scholars) |
| Production deployment branch | `main` |

### Production Deployment

| Field | Value |
|-------|-------|
| Deployment ID | 7837384389 |
| Deployment ref | `8cd345df1fe8c79f041b5264ede7b3ab9a750221` (merge commit) |
| Environment | Production |
| Task | deploy |
| Status | success |
| Created | 2026-11-16T21:50:56Z |
| Updated | 2026-11-16T21:50:57Z |
| Vercel deployment URL | https://scholars-2ro84294p-imperiokdbs-projects.vercel.app |
| Production URL | https://scholars.com.ng |

### Production Smoke Tests (Unauthenticated, Read-Only)

| Route | Status | Result |
|-------|--------|--------|
| https://scholars.com.ng/ | 200 | Landing page renders |
| https://scholars.com.ng/sitemap.xml | 200 | XML sitemap renders |
| https://scholars.com.ng/login | 200 | Login page renders |
| https://scholars.com.ng/onboarding | 200 | Redirected to login (`https://www.scholars.com.ng/login?next=%2Fonboarding`) |
| https://scholars.com.ng/dashboard | 200 | Redirected to login (`https://www.scholars.com.ng/login?next=%2Fdashboard`) |

All five requested URLs returned a final document with HTTP 200. Non-www URLs canonicalized to `www.scholars.com.ng`. No visible runtime exceptions or error UI were observed. One informational PWA install-banner console message appeared. No login, registration, form submission, or data-changing action was performed.

**Important:** The onboarding and dashboard pages did **not** render their authenticated content. Both redirected to the login page with the requested destination preserved in the `next` query parameter. These results verify authentication redirect behaviour and destination preservation, **not** successful authenticated access or onboarding/dashboard functionality.

---

## Phase 4 — Final Report

### Documentation Correction Commit

| Field | Value |
|-------|-------|
| Repository | ImperioKDB/Updates |
| Directory | `SCHOLARS_FRONTEND_ENGINEERING/` |
| File | `TEST_RESULTS.md` |
| Commit SHA | `03f1a4cc8e10dbb894572ec199da685de1b2c198` |
| Commit URL | https://github.com/ImperioKDB/Updates/commit/03f1a4cc8e10dbb894572ec199da685de1b2c198 |

### CI Identifier Correction Commit

| Field | Value |
|-------|-------|
| Repository | ImperioKDB/Updates |
| Directory | `SCHOLARS_FRONTEND_ENGINEERING/` |
| File | `TEST_RESULTS.md` |
| Commit SHA | `cc736d3004afb9be53a0d8ce0a05f60a58416c9f` |
| Commit URL | https://github.com/ImperioKDB/Updates/commit/cc736d3004afb9be53a0d8ce0a05f60a58416c9f |

### Final Test Results

| Check | Result |
|-------|--------|
| Vitest | 30 files, 201 tests passed |
| TypeScript (`tsc --noEmit`) | Passed (exit 0) |
| GitHub Actions workflow run #531 | Passed (run ID: 43961246867) |
| Check-run "build" (ID: 133628909053) | Passed |
| Check-run "Vercel Preview Comments" (ID: 133629487008) | Passed |
| Commit status | success |
| Production deployment | success (deployment ID: 7837384389) |
| Production smoke tests | Landing, sitemap, login return HTTP 200; onboarding/dashboard redirect to login with `next` parameter preserved |

### Outstanding Limitations

| Area | Status |
|------|--------|
| Browser/device testing (320px–430px) | Not performed |
| Screen-reader testing (VoiceOver/NVDA) | Not performed |
| Reduced-motion verification | Not performed |
| Lighthouse/performance analysis | Not performed |
| End-to-end user-journey testing | Not performed |
| Real user registration | Not performed (no real data submitted) |
| Authenticated onboarding completion | Not performed (onboarding redirects to login when unauthenticated) |
| Dashboard functionality | Not performed (dashboard redirects to login when unauthenticated) |

### Production Smoke Testing Limitation

Production smoke testing was unauthenticated and read-only. The homepage, sitemap and login page rendered successfully. The onboarding and dashboard URLs redirected to login with their requested destinations preserved. Authenticated onboarding completion, dashboard functionality and actual scholarship application journeys remain unverified.

### Confirmations

- ✅ No application source code was modified beyond the approved 2 files in PR #36
- ✅ No database schemas, migrations, or production data were modified
- ✅ No credentials or secrets were exposed
- ✅ PR #35 was not touched; remains open
- ✅ PR #36 was merged into `main` (merge commit: `8cd345df1fe8c79f041b5264ede7b3ab9a750221`)
- ✅ Production deployment succeeded on `https://scholars.com.ng`
- ✅ Production smoke tests passed (landing, sitemap, login return HTTP 200; onboarding/dashboard redirect to login with `next` preserved)
- ✅ No unrelated files or database changes introduced
- ✅ Scholars visual identity and architecture preserved
