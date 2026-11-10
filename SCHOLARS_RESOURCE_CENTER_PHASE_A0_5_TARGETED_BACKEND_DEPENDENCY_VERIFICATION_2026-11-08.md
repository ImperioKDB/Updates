# Scholars Resource Center — Phase A0.5 Targeted Backend Dependency Verification

**Assessment date:** 2026-11-08
**Primary repository:** `ImperioKDB/Scholars`, reviewed at `cf3682ce35912df7b9b9352193630fc404427c7c`
**Documentation repository:** `ImperioKDB/Updates`
**Prior foundation:** A0.4 at `01b43be5881cd7050574bc12e180b2ab6a618885`
**Review mode:** targeted, read-only source and live PostgreSQL catalog inspection
**Verdict:** **BLOCKED** — the matched live Scholars database exposes a structural authenticated self-elevation path through `profiles.is_admin`; there is no verified non-production target for safe implementation/testing; and production MFA/API exposure settings remain unverified.

## 1. Executive summary

The authoritative `public.is_admin(uuid)` definition **is available in the matched live database**. It is a stable SQL `SECURITY DEFINER` function owned by `postgres`, uses an empty `search_path`, and returns `profiles.is_admin` for the UUID supplied by the caller. Its effective ACL includes `PUBLIC:EXECUTE`; the `anon`, `authenticated`, `service_role`, and `postgres` roles can all execute it. It does not bind its argument to `auth.uid()`, so a caller able to invoke it can query the admin flag of an arbitrary UUID. That is an unauthorized administrator-membership oracle. The function alone only returns a Boolean and does not impersonate the JWT identity used by `auth.uid()` in RLS policies.

More seriously, live catalog privileges contradict the intended admin-flag protection in migration `0029_fix_profiles_upsert_table_privileges.sql`. That migration grants table-wide `INSERT` and `UPDATE` on `profiles` to `authenticated`, then revokes only column-scoped privileges on `is_admin`. The live database confirms that authenticated users still have effective `INSERT` and `UPDATE` privileges on `profiles.is_admin`. The live permissive `profiles_update_own` policy lets an authenticated user update their own row, and no admin-flag trigger, check constraint, or rewrite rule was found. This is a **verified structural self-elevation path**: after the flag is changed, the helper, application guards, and Resource Center RLS policies will treat that caller as an admin. No write or exploit attempt was made.

The app has multiple server-side guards: all 29 current `app/api/admin/**/route.ts` files include an inline `assertAdmin`/`requireAdmin` check, the middleware checks `/api/admin`, and the admin layout calls `requireAdmin`. Those controls do not close the database flaw because each ultimately trusts the same writable `profiles.is_admin` flag. No missing inline guard was found in those 29 routes. Client-side `isAdmin` state is used for navigation/visibility; it was not found to be the sole authorization check for the inspected API operations.

The live Resource Center objects exist. RLS is enabled on each of the five base tables, but not forced. `anon` has no base-table privileges; `authenticated` has direct `SELECT/INSERT/UPDATE` on identities, categories, articles and their join table, and `SELECT/INSERT` on revisions; `service_role` has all privileges. Policies gate authenticated writes on `is_admin(auth.uid())`, which is undermined by the profile self-elevation path. Public views are owned by `postgres`, have `security_barrier=true` but no `security_invoker` option, and grant `SELECT` to `anon` and `authenticated`. The views project the **current mutable article and category rows**, not the revision identified by `published_revision_id`.

The Supabase project mapped by the Scholars repository is `scholarship-platform` (`cmdglabohpttgfofcmqc`), which the source describes as the **live** project. The connected account has no development branches for it and no other clearly identified Scholars staging project. The separate `serena` project was not used. There is no safe isolated environment established for implementation testing.

No Scholars application code, database objects/data, Supabase settings, storage policies, environment variables, or deployment configuration were changed. This report is documentation only.

## 2. Scope and methodology

The investigation reused the A0.4 specification and reviewed only relevant current Scholars source: admin guards/access, middleware, session/service clients, representative guarded admin routes, profile-privilege migrations, the Resource Center schema migration, the existing publication RPC definition/call site, CI/workflow files, and Vercel cron configuration. It did not repeat the A0.3 129-migration inventory.

The repository’s `supabase/migrations/0001_init.sql:3-12` explicitly labels `scholarship-platform` (`cmdglabohpttgfofcmqc`) the live Supabase project and warns not to run that superseded initial schema against it. Supabase project metadata reported it `ACTIVE_HEALTHY`; it is treated as production for safety. The connected account also listed `serena` (`nmlhcofasxsngmvjjxti`), but that project was excluded as instructed. The Scholars project’s development-branch list was empty.

