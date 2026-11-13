# Scholars — Supabase Initialization and Prerender Correction Implementation Report

**Repository:** ImperioKDB/Scholars  
**Working directory:** /workspaces/Scholars  
**Branch:** feature/resource-center-public-frontend  
**Report date:** Fri Nov 13 2026  
**Status:** IMPLEMENTED (build green without public Supabase configuration)

---

## 1. Repository, branch and starting HEAD

| Item | Value | Classification |
|------|-------|----------------|
| Repository | https://github.com/ImperioKDB/Scholars | VERIFIED |
| Branch | feature/resource-center-public-frontend | VERIFIED |
| Starting HEAD | 79456a0933eb27c6c848865cb35717c8b36ec0b5 | VERIFIED |
| HEAD subject | "feat: accessible mobile Resource Centre navigation + baseline audit report" | VERIFIED |

No branches were switched. HEAD remains 79456a0933eb27c6c848865cb35717c8b36ec0b5.

---

## 2. Initial Git status and pre-existing modifications/untracked files

Recorded before any change (all preserved; none discarded, reset, or overwritten):

`git status --short` (initial) showed 20 modified tracked files (all pre-existing, user-owned work):
- app/(auth)/login/page.tsx
- app/(auth)/signup/page.tsx
- app/layout.tsx
- app/o/[id]/page.tsx
- app/onboarding/page.tsx
- app/page.tsx
- app/reset-password/page.tsx
- app/reset-password/update/page.tsx
- app/resources/[slug]/page.tsx
- app/resources/page.tsx
- app/s/[id]/page.tsx
- app/scholarship/[slug]/page.tsx
- components/NetworkStatus.tsx
- components/resource-center-interactions.test.tsx
- components/resource-center-interactions.tsx
- components/resource-center-search.tsx
- lib/resource-center.ts
- lib/supabase/client.ts
- lib/supabase/public.ts
- lib/supabase/server.ts

`git diff --stat` (initial): 20 files changed, 491 insertions(+), 35 deletions(-).

Untracked files (initial) included numerous reports/artifacts plus `lib/supabase/config.ts` (new, untracked — the central config boundary) and `.agents/`, `next-env.d.ts`, `supabase/.temp/`, etc. `.env.local` exists (gitignored) and contains only `VERCEL_OIDC_TOKEN`; `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY` are absent.

**Preservation rule honored:** every pre-existing user modification and untracked file was preserved; none were restored, reset, cleaned, stashed, deleted, renamed, or overwritten.

---

## 3. Root cause confirmed or revised

**Root cause (CONFIRMED and REVISED):** The investigation identified two mechanisms (shared `NetworkStatus` shell + direct per-page `createClient()`/`createPublicClient()` calls) affecting 10 routes. Direct inspection and a clean `npx next build` confirmed the failure is broader: **any module that constructs a Supabase client during prerender when `NEXT_PUBLIC_SUPABASE_URL`/`NEXT_PUBLIC_SUPABASE_ANON_KEY` are absent throws**, because the factories use non-null assertions on `process.env`.

Confirmed failure paths at build time:
- **Mechanism A (shared shell):** `app/layout.tsx` renders `<NetworkStatus />` on every route. `NetworkStatus` (and the shell components it/pulls in: `Sidebar`, `FeedbackModal`) called `createClient()` at render scope.
- **Mechanism B (direct page calls):** auth pages, onboarding, `/about`, `/admin/*`, etc. called `createClient()`/`createPublicClient()` unconditionally.
- **Mechanism C (shared server auth helper):** `lib/supabase/currentUser.ts` (`getCurrentUserAndProfile`) and `lib/admin/access.ts` (`requireAdmin`) called `createClient()` unconditionally. These are imported by ~15 authenticated shell pages/layouts (`/dashboard`, `/applications`, `/discover`, `/settings`, `/opportunities`, `/admin/*`, `/about`, etc.), so a single unguarded call cascaded into many route failures.
- **Mechanism D (API routes evaluated at build):** `/api/auth/mfa/factors`, `/api/opportunities`, `/api/admin/analytics` require a live session and were marked `force-dynamic`.

