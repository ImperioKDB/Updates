# Scholars — Staging Environment Establishment & Administrator Security Remediation

**Phase:** A0.7 — staging establishment and gated implementation attempt
**Assessment date:** 2026-11-09
**Application repository:** `ImperioKDB/Scholars`
**Documentation repository:** `ImperioKDB/Updates`
**Scholars source baseline:** `cf3682ce35912df7b9b9352193630fc404427c7c`
**Dedicated branch:** `security/admin-authorization-staging` (created locally from the baseline; not pushed)
**Decision:** **BLOCKED at Gate 2.** Gate 1 staging isolation passed. No application remediation, staging schema migration, or deployment was started because a representative Scholars database baseline could not be established from the available authoritative source artifacts without making unsupported assumptions.

## 1. Executive summary

A new, independent Supabase project named `scholars-staging` was created in the confirmed Imperio Org after the user approved its **$0/month** quote. It is healthy in `eu-west-1`, has its own project reference and API host, and starts empty: no Scholars public tables, no applied application migrations, no Auth users, and no Storage buckets were found. No production data, credentials, or secrets were copied.

The current Scholars source does not provide a proven clean-install baseline. The initial SQL file calls itself superseded and warns it is not a drop-in schema. The repository has 129 migration SQL files, duplicate numeric prefixes, 32 filenames containing `seed`, no tracked `supabase/config.toml`, and no canonical schema-only snapshot or migration manifest tying the source to the live schema. The Resource Center migration depends on `public.is_admin(uuid)`, which the source migration chain does not define. A0.5 provides the exact observed live helper definition, but restoring that one function would not establish all evolved application tables, grants/default privileges, triggers, policies, views, or routine bodies. The earlier A0.3 review also identifies data-dependent migration steps and real-data seed content.

Accordingly, no migration was attempted on the new project. Replaying `0001_init.sql`, replaying the full migration directory, or building a partial approximation would fail the task’s baseline-representativeness requirement. Because Gate 2 did not pass, Gates 3–5 were not entered. No Scholars code, application migration, Supabase staging schema, Vercel setting, or production object was changed. The local security branch remains clean and unpushed so it cannot trigger an unisolated Vercel Preview deployment.

## 2. Evidence labels and scope

- **VERIFIED — CURRENT TASK:** directly observed from this task’s repository, Supabase, or Vercel metadata checks.
- **VERIFIED — PRIOR READ-ONLY REVIEW:** a fact established by the cited A0.5/A0.6 report; it was reused rather than re-investigated against production.
- **INFERRED:** follows from verified evidence but was not exercised as a request or state change.
- **NOT TESTED:** no runtime test was run.
- **BLOCKED:** a required prerequisite is missing; work must not proceed past that gate.

This task did not execute SQL against production, read production profile/Auth rows, inspect or decrypt Vercel environment values, copy data, modify Production configuration, or deploy to production. The only staging SQL was an aggregate count query confirming zero Auth users and zero Storage buckets. Staging catalog and project metadata reads were otherwise read-only.

## 3. Gate summary

| Gate | Status | Evidence / reason |
|---|---|---|
| Gate 1 — staging project created and isolated | **PASS** | Separate healthy project/reference/host in Imperio Org; zero Auth users, zero Storage buckets, no Scholars public tables, empty app migration history. No production data or keys copied. |
| Gate 2 — database baseline reconstructed and validated | **BLOCKED** | No authoritative clean-install manifest/snapshot; `0001_init.sql` is explicitly superseded; missing source definition and incomplete provenance remain; replaying seeds or approximating the schema is unsafe. No migration was run. |
| Gate 3 — administrator remediation in staging | **BLOCKED — NOT STARTED** | Gate 2 did not pass. No remediation SQL or application code was written or applied. |
| Gate 4 — security/regression tests | **BLOCKED — NOT TESTED** | No representative database, synthetic Auth accounts, or staging API deployment exists. |
| Gate 5 — production-compatible migration/rollback plan | **BLOCKED — NOT PREPARED** | Compatibility with the production schema cannot be demonstrated from the available baseline. No production migration is authorized by this task. |