Authorized Supabase MCP access was used only against `cmdglabohpttgfofcmqc`. Queries were catalog/metadata `SELECT`s; no user/profile rows or application content were read. No SQL write, migration, storage/auth operation, production HTTP RPC probe, or test write was attempted. No credentials, keys, passwords, tokens, or environment values were read or reported.

### Evidence classifications

- **VERIFIED — SOURCE:** directly observed in the cited current repository source or migration.
- **VERIFIED — DATABASE:** directly returned by the read-only catalog query against the matched live project.
- **INFERRED:** follows from verified evidence but was not exercised as a write or request.
- **UNVERIFIED:** the relevant runtime setting or behavior was not available from the inspected source/catalog.
- **BLOCKED:** cannot safely be investigated or implemented further without a suitable isolated environment or separate authorization.

## 3. Authoritative `public.is_admin(uuid)` findings

### 3.1 Live definition and effective privilege contract

**VERIFIED — DATABASE.** The exact catalog result was:

| Property | Live result |
|---|---|
| Signature / result | `public.is_admin(uid uuid) RETURNS boolean` |
| Language / volatility | SQL / `STABLE` |
| Security mode | `SECURITY DEFINER` |
| Owner | `postgres`; not superuser, but `rolbypassrls=true` |
| Function settings | `search_path=""` |
| Body | `select coalesce((select p.is_admin from public.profiles p where p.id = uid), false)` |
| Stored ACL | `{postgres=X/postgres,service_role=X/postgres,=X/postgres}`; the empty grantee is `PUBLIC` |
| Effective execution | `anon`, `authenticated`, `service_role`, and `postgres` all pass `has_function_privilege(..., 'EXECUTE')` |

The function reads `profiles.is_admin` and accepts an arbitrary UUID; it does not compare `uid` with `auth.uid()`. This makes it an administrator-status oracle for any UUID to roles that can execute it. **The direct PostgREST HTTP route was not probed.** A read of `current_setting('pgrst.db_schemas', true)` and `current_setting('pgrst.db_anon_role', true)` returned `NULL`; therefore the live API exposed-schema configuration and direct RPC reachability remain **UNVERIFIED**. SQL-level execute access to `anon` and `authenticated` is verified.

An arbitrary function argument does not itself replace or spoof the caller’s JWT `auth.uid()`: the Resource Center policies call the helper with `auth.uid()` from the policy expression. The live Boolean oracle is a privacy/authorization-information exposure. The separate writable-profile path below is what makes self-elevation possible.

### 3.2 Source history versus live state

**VERIFIED — SOURCE:**

- `supabase/migrations/0002_harden_functions.sql:1-14` sets an empty search path and revokes function execution from `PUBLIC`, `anon`, and `authenticated`. It does **not** define the function body.
- `supabase/migrations/0023_lock_admin_flag.sql:80-114` revokes column-scoped `INSERT/UPDATE` on `profiles.is_admin`, defines permissive own-row profile policies at lines 85-98, then grants `EXECUTE` on `public.is_admin(uuid)` to `PUBLIC` at line 112. Its comments claim the helper is not a useful client RPC, but that claim is contradicted by the live function body accepting any UUID and returning the flag.
- `supabase/migrations/0029_fix_profiles_upsert_table_privileges.sql:1-7` explains that PostgREST upserts need table-level rights, grants `INSERT, UPDATE ON public.profiles TO authenticated` at line 4, and then revokes only column-scoped `INSERT/UPDATE` on `is_admin` at lines 5-6. A column-scoped revoke does not cancel a table-level privilege; the live effective privileges confirm the result.

Historical statements alone do not establish live function definitions or ACLs. Here, live catalog inspection resolves the function question and confirms the effective-grant regression.

### 3.3 Self-elevation finding

**VERIFIED — DATABASE / INFERRED EFFECT:** the live database reports `authenticated` has table-level `INSERT` and `UPDATE` on `profiles`, and effective `INSERT` and `UPDATE` on the `is_admin` column. The live `profiles_insert_own` policy permits insert only when `auth.uid() = id`; the permissive `profiles_update_own` policy permits update when and after update `auth.uid() = id`. Profile RLS is enabled. The inspected profile triggers cover community-invitation consent, referral completion, profile completeness, and `updated_at`; none protects `is_admin`. The profile check constraints do not cover `is_admin`, and no user-defined profile rewrite rule was found.

