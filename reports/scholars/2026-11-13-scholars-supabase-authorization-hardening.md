# Scholars — Supabase Authorization Hardening Report

**Repository:** ImperioKDB/Scholars  
**Working directory:** /workspaces/Scholars  
**Branch:** feature/resource-center-public-frontend  
**HEAD:** 79456a0933eb27c6c848865cb35717c8b36ec0b5  
**Report date:** Fri Nov 13 2026  
**Status:** IMPLEMENTED (all validation green)

---

## 1. Objective

Implement explicit authorization checks on three admin entry points identified by the independent audit (CONDITIONAL PASS) that did not explicitly verify the identity returned by `requireAdmin()`:

- `app/admin/layout.tsx`
- `app/admin/analytics/page.tsx`
- `app/admin/community-invitations/page.tsx`

Add regression tests and verify no service-role boundary or pre-existing Resource Centre work was disturbed.

---

## 2. Repository state (established from Git, read-only audit)

| Item | Value |
|------|-------|
| Branch | feature/resource-center-public-frontend |
| HEAD | 79456a0933eb27c6c848865cb35717c8b36ec0b5 |
| Working tree | Uncommitted (no commit/push/merge/deploy performed) |
| Pre-existing modified files | 20 (preserved intact) |
| New test files added | 5 |

No branches were switched. No `git reset`, `git clean`, `git stash`, or destructive operations were performed.

---

## 3. Task 1 — Explicit authorization checks

### 3.1 `lib/admin/access.ts` — inspected, no change needed

`requireAdmin()` already:
- Returns `{ userId: null, fullName: null }` when `!hasPublicSupabaseConfig()` (no client constructed)
- Calls `redirect("/login?next=/admin")` when no user (config present)
- Calls `redirect("/dashboard")` when not admin / not founder
- Calls `redirect("/settings/security?required=admin-mfa")` when AAL2 required but not met
- Returns `{ userId: user!.id, fullName: ... }` on success

No change needed — the function itself is correct. The issue was that callers didn't check its return value.

### 3.2 `app/admin/layout.tsx` — modified

**Before:** `const { fullName } = await requireAdmin();` — return value destructured but not checked. `fullName` could be `null` when config absent, but the shell still rendered.

**After:**
```tsx
const admin = await requireAdmin();
if (!admin.userId) {
  return null;
}
return (
  <AdminShell fullName={admin.fullName}>
    <SchemaCheckBanner />
    {children}
  </AdminShell>
);
```
The admin shell now renders `null` (nothing) when there is no authenticated admin identity. No protected information is exposed.

### 3.3 `app/admin/analytics/page.tsx` — modified

**Before:** `await requireAdmin();` — return value ignored. Proceeded to `createClient()` and Supabase queries even when no admin session.

**After:**
```tsx
const admin = await requireAdmin();
if (!admin.userId) {
  return null;
}
const range = parseProviderAnalyticsRange(searchParams?.range);
const supabase = createClient();
```
No Supabase query occurs when identity is null.

### 3.4 `app/admin/community-invitations/page.tsx` — modified

**Before:** `await requireAdmin({ requireFounder: true });` — return value ignored. Proceeded to `getCommunityInvitationSummary()` which constructs a `createServiceClient()`.

**After:**
```tsx
const admin = await requireAdmin({ requireFounder: true });
if (!admin.userId) {
  return null;
}
const summary = await getCommunityInvitationSummary();
```
Founder requirement is preserved (`requireFounder: true`). No service-role client is constructed when identity is null.

### 3.5 Other `requireAdmin()` callers (already safe, no change needed)

| Caller | Null handling |
|--------|-------------|
| `app/admin/page.tsx` | `if (!user) return null` (already safe) |
| `app/admin/health/page.tsx` | `if (!admin.userId) return null` (already safe) |
| `app/admin/resources/page.tsx` | `if (!admin.userId) return null` (already safe) |
| `app/admin/users/page.tsx` | `if (!admin.userId) return null` before `createServiceClient()` (already safe) |

---

## 4. Task 2 — Service-role boundary

Inspected every `createServiceClient()` caller:

