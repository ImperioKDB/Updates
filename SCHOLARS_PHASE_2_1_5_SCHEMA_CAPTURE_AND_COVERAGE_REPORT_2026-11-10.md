# Scholars Phase 2.1.5 — Schema Capture and Coverage Report

**Evidence window:** 2026-11-10, 10:25–10:32 CET (UTC+01:00)
**Scope:** Revalidate capture prerequisites and available metadata for production `cmdglabohpttgfofcmqc` and staging `aqhktriwaglvvrchxmtd`. This report does not claim a database dump or declarative tree was generated.

## Capture status

**BLOCKED — AUTHORIZED CAPTURE NOT AVAILABLE.** No production DDL artifact was created. The Supabase CLI was tested in help-only mode at the approved version `2.122.1`, but no properly restricted read-only database URL was available. The PostgREST Management API scopes could not be verified through the available MCP interface. No database command was run against either project.

| Capture item | Result |
|---|---|
| Supabase CLI version | `2.122.1`, run from a temporary npm package invocation for version/help checks only |
| `db dump` extraction | Not run |
| Declarative pg-delta generation | Not run |
| pg-delta runtime version | Not separately reported by CLI help; unknown |
| Extraction exit codes | Not applicable; no extraction command was run |
| Coverage warnings / unsupported-object list | None available |
| Generated file inventory / manual changes | None |
| Artifact SHA-256 hashes | None |

## Current environment and migration evidence

| Item | Current read-only evidence |
|---|---|
| Production | `cmdglabohpttgfofcmqc`, `scholarship-platform`, `eu-west-1`, `ACTIVE_HEALTHY`, PostgreSQL 17.6.1.155 |
| Staging | `aqhktriwaglvvrchxmtd`, `scholars-staging`, `eu-west-1`, `ACTIVE_HEALTHY`, PostgreSQL 17.11.0.018 |
| Production migration ledger | The authorized listing reaches the same final three versions recorded previously: `20261109120215`, `20261109120725`, `20261109121207`. The current report set records 180 entries; this execution did not independently recount the returned array. |
| Staging migration ledger | Empty |
| Staging application-schema tables | No tables returned for `public`, `api`, `private`, `editorial`, or `worker`; this inventory does not establish absence of views, functions, types, empty schemas, or other object kinds. |

The prior Phase 2.1.3 reconciliation found 180 production ledger entries, 129 migration files at the stated application baseline, and three additional current-main migration files. The live listing still ends with those same three entries; historical replay remains rejected as a baseline method. [1] [2]

## Extension manifest

The current production and staging extension inventories report the same five **installed** extensions and versions:

| Extension | Installed version | Schema | Note |
|---|---:|---|---|
| `pg_stat_statements` | 1.11 | `extensions` | Operational/platform extension |
| `pgcrypto` | 1.3 | `extensions` | Application dependency candidate |
| `plpgsql` | 1.0 | `pg_catalog` | PostgreSQL procedural language |
| `supabase_vault` | 0.3.1 | `vault` | Platform-managed; no Vault contents read or copied |
| `uuid-ossp` | 1.1 | `extensions` | Application dependency candidate |

The connector distinguishes an extension's `default_version` from its `installed_version`. Some available but uninstalled extension catalogue entries show different default versions between projects; their `installed_version` is null in both. They are not evidence of installed-version drift. The schema dump's default filters exclude extension-created schemas, so the installed-version list must remain a separate manifest. [3]

## Application repository comparison

The application repository is `ImperioKDB/Scholars`. The supplied baseline is `cf3682ce35912df7b9b9352193630fc404427c7c`; current `main` is `3deba708e146ceb2aa6846c4691d58ace93795b2`, three commits ahead. The compare contains only these added migration files and no changed application source paths:

- `supabase/migrations/20261109130500_correct_airtel_afara_application_route.sql`
- `supabase/migrations/20261109131500_reverify_kayode_and_nnpc_snepco_sources.sql`
- `supabase/migrations/20261109132500_update_airtel_scholarship_eligibility.sql`

The Phase 2.1.4 report was published after this application `main` commit. No later application-source change was observed at the current head. These three migrations are not proof of the missing historical chain and must not be used to invent one. [1] [4]

## Catalog inventory versus captured objects

A previously published Phase 2.1.5 bounded catalog inventory recorded 45 public tables, four public views, one public sequence, 157 public indexes, 31 public security-definer functions, zero public force-RLS tables, two storage buckets, 25 non-internal public triggers, and one reported publication membership. Those are **catalog inventory figures from that report**, not counts of objects in a portable schema artifact, and were not independently recounted in this pass. [5]

