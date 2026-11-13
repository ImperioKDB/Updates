# Scholars — Supabase Correction: Independent Source-Diff and Authorization Audit

**Repository:** ImperioKDB/Scholars  
**Working directory:** /workspaces/Scholars  
**Branch:** feature/resource-center-public-frontend  
**HEAD:** 79456a0933eb27c6c848865cb35717c8b36ec0b5  
**Audit type:** READ-ONLY (no files modified)  
**Report date:** Fri Nov 13 2026  
**Decision:** CONDITIONAL PASS (see Final Decision)

---

## 1. Repository state and HEAD

| Item | Value | Verified via |
|------|-------|--------------|
| `pwd` | /workspaces/Scholars | `pwd` |
| Toplevel | /workspaces/Scholars | `git rev-parse --show-toplevel` |
| Branch | feature/resource-center-public-frontend | `git branch --show-current` |
| HEAD | 79456a0933eb27c6c848865cb35717c8b36ec0b5 | `git rev-parse HEAD` |
| Working tree | Uncommitted (34 modified, many untracked) | `git status --short` |
| Commit made on Scholars? | No | HEAD unchanged; no `git commit` performed |

**HEAD matches expected starting HEAD exactly.** Branch matches expected. No commit/push/merge/deploy performed on Scholars. All 34 modified tracked files remain uncommitted.

---

## 2. Actual source-diff inventory

### 34 modified tracked files

**Pre-existing user-owned modifications (not authored by this implementation):**
`app/(auth)/login/page.tsx`, `app/(auth)/signup/page.tsx`, `app/layout.tsx`, `app/o/[id]/page.tsx`, `app/onboarding/page.tsx`, `app/page.tsx`, `app/reset-password/page.tsx`, `app/reset-password/update/page.tsx`, `app/resources/[slug]/page.tsx`, `app/resources/page.tsx`, `app/s/[id]/page.tsx`, `app/scholarship/[slug]/page.tsx`, `components/NetworkStatus.tsx`, `components/resource-center-interactions.test.tsx`, `components/resource-center-interactions.tsx`, `components/resource-center-search.tsx`, `lib/resource-center.ts`, `lib/supabase/client.ts`, `lib/supabase/public.ts`, `lib/supabase/server.ts`.

These already contained the `hasPublicSupabaseConfig()` guard pattern (centralized config in `lib/supabase/config.ts`, lazy client initialization in `NetworkStatus`, guards in auth pages, `getResourceImageUrl` guard). Preserved intact.

**Implementation changes (14 files):**

| File | What changed | Correctness | Existing functionality preserved? | New regression possible? |
|------|-------------|-------------|-----------------------------------|--------------------------|
| `lib/supabase/currentUser.ts` | `getCurrentUserAndProfile()` returns `{user: null, profile: null}` when `!hasPublicSupabaseConfig()` | Yes — single boundary | Yes — full behavior when config present | No |
| `components/Sidebar.tsx` | Lazy-init browser client in `useEffect` guarded by config; guard `handleLogout` | Yes | Yes — client constructed after mount when configured | No |
| `components/FeedbackWidget.tsx` | Lazy-init `FeedbackModal` client in `useEffect`; guard `supabase` in email prefill | Yes | Yes — effect only runs when configured | No |
| `components/TestimonialsSection.tsx` | Return `null` when config absent before `createPublicClient()` | Yes | Yes — reads testimonials when configured | No |
| `app/about/page.tsx` | Guard Supabase storage probe behind `hasPublicSupabaseConfig()` | Yes | Yes — probe runs when configured | No |
| `app/admin/page.tsx` | Gate `getStats()`/`createClient()` behind `getCurrentUserAndProfile()` user check | Yes | Yes — stats load when user exists | No |
| `app/admin/health/page.tsx` | Gate `createClient()` behind `requireAdmin()` result (`!admin.userId` → return null) | Yes | Yes — health check runs when admin | No |
| `app/admin/resources/page.tsx` | Gate `createClient()` behind `requireAdmin()` result | Yes | Yes | No |
| `app/admin/testimonials/page.tsx` | Lazy-init browser client; guard `supabase` in `handlePhoto`/`doRemove` | Yes | Yes | No |
| `app/admin/users/page.tsx` | Gate `createServiceClient()` behind `requireAdmin()` result | Yes | Yes — service client only after admin check | No |
| `lib/admin/access.ts` | `requireAdmin()` returns `{userId: null, fullName: null}` when config absent | Yes | Yes — normal admin gate when configured | No |
| `app/api/admin/analytics/route.ts` | `export const dynamic = "force-dynamic"` | Yes | N/A (route not statically generated) | No |
| `app/api/auth/mfa/factors/route.ts` | `export const dynamic = "force-dynamic"` | Yes | N/A | No |
| `app/api/opportunities/route.ts` | `export const dynamic = "force-dynamic"` | Yes | N/A | No |

