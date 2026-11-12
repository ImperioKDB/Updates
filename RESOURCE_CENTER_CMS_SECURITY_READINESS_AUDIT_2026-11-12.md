# Resource Centre CMS Security Readiness Audit — 2026-11-12

**Repository:** ImperioKDB/Scholars  
**Workspace:** /workspaces/Scholars  
**Production domain:** https://scholars.com.ng (Resource Centre: https://scholars.com.ng/resources)  
**Documentation repository:** ImperioKDB/Updates (cloned to /tmp/opencode/updates-repo; push not authorized — see section 10)  
**Audit date:** 2026-11-12  
**Mode:** READ-ONLY. No production SQL, no migrations applied, no RLS changes, no production data modified, no Supabase auth/settings changes, no env vars changed, no editorial users created, nothing deployed or merged.  
**Verdict:** The CMS backend is **NOT safe to begin implementing**. The public Resource Centre frontend is live and verified, but the backend editorial/authoring/publishing surface has unresolved security findings. Do not begin CMS implementation.

---

## 1. Scope and method

This audit reassesses the prior Resource Centre security findings against the **current** source code, Supabase migrations, RLS policies, and database functions in /workspaces/Scholars. It does not rely on old reports as proof of current state. Each prior report was re-read, and each concern was re-verified against current files (migrations read directly from disk; source read directly).

For each of the 10 concerns, a finding is classified as:

- **Resolved and independently verified**
- **Partially resolved**
- **Still unresolved**
- **Cannot verify with available access**

No access tokens, passwords, environment values, or private credentials are included in this report.

### 1.1 Prior reports reviewed (all located in ImperioKDB/Updates)

| Report | Date | Role |
|---|---|---|
| SCHOLARS_RESOURCE_CENTER_PHASE_0_2_FINAL_SECURITY_AND_SCHEMA_READINESS.md | 2026-11-06 | Final security and schema readiness (classification C: BLOCKED) |
| SCHOLARS_RESOURCE_CENTER_POST_DEPLOYMENT_SECURITY_CLARIFICATION_2026-11-07.md | 2026-11-07 | Post-deployment security clarification (classification C: BLOCKED) |
| SCHOLARS_RESOURCE_CENTER_PHASE_A0_4_BACKEND_FOUNDATION_SPECIFICATION_2026-11-08.md | 2026-11-08 | Backend foundation specification (BLOCKED) |
| SCHOLARS_RESOURCE_CENTER_PHASE_A0_5_TARGETED_BACKEND_DEPENDENCY_VERIFICATION_2026-11-08.md | 2026-11-08 | Targeted backend dependency verification (BLOCKED; verified live DB state) |

### 1.2 Current deployed state (re-verified)

- The public frontend is live (see RESOURCE_CENTER_PRODUCTION_VERIFICATION_2026-11-12.md): `/resources`, all 6 articles, all 6 categories, `/sitemap.xml` all return HTTP 200; advertising disabled by default.
- The production deployment is the PR #29 merge commit `137f2fa28a4f1a5b1fb6eaa55e3c6c3677bb4210` (2026-11-11 23:37:26 UTC).
- The Resource Centre schema migration `supabase/migrations/20261107130100_resource_center_schema.sql` is present in the current repo and defines five base tables (`resource_editorial_identities`, `resource_categories`, `resource_articles`, `resource_article_categories`, `resource_revisions`) and four public projection views (`resource_public_*`). Per A0.5 this matches the live database `cmdglabohpttgfofcmqc`.
- There are **zero** Resource Centre rows in production (articles, categories, identities, revisions all 0 per post-deployment clarification §2.3), so no draft/scheduled/archived content is currently exposed.

---

## 2. Findings by concern

### Concern 1 — Self-elevation through `profiles.is_admin`

**Classification: STILL UNRESOLVED (verified structural path)**

Evidence (current repo):

