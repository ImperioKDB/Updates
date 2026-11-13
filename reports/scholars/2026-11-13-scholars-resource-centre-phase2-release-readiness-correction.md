# Scholars Resource Centre — Phase 2 Release Readiness Correction

**Repository:** ImperioKDB/Scholars  
**Working directory:** `/workspaces/Scholars`  
**Branch:** `feature/resource-center-public-frontend`  
**HEAD commit:** `79456a0` — "feat: accessible mobile Resource Centre navigation + baseline audit report"  
**Report date:** Fri Nov 13 2026  
**Purpose:** Supplemental corrective audit. Re-verifies release-readiness claims after the latest Updates commit (`bc06fa7358a196a87d5c0eccc009ecfd2ac060aa`) was found to contain no new clarifications — its audit document is identical to the previous version (`c075714a71849618d190323bdff1897a05b2a91b`). All results below were produced by direct command execution and source inspection in this session; nothing is repackaged from any prior report.

---

## Strict boundaries observed (none violated)

- No application source code modified.
- No Supabase or Vercel settings modified.
- No environment-variable values or credentials exposed (variable names only).
- No commit, push, merge, deploy, or pull request created.
- No `git add .`, `git reset`, `git clean`, or `git stash`.
- All pre-existing untracked files preserved.
- No files deleted, reset, stashed, or cleaned.

---

# 1. Contradictions in the Previous Report

The previous Phase 2 reports (`SCHOLARS_RESOURCE_CENTRE_PHASE2_COMPLETION_REPORT.md` and `SCHOLARS_RESOURCE_CENTRE_PHASE2_FINAL_AUDIT_AND_VERCEL_HANDOFF.md`) make several claims that are contradicted by direct re-execution of the toolchain and inspection of the working tree.

### Contradiction 1 — "Build would succeed on Vercel with Supabase env vars" (no evidence)

The previous report concludes `npx next build` fails only environmentally and "would succeed on Vercel Preview with Supabase env vars configured."

- **Corrected:** No successful build has ever been observed or demonstrated in this session. `npx next build` exits with code 1. The claim that it "would succeed on Vercel" is an **unverified assumption**, not a verified fact. A release-ready branch must demonstrate a successful build under some condition; none has been demonstrated.

### Contradiction 2 — "/resources gracefully degrades when Supabase is unavailable"

The previous report claims `getResourceHomeWithRepositoryContent()` guards Supabase access behind `hasPublicSupabaseConfig()` and "gracefully degrades to local repository content when Supabase is unavailable," so `/resources` would not fail prerendering.

- **Corrected:** The source **does** confirm `getResourceHomeWithRepositoryContent()` is guarded (`lib/resource-center.ts:162-176`), and `hasPublicSupabaseConfig()` returns `false` in this environment because `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY` are absent — so `getResourceHome()` is NOT called and local content is used for the data layer.
- HOWEVER, the `/resources` prerender still fails. The build output shows `/resources/page` failing via the shared server chunk `.next/server/chunks/7495.js`, which calls `createClient()` unconditionally during prerender of the shared page shell. The graceful-degradation guard applies only to `getResourceHome*` data calls, **not** to the whole `/resources` page shell.
- **Correction:** `/resources` does NOT gracefully degrade in this environment — it fails prerender with the same missing-Supabase-credential error as the auth/legal/onboarding pages.

### Contradiction 3 — ".env.local contains placeholders/invalid credentials causing getResourceHome() to call createClient()"

The previous report states `.env.local` "exists ... so `hasPublicSupabaseConfig()` returns true, causing `getResourceHome()` to call `createClient()` during `/resources` prerender" and that the credentials are "placeholders/invalid."

- **Corrected:** FALSE on both counts. `.env.local` contains **only** `VERCEL_OIDC_TOKEN`. It does NOT contain `NEXT_PUBLIC_SUPABASE_URL` or `NEXT_PUBLIC_SUPABASE_ANON_KEY`. Therefore `hasPublicSupabaseConfig()` returns **false**, so `getResourceHome()` is NOT called during `/resources` prerender; local content is used. The claim that credentials are "placeholders/invalid" is unverified — no credential values were inspected or exposed; only the absence of the required variable names was confirmed.

### Contradiction 4 — "No blocking defects"

The previous report's final classification lists "Blocking defects: None."

- **Corrected:** There IS an outstanding release blocker: `next build` cannot complete (exit code 1) because `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY` are absent from `.env.local`. Until a successful build is demonstrated (locally with credentials, or on Vercel Preview with credentials configured), the branch cannot be declared release-ready.

