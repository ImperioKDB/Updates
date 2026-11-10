# Scholars Phase 2.1.4 — Strategy Decision and Final Assessment

**Investigation date:** 2026-11-10
**Decision posture:** Design and evidence only. No database or deployment change was performed.

## Executive decision

**Recommended strategy: Strategy B — a reviewed schema-only baseline generated from the current production state, with explicit exclusion of production data and platform-managed internals.**

**Final verdict: READY WITH CONDITIONS for approved staging-baseline preparation; NOT READY for execution.**

Strategy A, historical replay, cannot meet the provenance standard. The reachable Git history and public PR artifacts do not recover the missing migration bodies or a trustworthy execution manifest. Strategy B can create a reproducible current-state baseline, but it is a new baseline and must never be represented as a recovered historical chain.

## Comparison

| Decision criterion | Strategy A: replay historical migration directory | Strategy B: reviewed schema-only baseline |
|---|---|---|
| Source completeness | Fails: 74 ledger entries remain unresolved or ambiguous and matched files are not proven content-equivalent. [1] | Passes conditionally: current state can be captured through the supported Supabase CLI workflow. [2] |
| Reproducibility | Fails: ordering, duplicate prefixes, reference migrations, and manual-applied evidence are unresolved. | Passes conditionally: pin CLI/diff engine, hash the export, review exclusions, and test in an isolated database. |
| Production-data safety | Risky: replay may contain seeds/backfills or infer historical data behavior. | Stronger: default schema dump excludes data and custom roles; data and seeds remain separate approvals. [2] |
| Platform compatibility | Risky: repository SQL may include obsolete or platform-managed assumptions. | Stronger: Supabase filtering excludes managed internals, while approved managed-schema customizations are reviewed separately. [3] |
| Security fidelity | Unverified: historical grants, policies, and executor identity are not established. | Better but conditional: catalog comparison, PostgREST configuration capture, and role-specific tests are required. |
| Staging readiness | Cannot safely apply without guessing. | Staging is empty and healthy, with the same five installed extensions as production; it is suitable for a controlled synthetic baseline after approvals. |
| Operational governance | Fails: no checked-in migration executor or immutable execution manifest. | Passes conditionally: add one protected CI deployer, pinned CLI, concurrency, approvals, and an immutable manifest. |

## Current readiness facts

Production `cmdglabohpttgfofcmqc` and staging `aqhktriwaglvvrchxmtd` are both reported `ACTIVE_HEALTHY` in `eu-west-1`. They share the same installed extensions and versions: `pg_stat_statements` 1.11, `pgcrypto` 1.3, `plpgsql` 1.0, `supabase_vault` 0.3.1, and `uuid-ossp` 1.1. Staging has no Scholars application relations and no storage buckets in the current read-only catalog inventory. [4]

PostgREST settings are not yet verified through the supported Management API. The current SQL settings inspection returned no values for the relevant `pgrst` settings; this is an access/surface limitation, not proof that the settings are absent. The project administrator must produce the sanitized Management API configuration record and confirm exposed schemas before baseline execution.

## Conditions before execution

The following conditions are mandatory:

1. A project administrator supplies sanitized production and staging PostgREST configuration evidence using the documented scoped Management API path. [5]
2. A schema-only production export is generated with a pinned CLI and selected schemas, then scanned for data statements, platform-managed internals, roles, secrets, Vault material, and storage objects.
3. Approved `auth` and `storage` customizations are captured and reviewed separately; bucket configuration and policies are not assumed to be covered by a generic dump.
4. The export is compared against production catalog inventories and the Phase 2.1.2 application dependency matrix.
5. A new baseline migration or declarative schema tree is created with a new identifier, source hash, exclusion list, extension manifest, and reviewer approval. Historical versions are not reused.
6. The baseline is tested in a disposable local or isolated Postgres environment, then applied to empty staging only after explicit founder approval.
7. Generated database types are produced from staging and compared with the committed type contract; application, RLS, grants, function search-path, and API-surface tests pass.
8. A protected CI deployment job, scoped identity, immutable migration manifest, concurrency gate, and production approval are in place before any future production migration.
9. Production data is not copied. Any staging fixtures are synthetic or separately approved and de-identified.

## Stop conditions

Stop and request a decision if the export contains real user data, storage objects, Vault material, credentials, unexplained role changes, or an object that the selected diff engine cannot safely represent. Stop if the sanitized PostgREST configuration differs from the planned public API surface, if type generation changes privileged or public dependencies unexpectedly, or if staging cannot reproduce the reviewed schema without manual edits.

## Final assessment

The safest route is not to reconstruct what cannot be proven. Establish a current, sanitized, reviewable schema baseline in empty staging; preserve the historical migration report as an irrecoverability record; then build forward under a single governed migration executor. The strategy is ready for preparation, but the actual staging change remains intentionally blocked pending the conditions above.

## References

[1]: https://github.com/ImperioKDB/Updates/blob/main/SCHOLARS_PHASE_2_1_3_MIGRATION_PROVENANCE_RECONCILIATION_2026-11-09.md "Phase 2.1.3 migration provenance reconciliation"
[2]: https://supabase.com/docs/reference/cli/introduction "Supabase CLI reference"
[3]: https://supabase.com/docs/guides/local-development/diff-engines "Supabase diff engines"
[4]: https://github.com/ImperioKDB/Updates/blob/main/SCHOLARS_PHASE_2_1_3_STAGING_ENVIRONMENT_READINESS_AUDIT_2026-11-09.md "Phase 2.1.3 staging readiness audit"
[5]: https://supabase.com/docs/reference/api/v1-get-postgrest-service-config "Supabase Management API — Get PostgREST config"