- `supabase/migrations/0023_lock_admin_flag.sql:8-13` adds `profiles.is_admin` and revokes broad table privileges from `anon, authenticated`; lines 80-83 revoke column-scoped `INSERT (is_admin), UPDATE (is_admin)` from `anon, authenticated`.
- `supabase/migrations/0029_fix_profiles_upsert_table_privileges.sql:4-6` then grants table-level `INSERT, UPDATE ON public.profiles TO authenticated` and revokes only column-scoped `is_admin`. A column-scoped revoke does **not** cancel a table-level privilege.
- `supabase/migrations/0023_lock_admin_flag.sql:85-98` defines `profiles_update_own` with `using (auth.uid() = id)` / `with check (auth.uid() = id)` — an authenticated user can update their own row.
- No trigger, check constraint, or rewrite rule protects `is_admin` (0023 covers only ordinary profile fields in the updatable column list; `is_admin` is absent).
- `lib/admin/guard.ts`, `lib/admin/access.ts`, and `middleware.ts` all gate admin actions on `profiles.is_admin` read via `public.is_admin(auth.uid())`.
- `public.is_admin(uuid)` is `SECURITY DEFINER`, owner `postgres` (`rolbypassrls=true`), `search_path=""`, body `select coalesce((select p.is_admin from public.profiles p where p.id = uid), false)`, accepts an arbitrary UUID, and its effective ACL permits `anon`, `authenticated`, `service_role`, and `postgres` to EXECUTE (A0.5 §3.1, verified against live catalog).

Effect: an authenticated caller can set `is_admin = true` on their own profile row, after which every guard, middleware check, and Resource Centre RLS policy that calls `is_admin(auth.uid())` treats them as an administrator. Not write-tested in this audit (read-only), but the structural path is verified from source + live catalog. This defeats all downstream authorization.

**Related files:** `supabase/migrations/0023_lock_admin_flag.sql`, `0029_fix_profiles_upsert_table_privileges.sql`, `0002_harden_functions.sql`, `lib/admin/guard.ts`, `lib/admin/access.ts`, `middleware.ts`.

---

### Concern 2 — Separation of author, reviewer, and administrator permissions

**Classification: STILL UNRESOLVED**

Evidence (current repo):

- `supabase/migrations/20261107130100_resource_center_schema.sql:5-18, 35-63` defines `resource_editorial_identities` (author/reviewer references), `resource_articles.author_identity_id` and `.reviewer_identity_id`, but contains **no** author/reviewer/publisher capability table, no distinct editorial role, and **no rule requiring reviewer ≠ author**.
- All six base-table policies gate on `public.is_admin(auth.uid())` only (migration lines 129-150). There is no author-capability, reviewer-capability, or publisher-capability check.
- `community_role` (checked by existing admin helpers) is not a Resource Centre author/reviewer authorization model (A0.5 §4.4).
- No Resource Centre write/publish API or server action exists yet, so no role-separated editorial boundary has been implemented (A0.5 §4.1).

**Related files:** `supabase/migrations/20261107130100_resource_center_schema.sql`, `lib/admin/guard.ts`, `lib/admin/access.ts`.

---

### Concern 3 — Database-enforced publishing and approval transitions

**Classification: STILL UNRESOLVED**

Evidence (current repo):

- `resource_articles.status` is a CHECK-constrained enum (`draft, in_review, scheduled, published, archived`) with timestamp presence checks (`20261107130100_resource_center_schema.sql:42, 57-62`), but there is **no** transition state machine.
- A0.5 §5.3: no Resource Centre-specific authoring, review, publication, revision, or audit RPC exists; no user-defined triggers on the five Resource Centre tables; no submit/approve/schedule/publish/archive/correct operation.
- The broad admin `FOR ALL` policies permit an authenticated admin to `UPDATE` workflow fields directly (`status`, `reviewer_identity_id`, `published_at`, `published_revision_id`) with no transition validation (post-deployment clarification §4).
- No `expected_version`/optimistic locking, no idempotency, no atomic transition+audit transaction.

**Related files:** `supabase/migrations/20261107130100_resource_center_schema.sql`; cf. A0.4 §4.2 (allowed transitions, not implemented).

---

### Concern 4 — Immutable article revision integrity

**Classification: STILL UNRESOLVED (partially present)**

Evidence (current repo):

