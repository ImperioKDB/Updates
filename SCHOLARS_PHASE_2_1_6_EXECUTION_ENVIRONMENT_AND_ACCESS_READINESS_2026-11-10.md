# Scholars Phase 2.1.6 — Execution Environment and Access Readiness

**Status:** Partially prepared; authorized extraction access is unavailable.
**Evidence time:** 2026-11-10, 10:57–11:01 CET.
**Author:** Manus AI

## Scope and method

This report records safe local tool checks and available connector capabilities for production project `cmdglabohpttgfofcmqc` and staging project `aqhktriwaglvvrchxmtd`. Checks were limited to operating-system/tool discovery, pinned CLI version/help output, public GitHub metadata, and dedicated read-only Supabase project and metadata inventories. No database URL, service key, password, or Supabase OAuth token was read or printed. No arbitrary SQL, project-setting changes, or extraction operation was attempted.

## Confirmed findings

The workspace is Linux x86_64. SHA-256 tooling is available. `supabase`, `psql`, `pg_dump`, `postgres`, `initdb`, and Docker are not installed or available as system commands; Docker engine access is unavailable. The pinned Supabase CLI was verified using `npx --yes supabase@2.122.1`: version output was `2.122.1`. Help confirms `db dump` supports `--db-url`, `--schema`, and `--file`; the default dump is schema output and there is no `--schema-only` flag. Declarative generation supports `--db-url`, `--schema`, `--output-dir`, `--strict-coverage`, and `--experimental`. Help does not report the bundled pg-delta runtime version. The npm invocation emitted a notice that `v3.1.0` is newer; no version upgrade was performed.

The Supabase connector is authenticated but does not expose its OAuth scopes. It provides dedicated read-only project, migration, table, extension, and advisor inventories, but no PostgREST configuration GET operation or restricted database URL. The environment contains no supplied `DATABASE_URL`, `SUPABASE_DB_URL`, or PostgreSQL client. A Supabase Management API credential with verified `rest:read` and `data_api_config_read` scope was not available. GitHub CLI access to `ImperioKDB/Updates` was available and the repository was cloned cleanly at `d370147f960791cb12b28c333922172c32173dbc` for reporting.

## Access decision and security implications

Extraction preflight **fails closed**. No authorized, independently verified non-writing database connection was provided. The available catalog/metadata tools cannot establish a SQL account’s effective write restrictions and are not a substitute for the required restricted URL. No dump or declarative generation was run. No raw artifact or artifact hash exists. Current readiness is insufficient for extraction or restoration.

## Limitations and unresolved questions

The host distribution name was not captured. PostgreSQL client tooling, Docker, pg-delta runtime version, and exact package/binary checksum remain unknown. The Supabase OAuth token scopes are unknown. The separate Management API credential and least-privilege database connection remain unavailable. A private artifact-retention area was prepared only as a local temporary working path; no production schema artifact was placed there.

## Next action

A project administrator should supply a verified read-only database URL through an approved secret-injection mechanism and a short-lived Management API token or sanitized configuration export covering only approved non-secret fields. Confirm the effective read-only privileges before extraction. Install the approved PostgreSQL client or use an approved extraction workspace. Do not restore staging until separate review and authorization.

## References

[1]: https://supabase.com/docs/reference/cli/supabase-db-dump "Supabase CLI Database Dump Reference"
[2]: https://supabase.com/docs/guides/local-development/declarative-database-schemas "Supabase Declarative Database Schemas"
[3]: https://github.com/ImperioKDB/Updates/blob/a88ab72fcdddd58fe28315a1c04229a09511ab77/SCHOLARS_PHASE_2_1_5_BASELINE_CANDIDATE_AND_DECISION_REGISTER_2026-11-10.md "Phase 2.1.5 Candidate Decision Register"