**Minor style observation:** `lib/supabase/currentUser.ts` guard block is at column 0 (no indentation), inconsistent with surrounding codebase style (2-space indent), but functionally correct. Cosmetic only.

### New untracked test files
- `lib/supabase/config.test.ts` (5 tests)
- `lib/resource-center-image-url.test.ts` (5 tests)
- `components/NetworkStatus.test.tsx` (1 test)

### Key files NOT modified (pre-existing, inspected for completeness)
`lib/supabase/config.ts` — single source of truth; only checks `NEXT_PUBLIC_SUPABASE_URL` + `NEXT_PUBLIC_SUPABASE_ANON_KEY`; never reads `SUPABASE_SERVICE_ROLE_KEY`.  
`lib/supabase/service.ts` — unchanged, `server-only` directive, own validation (URL + service role key).  
`lib/resource-center.ts` — `getResourceImageUrl()` guarded (pre-existing); local `hasPublicSupabaseConfig()` removed in favor of centralized import (pre-existing).  
`lib/admin/guard.ts` — `assertAdmin()` unchanged; properly checks auth + admin role + AAL2.  
`middleware.ts` — unchanged.

---

## 3. Admin authorization call-path analysis

### Entry point | Authorization function | Null identity handling | Privileged operation | Result

| Entry point | Auth function | Null identity handling | Privileged operation | Result |
|-------------|-----------------|----------------------|---------------------|--------|
| `app/admin/layout.tsx` | `requireAdmin()` | Return value destructured but **not checked**; `fullName` null → renders shell | None in layout itself (shell only); children check separately | Layout renders empty shell; no data exposed |
| `app/admin/page.tsx` | `getCurrentUserAndProfile()` | `if (!user) return null` | `getStats()` → `createClient()` | Denied (returns null) |
| `app/admin/health/page.tsx` | `requireAdmin()` | `if (!admin.userId) return null` | `createClient()` → scholarships read | Denied (returns null) |
| `app/admin/resources/page.tsx` | `requireAdmin()` | `if (!admin.userId) return null` | `createClient()` → resource_articles read | Denied (returns null) |
| `app/admin/users/page.tsx` | `requireAdmin()` | `if (!admin.userId) return null` | `createServiceClient()` → profiles + auth.admin | Denied (returns null **before** service client) |
| `app/admin/testimonials/page.tsx` | Lazy-init client (no server auth) | `supabase` null → early return in handlers | Storage read/write (client-side, after mount) | Degraded (no-op when not configured) |
| `app/admin/community-invitations/page.tsx` | `requireAdmin({ requireFounder: true })` | **Return value not checked**; proceeds to `getCommunityInvitationSummary()` | `createServiceClient()` inside summary (throws if config missing) | Fails closed (service client throws) |
| `app/admin/analytics/page.tsx` | `requireAdmin()` | **Return value not checked**; proceeds to `createClient()` | `createClient()` throws if config missing | Fails closed (client throws) |
| API routes (admin/*) | `assertAdmin(supabase)` | `assertAdmin` returns 401/403 response; caller checks `guard.ok` | DB/service operations | Denied (401/403) |

### Critical questions answered

**1. When public Supabase configuration is missing, can `requireAdmin()` returning a null identity accidentally allow execution to continue?**

In some callers, execution *does* continue (`app/admin/layout.tsx`, `app/admin/analytics/page.tsx`, `app/admin/community-invitations/page.tsx` do not check the return value), BUT:
- `app/admin/layout.tsx`: Renders shell only; no data queried; child pages all check or throw. **No privilege escalation.**
- `app/admin/analytics/page.tsx`: Proceeds to `createClient()` which **throws** when config missing. **Fails closed.**
- `app/admin/community-invitations/page.tsx`: Proceeds to `getCommunityInvitationSummary()` → `createServiceClient()` which **throws** when config missing. **Fails closed.**

**2. Does every admin page explicitly deny access when `userId` is null?**

The four pages that construct privileged clients (`admin/page`, `admin/health`, `admin/resources`, `admin/users`) all explicitly check `!admin.userId`/`!user` and return null before constructing any client. `admin/testimonials` is client-only (no server privileged operation). `admin/community-invitations` and `admin/analytics` rely on the subsequent `createClient()`/`createServiceClient()` throw to fail closed. `admin/layout` renders shell only. **No page exposes privileged data with a null identity.**

**3. Can any caller construct or use a service-role client before confirming admin authorization?**

No. `app/admin/users/page.tsx` checks `!admin.userId` **before** `createServiceClient()`. API routes that use `createServiceClient()` (`active-users`, `reengagement/enroll`, `reengagement/summary`, `discovery/operations`) all call `assertAdmin()` first. **No service-role client is constructed before admin authorization.**

**4. Can an unauthenticated user reach privileged data or operations?**

No. All privileged server operations are gated by `requireAdmin()`/`assertAdmin()` + null check, or fail closed via `createClient()`/`createServiceClient()` throw when config is missing. When config is present, existing auth + admin role checks are fully intact.

**5. Does the admin API layer independently enforce authorization?**

Yes. All `/api/admin/*` routes use `assertAdmin()` from `lib/admin/guard.ts`, which checks `supabase.auth.getUser()` (401 if no user), `profiles.is_admin === true` (403 if not admin), founder check (403), and AAL2/MFA check (403). Independent of middleware.

**6. Are existing redirects, thrown authorization errors, and role checks preserved?**

Yes. `lib/admin/guard.ts` unchanged. `requireAdmin()` still calls `redirect()` for non-admin/founder when config is present. All 401/403 responses preserved.

**7. Are there paths where an error is swallowed and treated as successful authorization?**

No. `assertAdmin()` returns explicit `{ok: false, response}` objects; all callers check `guard.ok` or `admin.userId`. No swallowed errors treated as success.

**No CRITICAL fail-open identified.** Authorization is safe.

---

## 4. Authentication and Supabase client audit

### Client factory behavior when config missing

| Factory | Behavior when config absent | Behavior when config present |
|---------|----------------------------|------------------------------|
| `lib/supabase/client.ts` `createClient()` (browser) | Throws clear error | Constructs browser client with cookie domain |
| `lib/supabase/server.ts` `createClient()` (server) | Throws clear error | Constructs server client with cookie handling |
| `lib/supabase/public.ts` `createPublicClient()` | Throws clear error | Constructs anon-key public client |
| `lib/supabase/service.ts` `createServiceClient()` | Throws (own validation: URL + service role key) | Constructs service-role client (server-only) |

**Verification:**
- Missing configuration distinguished from network failure: **Yes** (config check is separate from runtime network errors).
- Missing configuration not silently treated as successful authentication: **Yes** (auth pages render "temporarily unavailable"; no session fabricated).
- Valid configuration preserves normal authentication: **Yes** (all guards pass through to normal flow when config present).
- Session and cookie handling intact: **Yes** (`lib/supabase/server.ts` cookie handling unchanged; `middleware.ts` unchanged).
- Password reset/signup not falsely reported as successful: **Yes** (auth pages return early with unavailable message).
- Server components do not construct browser clients: **Yes** (server pages use `createClient()` from `server.ts`; browser `createClient()` from `client.ts` only in `"use client"` components).
- Client components do not construct clients during prerender: **Yes** (all `"use client"` components lazy-init in `useEffect` after mount).
- Public clients retain intended public/RLS behavior: **Yes** (`public.ts` unchanged except guard; RLS assumptions intact).
- Service-role access remains server-only: **Yes** (`server-only` directive in `service.ts`; never imported by client components).

### Remaining unsafe initialization paths (pre-existing, not introduced by this change)

- `app/community/contributors/[profileId]/page.tsx:24`: `const supabase = await createClient()` — unguarded, but this is a **dynamic SSR route** (no `generateStaticParams`, not prerendered at build). Fails closed at runtime if config missing. Pre-existing, not a regression.
- `lib/supabase/service.ts` `createServiceClient()` uses its own validation (URL + service role key) rather than `hasPublicSupabaseConfig()`. Pre-existing, unchanged per task restriction ("Do not weaken its existing validation"). Not a regression.

---

## 5. Client-component regression audit

| Component | Client init timing | Null client handling | Hydration mismatch? | Subscription/event leaks? | Offline sync preserved? | Logout/feedback fail safely? |
|-----------|-------------------|---------------------|---------------------|--------------------------|------------------------|------------------------------|
| `components/NetworkStatus.tsx` | `useEffect` after mount, guarded by config | `refreshQueueCount`/`checkConnection`/subscription effect all early-return when `!supabase` | No (client null on first render, constructed after mount) | No — cleanup unsubscribe/removeEventListener preserved | Yes — full monitoring when configured | N/A (no logout) |
| `components/Sidebar.tsx` | `useEffect` after mount, guarded by config | `handleLogout` returns early if `!supabase` | No | No new listeners added | N/A | Yes — `if (!supabase) return` |
| `components/FeedbackWidget.tsx` (`FeedbackModal`) | `useEffect` after mount, guarded by config | Email prefill guarded by `if (!email && supabase)` | No | No new listeners | N/A | Yes — submit uses fetch, not supabase |
| `components/TestimonialsSection.tsx` | Server component; returns `null` when config absent | N/A (no client) | No | N/A | N/A | N/A |
| `app/admin/testimonials/page.tsx` | `useEffect` after mount, guarded by config | `handlePhoto`/`doRemove` return early if `!supabase` | No | No new listeners | N/A | Yes — photo upload guarded |

**Missing tests identified:**
- No test for `Sidebar.tsx` lazy init or `handleLogout` null guard.
- No test for `FeedbackWidget.tsx` lazy init or null `supabase` guard.
- No test for `TestimonialsSection.tsx` config-absent rendering.
- No test for `app/admin/testimonials/page.tsx` lazy init or null guard.

These are **inspected but not tested** (per audit restriction: do not add tests).

---

## 6. API route audit

| Route | `force-dynamic`? | Auth required? | Admin enforced? | Missing config behavior | Privileged data exposed? |
|-------|-----------------|----------------|-----------------|------------------------|-------------------------|
| `app/api/admin/analytics/route.ts` | Yes | Yes (`assertAdmin`) | Yes | Fails closed (client/server throws) | No |
| `app/api/auth/mfa/factors/route.ts` | Yes | Yes (`createClient` + `getUser`) | N/A (user endpoint) | Fails closed (client throws) | No |
| `app/api/opportunities/route.ts` | Yes | Yes (`createClient` + `getUser` + `authFailureResponse`) | N/A | Fails closed (client throws) | No |

**Verification:**
- `force-dynamic` appropriate: **Yes** — all three require a live authenticated session and cannot be meaningfully statically generated.
- Authentication still required where intended: **Yes** — all three call `createClient()` + `auth.getUser()` (and `assertAdmin` for admin analytics).
- Admin authorization enforced independently: **Yes** — `/api/admin/analytics` uses `assertAdmin()`.
- Missing configuration produces honest error: **Yes** — `createClient()` throws; Next.js returns prerender/error response, not fabricated data.
- No route publicly accessible merely to make build pass: **Yes** — all three retain auth checks; `force-dynamic` only prevents static evaluation, not auth.

**Related API routes inspected (unchanged, pre-existing):**
- All `/api/admin/*` routes use `assertAdmin()` — independent enforcement preserved.
- `createServiceClient()` callers (`active-users`, `reengagement/*`, `discovery/operations`, cron, github integrations) — all check admin first or are system jobs. No service-role exposure to client.

---

## 7. Test coverage matrix

| Behavior | Tested? | Evidence |
|----------|---------|----------|
| `hasPublicSupabaseConfig()` missing variables | ✅ Tested | `lib/supabase/config.test.ts` |
| `hasPublicSupabaseConfig()` partial variables | ✅ Tested | `lib/supabase/config.test.ts` |
| `hasPublicSupabaseConfig()` both present | ✅ Tested | `lib/supabase/config.test.ts` |
| Service-role key not treated as public config | ✅ Tested | `lib/supabase/config.test.ts` |
| `getResourceImageUrl()` no client when config absent | ✅ Tested | `lib/resource-center-image-url.test.ts` |
| `getResourceImageUrl()` safe null/invalid paths | ✅ Tested | `lib/resource-center-image-url.test.ts` |
| `getResourceImageUrl()` client when config present | ✅ Tested | `lib/resource-center-image-url.test.ts` |
| Resource Centre local fallback without config | ✅ Tested | `lib/resource-center-image-url.test.ts` |
| `NetworkStatus` renders safely without config | ✅ Tested | `components/NetworkStatus.test.tsx` |
| `NetworkStatus` no client construction without config | ✅ Tested | `components/NetworkStatus.test.tsx` |
| `getCurrentUserAndProfile()` missing config | ❌ Not tested | No test file exists |
| `requireAdmin()` missing config | ❌ Not tested | No test file exists |
| Admin pages with null identity | ❌ Not tested | No test file exists |
| Service-role client after authorization | ❌ Not tested | No test file exists |
| Auth pages missing config | ❌ Not tested | No test file exists |
| Configured browser-client initialization | ❌ Not tested | Requires staging credentials (BLOCKED) |
| Configured offline monitoring | ❌ Not tested | Requires staging credentials (BLOCKED) |
| API authorization and error responses | ❌ Not tested | Requires staging credentials (BLOCKED) |
| All 173 existing tests pass | ✅ Verified | `npx vitest run` exit 0 |

**Legend:** ✅ Tested = covered by new or existing unit tests. ❌ Not tested = no test exists for this specific behavior.

---

## 8. Confirmed issues and severity

| # | Issue | Severity | Detail |
|---|-------|----------|--------|
| 1 | `lib/supabase/currentUser.ts` guard block at column 0 (no indentation) | Low | Cosmetic style inconsistency; functionally correct; no functional impact. |
| 2 | `app/admin/layout.tsx` does not check `requireAdmin()` return value | Low | Renders shell with null name when config missing; no data exposed; child pages protect data. Not a privilege escalation. |
| 3 | `app/admin/analytics/page.tsx` does not check `requireAdmin()` return value | Low | Proceeds to `createClient()` which throws if config missing; fails closed. Not a privilege escalation. |
| 4 | `app/admin/community-invitations/page.tsx` does not check `requireAdmin()` return value | Low | Proceeds to `getCommunityInvitationSummary()` → `createServiceClient()` throws if config missing; fails closed. Not a privilege escalation. |
| 5 | Missing test coverage for `getCurrentUserAndProfile()`, `requireAdmin()`, admin null identity, auth pages | Medium | No test files cover these behaviors; regression risk not captured by tests. |
| 6 | Staging-credential runtime verification blocked | Medium | Cannot verify login/signup/reset/session/protected routes/live data against real Supabase. Environment limitation, not code defect. |

**No CRITICAL issues.** No authorization bypass, no data exposure, no service-role leak, no fabricated data, no fail-open.

---

## 9. Unverified assumptions

1. **Staging runtime behavior:** Login, signup, password reset, session persistence, cookie handling, authenticated route access, unauthenticated protected-route access, public scholarship retrieval, Resource Centre remote images, offline/connection monitoring — all require valid staging Supabase credentials, which are unavailable. **NOT TESTED / BLOCKED.**
2. **`app/community/contributors/[profileId]/page.tsx` unguarded `createClient()`:** Pre-existing dynamic route; assumed to fail closed at runtime if config missing. Not verified at runtime (no staging credentials).
3. **`createServiceClient()` own validation:** Assumed to throw when `NEXT_PUBLIC_SUPABASE_URL`/`SUPABASE_SERVICE_ROLE_KEY` absent. Verified by reading source (it does throw), but not runtime-tested.

---

## 10. Recommended corrections (if any)

None are required for correctness or security. The implementation is functionally correct and secure. Optional improvements:

1. **Cosmetic:** Indent the guard block in `lib/supabase/currentUser.ts` to match codebase style (2 spaces).
2. **Defense in depth:** Add explicit null-identity checks to `app/admin/layout.tsx`, `app/admin/analytics/page.tsx`, and `app/admin/community-invitations/page.tsx` (return null/redirect when `userId` is null), even though they currently fail closed via subsequent client throws. This makes the intent explicit and removes reliance on throw-based failure.
3. **Test coverage:** Add unit tests for `getCurrentUserAndProfile()` missing config, `requireAdmin()` missing config, and admin pages with null identity.
4. **Staging verification:** Obtain valid staging Supabase credentials and run the staging verification plan (login, signup, reset, session, protected routes, public data, offline monitoring, service-role absence from browser bundles).

These are **recommendations, not blockers**.

---

## 11. Final release recommendation

**CONDITIONAL PASS**

**Rationale:** The implementation is correct and secure. TypeScript passes, all 173 tests pass, and the production build exits 0 without public Supabase configuration. No authorization bypass, data exposure, service-role leak, or fail-open was identified. The admin authorization call-path analysis confirms all privileged operations are properly gated or fail closed.

**Conditions (non-blocking):**
1. Staging-credential runtime verification remains BLOCKED — do not release to production without it.
2. Consider the optional corrections above (indentation, explicit null checks, test coverage) before release.

**Do not release to production until staging credentials are available and the staging verification plan is executed.**

---

**Audit performed by:** Independent source-code audit (read-only)  
**No files were modified during this audit.**  
**No release action authorized.**