Together, these live privileges and policies establish a structural path for an authenticated caller to set the flag on their own row without an admin. This assessment did not attempt the update. Since `is_admin` reads that same flag, middleware, route guards, and RLS checks can subsequently recognize the caller as an administrator. Treat this as a **critical authorization defect requiring independent security-owner review**, not as a hypothetical function-body uncertainty.

## 4. Administrative authorization path

### 4.1 Existing checks and their trust source

- `lib/admin/guard.ts:19-83`: `assertAdmin()` calls `supabase.auth.getUser()`, reads `profiles.is_admin` and `community_role`, returns 401/403 on failure, optionally requires current and next AAL2 when `requireAal2` is passed or `REQUIRE_ADMIN_MFA=true`, and can apply a founder-role check.
- `lib/admin/access.ts:10-35`: Server Component `requireAdmin()` applies the same profile-flag check and optional AAL2/founder redirect.
- `middleware.ts:192-214`: the `/api/admin` middleware gate reads the signed-in user’s `profiles.is_admin` and conditionally checks AAL2. The route matcher includes `/api/admin/:path*` at lines 304-327.
- `app/admin/layout.tsx:5-13`: the admin route group calls `requireAdmin()` before rendering.
- A scoped scan found **29** `app/api/admin/**/route.ts` files; every one contained `assertAdmin` or `requireAdmin`. Representative examples: `app/api/admin/scholarships/route.ts:65-90` guards both `GET` and `POST`; `app/api/admin/discovery/route.ts:13-18,30-35` guards both discovery operations before data access or mutation. No unguarded admin API route was found by that scan.

These are genuine server-side checks, but every one ultimately trusts `profiles.is_admin`. Because the live database permits an authenticated user to alter that flag on their own row, the checks do not provide an independent boundary against self-elevation. Resource Center RLS policies have the same dependency.

The current app also has Resource Center reader surfaces. `app/admin/resources/page.tsx:6-10,13-17` calls `requireAdmin()` and uses the session-bound client to list article fields only; the page labels publishing workflow as next. Public readers at `app/resources/page.tsx`, `app/resources/[slug]/page.tsx`, and `app/resources/category/[slug]/page.tsx` read the public projection views. A scoped search of current `app/api/**`, `app/admin/**`, and `lib/**` found no Resource Center write/publish API or server action. The admin index is therefore not evidence that editorial mutations are implemented.


### 4.2 Client state, service role, and route coverage

**VERIFIED — SOURCE.** `components/Sidebar.tsx:111` uses `isAdmin` to show the admin navigation item; the app also passes the flag into presentation components. These UI states are not the authorization boundary for the inspected admin APIs. The APIs and Server Components use the server guards above.

`lib/supabase/server.ts:6-19,35-72` uses the cookie/session-bound Supabase client with the public anon key, so database calls retain the caller’s identity and are subject to RLS. `lib/supabase/service.ts:1-24` imports `server-only`, reads `SUPABASE_SERVICE_ROLE_KEY`, and documents that it bypasses RLS. The inspected administrative service-role caller `app/api/admin/discovery/operations/route.ts:7-17` calls `assertAdmin()` before creating the service client. The admin users Server Component calls `requireAdmin()` before using the service client (`app/admin/users/page.tsx:51-52`). The existing cron route checks a bearer `CRON_SECRET` before service-role work (`app/api/cron/deadline-check/route.ts:13-21`). No browser import of the service helper was found in the scoped source scan. This is source evidence only; production bundle/environment configuration was not inspected.

No admin Server Action (`"use server"`) was found in the scoped `app/admin` scan. This does not alter the direct database privilege finding.

### 4.3 MFA/AAL2

**VERIFIED — SOURCE / UNVERIFIED — RUNTIME.** Both `lib/admin/guard.ts:15-17,64-80` and `lib/admin/access.ts:4-6,27-33` require current and next AAL2 only if an option is passed or `REQUIRE_ADMIN_MFA === "true"`. `middleware.ts:38-40,204-212` applies the same setting to `/api/admin`. No current call site explicitly passes `requireAal2`; the route-wide gate is therefore conditional on the deployed environment variable. The MFA unenrollment route checks current AAL2 (`app/api/auth/mfa/unenroll/route.ts:7-19`), but that is not proof that editorial changes require AAL2. The production Vercel value/effective deployment was not read. **AAL2 on administrative/editorial operations is not verified as enabled.**