### Contradiction 5 — Phase 2 is ready because unit tests pass

The previous report implies the implementation is release-ready on the strength of passing unit tests and clean TypeScript.

- **Corrected:** Unit tests passing (162/162) and TypeScript being clean (exit 0) are necessary but **not sufficient** for deployment readiness. They do not substitute for a successful production build. `next build` is the gate this branch has not passed.

---

# 2. Corrected TypeScript Results

**Command run (this session):** `npx tsc --noEmit --pretty false`  
**Actual exit code:** 0  
**Diagnostics:** None reported. No output on stdout or stderr.  
**Source-code correctness:** PASS.

**Note on earlier TS6053 errors:** `tsconfig.json` includes `.next/types/**/*.ts` (line 21). Earlier TS6053 errors (`.next/types/app/scholarships/layout.ts`, `settings/layout.ts`, `settings/page.ts` not found) were stale generated-type/build artifacts from an incomplete prior build. Re-running `tsc` now exits 0 because `.next/types/` was regenerated by the (failed) `next build` run. The earlier TS6053s are classified as a resolved generated-type/build-artifact issue, **not** a source-code defect.

---

# 3. Corrected Build Diagnosis

**Command run (this session):** `npx next build`  
**Actual exit code:** 1  
**Result:** BUILD FAILED. 10 prerendering paths encountered errors and were not exported.

**Failing paths (verbatim from build output):**

| # | Route | Output path |
|---|-------|-------------|
| 1 | `/(auth)/login/page` | `/login` |
| 2 | `/(auth)/signup/page` | `/signup` |
| 3 | `/_not-found/page` | `/_not-found` |
| 4 | `/legal/privacy/page` | `/legal/privacy` |
| 5 | `/legal/terms/page` | `/legal/terms` |
| 6 | `/onboarding/page` | `/onboarding` |
| 7 | `/page/` | `/` (home) |
| 8 | `/reset-password/page` | `/reset-password` |
| 9 | `/reset-password/update/page` | `/reset-password/update` |
| 10 | `/resources/page` | `/resources` |

**Root cause (environmental, pre-existing, NOT a Phase 2 source-code defect):**

Every failure is one of two Supabase credential errors, both traceable to `createClient()` reading `process.env.NEXT_PUBLIC_SUPABASE_URL` and `process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY`, both absent from `.env.local`:

- `@supabase/ssr: Your project's URL and API key are required to create a Supabase client!` — stack trace points to shared chunk `.next/server/chunks/7495.js` (calls `createClient()` unconditionally during prerender of the shared shell) and to page chunks (`reset-password/page.js`, `reset-password/update/page.js`, etc.).
- `supabaseUrl is required.` — stack trace points to `.next/server/chunks/8188.js` → `app/o/[id]/page.js` → `app/page.js` (home page).

**Evidence this is environmental, not a Phase 2 defect:**

- Phase 2 modified files (`app/layout.tsx`, `app/resources/page.tsx`, `app/resources/[slug]/page.tsx`, `components/resource-center-interactions.tsx`, `components/resource-center-interactions.test.tsx`, `components/resource-center-search.tsx`) are purely presentational/accessibility (viewport export, 44px chips, rAF throttle, list roles, failure feedback). None introduce Supabase calls, env-var requirements, or server-side data fetching.
- The affected pages (`/login`, `/signup`, `/reset-password`, `/reset-password/update`, `/onboarding`, `/legal/*`, `/_not-found`, `/`, `/resources`) are all pre-existing and untouched by Phase 2.
- `.env.local` is gitignored, not tracked, and contains only `VERCEL_OIDC_TOKEN`. No Supabase URL or anon key names are present.
- `lib/supabase/server.ts:20-37` `createClient()` reads `process.env.NEXT_PUBLIC_SUPABASE_URL!` and `process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!` directly with no guard — it throws when either is absent.

**Classification:** Build verification = FAILED in this codespace. This is a pre-existing environmental issue (missing Supabase credentials), not a Phase 2 code defect. It is an **outstanding release blocker** until a successful `next build` is demonstrated, either locally with valid Supabase credentials or on Vercel Preview with the required env vars configured.

---

# 4. Actual `.env.local` State (names only — no values exposed)

**Tracking/ignore state:** `.env.local` is listed in `.gitignore` (line 4) and is **not tracked** by git (`git check-ignore -v .env.local` confirms it is ignored).

