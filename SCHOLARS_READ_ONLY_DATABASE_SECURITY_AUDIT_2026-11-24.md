# Scholars — Read-Only Database Security Audit

**Repository audited:** `ImperioKDB/Scholars`  
**Audited branch:** `main`  
**Inspected revision:** `c209862cd7e4b8e8d2cd0bfb1e7d0f56420582e9`  
**Target report repository:** `ImperioKDB/Updates`  
**Scope:** Repository and application-code inspection only  
**Production SQL executed:** No  
**Scholars files, migrations, Supabase settings, policies, and data modified during the audit:** No

## 1. Executive summary

The repository contains a serious privilege-escalation risk in the evolution of `public.profiles`.

Migration `0023_lock_admin_flag.sql` attempts to protect `profiles.is_admin` with column-level revokes. However, migration `0029_fix_profiles_upsert_table_privileges.sql` later grants table-level `INSERT` and `UPDATE` privileges to the `authenticated` role:

```sql
grant insert, update on table public.profiles to authenticated;
revoke insert (is_admin), update (is_admin)
  on table public.profiles from authenticated;
```

The later column-level revoke does not neutralize an existing table-level grant. If this migration sequence is present in production, an authenticated user may be able to update protected profile columns directly through PostgREST/Supabase, subject only to the owner-row RLS policy. The same problem affects `community_role`, which is explicitly granted in `0056_add_community_layer.sql`.

The application API schema does not accept `is_admin`, but that is not a sufficient database security boundary because users can call Supabase directly with the public authenticated client role.

Production exposure is **not confirmed**, because the repository contains comments stating that some migrations are reference-only, feature-branch migrations, or were applied manually. The actual Supabase migration history and effective ACLs were not inspected, in accordance with the original read-only operating rules.

The repository also has substantial migration-integrity risk: **139 SQL migration files**, duplicate numeric prefixes, a mixed legacy/timestamp naming scheme, missing numeric prefixes, reference-only migrations mixed with executable migrations, and migrations that are not consistently safely rerunnable.

The most important production verification is to inspect the effective table and column privileges for `public.profiles`, active policies and triggers, deployed function ACLs, and the actual Supabase migration history.

## 2. Confirmed vulnerabilities

### SCH-DB-001 — Authenticated users may regain write access to `profiles.is_admin`

**Severity:** CRITICAL  
**Affected component:** `public.profiles.is_admin`  
**Production exposure:** Confirmed in repository logic; production exposure unverified

#### Evidence

`supabase/migrations/0023_lock_admin_flag.sql:48-83` grants column-level profile updates and revokes `is_admin`:

```sql
grant update (...) on table public.profiles to authenticated;
revoke insert (is_admin), update (is_admin)
  on table public.profiles
  from anon, authenticated;
```

`supabase/migrations/0028_fix_profiles_authenticated_update_privilege.sql:4-33` restores column-level updates.

However, `supabase/migrations/0029_fix_profiles_upsert_table_privileges.sql:4-6` later adds:

```sql
grant insert, update on table public.profiles to authenticated;
revoke insert (is_admin), update (is_admin)
  on table public.profiles from authenticated;
```

The table-level grant gives the role general table `INSERT` and `UPDATE` capability. The subsequent column-level revoke does not reliably remove the effective table-level privilege.

The profile RLS policy in `0023` permits the authenticated user to update their own row:

```sql
using (auth.uid() = id)
with check (auth.uid() = id);
```

RLS restricts the row, not the sensitive column. Therefore, if the table-level ACL exists in production, a user may be able to submit an update to their own row containing `{ "is_admin": true }`.

#### Exploit or failure scenario

An authenticated user bypasses the Next.js profile API and sends a direct Supabase REST or client-library update against their own profile row.

#### Actual impact

A self-elevated user may pass checks such as `profile?.is_admin === true` in `lib/admin/guard.ts:38-51`, potentially gaining access to administrative routes, analytics, editorial tools, moderation operations, broadcasts, and service-backed workflows.

#### Recommended repair