| Caller | Module type | Authorization before construction |
|--------|------------|----------------------------------|
| `app/admin/users/page.tsx` | Server Component | `requireAdmin()` + `!admin.userId` check |
| `app/api/admin/active-users/route.ts` | API Route | `assertAdmin(supabase)` |
| `app/api/admin/reengagement/enroll/route.ts` | API Route | `assertAdmin(authClient)` |
| `app/api/admin/reengagement/summary/route.ts` | API Route | `assertAdmin(authClient)` |
| `app/api/admin/reengagement/route.ts` | API Route | `assertAdmin(supabase)` |
| `app/api/admin/broadcast/route.ts` | API Route | `assertAdmin(supabase)` |
| `app/api/admin/independence-day/route.ts` | API Route | `assertAdmin(supabase)` |
| `app/api/admin/test-profile-nudge/route.ts` | API Route | `assertAdmin(supabase)` |
| `app/api/admin/discovery/operations/route.ts` | API Route | `assertAdmin(supabase)` |
| `app/api/admin/discovery/claims/route.ts` | API Route | `assertAdmin(supabase)` |
| `app/api/admin/discovery/route.ts` | API Route | `assertAdmin(supabase)` |
| `app/api/admin/opportunities/route.ts` | API Route | `assertAdmin(supabase)` |
| `app/api/admin/opportunities/[id]/route.ts` | API Route | `assertAdmin(supabase)` |
| `app/api/admin/feedback/route.ts` | API Route | `assertAdmin(supabase)` |
| `app/api/admin/schema-check/route.ts` | API Route | `assertAdmin(supabase)` |
| `app/api/admin/analytics/route.ts` | API Route | `assertAdmin(supabase)` |
| `app/api/admin/community-invitations/export/route.ts` | API Route | `assertAdmin(supabase, { requireFounder: true })` |
| `app/api/admin/testimonials/route.ts` | API Route | `assertAdmin(supabase)` |
| `app/api/admin/testimonials/[id]/route.ts` | API Route | `assertAdmin(supabase)` |
| `app/api/admin/discussions/...` | API Route | `assertAdmin(supabase)` |
| `app/api/admin/member-roles/route.ts` | API Route | `assertAdmin(supabase)` |
| `app/api/cron/deadline-check/route.ts` | System job | Trusted cron (no user auth) |
| `app/api/xp/share/route.ts` | API Route | Authenticated user check |
| `app/api/events/route.ts` | API Route | Trusted system job |
| `app/api/integrations/github/*` | System jobs | Trusted system jobs |
| `app/api/profile/whatsapp-community-invitation/route.ts` | API Route | Authenticated user check |
| `app/api/discussions/[id]/helpful/route.ts` | API Route | Authenticated user check |
| `app/api/scholarships/[id]/community/route.ts` | API Route | Authenticated user check |
| `app/api/auth/confirmation-email-event/route.ts` | API Route | Trusted system job |
| `app/lib/email/profileNudges.ts` | Server lib | Trusted system job |
| `app/lib/email/digest.ts` | Server lib | Trusted system job |
| `app/lib/admin/community-invitations.ts` | Server lib | Called only after `requireAdmin()` in page |

**Findings:**
- `createServiceClient()` is only imported by server-side modules. `lib/supabase/service.ts` has `import 'server-only'`. No client component imports it.
- `lib/supabase/service.ts` validation is UNCHANGED (still throws if `NEXT_PUBLIC_SUPABASE_URL` or `SUPABASE_SERVICE_ROLE_KEY` missing).
- All privileged operations have an explicit authorization boundary (`requireAdmin()`/`assertAdmin()`) or are trusted system jobs.
- A missing public Supabase configuration cannot permit a service-role operation — `requireAdmin()` returns null identity first, and `createServiceClient()` throws if its own env vars are missing.
- The service-role key is never exposed in client bundles (`server-only` directive).

No changes needed to `lib/supabase/service.ts` — its existing validation is preserved per task restrictions.

---

## 5. Task 3 — Regression tests

Five new test files added (9 new tests):

