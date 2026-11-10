# Scholars Phase 2.1.5 — Schema Extraction Method Comparison

**Investigation date:** 2026-11-10
**Scope:** Compare `supabase db dump` schema-only extraction with `supabase db schema declarative generate` using documented behavior and the verified live catalog. No extraction or database modification was performed.

## Executive finding

The recommended future approach is a **pg-delta declarative generation as the primary candidate baseline, paired with a schema-only dump as an independent verification artifact**. This is a recommendation for the next authorized capture, not a claim that either artifact was generated in this phase.

The current phase is **BLOCKED — AUTHORIZED CAPTURE NOT AVAILABLE** because the approved Supabase CLI is not installed in the execution environment and no authorized read-only database URL or Management API token was supplied.

## Method comparison

| Dimension | `supabase db dump` schema-only | `supabase db schema declarative generate` with pg-delta | Assessment |
|---|---|---|---|
| Tables, columns, constraints, indexes | Strong SQL capture when selected schemas are authorized | Strong catalog-modeled capture | Both useful |
| Views and materialized views | Captured in SQL output subject to dump filters | Modeled and dependency ordered | pg-delta is easier to review per object |
| Functions and triggers | Captured as SQL definitions when included | Modeled through catalog comparison | Verify function bodies and security attributes in both |
| RLS policies | Captured for selected schemas; managed-schema handling needs explicit review | pg-delta includes relevant customizations in managed schemas | pg-delta is stronger for `auth`/`storage` customizations, but still review output |
| Comments, domains, roles, publication membership | Depends on dump options and filtering | pg-delta models more of these entities | Declarative method has better stated coverage |
| Security-invoker view settings | Must be verified in output/catalog | pg-delta models the setting according to current docs | Explicit verification required |
| Default privileges and grant overlays | SQL may include ownership/grants; inspect for environment-specific ACLs | Permissions are part of schema state, but default ACLs can produce noise | Neither removes the need for destination review |
| Unsupported objects | Dump can include SQL outside the desired baseline unless filtered | Warns on objects it does not track; `--strict-coverage` can fail | Use strict coverage and retain warnings |
| DML, buckets, and data | Schema-only should exclude table data, but output must be scanned | DML is not represented by declarative schema | Keep data and bucket rows as separate controlled workstreams |
| Managed schemas | Requires deliberate `auth`/`storage` selection and review | pg-delta can capture custom triggers/policies on managed tables | Separate review remains mandatory |
| Reproducibility | Pin CLI, flags, selected schemas, and hash output | Pin CLI, pg-delta behavior, flags, and hash tree | Both reproducible only with execution metadata |
| Human review | One large SQL file can be difficult to review | Per-object tree is easier to diff and review | Declarative tree is more reviewable |
| Security exposure of output | May contain sensitive role names, grants, function bodies, or configuration | May expose the same structural details across many files | Sanitize before repository publication |

## Documented pg-delta controls

Current Supabase documentation states that declarative generation requires pg-delta / the experimental workflow, supports `--strict-coverage`, writes under `supabase/schemas` by default, and can include customizations in managed schemas. The documentation also states that DML such as inserts, updates, deletes, and storage bucket rows are not captured by declarative schema diffs. Unsupported object classes generate warnings and can be made hard failures with `--strict-coverage`.

The recommended command shape for the next authorized run is conceptually:

```text
supabase db schema declarative generate --db-url <authorized-read-only-url> --output-dir <candidate-dir> --strict-coverage --experimental
```

The exact flags must be checked against the pinned installed CLI before execution. No credential or URL is included in this report.

The independent verification command should be a schema-only dump using the same authorized, non-writing connection and explicitly selected application/approved managed schemas. The resulting file must be scanned before retention.

## Selection rationale

The declarative tree is the better primary review artifact because it makes object-level review, dependency-aware migration generation, coverage warnings, and reproducible diffs practical. The dump remains valuable as a second source because it is a conventional SQL representation that can expose statements, grants, ownership, function bodies, and platform-specific details that a modeled tree may not preserve identically.

The two methods are complementary. A successful declarative generation must not be treated as complete merely because it produced files. A successful schema-only dump must not be treated as safe merely because it used the phrase `schema-only`.

## Capture requirements before execution

- Pin and record the exact Supabase CLI version.
- Record whether pg-delta is enabled and the exact command exit code.
- Use a read-only connection with no write capability.
- Select application schemas deliberately; review `auth` and `storage` customizations separately.
- Retain coverage warnings, unsupported-object lists, generated-file inventory, and SHA-256 hashes in a private controlled location.
- Scan for data statements, storage objects, Vault material, passwords, tokens, JWT secrets, and unexplained role or ownership changes.
- Do not commit raw dumps or generated files containing sensitive structural details to the public Updates repository.

## Limitations

No extraction artifacts, file inventories, CLI version, pg-delta version, exit code, or artifact hashes exist for this phase. The live catalog findings in the companion reports are not substitutes for an extraction artifact.

## References

- [Supabase CLI reference](https://supabase.com/docs/reference/cli/introduction)
- [Declarative database schemas](https://supabase.com/docs/guides/local-development/declarative-database-schemas)
- [Supabase diff engines](https://supabase.com/docs/guides/local-development/diff-engines)
- [Supabase database migrations](https://supabase.com/docs/guides/deployment/database-migrations)