### 4.4 Role model

**VERIFIED — SOURCE.** The Resource Center schema contains editorial identity records and article author/reviewer identity references, but no author/reviewer membership or capability table, distinct review/publish role, or rule requiring reviewer and author to be different users/identities (`20261107130100_resource_center_schema.sql:5-18,35-63`). The `community_role` checked by existing admin helpers is not a Resource Center author/reviewer authorization model. The schema requires a reviewer identity for some states; it does not establish reviewer independence.

## 5. Resource Center database security verification

All database statements below are **VERIFIED — DATABASE** for `cmdglabohpttgfofcmqc`; source migration statements are separately labelled.

### 5.1 Base tables, RLS, policies, and effective grants

All five base tables exist, are owned by `postgres`, have RLS enabled, and have `FORCE ROW LEVEL SECURITY` disabled. The catalog policy inventory returned four permissive `FOR ALL` policies for authenticated users, each requiring `is_admin(auth.uid())` in both `USING` and `WITH CHECK`. Revisions have an admin-only `INSERT` policy with `created_by = auth.uid()` and an admin-only `SELECT` policy.

| Base table(s) | `anon` effective table rights | `authenticated` effective table rights | `service_role` effective table rights |
|---|---|---|---|
| `resource_editorial_identities`, `resource_categories`, `resource_articles`, `resource_article_categories` | None | `SELECT`, `INSERT`, `UPDATE`; no `DELETE` | All checked rights, including `DELETE` and `TRUNCATE` |
| `resource_revisions` | None | `SELECT`, `INSERT`; no `UPDATE` or `DELETE` | All checked rights, including `UPDATE`, `DELETE`, and `TRUNCATE` |

The effective grants are broader than the migration’s initial `REVOKE ALL` and depend on RLS for authenticated writes. Because `is_admin` is self-elevatable under the live profile grants, that policy dependency is not a safe boundary. The `service_role` and owning role bypass normal RLS protections.

The actual article table allows an authenticated session to attempt `UPDATE`; RLS is the only per-row admin gate. Once a caller can make their own `is_admin` flag true, direct session-bound writes can reach workflow-sensitive fields as an admin. The table checks visible in source (`20261107130100_resource_center_schema.sql:57-62`) check required schedule/publication timestamps and a non-null reviewer identity; they do not encode a transition state machine, review independence, actor identity, or approval of a specific immutable revision.

### 5.2 Public views and mutable publication data

The four public views exist, are owned by `postgres`, and have `security_barrier=true`. The inspected `reloptions` contained no `security_invoker=true`; under the default owner-rights view behavior, the `postgres` view owner (which has `BYPASSRLS`) reads the base relations. The views grant `SELECT` to `anon` and `authenticated`, with no view write rights for those roles.

The live view definitions match the general source design:

- `resource_public_articles` selects the current article’s title, excerpt, `content_markdown`, type, URL/image and other displayed fields from `resource_articles`, joins the active author display fields, and filters to `status='published'`, non-null `published_at`, and `published_at <= now()`.
- `resource_public_article_categories` reads the current join rows and active category data, with a published/due article filter.
- The public identity/category views project active rows.

Neither the article view nor category view reads `resource_revisions.state` or checks `published_revision_id`. Consequently, public content is not a frozen revision snapshot: edits to the live article or association rows can change the currently served page while its status remains published. The security barrier and publication filter do not provide content immutability.

### 5.3 Revision, transaction, audit, and privileged-RPC status

The live constraint inventory confirms `resource_articles_published_revision_fk` is a single-column FK from `resource_articles.published_revision_id` to `resource_revisions.id`; it does not ensure that the selected revision belongs to the same article. Revisions have `UNIQUE(article_id, revision_number)`, but there is no composite constraint tying the article pointer to the revision’s `article_id` (`20261107130100_resource_center_schema.sql:54,82-101`). Authenticated users currently lack direct revision `UPDATE/DELETE` rights, which is a partial restriction, but `service_role` has both; the live catalog found no trigger on any Resource Center table that makes revisions globally append-only. There is no verified database immutability guarantee.

The live trigger query found **no user-defined triggers** on the five Resource Center tables. Both a targeted function-name inventory and a catalog search of public function bodies for references to the Resource Center tables found no Resource Center-specific authoring, review, publication, revision, or audit RPC. The app has public read pages and the guarded read-only admin index described in §4.1, but no Resource Center write endpoint or server action was found. Therefore there is no verified atomic Resource Center transition/publication operation or transition audit trail. This is consistent with A0.4’s backend finding; no wider migration review was repeated.

