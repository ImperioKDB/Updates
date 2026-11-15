# Scholars Resource Centre — Phase 2B Production Database Verification

## 1. Executive summary

This report records the execution of the approved read-only production verification SQL for the Scholars Resource Centre Phase 2B privilege regression. The correct Scholars production Supabase project was identified as **`scholarship-platform`**, project reference **`cmdglabohpttgfofcmqc`**. The separate `serena` project was not used.

The live catalog confirms the central security finding: `authenticated` has effective table-level `INSERT` and `UPDATE` on `public.profiles`, and it also has effective column-level `INSERT` and `UPDATE` on `public.profiles.is_admin`. The live RLS configuration includes the own-row update policy `profiles_update_own` with `USING (auth.uid() = id)` and `WITH CHECK (auth.uid() = id)`. RLS is enabled, but `FORCE ROW LEVEL SECURITY` is false. Therefore, the ordinary authenticated self-elevation path is **VERIFIED — DATABASE**: an authenticated user has the SQL privileges and own-row policy conditions needed to attempt changing their own `is_admin` value. No write or exploit reproduction was performed.

The function checks produced a material inconsistency that is preserved here. Section E.2 reports effective `EXECUTE = true` for `public`, `anon`, `authenticated`, and `service_role` on `public.is_admin(uuid)`, while Sections E.1 and E.3 returned no row for the exact `public.is_admin(uuid)` catalog match. Accordingly, the reported EXECUTE exposure is **VERIFIED — DATABASE** as returned by E.2, but the function's existence, owner, `SECURITY DEFINER` state, configuration/search path, and raw ACL are **UNVERIFIED** because the corresponding catalog queries returned empty sets. The function itself was not called.

**Final verdict: VERIFIED — CRITICAL VULNERABILITY CONFIRMED.** This verdict is based on the independently confirmed live `profiles` privilege and RLS combination. No remediation was attempted.

## 2. Verification date and time

Queries were executed individually in original SQL order on **2026-11-15**, between approximately **14:25:16 and 14:26:22 WAT (UTC+01:00)**. The execution environment recorded the same interval as 13:25:16–13:26:22 UTC. Report generation and publication followed the query run.

## 3. Confirmed project identity

- Supabase project name: `scholarship-platform`
- Supabase project reference: `cmdglabohpttgfofcmqc`
- Region: `eu-west-1`
- Status at discovery: `ACTIVE_HEALTHY`
- Database version reported by Supabase: PostgreSQL 17.6.1.155
- Scholars application repository source cross-check: `ImperioKDB/Scholars`
- Source identity cross-check: `supabase/migrations/0001_init.sql` explicitly references `scholarship-platform` and `cmdglabohpttgfofcmqc`
- Excluded project: `serena` (`nmlhcofasxsngmvjjxti`), which was inactive
- Also not used: `scholars-staging` (`aqhktriwaglvvrchxmtd`)

**Classification:** VERIFIED — DATABASE for the live Supabase project metadata; VERIFIED — SOURCE for the repository project-reference cross-check.

## 4. SQL source and execution method

- Repository: `ImperioKDB/Updates`
- Approved SQL commit: `5f4af4f2c96141a8a920288046952c3f6e189a67`
- Approved SQL path: `reports/scholars/sql/2026-11-15-resource-center-read-only-security-verification.sql`
- Baseline report commit: `ec36b2aa08ac5bf4ccf8ee9635b5c4065cc425a9`
- Baseline report path: `reports/scholars/2026-11-15-resource-center-phase-2b-privilege-regression-correction.md`
- Execution method: Supabase read-only catalog execution against project `cmdglabohpttgfofcmqc`
- Statements executed: 13 SELECT/catalog statements, individually, in original order
- Safety review: the approved file contains SELECT and read-only metadata queries only. No INSERT, UPDATE, DELETE, ALTER, DROP, CREATE, GRANT, REVOKE, TRUNCATE, profile-row reads, arbitrary `public.is_admin(uuid)` calls, secrets, or connection strings were added or executed.
- Tool-bounded execution: each approved SELECT was run as the inner query of a `SELECT * FROM (...) AS verification_result LIMIT 1000` wrapper so the read-only execution interface's explicit-result bound was satisfied. The approved inner SELECT text and all returned values are preserved in the companion results document.

## 5. Execution status by section

