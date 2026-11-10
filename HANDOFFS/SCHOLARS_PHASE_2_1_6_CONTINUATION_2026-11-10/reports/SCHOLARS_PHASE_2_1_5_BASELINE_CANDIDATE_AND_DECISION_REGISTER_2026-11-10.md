# Scholars Phase 2.1.5 — Baseline Candidate and Decision Register

**Evidence window:** 2026-11-10, 10:25–10:32 CET (UTC+01:00)
**Scope:** Final stop/go decision for controlled production schema capture and independent baseline review. No production or staging object, privilege, setting, or data was modified.

## Final verdict

# BLOCKED — AUTHORIZED CAPTURE NOT AVAILABLE

The required capture could not be safely completed. The approved CLI `2.122.1` was verified in help-only mode, but no approved non-writing database URL was available. PostgREST scopes could not be verified through the available authenticated MCP path. No dump, declarative tree, artifact hash set, or full function-body review exists. The current live catalog inventory and the earlier 2.1.5 security report are not portable baseline artifacts.

This is the exact blocked verdict required when authorized read-only access or security-sensitive evidence is unavailable. It is not a successful empty capture, and it does not authorize staging restoration.

## Methodology and evidence sources

Production `cmdglabohpttgfofcmqc` and staging `aqhktriwaglvvrchxmtd` were checked through read-only Supabase project, migration, table, and extension inventory tools. The application delta was checked from baseline SHA `cf3682ce35912df7b9b9352193630fc404427c7c` to current `main` SHA `3deba708e146ceb2aa6846c4691d58ace93795b2`. CLI version and supported flags were checked with help-only commands. Prior phase reports and official Supabase documentation are cited below. No raw SQL executor, database URL, or credential was used.

## Revalidated facts

| Item | Current status |
|---|---|
| Production project | `cmdglabohpttgfofcmqc`, `ACTIVE_HEALTHY`, `eu-west-1`, PostgreSQL 17.6.1.155 |
| Staging project | `aqhktriwaglvvrchxmtd`, `ACTIVE_HEALTHY`, `eu-west-1`, PostgreSQL 17.11.0.018 |
| Production migration ledger | Prior count is 180; current authorized listing still reaches the same latest three versions, through `20261109121207`; this pass did not independently recount the array |
| Staging migrations | Empty |
| Staging application tables | None returned in `public`, `api`, `private`, `editorial`, or `worker`; other object kinds were not ruled out |
| Installed extensions | Same five versions in production and staging: `pg_stat_statements` 1.11, `pgcrypto` 1.3, `plpgsql` 1.0, `supabase_vault` 0.3.1, `uuid-ossp` 1.1 |
| Application repository | Baseline `cf3682ce35912df7b9b9352193630fc404427c7c`; current `main` `3deba708e146ceb2aa6846c4691d58ace93795b2`; three migration files added, no changed app-source paths |
| PostgREST | `db_schema`, `db_extra_search_path`, anonymous role, and OpenAPI mode remain unverified |
| Capture artifact | None; zero objects captured into a portable DDL artifact; no hashes |

The prior Phase 2.1.5 catalog report recorded 45 public tables, four views, 31 security-definer functions, and related metadata. These are catalog inventory counts, not counts of captured artifacts. [1]

## Method decision

The conditional future recommendation is to generate a pg-delta declarative tree as the primary review artifact with `--strict-coverage`, and compare it with the default schema-only SQL dump. CLI 2.122.1 help confirms the declarative command supports `--db-url`, `--schema`, `--output-dir`, `--strict-coverage`, and `--experimental`. The same help confirms that `db dump` has no `--schema-only` flag; schema-only is the default, and `--schema` selects included schemas. Neither method was executed. [2] [3] [4]

The method is not approved as complete until actual outputs are reviewed. The dump excludes managed `auth`, `storage`, and extension-created schemas by default. The declarative docs describe pg-delta coverage and unsupported object warnings, but do not prove that every managed-schema customization or storage bucket configuration is captured by declarative `generate` in the pinned CLI. [3] [4]

## Decision register

| ID | Decision or gate | Status | Owner or evidence needed |
|---|---|---|---|
| D-215-01 | Historical migration replay | Rejected | Phase 2.1.3 found missing, ambiguous, and unverified source relationships; do not reconstruct history by inference |
| D-215-02 | New current-state baseline | Recommended, not captured | Project administrator provides approved read-only connection; founder approves a separate staging window later |
| D-215-03 | Primary extraction | Conditional recommendation: declarative pg-delta tree with strict coverage | Independent reviewer must inspect actual output and warnings |
| D-215-04 | Secondary verification | Conditional recommendation: default schema-only dump | Compare object/privilege coverage against the tree; keep both private |
| D-215-05 | PostgREST settings | Blocked | Project administrator supplies sanitized production and staging records with `rest:read` and `data_api_config_read` authorization |
| D-215-06 | Destination default privileges | Not cleared | Reconfirm staging creator-role defaults and approved ACL overlay through an authorized read-only metadata path |
| D-215-07 | Security-definer and browser RPC grants | Requires object-by-object review | Inspect private artifact; do not invoke sensitive production RPCs or blanket-revoke grants |
| D-215-08 | Application compatibility | Partial plan only | Compare the captured baseline with the dependency matrix, generate types, and run synthetic role tests |
| D-215-09 | Staging restore | Not authorized | Requires independent baseline review and separate explicit approval |
| D-215-10 | Production migration/deployment | Out of scope | Requires separate release authorization |