Remove table-level `INSERT` and `UPDATE` grants from `authenticated`. Use explicit column-level grants only, or route profile writes through a controlled server-side function that allowlists permitted columns. Verify the effective ACL after deployment.

#### Regression tests required

- Authenticated user cannot update `profiles.is_admin`.
- Authenticated user cannot insert a row with `is_admin = true`.
- Existing admins retain admin access.
- Service-role/admin maintenance operations continue to work.
- Direct PostgREST requests are tested separately from the Next.js API.

### SCH-DB-002 — Authenticated users may self-assign privileged `community_role`

**Severity:** HIGH  
**Affected component:** `public.profiles.community_role`  
**Production exposure:** Confirmed in repository logic; production exposure unverified

`supabase/migrations/0056_add_community_layer.sql:20-26` grants:

```sql
GRANT UPDATE (community_role) ON public.profiles TO authenticated;
```

It then creates an admin-only policy:

```sql
CREATE POLICY profiles_update_community_role_admin
  ON public.profiles
  FOR UPDATE TO authenticated
  USING (public.is_admin(auth.uid()))
  WITH CHECK (public.is_admin(auth.uid()));
```

The earlier table-level `UPDATE` grant from `0029` remains in effect. The ordinary owner-update policy and the admin-only policy are permissive policies combined with OR semantics. Therefore, the owner policy can allow a user to update their own row while the ACL allows updates to `community_role`.

#### Exploit or failure scenario

A normal authenticated user directly updates their own profile with `{ "community_role": "contributor" }`.

#### Actual impact

Users may obtain contributor-level presentation or moderation-adjacent privileges and create misleading public contributor identities.

#### Recommended repair

Do not grant `UPDATE (community_role)` to ordinary authenticated users. Use a service-role or tightly controlled admin RPC for role changes. Revoke broad table-level profile update privileges.

#### Regression tests required

- Student cannot update `community_role`.
- Contributor cannot promote themselves to founder.
- Admin role-management endpoint assigns only allowed roles.
- RLS and ACL behavior are tested through direct Supabase requests.

### SCH-DB-003 — Profile API and database boundaries rely on each other inconsistently

**Severity:** MEDIUM  
**Affected component:** `app/api/profile/route.ts`, `public.profiles`  
**Production exposure:** Repository-confirmed design weakness

The API uses a Zod allowlist in `app/api/profile/route.ts:36-79`, which excludes `is_admin` and `community_role`. However, the route writes with:

```ts
.from('profiles')
.upsert({ id: user.id, ...parsed.data }, { onConflict: 'id' })
```

The application allowlist is useful but is not a database security boundary. A public Supabase client can bypass this route entirely.

#### Recommended repair

Treat database ACL/RLS as authoritative. Keep application validation as defense in depth, but remove broad table-level profile grants.

## 3. Potential vulnerabilities requiring production verification

### SCH-DB-004 — Anonymous discussion RPC may expose community data if hardening is absent

**Severity:** HIGH  
**Affected component:** `get_scholarship_discussions(uuid,text,integer)`  
**Production exposure:** Unverified

`supabase/migrations/0056_add_community_layer.sql:268-374` creates a `SECURITY DEFINER` RPC and grants execution to both `anon` and `authenticated`:

```sql
GRANT EXECUTE ON FUNCTION public.get_scholarship_discussions(...)
TO anon, authenticated;
```

The function returns discussion content and author presentation fields including `author_name`, `author_avatar_url`, `author_role`, and `author_is_online`.

A later migration, `20261111032810_global_opportunity_access_hardening.sql:194-201`, revokes anonymous execution. Because production application is not confirmed, anonymous RPC exposure remains unresolved.

**Required verification:** Inspect `pg_proc.proacl` for the function and confirm the effective `anon` ACL.

### SCH-DB-005 — Legacy public preview views may expose broader columns

**Severity:** MEDIUM  
**Affected component:** `opportunity_public_previews`, `scholarship_public_previews`  
**Production exposure:** Unverified

`20261111033130_revoke_legacy_preview_view_anon.sql` revokes anonymous access to legacy views. Until that migration is confirmed in production, old views may remain queryable by anonymous users.