| Query ID | Section | Status | Result |
|---|---|---|---|
| Q01 | A.1 Schema USAGE/CREATE | Succeeded | 4 rows |
| Q02 | B.1 Role memberships | Succeeded | 9 rows |
| Q03 | B.2 Role attributes | Succeeded | 3 rows |
| Q04 | C.1 Effective table INSERT/UPDATE | Succeeded | 4 rows |
| Q05 | C.2 Effective `is_admin` column INSERT/UPDATE | Succeeded | 4 rows |
| Q06 | C.3 Ordinary-column comparison | Succeeded | 2 rows |
| Q07 | D.1 RLS and FORCE RLS | Succeeded | 1 row |
| Q08 | D.2 RLS policies | Succeeded | 6 rows |
| Q09 | D.3 Effective table grants | Succeeded | 19 rows |
| Q10 | D.4 Effective `is_admin` column grants | Succeeded | 12 rows |
| Q11 | E.1 Function metadata | Succeeded | Empty result set |
| Q12 | E.2 Effective function EXECUTE | Succeeded | 4 rows |
| Q13 | E.3 Raw function ACL | Succeeded | Empty result set |

No query returned an execution error. Empty result sets are preserved and are not treated as failures.

## 6. Analysis: `profiles.is_admin` privilege regression

### 6.1 Live effective privileges

Section C.1 directly reports:

- `authenticated`: table-level INSERT = `true`; table-level UPDATE = `true`
- `anon`: table-level INSERT = `false`; table-level UPDATE = `false`
- `service_role`: table-level INSERT = `true`; table-level UPDATE = `true`
- `public`: table-level INSERT = `false`; table-level UPDATE = `false`

Section C.2 directly reports for `authenticated` on `is_admin`:

- column-level INSERT = `true`
- column-level UPDATE = `true`

Section C.3 reports both `full_name` and `is_admin` as column-level UPDATE = `true` for `authenticated`. Section D.3 independently lists `authenticated` table-level `INSERT` and `UPDATE`. Section D.4 independently lists `authenticated` column-level `INSERT` and `UPDATE` on `is_admin`.

**Classification:** VERIFIED — DATABASE.

### 6.2 RLS conditions

Section D.1 reports `public.profiles` with `rls_enabled = true`, `force_rls = false`, and owner `postgres`.

Section D.2 reports the following relevant policies:

- `profiles_update_own`, command `w`, role `authenticated`, `USING (auth.uid() = id)`, `WITH CHECK (auth.uid() = id)`
- `profiles_update_community_role_admin`, command `w`, role `authenticated`, `USING (is_admin(auth.uid()))`, `WITH CHECK (is_admin(auth.uid()))`
- `profiles_insert_own`, command `a`, role `authenticated`, `WITH CHECK (auth.uid() = id)`
- `profiles_delete_own`, command `d`, role `authenticated`, `USING (auth.uid() = id)`

The own-row policy is therefore present in the live database. RLS limits rows but does not revoke SQL table or column privileges. Because the live SQL privilege checks are true and the own-row `USING` and `WITH CHECK` expressions both match the authenticated user's own row, the database has no structural privilege barrier preventing a self-update of `is_admin` through an ordinary database-supported write path.

**Classification:** VERIFIED — DATABASE.

### 6.3 Comparison with source findings

The previous Phase 2B baseline classified the following as VERIFIED — SOURCE only:

1. Migration `0029_fix_profiles_upsert_table_privileges.sql:4` grants table-level `INSERT, UPDATE` to `authenticated`.
2. Migration `0029:5-6` revokes `is_admin` column privileges, but a column-level revoke cannot cancel a table-level grant.
3. Migration `0023_lock_admin_flag.sql:85-91` creates `profiles_update_own`.
4. No later migration in the reviewed source corrects the table-level grant.

The live results now promote the central privilege regression from source-supported/unverified to **VERIFIED — DATABASE**. The result is not dependent on grant order.

## 7. RLS and FORCE RLS assessment

- RLS enabled: `true` — VERIFIED — DATABASE
- FORCE RLS: `false` — VERIFIED — DATABASE
- Table owner: `postgres` — VERIFIED — DATABASE
- Own-row update policy: present with exact expressions shown above — VERIFIED — DATABASE

`FORCE RLS = false` is a defense-in-depth weakness for owner-mediated access, although the critical ordinary-user self-elevation finding is already established by the effective `authenticated` privileges plus the own-row policy.

## 8. `public.is_admin(uuid)` exposure

Section E.2 reports:

| Role | Effective EXECUTE |
|---|---|
| `public` | `true` |
| `anon` | `true` |
| `authenticated` | `true` |
| `service_role` | `true` |