## Conditions before independent review

1. Provide a properly restricted non-writing database URL through an approved secret channel; do not paste or commit it. Confirm target endpoint, username, database, and effective privileges without printing the URL.
2. Provide sanitized Management API PostgREST evidence for both project refs. Do not grant the secret-read scope.
3. Run the pinned CLI `2.122.1` against explicitly selected approved schemas. Record exact commands, exit codes, warnings, private artifact paths, and SHA-256 hashes.
4. Retain raw artifacts privately. Scan them for data statements, bucket rows, Vault material, credentials, unexplained roles, platform-managed objects, and unsupported statements before any review copy is made.
5. Reconcile tables, routines, views, policies, grants, default privileges, triggers, publications, extensions, and managed-schema customizations to the prior catalog inventory.
6. Review function bodies, browser grants, RLS combinations, view security options, storage policies, and staging default privileges under the intended executor.
7. Test a synthetic restore in an isolated local/disposable database, generate types, and run the role-specific compatibility suite.
8. Obtain independent reviewer approval before any staging-restoration decision.

## Superseded setup guidance and safety status

The A0.8.1 instruction to add `SUPABASE_DB_URL` and start the extraction workflow remains superseded by the A0.8.2 security hold. Do not populate the secret or run the workflow until its read-only identity, endpoint verification, and privilege boundary are independently approved. This report does not change the extraction workflow or its README. [5]

No production or staging tables, functions, triggers, policies, grants, default privileges, roles, buckets, files, PostgREST settings, migration rows, or data were modified. No production table-row contents, student records, storage objects, credentials, JWT values, connection strings, or Vault contents were retrieved or committed. No CI workflow, application deployment, or Vercel build was triggered.

## Confirmed facts, inference, limitations, and unresolved questions

- **Confirmed:** the two project refs and active status, current extension list, staging's empty table/migration inventory in the named schemas, the current repository compare, CLI `2.122.1` help options, and absence of a generated DDL artifact.
- **Inherited evidence:** production ledger count 180 and catalog object counts/security findings are from the earlier bounded inventory reports; the current task revalidated the ledger's latest entries but did not independently recount the full array or re-run those catalog queries.
- **Inference:** a future declarative tree plus SQL dump is the strongest review candidate based on documented coverage and reviewability. No method has been validated against actual captured artifacts.
- **Limitations:** no approved read-only database URL, no artifact, no artifact hash, and no verified Management API scope were available in this review.
- **Unresolved:** PostgREST settings and token scopes; complete production DDL; pg-delta runtime version and unsupported objects; exact effective staging defaults; function-body and view semantics; and restore-role compatibility.

## Next phase

**Phase 2.1.6 — Authorized artifact capture and isolated compatibility review.** Keep it evidence-only until the administrator provides a secure read-only connection and sanitized PostgREST records. Generate and hash the artifacts privately, compare method coverage, and obtain an independent review. Do not restore staging or modify production until that review passes and a separate authorization is granted.

## Security implications

No baseline is safe to restore until the private artifacts, managed-schema coverage, browser grants, security-definer functions, view semantics, and destination defaults have been reviewed. The current evidence does not justify a staging restore, a production change, a privilege revocation, or a deployment.

## References

[1]: https://github.com/ImperioKDB/Updates/blob/a88ab72fcdddd58fe28315a1c04229a09511ab77/SCHOLARS_PHASE_2_1_5_SCHEMA_CAPTURE_AND_COVERAGE_REPORT_2026-11-10.md "Phase 2.1.5 Catalog Capture Readiness Report"
[2]: https://supabase.com/docs/reference/cli/introduction "Supabase CLI Reference"
[3]: https://supabase.com/docs/reference/cli/supabase-db-dump "Supabase CLI Database Dump Reference"
[4]: https://supabase.com/docs/guides/local-development/declarative-database-schemas "Supabase Declarative Database Schemas"
[5]: https://github.com/ImperioKDB/Updates/blob/main/SCHOLARS_A0_8_2_EXTRACTION_WORKFLOW_SECURITY_REFINEMENT_2026-11.md "A0.8.2 Extraction Workflow Security Refinement"
[6]: https://github.com/ImperioKDB/Updates/blob/3d3da285f1b076fbfebb1fdf1adbaadeb178d71f/SCHOLARS_PHASE_2_1_4_STRATEGY_DECISION_AND_FINAL_ASSESSMENT_2026-11-09.md "Phase 2.1.4 Strategy Decision"