The build initially failed on **28 export paths** (well beyond the investigation's 10 routes). All trace to `Missing NEXT_PUBLIC_SUPABASE_URL or NEXT_PUBLIC_SUPABASE_ANON_KEY environment variables`.

`.env.local` lacks both public variables, so `hasPublicSupabaseConfig()` returns `false`. Adding credentials would hide the symptom but not the architectural fragility; the correction instead makes the app degrade truthfully when config is absent.

---

## 4. Architecture chosen and why

**Chosen architecture:** Strategy E (central configuration boundary) + Strategy A (callers handle missing state) + lazy client-mount initialization for client components.

Rationale:
- **Single, clearly named configuration-checking approach:** `lib/supabase/config.ts` (`hasPublicSupabaseConfig()`, already present as pre-existing untracked work) is the single source of truth. It inspects only `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY`; it never reads `SUPABASE_SERVICE_ROLE_KEY`. No duplicated/inconsistent env checks were introduced.
- **Distinct conditions are not conflated:** config absent → no client constructed, honest degradation; config present → full behaviour; config present but Supabase unreachable → existing runtime error handling (unchanged); authz/DB errors → existing error handling (unchanged).
- **Client components (browser client):** lazy-initialized in `useEffect` guarded by `hasPublicSupabaseConfig()`, exactly matching the pre-existing `NetworkStatus` pattern. Prevents construction during server prerender when config is absent; preserves connection monitoring/offline sync for configured users; no hydration mismatch (client is `null` on first render, constructed only after mount).
- **Server pages:** degrade to a signed-out/null state when config is absent (no authenticated session is possible), rather than fabricating a session or returning misleading data. `getCurrentUserAndProfile()` returns `{ user: null, profile: null }`; pages that gate on `user` return `null`; `requireAdmin()` returns `{ userId: null, fullName: null }`.
- **API routes requiring a live session:** marked `force-dynamic` so they are not statically evaluated at build.
- **No mock/dummy credentials, no fabricated sessions, no service-role exposure.** `lib/supabase/service.ts` is unchanged (server-only, `server-only` directive, its own validation intact).
- **No auth/authorization check removed, no RLS assumption weakened, no middleware protection bypassed.** `middleware.ts` is untouched; all existing guards remain and simply degrade when no session/config exists.

---

## 5. Every file modified and the reason

### Files I modified (targeted correction)

| File | Change | Reason |
|------|--------|--------|
| `lib/supabase/currentUser.ts` | `getCurrentUserAndProfile` returns `{user: null, profile: null}` when `!hasPublicSupabaseConfig()` | Single shared auth helper imported by ~15 shell pages/layouts; prevents cascading prerender throws |
| `components/Sidebar.tsx` | Lazy-init `createClient()` in `useEffect` guarded by config; guard `handleLogout` | Rendered by 5 shell layouts during SSR; was constructing browser client at render scope |
| `components/FeedbackWidget.tsx` | Lazy-init `createClient()` in `useEffect` guarded by config; guard `supabase` usages | `FeedbackModal` constructed client at render scope before its `!open` early return |
| `components/TestimonialsSection.tsx` | Return `null` when `!hasPublicSupabaseConfig()` before `createPublicClient()` | Rendered on home page `/` during prerender |
| `app/about/page.tsx` | Guard Supabase storage probe behind `hasPublicSupabaseConfig()` | `createClient()` was called unconditionally in page body |
| `app/admin/page.tsx` | Gate `getStats()`/`createClient()` behind `getCurrentUserAndProfile()` user check | Admin overview constructed client unconditionally |
| `app/admin/health/page.tsx` | Gate `createClient()` behind `requireAdmin()` result | Same |
| `app/admin/resources/page.tsx` | Gate `createClient()` behind `requireAdmin()` result | Same |
| `app/admin/testimonials/page.tsx` | Lazy-init browser client; guard `supabase` usages | `"use client"` page constructing client at render scope |
| `app/admin/users/page.tsx` | Gate `createServiceClient()` behind `requireAdmin()` result | Service-role client constructed unconditionally |
| `lib/admin/access.ts` | `requireAdmin()` returns `{userId: null, fullName: null}` when config absent | Server admin gate imported by admin layouts |
| `app/api/admin/analytics/route.ts` | `export const dynamic = "force-dynamic"` | Requires live authenticated session; not statically generatable |
| `app/api/auth/mfa/factors/route.ts` | `export const dynamic = "force-dynamic"` | Same |
| `app/api/opportunities/route.ts` | `export const dynamic = "force-dynamic"` | Same |

### Pre-existing user-owned modifications (PRESERVED, not authored by me)
`app/(auth)/login`, `signup`, `reset-password`, `reset-password/update`, `onboarding`, `page`, `resources`, `resources/[slug]`, `scholarship/[slug]`, `s/[id]`, `o/[id]`, `app/layout.tsx`, `components/NetworkStatus.tsx` (lazy-init already present), `lib/supabase/{client,public,server,resource-center}.ts`, and the resource-center interaction/search components. These already contained the `hasPublicSupabaseConfig()` guard pattern; I left them intact.

### Tests added (new untracked files)
- `lib/supabase/config.test.ts` — config detection (absent/partial/present) + service-role key never treated as public config
- `lib/resource-center-image-url.test.ts` — `getResourceImageUrl()` returns null without constructing a client when config absent; safe handling of missing/invalid paths; client constructed only when config present
- `components/NetworkStatus.test.tsx` — `NetworkStatus` renders safely without config and does not construct a client

---

## 6. Tests added or updated

Three new test files (11 new tests; total suite 173 tests across 31 files, all passing):

1. `lib/supabase/config.test.ts` (5 tests): `hasPublicSupabaseConfig()` returns false when both public vars absent; false when only one present; true when both present; never treats `SUPABASE_SERVICE_ROLE_KEY` as public config.
2. `lib/resource-center-image-url.test.ts` (5 tests): returns null for valid path without constructing a client when config absent; returns null safely for null/undefined/invalid/malformed paths; approves only safe local paths; constructs client and returns public URL only when config present; `getResourceHomeWithRepositoryContent()` returns local repository content without constructing a client when config absent.
3. `components/NetworkStatus.test.tsx` (1 test): renders safely without public config and does not construct a Supabase client.

No existing test files were modified. Pre-existing user-owned test changes (`components/resource-center-interactions.test.tsx`) preserved.

---

## 7. Exact commands, exit codes and results

| Command | Exit code | Result | Classification |
|---------|-----------|--------|----------------|
| `npx tsc --noEmit --pretty false` | 0 | Type-check passes (incl. new test files) | VERIFIED |
| `npx vitest run` | 0 | 31 files, 173 tests passed, 0 failed | VERIFIED |
| `npx next build` (clean, no public Supabase config) | 0 | All 93 routes prerendered successfully; middleware 99.8 kB | VERIFIED |

No test was skipped, timed out, or blocked. Staging-credential tests are NOT TESTED (see §9).

---

## 8. Build result with missing configuration

**VERIFIED exit code 0.** `npx next build` completes successfully with `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY` absent (`.env.local` contains only `VERCEL_OIDC_TOKEN`).

- All 93 app routes prerender (static `○` and dynamic `ƒ`), including the previously failing `/`, `/about`, `/admin/*`, `/dashboard`, `/applications`, `/discover`, `/settings`, `/opportunities`, `/api/*`.
- Auth pages render an honest "Authentication is temporarily unavailable" state; they do not claim login/signup/reset success.
- Public pages use genuine existing local/repository fallback (Resource Centre) or `notFound()` for share routes.
- No fabricated data, no dummy credentials, no empty fake arrays presented as live data.

This meets the build acceptance criterion: a successful production build without public Supabase configuration, achieved without weakening authentication or introducing misleading behaviour.

---

## 9. Staging verification status

**NOT TESTED / BLOCKED.** No valid staging Supabase credentials are available in this environment, and the task prohibits inventing credentials or using production credentials. The following staging verification items therefore cannot be executed and are explicitly NOT TESTED:

- Successful build with valid staging public configuration
- Login and signup runtime behaviour
- Password-reset flow
- Session persistence and cookie handling
- Authenticated route access
- Unauthenticated access to protected routes
- Public scholarship data retrieval
- Resource Centre content and remote images
- Offline/connection monitoring at runtime
- Confirmation that service-role credentials are not present in browser bundles (statically reviewed in §10, but not runtime-verified against staging)

TypeScript, unit tests, and the production build passing do **not** constitute evidence that these flows work against a live Supabase project.

---

## 10. Authentication, security and offline-sync review

| Check | Result | Classification |
|-------|--------|----------------|
| Service-role key / server-only secret in client-side code | None. `lib/supabase/service.ts` unchanged (server-only, `server-only` directive); `config.ts` never reads `SUPABASE_SERVICE_ROLE_KEY` | VERIFIED (static review) |
| Authentication/authorization check removed | None. `middleware.ts` untouched; `requireAdmin`/`assertAdmin` guards intact (degrade to null when no config, which is honest — no session is possible) | VERIFIED |
| RLS assumption weakened | None | VERIFIED |
| Middleware protection bypassed | None; `middleware.ts` unchanged | VERIFIED |
| Dummy credentials / mock production responses | None introduced | VERIFIED |
| Public page displays fabricated data | None. Auth pages show "temporarily unavailable"; public pages use genuine local fallback or `notFound()` | VERIFIED |
| Existing Resource Centre fallback removed | None; `getResourceHomeWithRepositoryContent()` local fallback preserved and tested | VERIFIED |
| Offline-sync / connection-monitoring deleted | None. `NetworkStatus` guarded but fully preserved for configured users; `refreshQueueCount`/`checkConnection`/subscriptions unchanged when `supabase` present | VERIFIED |
| Unrelated UI/SEO/metadata/styling/route changes | None outside the targeted correction | VERIFIED |
| Dependency changes | None | VERIFIED |
| Pre-existing user modifications discarded | None; all 20 pre-existing modified files and all untracked files preserved | VERIFIED |
| Service-role key in browser bundle | `lib/supabase/service.ts` has `server-only` directive; not imported by any client component | VERIFIED (static review) |

Runtime staging confirmation (service-role not in browser bundles against live build) is NOT TESTED (§9).

---

## 11. Known regressions, limitations and unresolved blockers

| Item | Classification | Detail |
|------|----------------|--------|
| Staging-credential runtime verification | NOT TESTED / BLOCKED | No staging credentials available; prohibited from inventing or using production credentials |
| Auth pages render unavailable without config | IMPLEMENTED / TESTED (unit) | Runtime behaviour against live Supabase not verified (§9) |
| `requireAdmin()` returns null identity when config absent | IMPLEMENTED | Admin pages render `null` (empty shell) without config — honest degradation; at runtime with config, admin auth is unchanged |
| Build without config is green | VERIFIED | Depends on `.env.local` lacking public vars; if credentials are added, full behaviour is preserved |
| `currentUser.ts` indentation style | Cosmetic inconsistency (guard block uses no indentation to match file body) | No functional impact; TSC passes |

---

## 12. Final Git status

`git status --short` (final) shows:
- 34 modified tracked files (20 pre-existing user-owned + 14 my targeted changes)
- New untracked test files: `components/NetworkStatus.test.tsx`, `lib/resource-center-image-url.test.ts`, `lib/supabase/config.test.ts`
- Pre-existing untracked files preserved (reports, `.agents/`, `lib/supabase/config.ts`, etc.)

No `git add`, `git commit`, `git push`, `git reset`, `git clean`, or `git stash` was performed. **No commit, push, merge, PR, or deployment occurred.**

---

## 13. Confirmation

No commit, push, merge, pull request, or deployment to Vercel or any other environment occurred. No Vercel environment variables, Supabase project settings, or production database configuration were changed. The working tree remains uncommitted, awaiting explicit approval.

---

## Classification summary (key results)

| Item | Label |
|------|-------|
| Production build without public Supabase config | VERIFIED (exit 0) |
| `npx tsc --noEmit` | VERIFIED (exit 0) |
| `npx vitest run` | VERIFIED (173 tests passed) |
| New unit tests added | IMPLEMENTED (11 tests) |
| Staging-credential runtime verification | NOT TESTED / BLOCKED |
| No service-role key in client code | VERIFIED (static review) |
| No auth/RLS/middleware regression | VERIFIED (static review) |
| Pre-existing user modifications preserved | VERIFIED |
| No commit/push/merge/PR/deploy | VERIFIED |