- `resource_revisions.state` is `jsonb NOT NULL` with only `check (jsonb_typeof(state) = 'object')` (`20261107130100_resource_center_schema.sql:86-87, 92`) — no required keys, no complete-article snapshot contract, no category/author/reviewer snapshots, no source/review metadata enforcement (post-deployment clarification §5).
- Revisions have `UNIQUE(article_id, revision_number)` but **no** composite constraint binding `published_revision_id` to the same article's revision (`resource_articles.published_revision_id` FK only checks the revision ID exists, not that it belongs to the article; lines 54, 97-101).
- No trigger or grant boundary makes revisions append-only; authenticated users lack direct revision UPDATE/DELETE, but `service_role` can, and no immutability trigger exists (A0.5 §5.3).
- Public views read **mutable current article/category rows**, not `resource_revisions.state` or `published_revision_id` (migration lines 169-203). Edits to a published row change the public page without a reviewed snapshot.
- Restoration-creates-a-new-revision and obsolete-approval-cannot-be-reused are not implemented.

**Related files:** `supabase/migrations/20261107130100_resource_center_schema.sql` (lines 54, 82-101, 169-203).

---

### Concern 5 — AAL2/MFA requirements for editorial actions

**Classification: CANNOT VERIFY with available access (runtime unverified)**

Evidence (current repo):

- `lib/admin/guard.ts:15-17, 64-80` (`assertAdmin`) and `lib/admin/access.ts:4-6, 27-33` (`requireAdmin`) require current and next AAL2 **only** if `requireAal2` is passed or `REQUIRE_ADMIN_MFA === "true"`.
- `middleware.ts:38-40, 204-212` applies the same conditional setting to `/api/admin`.
- **No call site explicitly passes `requireAal2`** (A0.5 §4.3). The route-wide gate is conditional on the deployed environment variable.
- `.env.example` sets `REQUIRE_ADMIN_MFA=false`. The production Vercel value/effective deployment was **not** read (read-only audit; no env access).
- MFA routes exist (TOTP enrollment/list/verify/removal) but their existence is not evidence that every editorial operation requires AAL2 (A0.4 §2.2).

Conclusion: AAL2 on editorial actions is **not verified as enabled**; it is conditional and the production flag is unreadable in this read-only access.

**Related files:** `lib/admin/guard.ts`, `lib/admin/access.ts`, `middleware.ts`, `.env.example`.

---

### Concern 6 — Isolation and availability of a staging environment

**Classification: CANNOT VERIFY / STILL UNRESOLVED**

Evidence (current repo + Updates reports):

- Production Supabase project is `scholarship-platform` (`cmdglabohpttgfofcmqc`), identified as live in `supabase/migrations/0001_init.sql:3-12`. No Supabase development branches exist (A0.5 §6; post-deployment clarification §2.1).
- A separate project named `serena` exists but **no evidence establishes it as a Scholars staging environment**; it must not be treated as staging without owner confirmation (A0.5 §6; post-deployment clarification §2.1).
- No `supabase/config.toml`; `.env.example` lists variable names only; no migration-deployment command in CI/vercel.json/package.json (A0.5 §6.2).
- There is **no verified non-production Scholars database** for safely testing privilege remediation or editorial operations.

**Related files:** `supabase/migrations/0001_init.sql`; A0.5 §6; post-deployment clarification §2.1, §6.

---

### Concern 7 — RLS coverage for all editorial tables

**Classification: PARTIALLY RESOLVED**

Evidence (current repo + live-catalog-verified in A0.5 / post-deployment clarification):

