# Scholars Resource Centre — Phase 2 Release Readiness Correction

**Repository:** ImperioKDB/Scholars
**Working directory:** `/workspaces/Scholars`
**Branch:** `feature/resource-center-public-frontend`
**HEAD commit:** `79456a0` — "feat: accessible mobile Resource Centre navigation + baseline audit report"
**Report date:** Fri Nov 13 2026
**Purpose:** Supplemental corrective audit. Re-verifies release-readiness claims after the latest Updates commit (`bc06fa7358a196a87d5c0eccc009ecfd2ac060aa`) was found to contain no new clarifications — its audit document is identical to the previous version (`c075714a71849618d190323bdff1897a05b2a91b`).

**Strict boundaries observed (none violated):**
- No application source code modified.
- No Supabase or Vercel settings modified.
- No environment-variable values or credentials exposed.
- No commit, push, merge, deploy, or pull request created.
- No `git add .`, `git reset`, `git clean`, or `git stash`.
- All pre-existing untracked files preserved.
- No files deleted, reset, stashed, or cleaned.

---

# 1. Contradictions in the Previous Report

The previous report (`SCHOLARS_RESOURCE_CENTRE_PHASE2_FINAL_AUDIT_AND_VERCEL_HANDOFF.md`) makes several claims that are contradicted by direct inspection of the working tree and re-execution of the build toolchain.

### Contradiction 1 — "Successful TypeScript" vs. un-run claim
The report states `npx tsc --noEmit --pretty false` exits 0 with no errors.
- **Verified:** Re-ran `npx tsc --noEmit --pretty false` → **exit code 0**, no diagnostics, no output. Confirmed clean. This specific claim holds, but it was presented as evidence the codebase is "ready" while ignoring the build failure.

### Contradiction 2 — "Build would succeed on Vercel with Supabase env vars" (no evidence)
The report concludes `npx next build` fails only environmentally and "would succeed on Vercel Preview with Supabase env vars configured."
- **Verified:** Re-ran `npx next build` → **exit code 1**, 10 prerendering paths failed, ALL due to missing Supabase credentials (`@supabase/ssr: Your project's URL and API key are required to create a Supabase client!`).
- **Critical:** No successful build has ever been observed in this session. The claim "would succeed on Vercel" is an **unverified assumption**, not a verified fact. The build has not been shown to pass under any condition.

### Contradiction 3 — "/resources gracefully degrades when Supabase is unavailable"
The report claims `getResourceHomeWithRepositoryContent()` guards Supabase access behind `hasPublicSupabaseConfig()` and "gracefully degrades to local repository content when Supabase is unavailable," so `/resources` would not fail.
- **Verified:** The source confirms `getResourceHomeWithRepositoryContent()` IS guarded (see `lib/resource-center.ts:162-176`), BUT the `/resources` prerender still fails in this codespace because the shared server chunk `7495.js` calls `createClient()` unconditionally during prerender of the login/signup/not-found/onboarding/legal shell that is shared into `/resources`. The failing paths include `/resources/page: /resources`.
- **Correction:** `/resources` does NOT gracefully degrade in this environment — it fails prerender with the same Supabase credential error as every other affected path. The graceful-degradation path applies only to `getResourceHome*` data calls, not to the whole page shell.

### Contradiction 4 — "No blocking defects"
The report's final classification lists "Blocking defects: None."
- **Corrected:** There IS an outstanding release blocker: `next build` cannot complete (exit code 1) because `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY` are absent from `.env.local`. Until a successful build is demonstrated (in this codespace or on Vercel with credentials), the branch cannot be declared release-ready.

### Contradiction 5 — ".env.local contains placeholders/invalid credentials"
The report states `.env.local` "exists ... so `hasPublicSupabaseConfig()` returns true, causing `getResourceHome()` to call `createClient()` during `/resources` prerender. The Supabase credentials in this codespace are placeholders/invalid for the build environment."
- **Verified:** FALSE on both counts. `.env.local` contains **only** `VERCEL_OIDC_TOKEN`. It does NOT contain `NEXT_PUBLIC_SUPABASE_URL` or `NEXT_PUBLIC_SUPABASE_ANON_KEY`. Therefore `hasPublicSupabaseConfig()` returns **false**, so `getResourceHome()` is NOT called during `/resources` prerender; instead local content is used. The failure of `/resources` comes from the shared unguarded `createClient()` call in chunk `7495.js`, not from invalid placeholder credentials being used. The claim that credentials are "placeholders/invalid" is unverified — no credential values were inspected or exposed; only the absence of the required names was confirmed.

---

# 2. Corrected TypeScript Results

**Command run:** `npx tsc --noEmit --pretty false`  
**Actual exit code:** 0  
**Diagnostics:** None reported. No output on stdout or stderr.  
**Source-code correctness:** PASS.

Note: `tsconfig.json` includes `.next/types/**/*.ts` (line 21). The earlier TS6053 errors reported by the previous audit (`.next/types/app/scholarships/layout.ts`, `settings/layout.ts`, `settings/page.ts` not found) were stale generated-type/build artifacts from an incomplete prior build. Re-running `tsc` now exits 0 because `.next/types/` was regenerated by the (failed) `next build` run. The earlier TS6053s are classified as a resolved generated-type/build-artifact issue, not a source-code defect.

---

# 3. Corrected Build Diagnosis

**Command run:** `npx next build`  
**Actual exit code:** 1  
**Result:** BUILD FAILED. 10 prerendering paths encountered errors and were not exported.

