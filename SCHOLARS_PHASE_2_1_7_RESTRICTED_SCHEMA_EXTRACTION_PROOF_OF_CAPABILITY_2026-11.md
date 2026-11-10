# Scholars Phase 2.1.7 — Restricted Schema Extraction Proof of Capability

**Decision:** **NOT TESTED — isolated runtime unavailable; fail closed**
**Date:** 2026-11-10
**Scope:** Local tooling preflight and documentation only
**Repositories:** `ImperioKDB/Scholars`, `ImperioKDB/Updates`, `ImperioKDB/scholars-schema-extraction`

## 1. Executive conclusion

The requested proof-of-capability experiment could not be performed because this workspace has no suitable disposable PostgreSQL/Supabase runtime. The required tools `postgres`, `initdb`, `psql`, `pg_dump`, Docker, and Podman are not installed or available as executable commands.

The pinned Supabase CLI was checked in help/version-only mode and reported `2.122.1`. No database URL was supplied, no Supabase project was selected, and no database connection or SQL operation was attempted. Production and staging were not used as substitutes.

Therefore, this report makes no claim about whether `pg_dump` or pg-delta can operate with the proposed restricted identity. The extraction methods, restricted identity, forbidden-operation tests, object coverage, and legitimate owner-operation tests are all **NOT TESTED**. Phase 2.1.6 remains **NO-GO / BLOCKED — AUTHORIZED CAPTURE NOT AVAILABLE**.

## 2. Safety boundary observed

No production or staging database was connected to, queried, extracted from, or modified. No `SUPABASE_DB_URL` was created, retrieved, or populated. The existing GitHub Actions workflow was not run. No production artifact was generated. No roles, privileges, Supabase settings, Vercel settings, application code, migrations, or deployments were changed.

The absence of a disposable runtime is an explicit stopping condition in the Phase 2.1.7 task. Substituting either existing Supabase project would violate the task and would not establish an isolated proof.

## 3. Test architecture that was required

A valid experiment would require a disposable local PostgreSQL/Supabase environment or an independently isolated equivalent containing only fabricated records and synthetic objects:

- Application-like tables with synthetic rows only.
- Primary and foreign keys.
- Indexes and sequences.
- Views.
- Functions and triggers.
- RLS policies.
- Grants and default privileges.
- At least one synthetic administrator-related function.

It would also require two synthetic identities:

1. A privileged owner/test identity used only to create and inspect the synthetic database.
2. A dedicated restricted extraction identity that owns no application objects, has no privileged memberships, has no application-table `SELECT`, has no DML or DDL privileges, has `NOSUPERUSER`, `NOCREATEDB`, `NOCREATEROLE`, `NOBYPASSRLS`, and has only the minimum catalog/schema access demonstrated to be necessary.

No such runtime or identities were created because the required database engine was unavailable.

## 4. Local preflight evidence

The following commands were run locally as discovery/version checks only:

```bash
command -v postgres
command -v initdb
command -v psql
command -v pg_dump
command -v docker
command -v podman
postgres --version
initdb --version
psql --version
pg_dump --version
docker --version
npx --yes supabase@2.122.1 --version
```

Results:

| Capability | Result |
|---|---|
| `postgres` | **NOT AVAILABLE** — command not found |
| `initdb` | **NOT AVAILABLE** — command not found |
| `psql` | **NOT AVAILABLE** — command not found |
| `pg_dump` | **NOT AVAILABLE** — command not found |
| Docker | **NOT AVAILABLE** — command not found |
| Podman | **NOT AVAILABLE** — command not found |
| Supabase CLI version check | **PASS — help/version only**, reported `2.122.1` |
| Database connection | **NOT ATTEMPTED** |

The CLI version check emitted only the normal telemetry/update notices. It did not connect to a database.

## 5. Restricted identity definition

**NOT CREATED / NOT TESTED.** No synthetic database existed in which to create the identity. The future test must record the exact role attributes, memberships, ownership, schema privileges, catalog privileges, and object-level privileges. It must verify effective privileges rather than relying only on intended grants.

The future test must specifically prove:

- No application table, schema, view, sequence, function, or trigger ownership.
- No `SUPERUSER`, `CREATEDB`, `CREATEROLE`, `REPLICATION`, or `BYPASSRLS`.
- No inherited or settable privileged membership.
- No application-table or table-like `SELECT`.
- No `INSERT`, `UPDATE`, `DELETE`, `TRUNCATE`, `REFERENCES`, `TRIGGER`, or object-creation privileges.
- Only the metadata/catalog/schema access required by the tested extraction command.

No production role or grant was inspected or modified for this experiment.

## 6. pg_dump test

**Status: NOT TESTED.** `pg_dump` is not installed, and no isolated PostgreSQL server exists.