**Required verification:** Inspect `pg_views.definition`, `information_schema.role_table_grants`, `pg_class.relacl`, and approved anonymous REST behavior for the view names.

### SCH-DB-006 — Storage buckets are intentionally publicly readable

**Severity:** INFORMATIONAL / MEDIUM depending on data expectations  
**Affected component:** Storage buckets `avatars` and `site`  
**Production exposure:** Repository-confirmed intent; deployed state unverified

`0010_add_profile_avatars.sql` creates a public-read `avatars` policy:

```sql
create policy "avatars_public_read"
on storage.objects for select
using (bucket_id = 'avatars');
```

`0013_add_site_assets_bucket.sql` similarly makes all `site` objects publicly readable. This is consistent with the comments, but any object in those buckets is publicly retrievable if its path is known or discoverable.

**Recommended review:** Separate public and private buckets, or restrict policies to approved object prefixes.

## 4. High-risk database design decisions

### SCH-DB-007 — Administrative authorization depends on a mutable profile row

**Severity:** HIGH  
**Affected component:** `profiles.is_admin`, application admin guards  
**Production exposure:** Design confirmed; exploit depends on effective ACLs

Administrative authorization repeatedly depends on `public.is_admin(auth.uid())` or application-side reads of `profiles.is_admin`. This is acceptable only if the column is strictly immutable to ordinary roles. The migration sequence does not consistently preserve that invariant.

### SCH-DB-008 — SECURITY DEFINER functions require deployment-state verification

**Severity:** MEDIUM  
**Affected component:** Multiple public functions  
**Production exposure:** Unverified

The repository contains many `SECURITY DEFINER` functions, including discussion, analytics, discovery publication, maintenance, notification, workflow, and visitor-metrics functions. Each requires verification of `prosecdef`, `proconfig`, owner, `proacl`, schema qualification, and execution grants to `PUBLIC`, `anon`, or `authenticated`.

Repository hardening migrations revoke broad execution in several cases, but production application is not confirmed.

## 5. Migration integrity findings

### SCH-DB-009 — Duplicate migration version prefixes

**Severity:** HIGH  
**Affected component:** `supabase/migrations/`  
**Production exposure:** Repository-confirmed integrity risk

The repository contains 139 SQL migration files with duplicate numeric prefixes, including `0002`, `0004`, `0006`, `0015`, `0021`, `0023`, `0034`, `0035`, `0045`, `0046`, `0052`, `0057`, `0061`, `0062`, `0063`, `0078`, `0087`, `0102`, and `0103`.

It also mixes legacy numeric filenames with timestamp filenames beginning at `20261107130000_security_boundary_remediation.sql`. Ordering is ambiguous unless the deployment system uses the full filename as the migration key and the team has documented ordering rules.

### SCH-DB-010 — Repository migration history is not self-contained

**Severity:** HIGH  
**Affected component:** early migrations  
**Production exposure:** Repository-confirmed; production state unknown

`0001_init.sql` explicitly states that it is superseded and differs from the live project. `0002_harden_functions.sql` attempts to alter functions such as `set_updated_at()`, `calculate_profile_completeness(profiles)`, and `is_admin(uuid)` that are not all defined by `0001_init.sql`.

A clean replay of this repository therefore does not establish the same schema as production.

### SCH-DB-011 — Several migrations are reference-only or manually applied

**Severity:** MEDIUM  
**Affected component:** migrations `0010` and `0013`, among others  
**Production exposure:** Unverified

`0010_add_profile_avatars.sql` and `0013_add_site_assets_bucket.sql` state that they were applied live through the Supabase SQL editor and are reference records only. Other timestamped migrations describe themselves as feature-branch migrations that should not be applied without review.

Repository filename presence is therefore insufficient evidence of production state.

### SCH-DB-012 — Migration idempotency is inconsistent

**Severity:** MEDIUM  
**Affected component:** migration replay and recovery  
**Production exposure:** Repository-confirmed reliability risk

Many migrations use `CREATE POLICY`, `CREATE TRIGGER`, or `ALTER TABLE ADD CONSTRAINT` without consistent existence guards. Re-running such migrations can fail partway through and leave partial state unless the deployment runner provides transactional handling.

