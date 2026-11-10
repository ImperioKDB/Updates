# Scholars Phase 2.1.6 — Schema Artifact Capture and Integrity

**Status:** BLOCKED — no authorized production capture.
**Evidence time:** 2026-11-10, 10:57–11:01 CET.
**Author:** Manus AI

## Scope and methodology

This report records the current capture result for production `cmdglabohpttgfofcmqc` and the state of staging `aqhktriwaglvvrchxmtd`. It uses the Supabase project, migration, table, extension, and advisor tools that expose metadata without running arbitrary SQL; GitHub’s public compare/tree APIs; and local version/help checks for the pinned CLI. No database rows were queried through SQL, no storage objects or Vault contents were accessed, and no schema extraction command was run.

## Confirmed findings

Both projects are active and healthy in `eu-west-1`. The production migration listing still ends with `20261109120215 / correct_airtel_afara_application_route`, `20261109120725 / reverify_kayode_and_nnpc_snepco_sources`, and `20261109121207 / update_airtel_scholarship_eligibility`; the staging migration list is empty. The previously reconciled ledger count is 180; the current inventory confirms its latest entries but was not independently reduced to a separate numeric count in this run. The production public-table inventory lists 45 tables. Staging returns no tables in `public`, `api`, `private`, `editorial`, or `worker`; this does not establish that all schemas or non-table object types are absent.

Both projects report the same five installed extensions and versions: `pg_stat_statements` 1.11, `pgcrypto` 1.3, `plpgsql` 1.0, `supabase_vault` 0.3.1, and `uuid-ossp` 1.1. The inventories also list available but uninstalled extensions; differences in their default catalogue versions are not installed-version drift. No Vault contents were read.

The Supabase CLI `2.122.1` version/help checks passed, but neither `db dump` nor declarative generation was executed. No declarative files, schema-only SQL dump, exclusion manifest, artifact manifest, or artifact hashes exist. Captured artifact object count is **zero**. There is no pg-delta runtime version or extraction exit code to report.

The current Scholars main is `3deba708e146ceb2aa6846c4691d58ace93795b2`; the supplied baseline is `cf3682ce35912df7b9b9352193630fc404427c7c`. Current main is three commits ahead and adds three migration files only. Their version/name entries are the latest three production ledger records. This confirms the migration ledger metadata, not the resulting production row state or captured DDL.

## Integrity and coverage

SHA-256 is available locally, but there are no source artifacts to hash. Prior inventory numbers for functions, views, indexes, triggers, buckets, publications, ACLs, and defaults remain historical catalog observations, not counts of captured objects. Current advisor output re-observes some security findings, but does not substitute for definitions in a portable artifact.

## Limitations and next action

The required non-writing database URL and verified PostgREST read authorization were unavailable. There is no local `pg_dump`, PostgreSQL server/client, or Docker engine. A project administrator must provide an approved read-only connection through secure injection, confirm its effective privileges, and provide sanitized PostgREST evidence. Then run the pinned methods, preserve private outputs, hash each file, and publish only reviewed sanitized inventories. Do not restore to staging in this phase.

## References

[1]: https://github.com/ImperioKDB/Scholars/compare/cf3682ce35912df7b9b9352193630fc404427c7c...3deba708e146ceb2aa6846c4691d58ace93795b2 "Scholars Baseline-to-Main Compare"
[2]: https://github.com/ImperioKDB/Updates/blob/a88ab72fcdddd58fe28315a1c04229a09511ab77/SCHOLARS_PHASE_2_1_5_SCHEMA_CAPTURE_AND_COVERAGE_REPORT_2026-11-10.md "Phase 2.1.5 Schema Capture and Coverage"
