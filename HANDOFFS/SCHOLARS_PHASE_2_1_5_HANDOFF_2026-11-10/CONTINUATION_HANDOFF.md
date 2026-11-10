# Scholars Phase 2.1.5 — Continuation Handoff

**Prepared:** 2026-11-10
**Purpose:** Continue the controlled database schema capture and baseline security review in a new Manus AI session.

## Current final state

Phase 2.1.5 is complete as an evidence-gathering and preparation phase. The final verdict is:

> **BLOCKED — AUTHORIZED CAPTURE NOT AVAILABLE**

The six sanitized reports were committed and pushed to `ImperioKDB/Updates`.

- Updates commit: `a88ab72fcdddd58fe28315a1c04229a09511ab77`
- Commit message: `docs: add Phase 2.1.5 schema capture review`
- Remote: https://github.com/ImperioKDB/Updates
- Commit URL: https://github.com/ImperioKDB/Updates/commit/a88ab72fcdddd58fe28315a1c04229a09511ab77
- Working tree after push: clean

No Scholars application code was changed. No Vercel deployment was triggered. No production or staging object, privilege, setting, migration row, storage file, or data was modified.

## Exact report payload

1. `SCHOLARS_PHASE_2_1_5_POSTGREST_CONFIGURATION_EVIDENCE_2026-11-10.md`
2. `SCHOLARS_PHASE_2_1_5_SCHEMA_EXTRACTION_METHOD_COMPARISON_2026-11-10.md`
3. `SCHOLARS_PHASE_2_1_5_SCHEMA_CAPTURE_AND_COVERAGE_REPORT_2026-11-10.md`
4. `SCHOLARS_PHASE_2_1_5_BASELINE_SECURITY_REVIEW_2026-11-10.md`
5. `SCHOLARS_PHASE_2_1_5_APPLICATION_COMPATIBILITY_AND_PRIVILEGE_ANALYSIS_2026-11-10.md`
6. `SCHOLARS_PHASE_2_1_5_BASELINE_CANDIDATE_AND_DECISION_REGISTER_2026-11-10.md`

The reports are included in the `reports/` directory of this package and are also present in the Updates repository at the commit above.

## Project and environment references

- Application repository: `https://github.com/ImperioKDB/Scholars`
- Reports repository: `https://github.com/ImperioKDB/Updates`
- Production Supabase project: `cmdglabohpttgfofcmqc` (`scholarship-platform`)
- Staging Supabase project: `aqhktriwaglvvrchxmtd` (`scholars-staging`)
- Application baseline SHA: `cf3682ce35912df7b9b9352193630fc404427c7c`
- Current application `origin/main` observed: `3deba708e146ceb2aa6846c4691d58ace93795b2`
- Previous phase: Phase 2.1.4 commit `3d3da285f1b076fbfebb1fdf1adbaadeb178d71f`

## Verified read-only evidence

Both Supabase projects reported `ACTIVE_HEALTHY` in `eu-west-1`.

Production catalog evidence:

- Migration ledger count: 180 rows.
- Public tables/partitioned tables: 45; all have RLS enabled.
- Public force-RLS tables: 0.
- Public views: 4 Resource Center views.
- Public indexes: 157.
- Public sequences: 1.
- Public security-definer functions: 31.
- Storage buckets: `avatars` and `site`.
- Realtime publication membership observed: `public.scholarship_discussions` in `supabase_realtime`.
- Non-internal application/managed trigger inventory was read without invoking functions.

Production and staging both reported these extensions:

- `pg_stat_statements` 1.11 in `extensions`
- `pgcrypto` 1.3 in `extensions`
- `plpgsql` 1.0 in `pg_catalog`
- `supabase_vault` 0.3.1 in `vault`
- `uuid-ossp` 1.1 in `extensions`

Staging returned no Scholars application relations in the bounded catalog inventory. It remains an empty destination, not a restored baseline.

The application repository contains 129 migration files at the stated baseline and 132 at current `origin/main`. Three new migrations were observed after the baseline:

- `20261109130500_correct_airtel_afara_application_route.sql`
- `20261109131500_reverify_kayode_and_nnpc_snepco_sources.sql`
- `20261109132500_update_airtel_scholarship_eligibility.sql`

## Confirmed blockers

1. The approved Supabase CLI was not installed in the execution environment.
2. No authorized read-only database URL was available for `supabase db dump`.
3. No scoped Supabase Management API token was available.
4. The documented GET endpoint returned HTTP 401 for both project refs:
   `https://api.supabase.com/v1/projects/{ref}/postgrest`
5. PostgREST fields including `db_schema`, `db_extra_search_path`, anonymous role, and OpenAPI mode remain unresolved.
6. No schema-only dump or pg-delta declarative artifact was generated; therefore there are no extraction exit codes, coverage warnings, generated-file inventories, or artifact hashes from this phase.