## 6. Performance and scalability risks

### SCH-PERF-001 — Email digest performs unbounded reads

**Severity:** HIGH at scale  
**Affected component:** `lib/email/digest.ts:59-77`  
**Production exposure:** Code-confirmed; query-plan impact unverified

The digest reads all profiles and recent verified listings without explicit limits, and reads up to 100,000 announcement-log rows. At 100,000+ users this can cause high memory usage, long serverless execution times, and incomplete processing.

**Recommended repair:** Cursor pagination, bounded campaign batches, indexed date/dedupe queries, and a durable campaign work queue.

### SCH-PERF-002 — Profile nudge worker loads complete profile rows

**Severity:** HIGH at scale  
**Affected component:** `lib/email/profileNudges.ts:169-180`  
**Production exposure:** Code-confirmed

The worker executes:

```ts
.from('profiles')
.select('*')
.lt('profile_completeness', 100)
```

There is no database-side limit or pagination. Full profile rows include personal and eligibility fields not all required by the campaign.

**Recommended repair:** Select only required columns and paginate by a stable key.

### SCH-PERF-003 — Re-engagement processing silently truncates datasets

**Severity:** MEDIUM/HIGH  
**Affected component:** `app/api/admin/reengagement/route.ts:54-70`  
**Production exposure:** Code-confirmed

The route limits profiles to 1,000, events/saved scholarships/applications to 10,000 each, and Auth users to at most 10,000. It creates assignments from those truncated sets without reporting incomplete source data.

**Recommended repair:** Use paginated reads or database-side segmentation queries and return explicit completeness/cursor status.

### SCH-PERF-004 — Profile endpoints over-fetch sensitive data

**Severity:** MEDIUM  
**Affected component:** `app/api/profile/route.ts:103-107`, `140-143`  
**Production exposure:** Code-confirmed but owner-scoped by RLS

Both GET and POST return `select('*')`. RLS restricts the result to the current user, but future sensitive-column additions would automatically appear in API responses.

**Recommended repair:** Use explicit response projections.

### SCH-PERF-005 — Potential correlated counting in community RPC

**Severity:** MEDIUM  
**Affected component:** `0056_add_community_layer.sql:342-372`  
**Production exposure:** Code-confirmed query pattern; query plan unverified

`get_scholarship_discussions` computes `reply_count` using a correlated count for each visible discussion row. The RPC limits output to 100 rows, but the underlying work can become expensive as discussion tables grow.

**Required verification:** An approved read-only `EXPLAIN (FORMAT JSON)` on representative production-sized data.

## 7. Evidence for the primary finding

The highest-risk evidence chain is:

1. `0023_lock_admin_flag.sql` tries to revoke sensitive profile columns.
2. `0028_fix_profiles_authenticated_update_privilege.sql` restores ordinary profile update columns.
3. `0029_fix_profiles_upsert_table_privileges.sql` grants table-wide `INSERT` and `UPDATE`.
4. `0056_add_community_layer.sql` grants `UPDATE (community_role)` and relies on an admin-only policy.
5. `0094` and `0095` protect WhatsApp consent fields only; neither protects `is_admin` nor `community_role`.
6. `app/api/profile/route.ts` protects fields at the application layer but does not protect direct Supabase access.
7. `lib/admin/guard.ts` trusts `profiles.is_admin`.

This is a complete privilege-escalation path if the broad ACL from `0029` is present in production.

## 8. Exact production metadata needed

The following metadata is required to resolve production uncertainty. These queries are read-only and were not executed during this audit.

### Migration history

```sql
SELECT version, name
FROM supabase_migrations.schema_migrations
ORDER BY version
LIMIT 500;
```

### Effective profile table privileges

```sql
SELECT grantee, privilege_type, is_grantable
FROM information_schema.role_table_grants
WHERE table_schema = 'public'
  AND table_name = 'profiles'
  AND grantee IN ('public', 'anon', 'authenticated', 'service_role')
ORDER BY grantee, privilege_type
LIMIT 100;
```

### Effective profile column privileges