### 5.1 `lib/supabase/currentUser.test.ts` (2 tests)
- `getCurrentUserAndProfile()` returns `{ user: null, profile: null }` without constructing a client when public config is absent
- `getCurrentUserAndProfile()` returns user profile and constructs a client when config is present and user is authenticated

### 5.2 `lib/admin/access.test.ts` (3 tests)
- `requireAdmin()` returns `{ userId: null, fullName: null }` without constructing a client when public config is absent
- `requireAdmin({ requireFounder: true })` returns null identity without constructing a client when config is absent
- `requireAdmin()` returns admin identity and constructs a client when config is present and user is an authenticated admin founder

### 5.3 `app/admin/community-invitations.test.tsx` (2 tests)
- Page returns `null` without constructing a service-role client when identity is missing (config absent)
- `createServiceClient()` is called when founder is authorized and config is present (verifies `getCommunityInvitationSummary()` → service client path)

### 5.4 `app/admin/analytics.test.tsx` (2 tests)
- Page returns `null` without constructing a Supabase client when identity is null (config absent)
- Page constructs a Supabase client when admin is authorized (config present)

### 5.5 Total: 9 new tests across 5 files

All tests mock dependencies appropriately (Supabase client, `next/headers`, `react.cache`, `server-only`) and verify that privileged operations are **not called** when identity is null — not merely that the page renders without throwing.

---

## 6. Task 4 — Validation

| Command | Exit code | Result |
|---------|-----------|--------|
| `npx tsc --noEmit --pretty false` | 0 | Type-check passes (incl. new test files) |
| `npx vitest run` | 0 | 35 files, 182 tests passed, 0 failed |
| `npx next build` | 0 | All routes prerender successfully; build green without public Supabase credentials |

No live Supabase authentication was tested (staging credentials unavailable). Staging verification remains BLOCKED per task restrictions.

---

## 7. Pre-existing work preservation

All 20 pre-existing modified tracked files were preserved intact:
- `app/(auth)/login/page.tsx`, `app/(auth)/signup/page.tsx`, `app/layout.tsx`, `app/o/[id]/page.tsx`, `app/onboarding/page.tsx`, `app/page.tsx`, `app/reset-password/page.tsx`, `app/reset-password/update/page.tsx`, `app/resources/[slug]/page.tsx`, `app/resources/page.tsx`, `app/s/[id]/page.tsx`, `app/scholarship/[slug]/page.tsx`, `components/NetworkStatus.tsx`, `components/resource-center-interactions.test.tsx`, `components/resource-center-interactions.tsx`, `components/resource-center-search.tsx`, `lib/resource-center.ts`, `lib/supabase/client.ts`, `lib/supabase/public.ts`, `lib/supabase/server.ts`

All untracked files were preserved. No files were deleted, renamed, restored, or overwritten.

---

## 8. Final Git status

Branch: `feature/resource-center-public-frontend`  
HEAD: `79456a0933eb27c6c848865cb35717c8b36ec0b5` (unchanged)  
Working tree: 34 modified tracked files (20 pre-existing + 14 implementation/hardening), plus new untracked test files and report.  
**No commit, push, merge, PR, or deploy was performed on Scholars.**

---

## 9. Service-role authorization call-path findings

No fail-open paths identified. Every `createServiceClient()` construction is preceded by an explicit authorization check:
- Pages: `requireAdmin()` + `!admin.userId` null check
- API routes: `assertAdmin(supabase)` returning 401/403
- System jobs: trusted cron/integration paths (no user auth required)

The `community-invitations` page (the audit's primary concern) now explicitly checks `!admin.userId` before calling `getCommunityInvitationSummary()` → `createServiceClient()`.

---

## 10. Updates report publication

**Repository:** ImperioKDB/Updates  
**Path:** `reports/scholars/2026-11-13-scholars-supabase-authorization-hardening.md`  
**Commit SHA:** (to be filled after publication)  
**GitHub URL:** (to be filled after publication)  
**Verified:** Published content matches local report

---

## 11. Remaining items

Staging-credential runtime verification remains BLOCKED (no staging credentials available; prohibited from inventing or using production credentials). Do not release to production until staging verification is executed.