One adjacent, non-Resource-Center RPC does exist: `public.publish_discovery_candidate(uuid)`. The live definition is `SECURITY DEFINER`, owned by `postgres`, with `search_path=public`; its body checks that `auth.uid()` is non-null and `public.is_admin(actor_id)` before publishing a scholarship candidate. It has effective `EXECUTE` for `authenticated` and, in live ACL, also explicit `anon` (the anon path should fail the function’s null-actor check). The current source route also calls `assertAdmin()` before the RPC (`app/api/admin/discovery/route.ts:30-45`). This RPC is not an existing Resource Center publication mechanism, but it shares the compromised admin helper and therefore inherits the self-elevation risk. Its live anon ACL differs from the latest inspected migration’s `REVOKE ... FROM PUBLIC; GRANT ... TO authenticated` (`0066_require_current_freshness_for_publication.sql:40-41`), indicating ACL drift or an unrecorded grant that requires owner review.

## 6. Production versus non-production environment

**VERIFIED — SOURCE / DATABASE METADATA.** The connected Supabase account listed only `scholarship-platform` and `serena`. The Scholars repository explicitly identifies `scholarship-platform` (`cmdglabohpttgfofcmqc`) as its live project (`supabase/migrations/0001_init.sql:3-12`). It is active/healthy. Its development-branch list is empty. The `serena` project is a separate project and was not queried for Scholars data or used as a substitute.

**VERIFIED — SOURCE.** No tracked `supabase/config.toml` was found. `.env.example` lists variable names but no usable deployment mapping. `.github/workflows/ci.yml:20-31` uses placeholder public Supabase values and runs install, typecheck, tests, and build; it does not apply database migrations. A scoped search of workflows, `package.json`, and `vercel.json` found no Supabase migration-deployment command. `vercel.json:6-10` contains a daily deadline-check cron, not a schema deployment path.

**BLOCKED.** No legitimate isolated Scholars development/staging project or branch is currently established in the connected account. Treat the matched project as production; do not test A1 changes there. Creation of a Supabase branch/project was not authorized or attempted. The Vercel production environment’s `REQUIRE_ADMIN_MFA` value and its mapping to this Supabase project remain unverified.

## 7. Dependency matrix

| Dependency | Existing state | Evidence | Risk | Required resolution |
|---|---|---|---|---|
| Administrator function | Live `SECURITY DEFINER` Boolean lookup of `profiles.is_admin` by caller-supplied UUID; `PUBLIC` execute; arbitrary-UUID status oracle. | **VERIFIED — DATABASE** `pg_proc`, `pg_roles`, `proacl`, `has_function_privilege`; source conflict at migrations 0002 and 0023. | **Critical.** Membership disclosure and reliance on an unsafe, broadly executable helper. | Security owner must approve safe caller semantics and execution scope; validate policies and RPC behavior in an isolated environment. |
| Admin authorization path | Server guards/middleware cover 29 admin API route files, but all trust the same profile flag. Live authenticated users can effectively write that flag on their own row. | **VERIFIED — SOURCE/DATABASE** guard, middleware, policies, effective grants and migrations 0023/0029. | **Critical.** Structural self-elevation defeats route guards and RLS. | Resolve table-wide profile grants and the admin flag trust boundary; independently verify effective privileges and own-row denial before Phase A1. |
| Author/reviewer separation | Identity references exist; no author/reviewer capability model or independent-review constraint. | **VERIFIED — SOURCE** Resource Center migration lines 5-18, 35-63. | High; same person or any platform admin can potentially perform both roles. | Define and enforce editorial capabilities and reviewer independence in DB-backed server operations. |
| MFA/AAL2 | Conditional on `REQUIRE_ADMIN_MFA=true`; no explicit `requireAal2` call site. Production setting unknown. | **VERIFIED — SOURCE / UNVERIFIED — RUNTIME** guard/access/middleware; no Vercel env inspection. | High; editing/publishing might accept AAL1 sessions. | Owner confirms effective production flag without sharing secrets; require and test AAL2 for sensitive editorial actions in staging. |
| RLS and table privileges | RLS on all base tables, not forced; authenticated writes on four tables depend on the vulnerable helper; `service_role` is unrestricted. | **VERIFIED — DATABASE** relation flags, policies, `has_table_privilege`. | Critical until admin flag is protected; service key compromise would bypass all table RLS. | Repair the profile privilege path; test policies per role; keep service-role usage server-only and narrowly authenticated. |
| Public view consistency | Public views are owner-rights, security-barrier projections and read mutable article/category rows. | **VERIFIED — DATABASE** owner/options/`pg_get_viewdef`; `anon`/`authenticated` have SELECT. | High; edits to a published row/join update public content without a reviewed snapshot. | Bind public projection to the exact approved revision and publication record; validate least-privilege view behavior. |
| Immutable revisions | Authenticated cannot directly update/delete revisions; service role can, and no immutability trigger exists. FK does not ensure same-article revision. | **VERIFIED — DATABASE/SOURCE** rights, trigger inventory, migration lines 82-101. | High; snapshots are not globally immutable or correctly bound. | Add DB-enforced append-only and same-article revision invariants, tested in isolation. |
| Publishing transactions | A guarded read-only admin index exists, but no Resource Center publish/schedule RPC, write endpoint, or trigger was found; only unrelated scholarship discovery RPC exists. | **VERIFIED — SOURCE/DATABASE** scoped code/function/trigger inspection; A0.4. | High; no single atomic, guarded editorial publication boundary exists. | Implement only after security/environment gates, using a narrowly authorized transaction and state transition checks. |
| Audit trail | No Resource Center audit table/trigger/RPC found in the scoped current schema/source. | **VERIFIED — SOURCE/DATABASE** targeted inventory; no broad migration review repeated. | Medium-high; no reliable state-transition actor/history record. | Include append-only audit events in the approved transition transaction. |
| Non-production environment | Live Scholars project identified; no branches and no separate Scholars staging project identified; Serena excluded. | **VERIFIED — DATABASE METADATA/SOURCE** project list, branch list, repository project reference. | **Blocking.** No safe target for testing privilege remediation or A1. | Owner provisions/identifies an isolated Scholars staging project/branch and documents project mapping before further implementation. |