## 4. Staging project establishment

| Field | Verified value |
|---|---|
| Project name | `scholars-staging` |
| Project reference | `aqhktriwaglvvrchxmtd` |
| Organization | Imperio Org (`xcygvuivzlascuarwqzl`), same organization as production |
| Organization plan | Free |
| Project quote | $0/month, user-confirmed before creation |
| Region | `eu-west-1` |
| Creation status | `ACTIVE_HEALTHY` |
| Staging API host | `aqhktriwaglvvrchxmtd.supabase.co` |
| Staging database | PostgreSQL 17.11.0.018 (engine 17) |
| Production comparison | `scholarship-platform`, ref `cmdglabohpttgfofcmqc`, also `eu-west-1`, PostgreSQL 17.6.1.155 |

**Isolation checks — PASS:** the staging reference and API host differ from production. The fresh staging project has an independent database and project-scoped Auth/Storage services. `public` contained no Scholars application tables; the application migration history was empty; `auth.users` count was 0; `storage.buckets` count was 0. The built-in Supabase Storage schema exists, as expected, but no bucket or object data was added. No project keys/passwords were retrieved, recorded, or reused. No production records were copied.

**Auth/Storage configuration limits:** the project boundary is independent, but Auth redirect/email/MFA settings were not customized or runtime-verified. No bucket was created because no schema baseline or asset test required one yet. These remain **NOT TESTED**, not assumed configured. The two projects have different PostgreSQL minor versions; that version difference must be considered when evaluating final compatibility.

## 5. Repository and deployment boundaries

### Scholars source and branch

The connected default branch is `main`, at `cf3682ce35912df7b9b9352193630fc404427c7c`. The worktree was clean before and after creating local branch `security/admin-authorization-staging` at that commit. The branch has no code, migration, or configuration changes and was not pushed. A remote branch does not exist.

The relevant current source includes `app/api/profile/route.ts`, `lib/admin/guard.ts`, `lib/admin/access.ts`, `middleware.ts`, `lib/supabase/server.ts`, `lib/supabase/service.ts`, the admin Resource Center index, and public Resource Center reader routes. The admin Resource Center page is read-only; the A0.5 source scan found no Resource Center write/publish handler. The service client is `server-only` and requires `SUPABASE_SERVICE_ROLE_KEY`; it bypasses RLS, so a Preview value must be staging-only.

### Migration/source findings

- `supabase/migrations/0001_init.sql:3-12` identifies itself as superseded, says it differs from the live schema, and describes itself as a starting point to adapt—not a drop-in script.
- `supabase/migrations/0023_lock_admin_flag.sql` attempts to restrict profile DML and protect `is_admin`; `0029_fix_profiles_upsert_table_privileges.sql:1-7` later restores table-wide `INSERT, UPDATE` to `authenticated` and revokes only column-scoped rights. A0.5 verified the live effective-grant regression.
- `supabase/migrations/20261107130100_resource_center_schema.sql` depends on `auth.users`, UUID generation, and `public.is_admin(auth.uid())`; it does not define the admin helper. A0.3 documents additional non-idempotent policy/FK and ownership/view caveats.
- `supabase/migrations/0002_harden_functions.sql` hardens an existing helper but does not supply its body. A0.5 recorded the exact live body as a stable SQL `SECURITY DEFINER` function owned by `postgres`, with empty `search_path`, returning the `profiles.is_admin` flag for the supplied UUID, and `PUBLIC EXECUTE`. That verified live body is not an authoritative source-controlled clean-install migration.
- The repository contains 129 SQL migrations, 32 filenames containing `seed`, repeated version prefixes (including `0002`, `0004`, `0021`, `0023`, `0062`, and others), and no tracked `supabase/config.toml`, `supabase/seed.sql`, or installed Supabase CLI in the inspected workspace. Lexical order alone is not verified as the order applied to the live database.
- Earlier A0.3 findings identify real-data seed content and migrations with data-dependent preconditions. Excluding seed files alone would not prove the remaining migrations produce the current schema or the same grants, RLS, functions, triggers, views, ownership, and default privileges.