```sql
SELECT grantee, column_name, privilege_type, is_grantable
FROM information_schema.column_privileges
WHERE table_schema = 'public'
  AND table_name = 'profiles'
  AND grantee IN ('public', 'anon', 'authenticated', 'service_role')
  AND column_name IN ('is_admin', 'community_role')
ORDER BY grantee, column_name, privilege_type
LIMIT 100;
```

### Active profile policies

```sql
SELECT schemaname, tablename, policyname, permissive, roles,
       cmd, qual, with_check
FROM pg_catalog.pg_policies
WHERE schemaname = 'public'
  AND tablename = 'profiles'
ORDER BY policyname
LIMIT 100;
```

### Profile triggers

```sql
SELECT n.nspname AS schema_name,
       c.relname AS table_name,
       t.tgname AS trigger_name,
       pg_get_triggerdef(t.oid) AS trigger_definition,
       p.proname AS function_name
FROM pg_trigger t
JOIN pg_class c ON c.oid = t.tgrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
JOIN pg_proc p ON p.oid = t.tgfoid
WHERE n.nspname = 'public'
  AND c.relname = 'profiles'
  AND NOT t.tgisinternal
ORDER BY t.tgname
LIMIT 100;
```

### Function security and ACLs

```sql
SELECT n.nspname AS schema_name,
       p.proname,
       pg_get_function_identity_arguments(p.oid) AS arguments,
       p.prosecdef AS security_definer,
       p.proconfig,
       p.proacl
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
ORDER BY p.proname
LIMIT 500;
```

### Public preview view definitions and grants

```sql
SELECT schemaname, viewname, definition
FROM pg_catalog.pg_views
WHERE schemaname = 'public'
  AND viewname IN (
    'opportunity_public_previews',
    'scholarship_public_previews',
    'opportunities_public_preview_v1',
    'scholarships_public_preview_v1'
  )
ORDER BY viewname
LIMIT 20;
```

### Storage policies

```sql
SELECT schemaname, tablename, policyname, permissive, roles,
       cmd, qual, with_check
FROM pg_catalog.pg_policies
WHERE schemaname = 'storage'
  AND tablename = 'objects'
ORDER BY policyname
LIMIT 200;
```

## 9. Recommended repairs, without implementation

1. Remove table-level `INSERT` and `UPDATE` privileges from `authenticated` on `public.profiles`.
2. Re-grant only an explicit allowlist of ordinary profile columns.
3. Ensure `is_admin`, `community_role`, and future privileged columns are absent from ordinary-role grants.
4. Move community-role changes to a dedicated admin-only RPC or service-role route.
5. Add a database regression test attempting direct authenticated updates to `is_admin` and `community_role`.
6. Establish one canonical migration naming/order system.
7. Separate reference-only/manual SQL from executable migrations.
8. Record the real production migration history in a verifiable deployment artifact.
9. Paginate digest, profile-nudge, and re-engagement queries.
10. Replace wildcard profile responses with explicit projections.
11. Review whether all objects in the public `site` storage bucket should be publicly readable.
12. Verify every `SECURITY DEFINER` function’s owner, ACL, search path, and schema qualification.

## 10. Prioritized remediation plan

1. **CRITICAL:** Verify and remove effective `authenticated` table-level `INSERT`/`UPDATE` privileges on `public.profiles`.
2. **CRITICAL:** Test direct Supabase/PostgREST writes to `is_admin` and `community_role` using a non-admin authenticated account.
3. **HIGH:** Replace role assignment with a dedicated admin-only database/API path.
4. **HIGH:** Verify production function ACLs and anonymous access to discussion and legacy preview RPCs/views.
5. **HIGH:** Reconcile production migration history with repository history.
6. **MEDIUM:** Normalize migration naming and eliminate duplicate-prefix ambiguity.
7. **MEDIUM:** Paginate high-volume worker queries and eliminate `select('*')` in campaign paths.
8. **LOW/INFORMATIONAL:** Review intentionally public storage buckets and document their data-classification expectations.

No repairs to Scholars or Supabase were implemented as part of the audit. This report is an inspection artifact only.