## 8. Confirmed risks and unresolved uncertainties

### Confirmed risks

1. **Critical — authenticated profile self-elevation.** The live role has effective `INSERT/UPDATE` on `profiles.is_admin`; own-row RLS permits the authenticated user’s own row; no admin-flag trigger, check constraint, or rule was found. This was not write-tested.
2. **High — arbitrary-UUID administrator oracle.** `anon` and `authenticated` inherit `PUBLIC EXECUTE` on a `SECURITY DEFINER` helper that returns the flag for any supplied UUID. HTTP PostgREST exposure was not probed, so characterize this as verified SQL role access and an oracle capability, not a verified HTTP endpoint.
3. **High — published content is mutable.** Public views read current article/category rows rather than an approved immutable revision. Authenticated admin-level writes are possible directly through the tables; the self-elevation issue can reach those policies.
4. **High — no isolated implementation environment.** The only source-matched Scholars database is identified as live; no development branches exist.
5. **High/uncertain — MFA is conditional.** No evidence establishes that `REQUIRE_ADMIN_MFA` is true in the currently deployed Vercel environment.
6. **Adjacent ACL drift.** Live `publish_discovery_candidate(uuid)` includes explicit `anon` execute although the latest inspected source migration revokes from `PUBLIC` and grants to `authenticated`. Its own body rejects a null `auth.uid()`, but the difference needs owner resolution.

### Unresolved or untested

- Whether the production PostgREST API exposes `public` for direct RPC requests; database `pgrst.db_schemas` and `pgrst.db_anon_role` settings returned NULL in this SQL session. No HTTP call was made.
- Whether production Vercel currently sets `REQUIRE_ADMIN_MFA=true`; no environment values were accessed.
- Whether any account has already exploited the profile privilege path. No user rows, admin identities, logs, or audit data were inspected.
- Whether any live deployment-specific configuration differs from the repository beyond the ACL differences explicitly noted.
- Storage bucket/policy state and service-role deployment secret exposure were outside this targeted read-only verification.

## 9. Minimal owner actions for inaccessible evidence

No additional database credentials or secret values are requested. The following owner checks can resolve the remaining runtime-only facts:

1. In the Supabase Dashboard/API settings for `cmdglabohpttgfofcmqc`, confirm the exposed schemas and whether `public.is_admin` and `publish_discovery_candidate` are reachable through PostgREST. Do not send API keys or tokens. Prefer a disposable staging account/project for any RPC test.
2. In Vercel, confirm whether the effective production deployment has `REQUIRE_ADMIN_MFA` enabled; report only the Boolean setting and deployment/environment name, not secret values.
3. The database/security owner should independently review access logs and admin-role changes for evidence of prior self-elevation, because no live user rows or logs were examined here.
4. Provide or establish an isolated Scholars staging database and confirm its project ref before any remediation test. Do not substitute the `serena` project.

