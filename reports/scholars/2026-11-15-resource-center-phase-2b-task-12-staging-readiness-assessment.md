# Scholars Resource Centre — Task 12 Staging Readiness Assessment

**Assessment date:** 2026-11-15
**Scholars source:** `142146a67cb21eeec8d74832bc326c1fcd5dd5f4`
**Updates publication reviewed:** `81ecdf6edc87a9cb491d77e3ff83541019f8a370`
**Staging:** `scholars-staging` / `aqhktriwaglvvrchxmtd`

## Final verdict

# BLOCKED — STAGING ENVIRONMENT UNSAFE OR INCOMPLETE

The staging project itself is safely isolated and contains no unexpected Scholars data, but the required representative schema baseline was not reconstructed. The source migration history is incomplete as a clean-install specification: the initial migration is explicitly superseded, migration prefixes are duplicated, 33 files contain real-looking application/business seeds, several migrations have data or object prerequisites, and the Resource Centre/security migrations depend on functions and evolved schema not established by a trusted baseline. Staging is **not ready for administrator remediation** and the Task 11 SQL proposal must not be applied.

## Gate assessment

| Gate | Result | Evidence |
|---|---|---|
| Project identity | **PASS** | Exact `scholars-staging` reference verified; differs from production and `serena`. |
| Isolation | **PASS** | Separate healthy Supabase project; no application data, Auth users, buckets, or public tables. |
| Current contents inventory | **PASS** | Migration history, tables, counts, functions, views, policies and triggers inventoried read-only. |
| Migration manifest | **COMPLETE** | All 136 source migrations listed and classified. |
| Schema reconstruction | **BLOCKED** | No authoritative clean-install baseline; no migration applied. |
| Schema parity | **BLOCKED** | Empty staging cannot be treated as parity. |
| Profile/admin security baseline | **BLOCKED** | No `profiles`, `is_admin`, helper, policies, triggers or routines exist in staging. |
| Resource Centre baseline | **BLOCKED** | Resource Centre tables/views/policies are absent. |
| Storage/application buckets | **BLOCKED** | No application buckets or policies exist. |
| Vercel Preview isolation | **BLOCKED / UNVERIFIED** | No custom environment; inspected Supabase variable metadata is shared across Production and Preview targets, not proven staging-bound. |
| Synthetic identities | **NOT STARTED** | No accounts created; no production identities used. |
| Administrator remediation readiness | **NO-GO** | Gate for representative baseline did not pass. |

## Evidence classification

- **VERIFIED — PROJECT METADATA:** project name, reference, region, status, PostgreSQL version, organization, production comparison, and Vercel project metadata.
- **VERIFIED — LIVE STAGING DATABASE:** empty application migration history; zero public application tables; zero Auth users; zero storage buckets; zero public functions/views/policies/triggers; built-in storage schema only.
- **VERIFIED — SOURCE:** 136 migration files, duplicate prefixes, superseded `0001_init.sql`, seed volume, Task 11 dependencies, and current `vercel.json`.
- **VERIFIED — TEST:** none; no application runtime, Auth flow, RLS request, migration, or regression test was run.
- **INFERRED:** a partial replay or filename-only ordering would not establish representative schema parity.
- **UNVERIFIED:** Auth configuration, MFA, Vercel variable values, Preview-to-staging binding, and runtime application behavior.
- **BLOCKED:** staging schema reconstruction and all downstream administrator-remediation gates.

## Required next steps

1. Obtain owner approval for an authoritative schema-only baseline or a bounded source-derived reconstruction bundle.
2. Define exact ordered prerequisites, omitted seeds, supplied functions, role/ownership/default-privilege assumptions, and final-state deviations.
3. Apply only that approved bundle to `aqhktriwaglvvrchxmtd`; never reset, drop, truncate, or overwrite the existing project.
4. Run the companion read-only verification SQL and compare every expected object class before creating synthetic identities.
5. Configure a branch-scoped Preview environment with staging-only Supabase URL, anon key, and server-only service-role credential through an approved secure Vercel workflow. Do not change production settings.
6. Only after baseline parity passes, create synthetic anonymous/student/admin/recovery test identities under separate authorization and proceed to the next task.

## Safety confirmations

- Production SQL executed: **No**.
- Staging SQL that changes state: **No**.
- Production data copied: **No**.
- Production credentials/secrets copied: **No**.
- Scholars source or migration files modified: **No**.
- Task 11 administrator remediation applied: **No**.
- Vercel configuration changed: **No**.
- Application deployed: **No**.
- PR created or merged: **No**.
- Serena used: **No**.

Stop condition reached after the six Task 12 deliverables were prepared. Do not proceed to Task 13 or apply administrator remediation without explicit authorization and a newly approved baseline decision.