### Vercel

The Scholars Vercel project is `scholars` (`prj_n4Unq6wzjbjRT9TcRGKvFD9jIfBk`), linked to `ImperioKDB/Scholars` in the Hobby team. Existing branch deployments appear in Vercel’s deployment history; custom environments count is zero. Project metadata reports SSO protection enabled for deployments except custom domains. The tracked `vercel.json` contains the existing daily deadline-check cron.

No Vercel environment values were retrieved/decrypted or changed. No deployment was triggered by this task. Since the security branch remains unpushed, it has not created a Preview deployment. A branch-scoped Preview mapping to `scholars-staging` is **NOT CONFIGURED/NOT VERIFIED**. Before any future push that could trigger Preview, ensure branch-specific Preview values bind `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, and `REQUIRE_ADMIN_MFA` to staging-only settings for `security/admin-authorization-staging`; never reuse a Production service-role value. The staging service-role key must be entered through an authorized secure settings surface, not sent in chat or placed in source control. Until that isolation can be verified, keep the branch unpushed.

## 6. Gate 2 — baseline reconstruction decision

### What was verified

The newly created staging project is empty of Scholars application schema and data. The repository and A0.3–A0.6 evidence were checked only for the dependencies needed to decide whether a trustworthy baseline could be assembled. Relevant tables begin in an explicitly superseded `0001_init.sql` and are evolved by many later migrations. The code and migrations include Auth-trigger provisioning, profile upsert/delete assumptions, scholarship/application/matching schema, Resource Center policies/views, and routines with role-specific grants. A0.6’s live reference inventory is 55 policy definitions whose expressions mention `is_admin` and eight routine bodies with admin-helper/flag dependencies.

The known eight production-reference routines from A0.6 are `public.is_admin(uuid)`, `get_admin_metrics_summary`, `get_provider_analytics`, `get_daily_visitor_metrics`, `get_auth_confirmation_email_analytics`, `publish_discovery_candidate`, `flag_expired_opportunities`, and `seed_scholarship_prompts`. This is prior production catalog evidence—not a staging inventory. The 55 policy count likewise comes from A0.6; this task did not run production SQL or claim that the empty staging database contains those policies.

### Exact blocker and failure boundary

No SQL migration failed at runtime because none was executed. The blocking failure is the absence of a proven, source-controlled clean-install path that can produce a sufficiently representative schema on this new project:

1. The only initial schema file reviewed is explicitly superseded and incomplete relative to the live project.
2. The exact live helper is not defined in the migration chain. A0.5 provides its catalog definition, but manually injecting it would be a deliberate reconstruction deviation and would solve only one missing object.
3. The repository has no canonical migration manifest/config or schema-only baseline artifact. Duplicate numeric prefixes and the prior audit’s ordering/provenance warnings mean the runner order cannot be inferred safely from filenames alone.
4. The full application baseline must include evolved profile, account-deletion, scholarship/application/matching, Auth-trigger, Resource Center, ACL/default-privilege, view, and routine dependencies. A partial schema assembled from selected files could make tests pass in an artificial model while omitting a live policy or privileged caller.
5. Blindly replaying historical seeds is prohibited; skipping files named `seed` would not resolve data-dependent DDL or prove the resulting final schema. Replaying every migration was therefore not attempted.

This is the A0.3-recommended reconstruction decision point. A reviewed schema-only build artifact or a source-derived reconstruction manifest, with every deviation and required object owner/grant/policy documented, is needed before applying DDL. No missing function was invented or approximated.

## 7. Baseline verification matrix

No baseline behavior test was executed. Every item below is **NOT TESTED** because Gate 2 is blocked.

| Required baseline behavior | Status | Reason |
|---|---|---|
| Ordinary registration / Auth provisioning trigger | **NOT TESTED** | No representative Auth/schema baseline or synthetic account was created. |
| Ordinary profile creation and updates | **NOT TESTED** | Profile table/column grants and final schema are not established in staging. |
| Profile deletion and self-service account deletion | **NOT TESTED** | The profile cascade/deletion schema and application runtime are not available in staging. |
| Legitimate administrator provisioning/access | **NOT TESTED** | No synthetic admin or reviewed staging bootstrap/recovery procedure exists. |
| Public Resource Center reads | **NOT TESTED** | Resource tables/views have not been installed. |
| Resource Center administrative authorization | **NOT TESTED** | No representative policies/helper or authenticated API preview exists. |
| Scholarship applications | **NOT TESTED** | `applications` final DDL, triggers, grants, and required related objects are not established. |
| Matching dependencies | **NOT TESTED** | Final profile/scholarship/rules/functions schema is not established. |
| RLS under `anon` and `authenticated` | **NOT TESTED** | No Scholars app policies are present. |
| Extensions, ownership, ACL/default privileges | **NOT TESTED** | Fresh-project extension inventory is not a substitute for the production-relevant object/grant baseline. |

## 8. Security implementation and dependency verification status

No implementation change was made. In particular, staging still has no Scholars `profiles` table or `is_admin` authority, so no flag trigger, management function, current-user helper, audit table, RLS rewrite, or profile upsert change was written or applied. No A0.6 implementation migration exists from this task.

The A0.6 architectural direction remains the starting point once Gate 2 can pass: retain `profiles.is_admin` as the single platform-admin authority; remove effective ordinary-user writes rather than relying on a column revoke under table-wide DML; protect the flag at the database boundary; preserve ordinary allowlisted profile operations and self-service deletion; replace arbitrary-UUID membership lookup with a caller-bound helper using `auth.uid()`; and provide a narrowly authorized, audited administrator lifecycle/recovery path. This is a recommendation, not implemented staging behavior.

### Policy/routine inventory status

| Dependency class | Prior verified live reference | Staging result |
|---|---:|---|
| RLS policy expressions referencing `is_admin(` | 55 (A0.6) | **NOT TESTED** — no app policies exist in fresh staging. No exact policy inventory generated. |
| Routine bodies referencing admin helper/flag | 8 named above (A0.6) | **NOT TESTED** — no Scholars routines exist in fresh staging. No exact routine inventory generated. |

An exact all-policy/all-routine inventory must be generated from the reconstructed staging database and compared with an explicitly documented source baseline before replacing the helper. Do not treat the A0.6 count as staging evidence.

### API route review (source-only reuse)

A0.5/A0.6 reviewed all 29 `app/api/admin/**/route.ts` files at the same Scholars HEAD. The source review found a server-side `assertAdmin` or equivalent guard in each; no route used client-supplied administrator state as its authorization predicate. The shared guard, middleware, and admin layout all ultimately trust the authenticated user’s `profiles.is_admin` value, so the verified prior live database write weakness undermines that common trust source. These are **VERIFIED — SOURCE / PRIOR READ-ONLY DATABASE** findings. No route was exercised in this task; ordinary-user denial, legitimate-admin access, side-effect ordering, and service-role behavior are **NOT TESTED** here. The detailed A0.6 route matrix is not duplicated in this report.

## 9. Security and regression test results

No security or regression tests were run in this phase. There is no PASS result to report. The following required A0.7 scenarios remain **NOT TESTED**: anonymous admin-route denial; ordinary student admin-API denial; self/other-user `is_admin` modification denial; profile-upsert escalation denial; legitimate administrator access; Resource Center public published read and unpublished denial; unauthorized content mutation denial; ordinary account deletion; administrator deletion/recovery; audit-row immutability; function execution ACLs; trusted nested `SECURITY DEFINER` operations; and scholarship/application/matching regression behavior.

The existing CI workflow uses placeholder public Supabase values and runs install, typecheck, tests, and build; it does not apply database migrations. CI was not run because no application change was made and Gate 2 did not pass. No claim about a new build, Preview, or deployed behavior is made.

## 10. Migration, rollback, and production readiness

No migration or rollback plan was prepared for execution. A0.6’s proposed atomic dependency cutover cannot be made production-compatible until the staging schema, exact grants/owners, current routine bodies, all 55 dependent policy definitions, and all eight routine dependencies are represented and verified. The first future migration must include explicit preconditions and post-migration ACL/policy checks, account for trusted Auth provisioning and nested `SECURITY DEFINER` operations, retain ordinary profile update/delete behavior, and document an owner-controlled administrator recovery procedure. It must be tested only on staging.

Production remains **NO-GO / BLOCKED**. This report authorizes no production SQL, project/configuration change, migration, merge, or deployment. Production differences from the eventual staging schema are unknown and must be resolved before a separately approved production change.

## 11. Exact actions required to resume safely

1. Establish an authoritative **schema-only** baseline source already reviewed for the relevant Scholars revision, or approve a documented source-derived reconstruction manifest that identifies the exact ordered non-seed DDL, data-dependent steps to omit/transform, and every deliberate deviation. It must cover the Auth/profile lifecycle, admin helper and dependencies, scholarships/applications/matching, Resource Center, grants/owners/default privileges, views, functions, triggers, and RLS. Do not include production user records, credentials, tokens, or secrets.
2. Apply that baseline to `aqhktriwaglvvrchxmtd` only. Compare exact staged tables/columns/constraints/indexes/functions/triggers/grants/views/policies with the approved manifest; create synthetic accounts/data only after the baseline is validated.
3. Before pushing the security branch, configure and verify Preview-only, branch-scoped Vercel settings for `security/admin-authorization-staging` so every Supabase URL/key is staging-only. The staging service-role key must be entered via a secure owner-controlled settings flow, never chat or source control. Keep Production variables unchanged. Do not trigger a Preview deployment until this is verified.
4. Establish the private owner-approved bootstrap/recovery procedure for synthetic staging administrators. Do not record administrator identities in the public report.

No owner-supplied secrets are requested. If no authoritative baseline artifact exists, the next decision is whether the database/security owner accepts a bounded, documented reconstruction with known source-versus-live gaps; absent that decision, Gate 2 remains blocked.

## 12. Final status

**Gate 1: PASS. Gate 2: BLOCKED. Gates 3–5: BLOCKED / NOT STARTED. Production readiness: NO-GO.**

The required staging project exists and is isolated. The source does not yet support a defensible representative database baseline, and the task explicitly forbids passing this gate through guesswork. No security code or migration has been applied. The dedicated branch is local, clean, and unpushed; no Preview or production deployment occurred. Work should resume only after the Gate 2 baseline source/reconstruction decision and Preview isolation prerequisites are resolved.

## References

- A0.3 migration/schema reconstruction assessment: `SCHOLARS_RESOURCE_CENTER_PHASE_A0_3_MIGRATION_AND_SCHEMA_RECONSTRUCTION_ASSESSMENT_2026-11-07.md`.
- A0.4 Resource Center backend foundation: `SCHOLARS_RESOURCE_CENTER_PHASE_A0_4_BACKEND_FOUNDATION_SPECIFICATION_2026-11-08.md`.
- A0.5 targeted backend dependency verification: `SCHOLARS_RESOURCE_CENTER_PHASE_A0_5_TARGETED_BACKEND_DEPENDENCY_VERIFICATION_2026-11-08.md`.
- A0.6 administrator authorization remediation specification: `SCHOLARS_ADMIN_AUTHORIZATION_SECURITY_REMEDIATION_SPECIFICATION_A0_6_2026-11-08.md`.
- Scholars migration/source references: `supabase/migrations/0001_init.sql`, `0002_harden_functions.sql`, `0023_lock_admin_flag.sql`, `0029_fix_profiles_upsert_table_privileges.sql`, `20261107130000_security_boundary_remediation.sql`, and `20261107130100_resource_center_schema.sql`.