- RLS is **enabled** on all five base tables (`20261107130100_resource_center_schema.sql:103-107`), but `FORCE ROW LEVEL SECURITY` is **disabled** (post-deployment clarification §4; A0.5 §5.1).
- Table grants: `anon` has none; `authenticated` has SELECT/INSERT/UPDATE on identities/categories/articles/article-category links and SELECT/INSERT on revisions; `service_role` has all (migration lines 110-127).
- Four `FOR ALL` admin policies gate authenticated writes on `is_admin(auth.uid())`; revisions have admin-only INSERT (`created_by = auth.uid()`) and SELECT (migration lines 129-150).
- Four public views exist with `security_barrier=true` but **no `security_invoker=true`**; owner is `postgres` (`BYPASSRLS`); `SELECT` granted to `anon, authenticated` (migration lines 157-214; post-deployment clarification §3).
- Views project approved columns with fixed `status='published' AND published_at <= now()` predicates, so the **current** exposure is limited — but safety depends on every future view definition preserving explicit columns, and it does **not** come from base-table RLS because the view owner bypasses RLS (post-deployment clarification §3.2).

Gap: RLS covers all tables but is not forced and depends on the compromised `is_admin` helper (Concern 1); the view model is owner-executed, not invoker-enforced.

**Related files:** `supabase/migrations/20261107130100_resource_center_schema.sql` (lines 103-214).

---

### Concern 8 — Service-role key handling and privileged server operations

**Classification: PARTIALLY RESOLVED**

Evidence (current repo):

- `lib/supabase/service.ts:1-24` imports `server-only`, reads `SUPABASE_SERVICE_ROLE_KEY`, documents that it bypasses RLS; must be server-only.
- Service-role use is behind guards: `app/api/admin/discovery/operations/route.ts:7-17` calls `assertAdmin()` before creating the service client; `app/admin/users/page.tsx:51-52` calls `requireAdmin()` before using the service client (A0.5 §4.2).
- Cron route `app/api/cron/deadline-check/route.ts:13-21` checks bearer `CRON_SECRET` before service-role work.
- A scoped scan found no browser import of the service helper (A0.5 §4.2).
- Gap: production `SUPABASE_SERVICE_ROLE_KEY` exposure/rotation was not inspected (read-only); `service_role` is unrestricted on the Resource Centre base tables (all rights), so any key compromise bypasses all table RLS. No narrow scoped service-role policy for Resource Centre operations exists yet.

**Related files:** `lib/supabase/service.ts`, `lib/supabase/server.ts`, `app/api/admin/discovery/operations/route.ts`, `app/admin/users/page.tsx`, `app/api/cron/deadline-check/route.ts`.

---

### Concern 9 — Audit-log integrity and accountability

**Classification: STILL UNRESOLVED**

Evidence (current repo):

- A0.5 §5.3: no Resource Centre audit table, trigger, or RPC found in the scoped schema/source; no append-only transition ledger.
- A0.4 §6.3 recommends an append-only `resource_article_audit_events` ledger (not implemented).
- `resource_revisions` records `created_by` and `created_at` but no approval actor/time/decision/hash, no idempotency key, no transition event type.
- No publication-attempt/failure record exists.