**Failing paths (verbatim from build output):**
1. `/(auth)/login/page` → `/login`
2. `/(auth)/signup/page` → `/signup`
3. `/_not-found/page` → `/_not-found`
4. `/legal/privacy/page` → `/legal/privacy`
5. `/legal/terms/page` → `/legal/terms`
6. `/onboarding/page` → `/onboarding`
7. `/page/` → `/`
8. `/reset-password/page` → `/reset-password`
9. `/reset-password/update/page` → `/reset-password/update`
10. `/resources/page` → `/resources`

**Root cause (environmental, pre-existing, NOT a Phase 2 source-code defect):**
Every failure is `@supabase/ssr: Your project's URL and API key are required to create a Supabase client!` — caused by `createClient()` reading `process.env.NEXT_PUBLIC_SUPABASE_URL` and `process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY`, both of which are absent from `.env.local`.

**Evidence this is environmental, not a Phase 2 defect:**
- Phase 2 modified files (`app/layout.tsx`, `app/resources/page.tsx`, `app/resources/[slug]/page.tsx`, `components/resource-center-interactions.tsx`, `components/resource-center-search.tsx`, and their tests) are purely presentational/accessibility (viewport export, 44px chips, rAF throttle, list roles, failure feedback). None introduce Supabase calls, env-var requirements, or server-side data fetching.
- The affected pages (`/login`, `/signup`, `/reset-password`, `/onboarding`, `/legal/*`, `/_not-found`, `/`, `/resources`) are all pre-existing and untouched by Phase 2.
- `.env.local` is gitignored, not tracked, and contains only `VERCEL_OIDC_TOKEN`. No Supabase URL or anon key names are present.

**Classification:** Build verification = PARTIAL / FAILED in this codespace. Cannot proceed to a release decision until a successful `next build` is demonstrated, either locally with valid Supabase credentials or on Vercel Preview with the required env vars configured. **This is an outstanding release blocker.**

---

# 4. Actual `.env.local` State (names only — no values exposed)

**Tracking/ignore state:** `.env.local` is listed in `.gitignore` (line 4) and is **not tracked** by git (`git ls-files .env.local` returns empty; `git check-ignore -v .env.local` confirms it is ignored).

**Required environment-variable names confirmed MISSING from `.env.local`:**
- `NEXT_PUBLIC_SUPABASE_URL` — MISSING
- `NEXT_PUBLIC_SUPABASE_ANON_KEY` — MISSING

**Environment-variable name PRESENT:**
- `VERCEL_OIDC_TOKEN` — present (only)

No secret values were displayed or inspected. Only variable names were enumerated. The absence of the two Supabase names is the direct cause of the build failure in Section 3.

---

# 5. Vercel Preview Requirements (verified against official documentation)

Official Vercel documentation consulted: `https://vercel.com/docs/environment-variables` and `https://vercel.com/docs/git` (last updated 2026-09-17 / 2026-09-18).

### 5.1 Non-production branch deployments
- Vercel creates a Preview Deployment for pushes to any Git branch that does **not** match the Production Branch (default: `main`).
- All non-`main` branches are, by default, preview branches; each receives its own generated `*.vercel.app` domain.

### 5.2 Pull-request deployments
- After creating a PR against the production branch, Vercel creates a unique deployment to preview changes.
- On merge to the production branch, Vercel creates a Production Deployment; production is NOT affected by the preview.

### 5.3 Preview-specific and branch-specific environment variables
- Preview environment variables are applied to deployments from any branch that does not match the Production Branch.
- A preview variable can apply to all non-production branches, or to a specific branch. Branch-specific variables override other preview variables with the same name.
- Environment-variable changes apply only to **new** deployments; a running deployment keeps the values it was built with (must redeploy after changes).

### 5.4 Production branch protection
- The Production Branch is configurable in Project Settings → Environments → Production → Branch Tracking. Default is `main` (fallback `master`, then the repo default branch).
- **Verification step:** Confirm `feature/resource-center-public-frontend` is **not** configured as the Production Branch. It must remain a preview-only branch.

### 5.5 What can and cannot be verified from this environment
- **Cannot verify** (no Vercel credentials / no dashboard access): whether the Vercel Git integration is connected, whether `feature/resource-center-public-frontend` is the Production Branch, whether auto-deploy preview branches is enabled, and what Preview env vars are currently configured. These are dashboard-level instructions to verify.

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
| **Verified facts** | `tsc --noEmit` exit 0, clean; `next build` exit 1 with 10 Supabase-credential prerender failures; `.env.local` contains only `VERCEL_OIDC_TOKEN` (Supabase names missing); `.env.local` is gitignored and untracked; 162/162 vitest tests pass; `/resources` does NOT gracefully degrade in this environment (shared chunk `7495.js` calls `createClient()` unconditionally); official Vercel Preview docs verified | Direct command execution, source inspection, environment-variable name enumeration, documentation fetch |
| **OpenCode-reported results** | All results above were produced by this OpenCode session (tsc, next build, vitest, git, .env.local name enumeration); none are repackaged from the previous report | Direct execution in this session |
| **Unverified assumptions** | "Build would succeed on Vercel with Supabase env vars" (never demonstrated); production RLS is read-only for anon role; staging Supabase project exists/is accessible; Vercel Git integration connected; `feature/resource-center-public-frontend` is not the Production Branch | Not evidenced in this session; require Vercel dashboard/Supabase access |
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