Do not convert these access failures into assumptions. Do not claim that a SQL NULL or absent result proves a PostgREST setting is unset.

## Security findings requiring follow-up

- All 45 public tables have RLS enabled, but none has force RLS.
- Many application tables have broad `anon`/`authenticated` ACLs; effective access depends on RLS and policy combinations.
- There are 31 public security-definer functions.
- `is_admin(uuid)` is security-definer and has PUBLIC execute in the observed ACL summary.
- `get_admin_metrics_summary(timestamptz)` is security-definer with `anon` and `authenticated` execute grants.
- `run_achievement_checks(uuid)` is security-definer with PUBLIC/anonymous/authenticated execute grants.
- Function bodies and dynamic SQL were intentionally not retrieved or invoked; exploitability is unverified.
- The four Resource Center views are `security_barrier=true`, public-read, and filtered to active/published content; security-invoker behavior remains to be explicitly verified.
- Production and staging `postgres` default privileges differ materially. Staging defaults are broader for newly created public tables/functions/schema objects. Restoration executor identity and ACL overlays must be explicit.
- Storage policies permit public reads for `avatars` and `site`; owner/admin write paths are policy-controlled. No storage objects were read.
- The `auth.users` trigger `on_auth_user_created` calls `handle_new_user()`. Managed-schema customizations must be reviewed separately.

## Recommended extraction strategy

For the next authorized phase:

1. Primary artifact: `supabase db schema declarative generate` using pg-delta with strict coverage, pinned CLI, selected schemas, and a private output directory.
2. Secondary artifact: schema-only `supabase db dump` using the same authorized non-writing connection.
3. Compare the two privately; retain coverage warnings and unsupported-object lists.
4. Hash the unmodified private artifacts.
5. Scan for data statements, storage objects, Vault material, credentials, JWT secrets, unexplained roles, and platform-managed internals.
6. Publish only sanitized conclusions, never raw production dumps.

The primary/secondary choice is a recommendation, not an executed capture. Current Supabase documentation says declarative schema generation is pg-delta based, supports `--strict-coverage`, models many object classes, and does not capture DML such as storage bucket rows. The dump must still be reviewed because schema-only does not automatically guarantee that every inappropriate statement is absent.

## Exact next phase

**Phase 2.1.6 — Authorized artifact capture and isolated compatibility review.**

Required sequence:

1. Obtain explicit authorization and a properly scoped, non-writing database URL or approved read-only connector.
2. Install/pin a reviewed Supabase CLI and record its exact version.
3. Verify the available declarative and strict-coverage flags before running anything.
4. Capture the declarative tree and schema-only dump privately.
5. Record command, exit code, CLI/pg-delta version, warnings, unsupported objects, file inventory, and SHA-256 hashes.
6. Retrieve sanitized PostgREST configuration evidence through the supported Management API path.
7. Compare artifact inventory with production catalog evidence and the Phase 2.1.2 application dependency matrix.
8. Review security-definer bodies, search paths, public EXECUTE grants, RLS combinations, view options, publication membership, triggers, defaults, and managed schemas.
9. Build a synthetic isolated destination without production data and generate database types.
10. Run role-specific API/RLS/application smoke tests.
11. Obtain independent reviewer approval before considering any staging restoration.
12. Request a separate explicit authorization before applying anything to staging.

## Hard safety boundaries

- Do not restore staging in the next session without separate explicit approval.
- Do not apply migrations to production or staging.
- Do not change PostgREST settings, roles, ownership, ACLs, default privileges, RLS, buckets, or data.
- Do not retrieve service-role keys, JWT secrets, passwords, connection strings, Vault contents, student records, or storage files.
- Do not commit raw schema dumps or sensitive configuration artifacts to the public Updates repository.
- Do not force-push or delete tables, buckets, data, or repository history.
- Do not treat a successful Vercel build as evidence of database migration execution.

## Source documentation

- https://supabase.com/docs/reference/cli/introduction
- https://supabase.com/docs/guides/local-development/declarative-database-schemas
- https://supabase.com/docs/guides/local-development/diff-engines
- https://supabase.com/docs/reference/api/v1-get-postgrest-service-config
- https://supabase.com/docs/guides/api/using-custom-schemas
- https://supabase.com/docs/guides/deployment/database-migrations
- https://supabase.com/docs/guides/api/rest/generating-types

## Package contents

- `CONTINUATION_HANDOFF.md` — this file.
- `PHASE_2_1_5_BRIEF.txt` — exact task brief supplied for this phase.
- `SOURCE_REPOSITORY_STATE.txt` — repository and commit metadata.
- `reports/` — all six sanitized reports committed at Updates commit `a88ab72...`.
- `MANIFEST.sha256` — hashes for every package file.

This package contains no credentials, raw production schema dump, production data, storage object, or secret configuration value.