The core self-elevation issue is already established from live catalog evidence; these actions do not change that finding or make Phase A1 safe by themselves.

## 10. Recommended implementation prerequisites

1. Stop and obtain independent security/database-owner review of the live `profiles` grants. Resolve the table-wide authenticated `INSERT/UPDATE` grant so the intended `is_admin` column denial is effective, while preserving only necessary profile-upsert behavior. Do not apply a production change as part of A0.5.
2. Review the `is_admin` function’s caller semantics and grants. Eliminate arbitrary-subject disclosure or remove direct API exposure while preserving a tested, least-privilege RLS policy path. Verify both anon and authenticated behavior without weakening RLS.
3. Review live `publish_discovery_candidate` ACL drift and harden its execution contract in the authorized change phase; its admin check depends on the same helper.
4. Establish and verify an isolated Scholars staging environment. Re-test the effective grants, profile policies, helper ACL/behavior, admin middleware, and Resource Center policies there before considering production rollout.
5. Confirm effective AAL2 enforcement for editing/review/publication and define distinct author/reviewer/publisher capabilities before building endpoints.
6. Design publication around immutable, same-article revision snapshots, transactional transitions, and append-only audit; ensure public views read the approved snapshot rather than mutable draft/current article fields.
7. Preserve the existing server-only service-role boundary. Any future operation using it must have explicit server-side actor/job authorization and be covered by tests that prove browser code cannot import or receive the key.

These are prerequisites, not implemented changes. Phase A1 must wait for independent review and explicit implementation authorization.

## 11. Phase A1 verdict

# **BLOCKED**

The current live database does not satisfy the administrator-flag boundary assumed by the application and A0.4: authenticated users have effective writes to their own `profiles.is_admin` value, and the admin helper plus route/RLS guards trust that value. There is also no verified non-production Scholars environment for safely testing a repair or new editorial operations. The unknown production MFA/API exposure settings add further uncertainty.

Do not begin Resource Center backend implementation, use the current live project as a test target, or treat Serena as staging. Resolve the security issue under a separately authorized review, establish a safe test environment, and re-assess before Phase A1.

## 12. Read-only evidence queries and metadata sources

The following are the SQL/catalog query forms used against project `cmdglabohpttgfofcmqc`; each is read-only and includes an explicit `LIMIT`. No database mutation statements were executed.

### Function definition and owner/security metadata

```sql
select n.nspname as schema_name, p.proname as function_name,
       pg_get_function_identity_arguments(p.oid) as arguments,
       pg_get_function_result(p.oid) as result_type, l.lanname as language,
       r.rolname as owner, r.rolsuper as owner_superuser,
       r.rolbypassrls as owner_bypassrls, p.prosecdef as security_definer,
       p.provolatile as volatility, p.proconfig as function_settings,
       p.proacl::text as stored_acl, pg_get_functiondef(p.oid) as definition
from pg_proc p
join pg_namespace n on n.oid=p.pronamespace
join pg_language l on l.oid=p.prolang
join pg_roles r on r.oid=p.proowner
where n.nspname='public' and p.proname='is_admin'
  and p.pronargs=1 and oidvectortypes(p.proargtypes)='uuid'
limit 5;
```

### Effective helper execution rights

```sql
select p.oid::regprocedure::text as function_signature,
       r.rolname as checked_role,
       has_function_privilege(r.oid,p.oid,'EXECUTE') as can_execute,
       coalesce((select string_agg(
         (case when a.grantee=0 then 'PUBLIC'
               else coalesce(g.rolname,'oid:'||a.grantee::text) end)
         ||':'||a.privilege_type
         ||case when a.is_grantable then ':grantable' else '' end,
         ', ' order by a.grantee,a.privilege_type)
         from aclexplode(coalesce(p.proacl,acldefault('f',p.proowner))) a
         left join pg_roles g on g.oid=a.grantee),
         '(no explicit ACL entries)') as acl_entries
from pg_proc p
join pg_namespace n on n.oid=p.pronamespace
cross join pg_roles r
where n.nspname='public' and p.proname='is_admin'
  and p.pronargs=1 and oidvectortypes(p.proargtypes)='uuid'
  and r.rolname in ('anon','authenticated','service_role','postgres')
limit 10;
```

