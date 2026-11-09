# Scholars Phase 2.1.1 — Manus Session Handoff

**Prepared:** 2026-11-09
**Purpose:** Resume the Scholars production security investigation from the exact stopping point of the previous Manus session.
**Status:** Audit and documentation package complete; no implementation authorized or performed.

## Start here

1. Read the five documents in `documents/`. The executive report is the entry point; the privilege matrix is the detailed evidence inventory, followed by target design, remediation/rollback plan, and test specification.
2. Confirm the GitHub state at Updates commit [`013087318da98e6739611f44d8f84fed3fa96705`](https://github.com/ImperioKDB/Updates/commit/013087318da98e6739611f44d8f84fed3fa96705). That documentation-only commit was pushed to `ImperioKDB/Updates` branch `main`; remote `main` was verified at the same SHA and the local checkout was clean.
3. Read project files `01_PRD.md`, `Anti AI slop for Frontend skill.md`, and `Animation Skill.md` only if later work touches the application UX/frontend. They were not changed by this audit.
4. Do not apply SQL, ACL, RLS, function, environment, storage, application-code, or deployment changes without explicit authorization for the implementation phase. The existing project working convention requests direct pushes/deployment for authorized code changes; it does not override the audit's expressly read-only state or unresolved product/security decisions.

## Repositories and commits

- Documentation repository: `https://github.com/ImperioKDB/Updates`, branch `main`.
- Completed handoff commit: `013087318da98e6739611f44d8f84fed3fa96705` (`docs: add Scholars production security review`). It adds exactly five Markdown deliverables.
- Previous Updates baseline: `912158f9a7043aa744531275d78d44d164c9c05f`.
- Phase 2.1 baseline security-policy document was referenced at commit `abb19a697703aab91f783b8e5258acebf35bf02a`.
- Application repository inspected read-only: `https://github.com/ImperioKDB/Scholars`, source commit `cf3682ce35912df7b9b9352193630fc404427c7c`. No app changes were made.
- Supabase project inspected read-only: `cmdglabohpttgfofcmqc` (`eu-west-1`). No production or staging changes were made.

## Executive findings

- All 11 in-scope production tables had direct browser-role ACLs equivalent to `arwdDxtm` for `anon` and `authenticated`, despite RLS. RLS protects ordinary row operations but does not supply column projections and does not filter TRUNCATE.
- The live catalog contained 31 public `SECURITY DEFINER` functions: 23 had effective EXECUTE for `anon` and `authenticated`; eight were restricted to `postgres`/`service_role`. A separate query found 10 browser-executable non-definer functions.
- Specific RPC concerns include `is_admin(uuid)` executable by PUBLIC (arbitrary profile admin-status oracle); `get_admin_metrics_summary(timestamptz)` with an application-outcome aggregate outside its admin-filtered event query; exact public social-proof metrics without small-cohort suppression; trending IDs with caller-controlled threshold/window; online presence in discussion results; and cross-profile `run_achievement_checks(uuid)` side effects.
- The `publish_discovery_candidate(uuid)` definer function has meaningful in-body authorization/readiness gates but remains a privileged write RPC and should be narrowly granted and fully tested.
- `exec_sql` was absent from the live function catalog. The admin schema-check application route attempts it and falls back; no SQL-execution RPC was found.
- `supabase_admin` future default privileges remain broader than `postgres` defaults. The checked-in security-remediation migration only changed defaults for `postgres` and did not remediate existing ACLs.
- The production migration ledger is not fully mapped to checked-in migrations (including opportunities creation and cycle-events migration provenance). The current `scholars-staging` project did not have a Scholars schema/migration baseline and is not ready for these tests.

## Evidence limits and safety boundary

The review used read-only Supabase metadata, migration-ledger, project-advisor inspection and static code review. It did not read application rows, user data, secrets, or credentials; did not call production HTTP/RPC endpoints; and did not run destructive tests. Thus direct table-route HTTP behavior, exact deployed PostgREST exposed-schema configuration, and actual trigger-function HTTP invocation remain unverified. An ACL is not itself proof that a specific HTTP request succeeds. The audit made no changes to production, staging, Scholars code, Vercel, or storage.

The original investigation ran SQL inspection under the `postgres` metadata role. Role facts and function ACLs are in the matrix. Do not treat SQL-session checks as JWT/API authorization tests.

## Recommended continuation sequence

1. **Resolve decisions before implementation.** Obtain explicit business/security approvals for public fields and metrics (research notes, cycle notes/actor IDs, competitiveness data, exact counts, contributor identity/presence), intended editor/approver/auditor roles, migration executor, and supported remediation path for `supabase_admin` defaults.
2. **Repair provenance and establish staging.** Reconcile applied production ledger entries to tracked migration files, especially the deployed opportunities creation and unresolved cycle-events mapping. Establish an isolated Scholars staging baseline, migration ledger, generated DB types, known PostgREST exposed schemas, synthetic fixtures and reset procedure. Do not clone production user data.
3. **Run the test specification.** Use independent anon/student A/student B/admin/editor/service identities and synthetic fixtures. Test actual PostgREST and Next.js route behavior, per-function grants, all table/column/RLS expectations, views, trigger behavior, cross-user access, defaults, and negative cases. Do not probe production or use production data for tests.
4. **Prepare implementation as a separate approved phase.** Design additive and staged migration(s), new narrow public projections/RPCs, default-privilege corrections for every sanctioned object-creator role, revocation of unnecessary browser grants, compatibility updates to the app call sites, regenerated types, migration rollback, and tests. Preserve all existing data; do not drop tables/buckets or use force-push.
5. **After explicit approval, implement and verify.** Apply changes to staging first, run full tests/build/typecheck, push authorized app changes, verify Vercel Preview, and only perform production migrations after separate approval and a tested rollback plan. No deployment was triggered for the completed docs-only commit.

## Files in this export

`documents/` contains the exact five Markdown deliverables committed in the Updates handoff commit:

- `SCHOLARS_PHASE_2_1_1_PRODUCTION_SECURITY_INVESTIGATION_2026-11-09.md`
- `SCHOLARS_PHASE_2_1_1_PRIVILEGE_AND_API_EXPOSURE_MATRIX_2026-11-09.md`
- `SCHOLARS_PHASE_2_1_1_LEAST_PRIVILEGE_TARGET_DESIGN_2026-11-09.md`
- `SCHOLARS_PHASE_2_1_1_SECURITY_REMEDIATION_AND_ROLLBACK_PLAN_2026-11-09.md`
- `SCHOLARS_PHASE_2_1_1_SECURITY_TEST_SPECIFICATION_2026-11-09.md`

`SHA256SUMS.txt` contains checksums for the five document copies and this README. This archive deliberately excludes credentials, private keys, database exports, user records, and the raw tool/session transcript.