**Required environment-variable names confirmed MISSING from `.env.local`:**

- `NEXT_PUBLIC_SUPABASE_URL` — MISSING
- `NEXT_PUBLIC_SUPABASE_ANON_KEY` — MISSING

**Environment-variable name PRESENT:**

- `VERCEL_OIDC_TOKEN` — present (only)

No secret values were displayed or inspected. Only variable names were enumerated. The absence of the two Supabase names is the direct cause of the build failure in Section 3.

For reference, `.env.example` (tracked example file, no values) declares both `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY` among its expected names, confirming these are required variables the project expects.

---

# 5. Vercel Preview Requirements (verified against official documentation)

Official Vercel documentation consulted (fetched live):

- `https://vercel.com/docs/environment-variables` (last updated 2026-09-17)
- `https://vercel.com/docs/git` (last updated 2026-09-18)

### 5.1 Non-production branch deployments

- Vercel creates a Preview Deployment for pushes to any Git branch that does **not** match the Production Branch (default: `main`).
- All non-`main` branches are, by default, preview branches; each receives its own generated `*.vercel.app` domain.

### 5.2 Pull-request deployments

- After creating a pull request against the production branch, Vercel creates a unique deployment to preview changes.
- On merge to the production branch, Vercel creates a Production Deployment; production is **not** affected by the preview.

### 5.3 Preview-specific and branch-specific environment variables

- Preview environment variables are applied to deployments from any branch that does not match the Production Branch.
- A preview variable can apply to all non-production branches, or to a specific branch. Branch-specific variables override other preview variables with the same name.
- Environment-variable changes apply only to **new** deployments; a running deployment keeps the values it was built with (must redeploy after changes).

### 5.4 Production branch protection

- The Production Branch is configurable in Project Settings → Environments → Production → Branch Tracking. Default is `main` (fallback `master`, then the repo default branch).
- **Verification step:** Confirm `feature/resource-center-public-frontend` is **not** configured as the Production Branch. It must remain a preview-only branch.

### 5.5 What can and cannot be verified from this environment

- **Cannot verify** (no Vercel credentials / no dashboard access): whether the Vercel Git integration is connected, whether `feature/resource-center-public-frontend` is the Production Branch, whether auto-deploy preview branches is enabled, and what Preview env vars are currently configured. These are dashboard-level instructions to verify manually.

---

# 6. Preview Environment Checklist

| # | Check | Required? | Status | Notes |
|---|-------|-----------|--------|-------|
| 1 | `next build` script present in `package.json` | Yes | Met | `"build": "next build"` |
| 2 | `next.config.js` present and valid | Yes | Met | CSP headers, `reactStrictMode: true`, region `dub1` |
| 3 | `vercel.json` present | Yes | Met | Regions `["dub1"]`, cron deadline-check |
| 4 | Branch is NOT the Production Branch | Yes | **Unverified** | Confirm in Vercel dashboard; default Production Branch = `main` |
| 5 | `NEXT_PUBLIC_SUPABASE_URL` configured in Preview env | Yes (for build) | **Missing locally** | `.env.local` lacks it; configure in Vercel Preview settings |
| 6 | `NEXT_PUBLIC_SUPABASE_ANON_KEY` configured in Preview env | Yes (for build) | **Missing locally** | `.env.local` lacks it; configure in Vercel Preview settings |
| 7 | `NEXT_PUBLIC_APP_URL` configured (Preview URL) | Recommended | Fallback exists | Code uses `process.env.NEXT_PUBLIC_APP_URL || "https://www.scholars.com.ng"` |
| 8 | `SUPABASE_SERVICE_ROLE_KEY` NOT present in Preview | Must NOT | — | Server-only; must never be added to Preview env vars |
| 9 | Successful `next build` demonstrated | Yes | **Not met** | Exit code 1 in this codespace; blocker |
| 10 | Real-device mobile verification | Recommended | Not verified | Viewport safe areas, theme color, tap delay, keyboard resize |

### Staging Supabase credentials — recommendation

**Recommendation:** Use a **separate staging Supabase project** for the Vercel Preview environment, with `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY` pointing at the staging project (not production).

**Risks of using production Supabase credentials in Preview:**