Consequently, the number of production objects captured into an artifact is **zero**. No table rows, student records, storage objects, or production data were exported or copied.

## Coverage that remains unverified

| Object or behavior | Evidence status |
|---|---|
| Table/column definitions, keys, constraints, indexes, sequences, and types | Live catalog inventory exists in prior reports; emitted DDL not captured |
| Views and materialized views | Four public Resource Center views were recorded previously; definitions and security options not captured in this pass |
| Function bodies and procedures | Function metadata was recorded previously; full bodies, dynamic SQL, and search-path safety were not inspected here |
| Triggers and RLS policies | Prior catalog summaries exist; no portable definition set was generated |
| Grants, ownership, default privileges | Prior reports identify creator-role differences; a full artifact overlay was not generated or compared |
| `auth` and `storage` customizations | Prior inventory reports relevant triggers and policies; extraction-method completeness remains unproven |
| Storage buckets and objects | Two bucket names were recorded in the prior catalog summary; bucket configuration is not DDL and no storage objects were read or copied |
| Publications and extension-managed objects | Prior inventory notes one publication membership and five installed extensions; full portability not verified |
| Unsupported pg-delta objects | Unknown; no strict-coverage run occurred |
| Cross-method equivalence | Unknown; no dump or declarative artifact exists |

The default Supabase dump excludes `auth`, `storage`, and extension-created schemas. pg-delta documentation describes managed-schema customizations for initial `db pull`, but the reviewed sources do not establish full parity for declarative `generate` under the pinned CLI. Storage bucket rows require separate handling because schema diffs do not capture DML. [2] [3] [6]

## Limitations and next capture gate

The current evidence is sufficient to confirm the named project refs, the empty staging table/migration inventory, the installed extension list, and repository delta. It is not a replacement for the requested production DDL capture. Before independent baseline review, an administrator must provide an approved non-writing database URL through a secure channel and the project administrator must provide sanitized PostgREST evidence. Then run both methods at the pinned CLI, preserve warnings and private hashes, and reconcile the outputs to a bounded catalog inventory. Do not restore staging during that capture step.

## Methodology and evidence source

Project identity, migration inventory, table inventory, and installed extensions were checked through dedicated read-only Supabase MCP tools. Repository changes were checked through the public GitHub compare for the exact supplied baseline and current `main`. CLI options were checked locally using version/help commands only. Earlier object counts are attributed to the prior Phase 2.1.5 report and were not recomputed here. Official CLI and diff-engine behavior is cited below.

## Unresolved questions and security implications

No portable DDL exists to confirm function bodies, policies, grants, ownership, default privileges, managed-schema customizations, or pg-delta coverage warnings. No independent reviewer can assess restore behavior or detect sensitive SQL until the private artifacts are generated and scanned. A staging table inventory without relations does not by itself prove the full project is empty or safe to restore.

## Confirmed facts versus inference

- **Confirmed:** no dump or declarative tree was generated; the named project refs, current installed extensions, staging table inventory, and repository compare were checked with read-only tools.
- **Inherited, not re-run:** catalog object counts and security details recorded in the earlier Phase 2.1.5 inventory.
- **Inference:** a separate managed-schema and bucket-configuration review will be required even if a schema artifact is generated successfully.

## References

[1]: https://github.com/ImperioKDB/Updates/blob/3d3da285f1b076fbfebb1fdf1adbaadeb178d71f/SCHOLARS_PHASE_2_1_3_MIGRATION_PROVENANCE_RECONCILIATION_2026-11-09.md "Phase 2.1.3 Migration Provenance Reconciliation"
[2]: https://supabase.com/docs/reference/cli/supabase-db-dump "Supabase CLI Database Dump Reference"
[3]: https://supabase.com/docs/guides/local-development/declarative-database-schemas "Supabase Declarative Database Schemas"
[4]: https://github.com/ImperioKDB/Scholars/compare/cf3682ce35912df7b9b9352193630fc404427c7c...3deba708e146ceb2aa6846c4691d58ace93795b2 "Scholars Baseline-to-Main Comparison"
[5]: https://github.com/ImperioKDB/Updates/blob/a88ab72fcdddd58fe28315a1c04229a09511ab77/SCHOLARS_PHASE_2_1_5_SCHEMA_CAPTURE_AND_COVERAGE_REPORT_2026-11-10.md "Prior Phase 2.1.5 Catalog Capture Readiness Report"
[6]: https://supabase.com/docs/guides/local-development/diff-engines "Supabase pg-delta and migra Diff Engines"