**Related files:** `supabase/migrations/20261107130100_resource_center_schema.sql` (lines 82-93); cf. A0.4 §6.3, §9 (migration #3).

---

### Concern 10 — Protection against unauthorised publication, editing, and deletion

**Classification: STILL UNRESOLVED**

Evidence (current repo):

- Publication/editing/deletion ultimately depend on `is_admin(auth.uid())` (Concern 1, structurally self-elevatable).
- The broad admin `FOR ALL` policies allow direct table UPDATE on `status`, `reviewer_identity_id`, `published_at`, `published_revision_id` with no transition validation (Concern 3).
- No guarded submit/approve/schedule/publish/archive/correct endpoint exists (A0.5 §5.3); the admin index (`app/admin/resources/page.tsx`) is read-only and labels publishing as "next" (A0.5 §4.1).
- No draft leakage prevention beyond the published-only view predicate; no reviewer-separation, no approval-freshness, no scheduled-time invariant, no MFA gate at the database boundary.

**Related files:** `supabase/migrations/20261107130100_resource_center_schema.sql`, `lib/admin/guard.ts`, `0023_lock_admin_flag.sql`, `0029_fix_profiles_upsert_table_privileges.sql`.

---

## 3. Summary classification table

| # | Concern | Classification |
|---|---|---|
| 1 | Self-elevation through `profiles.is_admin` | Still unresolved |
| 2 | Author / reviewer / administrator separation | Still unresolved |
| 3 | Database-enforced publishing & approval transitions | Still unresolved |
| 4 | Immutable article revision integrity | Still unresolved (partially present) |
| 5 | AAL2/MFA for editorial actions | Cannot verify (runtime unverified) |
| 6 | Staging environment isolation & availability | Cannot verify (no confirmed staging) |
| 7 | RLS coverage for all editorial tables | Partially resolved |
| 8 | Service-role key handling & privileged server ops | Partially resolved |
| 9 | Audit-log integrity & accountability | Still unresolved |
| 10 | Protection against unauthorised publication/edit/delete | Still unresolved |

---

## 4. Reassessment against prior reports

All four prior reports remain consistent with the current codebase:

- **Phase 0.2 (2026-11-06):** classification C (BLOCKED by existing security findings). The service-role-only worker boundary discrepancy, `announcement_log` inconsistency, and the recommendation for dedicated public views with `security_invoker = true` are all still reflected in current source/migrations. **Still valid.**
- **Post-deployment clarification (2026-11-07):** the deployed foundation exists with zero Resource Centre rows; views are owner-executed (not `security_invoker`); RLS not forced; broad admin `ALL` policies permit direct workflow-field updates; no transition operation/MFA/immutability; no staging confirmed; sitemap omitted `/resources` and categories at that time. **Still valid** — note: the current production sitemap now DOES include `/resources`, all 6 categories, and all 6 articles (PR #29 sitemap fix verified live), so that SEO gap is resolved, but the security gaps are not.
- **A0.4 (2026-11-08):** schema is a useful foundation but not an editorial workflow implementation; `public.is_admin(uuid)` definition/effective contract unresolved; no transition enforcement, immutability, or audit. **Still valid** — the migration is now in the current repo and matches what A0.4 described as pinned.
- **A0.5 (2026-11-08):** verified against the live database that authenticated users have effective `INSERT/UPDATE` on `profiles.is_admin`; `is_admin()` is a broadly-executable arbitrary-UUID oracle; no verified non-production environment; MFA conditional. **Still valid and now re-confirmed against current source.**

No prior finding has been resolved in the current codebase.

---

## 5. Readiness conclusion

**Is the CMS safe to begin implementing? No.**

- The **public Resource Centre frontend** is live, verified, and safe (ads disabled, no exposed credentials, all routes 200, canonicals and JSON-LD correct).
- The **CMS backend (authoring, review, scheduling, publishing, archiving, correction)** is **blocked**. The foundational schema/views exist, but none of the editorial security boundaries are implemented or verified:
  - `profiles.is_admin` self-elevation path is structurally open.
  - No author/reviewer/publisher capability model.
  - No database-enforced transition state machine.
  - No revision immutability or same-article binding.
  - No audit ledger.
  - AAL2 not verified enabled; no confirmed staging environment.

The CMS must **not** be built on top of the current broad admin table-write path. Implementation should wait for: (1) owner-approved remediation of the `profiles.is_admin` grant/self-elevation path and `is_admin()` helper contract, (2) an isolated non-production Scholars staging environment, (3) explicit AAL2/MFA policy for editorial actions, and (4) database-enforced transitions, immutable revisions, and audit.

---

## 6. Read-only confirmation

No production SQL was run, no migrations applied, no RLS policies changed, no production data modified, no Supabase authentication settings changed, no environment variables modified, no editorial users created, nothing deployed, nothing merged, and no security control weakened. No access tokens, passwords, environment values, or private credentials were read or reported.

**Publishing blocker:** Push to `ImperioKDB/Updates` is not authorized (`git push` → 403 permission denied to ImperioKDB). Per the task fallback, all three reports are saved in the Scholars workspace:
- `/workspaces/Scholars/RESOURCE_CENTER_PRODUCTION_VERIFICATION_2026-11-12.md`
- `/workspaces/Scholars/CODEGRAPH_FRESH_SESSION_VERIFICATION_2026-11-12.md`
- `/workspaces/Scholars/RESOURCE_CENTER_CMS_SECURITY_READINESS_AUDIT_2026-11-12.md`