1. A Preview deployment is publicly accessible at a `*.vercel.app` URL. The `NEXT_PUBLIC_SUPABASE_ANON_KEY` is designed to be public for client-side Supabase use, but a Preview pointed at production would read (and potentially write to, depending on RLS) production data.
2. Resource Centre public pages perform reads only through `resource_public_*` projection views (Phase 2 adds no write paths). Still, a Preview pointed at production could expose production data to anyone with the preview URL if RLS is misconfigured.
3. Never expose `SUPABASE_SERVICE_ROLE_KEY` (server-only) in any Preview environment variable — it is not `NEXT_PUBLIC_*` and must not be added.

**Safeguards before testing against production data:**

1. Prefer a staging Supabase project with mirrored (non-sensitive) data.
2. If production credentials must be used, confirm RLS on `resource_public_*` views is read-only for the anon role and that no sensitive columns are exposed.
3. Confirm `hasPublicSupabaseConfig()` guard behavior so Preview degrades gracefully if staging is unavailable (see Section 3 correction: the whole `/resources` page shell currently does NOT degrade because chunk `7495.js` calls `createClient()` unconditionally).

---

# 7. Classification of Findings

| Category | Items | Basis |
|----------|-------|-------|
| **Verified facts** | `tsc --noEmit --pretty false` exit 0, clean; `next build` exit 1 with 10 Supabase-credential prerender failures (exact paths listed in Section 3); `.env.local` contains only `VERCEL_OIDC_TOKEN` (Supabase names missing); `.env.local` is gitignored and untracked; 162/162 vitest tests pass; `/resources` does NOT gracefully degrade in this environment (shared chunk `7495.js` calls `createClient()` unconditionally; build output confirms); `getResourceHomeWithRepositoryContent()` IS guarded by `hasPublicSupabaseConfig()` but that guard returns false here; official Vercel Preview/git docs verified | Direct command execution, source inspection, environment-variable name enumeration, documentation fetch |
| **OpenCode-reported results** | All results above were produced by this OpenCode session (tsc, next build, vitest, git, .env.local name enumeration, Vercel docs fetch); none are repackaged from any previous report | Direct execution in this session |
| **Unverified assumptions** | "Build would succeed on Vercel with Supabase env vars" (never demonstrated); production RLS is read-only for anon role; a staging Supabase project exists/is accessible; Vercel Git integration is connected; `feature/resource-center-public-frontend` is not the Production Branch | Not evidenced in this session; require Vercel dashboard / Supabase access |
| **Outstanding release blockers** | (B1) `next build` exit code 1 — cannot complete without `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY`; (B2) No successful build demonstrated under any condition; (B3) `/resources` page shell fails prerender due to unguarded shared `createClient()` call in chunk `7495.js` | Direct `next build` execution |

---

# 8. Final GO / NO-GO Decision

**DECISION: NO-GO**

**Reasons:**

1. `npx next build` exits with code 1. Ten prerendering paths fail, all due to missing `NEXT_PUBLIC_SUPABASE_URL` / `NEXT_PUBLIC_SUPABASE_ANON_KEY`. A release-ready branch must produce a successful build; none has been demonstrated.
2. `.env.local` lacks both required Supabase env-variable names; it contains only `VERCEL_OIDC_TOKEN`. The build cannot succeed locally without credentials (which must not be exposed or fabricated).
3. The claim that `/resources` gracefully degrades when Supabase is unavailable is incorrect for this environment: the page shell fails prerender via an unguarded shared `createClient()` call.
4. Production branch protection and Vercel Preview env-var configuration cannot be verified without Vercel dashboard access; the branch must be confirmed as non-production.
5. Unit tests passing (162/162) and TypeScript being clean (exit 0) are necessary but **not sufficient** for deployment readiness. They do not substitute for a successful production build.

**Conditions to reach GO:**

- (C1) Configure `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY` in Vercel Preview (preferably pointing at a staging Supabase project, not production).
- (C2) Re-run `npx next build` (locally with credentials, or on Vercel Preview) and demonstrate exit code 0 with zero prerendering errors.
- (C3) Confirm `feature/resource-center-public-frontend` is **not** the Production Branch in Vercel project settings.
- (C4) Complete real-device mobile verification (viewport safe areas, theme color, tap delay, keyboard resizing) — recommended before production, optional for Preview.

**Stopping here.** Awaiting explicit approval before any commit, push, merge, or deployment. No application source code, Supabase settings, or Vercel settings were modified in producing this report.

**Report location:** `/workspaces/Scholars/SCHOLARS_RESOURCE_CENTRE_PHASE2_RELEASE_READINESS_CORRECTION.md`