The future run must record:

- Exact PostgreSQL and Supabase CLI versions.
- Exact schema-only command and selected schemas.
- Exit code, warnings, and permission errors.
- Captured object inventory and missing objects.
- A scan proving the output contains definitions rather than synthetic application records.
- Whether the restricted identity can complete without application-table `SELECT`.

No SQL output, hash, warning set, or coverage result exists from this Phase 2.1.7 attempt.

## 7. pg-delta test

**Status: NOT TESTED.** Supabase CLI `2.122.1` is available only through a version/help-only invocation; no database URL or isolated database was supplied. No declarative generation command was run.

The future run must use `db schema declarative generate` with `--strict-coverage` where supported and record:

- CLI and pg-delta runtime versions, if discoverable.
- Exact command, selected schemas, exit code, warnings, and unsupported objects.
- Captured object types and missing objects.
- Effective privileges required by the restricted identity.
- Whether functions, triggers, RLS, grants, defaults, views, and synthetic administrator-related objects are represented.

A successful command must not be treated as proof of complete coverage.

## 8. Forbidden-operation tests

**Status: NOT TESTED.** No synthetic database or restricted identity was available. The following operations were not attempted:

| Operation | Required future result | Phase 2.1.7 result |
|---|---|---|
| `SELECT` synthetic application table | Must fail | **NOT TESTED** |
| `INSERT` application table | Must fail | **NOT TESTED** |
| `UPDATE` application row | Must fail | **NOT TESTED** |
| `DELETE` application row | Must fail | **NOT TESTED** |
| `CREATE TABLE` | Must fail | **NOT TESTED** |
| `ALTER TABLE` | Must fail | **NOT TESTED** |
| `CREATE FUNCTION` | Must fail | **NOT TESTED** |
| Change privileges | Must fail | **NOT TESTED** |
| Assume elevated role | Must fail | **NOT TESTED** |
| Legitimate owner-controlled synthetic operation | Must succeed using separate owner identity | **NOT TESTED** |

No failure or success is inferred from the absence of tools.

## 9. Method comparison

| Capability | pg_dump | pg-delta |
|---|---|---|
| Schema extraction succeeds under restricted identity | NOT TESTED | NOT TESTED |
| Requires application-row `SELECT` | NOT TESTED | NOT TESTED |
| Reads synthetic application records | NOT TESTED | NOT TESTED |
| Can modify database objects | NOT TESTED | NOT TESTED |
| Captures functions and triggers | NOT TESTED | NOT TESTED |
| Captures RLS and grants | NOT TESTED | NOT TESTED |
| Unsupported objects | NOT TESTED | NOT TESTED |
| Suitable for future restricted extraction | NOT TESTED | NOT TESTED |

No method is recommended as proven from this experiment. Phase 2.1.6’s conditional recommendation—declarative output as the primary review candidate with a schema-only dump as a cross-check—remains conditional and unvalidated.

## 10. Remaining uncertainties

The experiment leaves these questions open:

1. Whether a restricted identity can enumerate and render the required catalog metadata without application-table `SELECT`.
2. Whether the pinned Supabase CLI invokes operations requiring privileges broader than the intended boundary.
3. Whether pg-delta and the SQL dump differ under a restricted identity.
4. Which catalog/schema privileges are the actual minimum for each method.
5. Whether views, functions, triggers, RLS policies, grants, default privileges, extensions, and publications are represented completely.
6. Which objects are unsupported or omitted by pg-delta strict coverage.
7. Whether managed-schema customizations and storage bucket configuration require separate handling.
8. Whether owner-controlled operations remain available without weakening the restricted identity.

## 11. Recommended next architecture

Do not change the production extraction workflow or create a production secret based on this report. First provide a disposable PostgreSQL/Supabase runtime, preferably in an isolated local or separately approved environment. Build only synthetic objects and records, create the restricted identity there, and run the complete experiment with exact logs, exit codes, coverage inventories, and privilege-failure tests.

If the restricted identity cannot run either method without application-row access, do not weaken production. Instead, document the precise missing catalog privilege and evaluate the narrowest alternative under owner review—for example, a provider-enforced read-only source combined with a no-row-access identity, or a separately controlled metadata-capture mechanism. Any alternative must preserve endpoint verification, TLS identity verification, artifact confidentiality, and independent review.

Only a passing isolated experiment, followed by independent security review, can move the workstream toward authorized private production capture. This report does not authorize that capture.

## 12. Final status

**Phase 2.1.7: NOT TESTED — STOPPED at the isolated-runtime prerequisite.**

Wait for independent review, provision of an approved disposable runtime, and explicit authorization to repeat the isolated experiment. Do not proceed to production extraction, staging reconstruction, remediation, or deployment.