### Profile table/column grants and profile policies

```sql
select c.relname, pg_get_userbyid(c.relowner) as owner,
       c.relrowsecurity as rls_enabled,
       c.relforcerowsecurity as force_rls, c.relacl::text as table_acl,
       r.rolname as checked_role,
       has_table_privilege(r.oid,c.oid,'INSERT') as can_insert,
       has_table_privilege(r.oid,c.oid,'UPDATE') as can_update,
       has_column_privilege(r.oid,c.oid,'is_admin','INSERT') as can_insert_is_admin,
       has_column_privilege(r.oid,c.oid,'is_admin','UPDATE') as can_update_is_admin
from pg_class c join pg_namespace n on n.oid=c.relnamespace
cross join pg_roles r
where n.nspname='public' and c.relname='profiles'
  and r.rolname in ('anon','authenticated','service_role')
limit 10;
```

```sql
select schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
from pg_policies
where schemaname='public' and tablename='profiles'
limit 100;
```

### Resource Center existence, RLS, view options/definitions, and policies

```sql
select c.relname, c.relkind, pg_get_userbyid(c.relowner) as owner,
       c.relrowsecurity as rls_enabled,
       c.relforcerowsecurity as force_rls,
       c.reloptions as relation_options,
       case when c.relkind='v' then pg_get_viewdef(c.oid,true) else null end
         as view_definition
from pg_class c join pg_namespace n on n.oid=c.relnamespace
where n.nspname='public'
  and c.relname in ('resource_editorial_identities','resource_categories',
    'resource_articles','resource_article_categories','resource_revisions',
    'resource_public_editorial_identities','resource_public_categories',
    'resource_public_articles','resource_public_article_categories')
limit 20;
```

```sql
select c.relname as table_name, r.rolname as checked_role,
       has_table_privilege(r.oid,c.oid,'SELECT') as can_select,
       has_table_privilege(r.oid,c.oid,'INSERT') as can_insert,
       has_table_privilege(r.oid,c.oid,'UPDATE') as can_update,
       has_table_privilege(r.oid,c.oid,'DELETE') as can_delete,
       has_table_privilege(r.oid,c.oid,'TRUNCATE') as can_truncate
from pg_class c join pg_namespace n on n.oid=c.relnamespace
cross join pg_roles r
where n.nspname='public' and c.relkind='r'
  and c.relname in ('resource_editorial_identities','resource_categories',
    'resource_articles','resource_article_categories','resource_revisions')
  and r.rolname in ('anon','authenticated','service_role')
limit 20;
```

```sql
select schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
from pg_policies
where schemaname='public'
  and tablename in ('resource_editorial_identities','resource_categories',
    'resource_articles','resource_article_categories','resource_revisions')
limit 100;
```

### Public function bodies referencing Resource Center tables

```sql
select n.nspname as schema_name, p.proname as function_name,
       pg_get_function_identity_arguments(p.oid) as arguments,
       pg_get_userbyid(p.proowner) as owner,
       p.prosecdef as security_definer,
       p.proconfig as function_settings, p.proacl::text as acl
from pg_proc p join pg_namespace n on n.oid=p.pronamespace
where n.nspname='public'
  and p.prosrc ~* 'resource_(editorial_identities|categories|articles|article_categories|revisions)'
limit 50;
```

### Live Resource Center constraints

```sql
select c.relname as table_name, con.conname as constraint_name,
       con.contype as constraint_type,
       pg_get_constraintdef(con.oid,true) as definition
from pg_constraint con
join pg_class c on c.oid=con.conrelid
join pg_namespace n on n.oid=c.relnamespace
where n.nspname='public'
  and c.relname in ('resource_editorial_identities','resource_categories',
    'resource_articles','resource_article_categories','resource_revisions')
limit 100;
```

Other metadata sources used: Supabase `list_projects`, `get_project`, and `list_branches` for the matched project; `has_table_privilege` for public view grants; `pg_trigger`/`pg_get_triggerdef` for Resource Center and profile triggers; `pg_constraint`/`pg_get_constraintdef` for profile and Resource Center constraints; `pg_rewrite` for profile rules; `pg_get_functiondef` and effective `has_function_privilege` for the adjacent publication RPC; and `current_setting('pgrst.db_schemas', true)` / `current_setting('pgrst.db_anon_role', true)` for the session-visible PostgREST settings.

---

**No application, database, authentication, storage, production configuration, or deployment changes were made.**