This is a direct live privilege result and is classified **VERIFIED — DATABASE** as returned by the approved query. It indicates that the privilege check reports PUBLIC-level execution exposure, which also covers `anon` and `authenticated`.

However, Sections E.1 and E.3 both returned empty result sets for the exact catalog predicate `public.is_admin(uuid)`. Consequently, the following are **UNVERIFIED**: function existence under that exact catalog identity, owner, `SECURITY DEFINER`, configured search path, function kind, and raw ACL. The discrepancy is recorded as an unresolved live-catalog inconsistency; no additional query was substituted, and the function was not executed.

The safe conclusion is: **EXECUTE exposure is confirmed by E.2, but the function metadata and exact ACL are not confirmed by E.1/E.3.**

## 9. Role inheritance findings

Section B.1 found no membership rows where `anon`, `authenticated`, or `service_role` is the `member_role`. It did find these roles as `granted_role` to other database roles:

- `authenticator` receives `anon`, `authenticated`, and `service_role`; all three memberships report `inherits_privileges = false` and `can_set_role = true`.
- `postgres` receives all three; memberships report `inherits_privileges = true` and `can_set_role = true`, with `can_admin_grant = true`.
- `supabase_realtime_admin` receives all three; memberships report `inherits_privileges = false` and `can_set_role = true`.

Section B.2 reports `anon`, `authenticated`, and `service_role` as non-login, non-superuser roles with `inherits_by_default = true`.

The direction is important: `member_role` is the role receiving membership; `granted_role` is the role whose privileges may be inherited. `PUBLIC` is not represented as an ordinary `pg_auth_members` row and must not be interpreted as one.

**Classification:** VERIFIED — DATABASE.

## 10. Security risk assessment

**Critical:** The live database confirms an ordinary `authenticated` role can structurally write `profiles.is_admin` on its own profile row. This is a privilege-escalation/self-elevation condition, even though the actual write was not attempted.

**High:** `FORCE RLS` is disabled on `public.profiles`. This does not create the ordinary-user finding by itself, but it leaves owner-mediated access outside forced RLS coverage.

**High / unresolved metadata:** E.2 reports PUBLIC/anon/authenticated EXECUTE on `public.is_admin(uuid)`, which would expose a boolean admin-membership oracle if the exact function exists as assumed. E.1/E.3 returned no exact function row, so the implementation and ACL details remain unresolved.

No personal profile records, authentication records, secrets, access tokens, passwords, or service-role keys were read or included.

## 11. Remaining unknowns

1. Why E.2 reports `true` for `public.is_admin(uuid)` while E.1 and E.3 return no exact catalog row.
2. The exact owner, `SECURITY DEFINER` setting, `search_path`, function kind, and raw ACL for the function referenced by E.2.
3. Whether the E.2 privilege target resolves to an overloaded or differently represented function identity not matched by the E.1/E.3 text predicate.
4. Whether any application-layer behavior or external control prevents exploitation; this was intentionally not tested.
5. Whether `postgres` owner access is relevant to any production request path; this was not reproduced.

These unknowns do not negate the independently confirmed `profiles.is_admin` privilege regression.

## 12. Recommended remediation priorities (not implemented)

1. Immediately remove effective table-level `INSERT` and `UPDATE` from `authenticated` on `public.profiles`; replace them with narrowly scoped column privileges that exclude `is_admin`, and verify both table- and column-level effective privileges afterward.
2. Preserve or strengthen the intended own-profile RLS behavior while ensuring it cannot be combined with a writable admin flag.
3. Resolve the E.1/E.2/E.3 function inconsistency, then ensure the helper has a fixed, safe search path and only the minimum execution exposure needed for policy evaluation; verify the exact live ACL afterward.
4. Evaluate whether `FORCE ROW LEVEL SECURITY` is required for the production ownership model.
5. Add a regression check to migration/deployment verification so table-level grants cannot silently reintroduce writable privileged columns.

No remediation, migration, privilege change, function change, RLS change, deployment, or source-code change was performed in this task.

## 13. Final verdict

**VERIFIED — CRITICAL VULNERABILITY CONFIRMED**

The live production database directly confirms the critical `profiles.is_admin` self-elevation path through effective `authenticated` table/column privileges combined with the own-row update policy. Function EXECUTE exposure is also reported by the approved E.2 query, but exact function metadata remains unresolved because E.1 and E.3 returned empty sets. This report stops at verification and publication, as required.
