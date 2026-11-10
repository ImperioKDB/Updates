# Scholars Phase 2.1.6 — Declarative vs Dump Coverage Reconciliation

**Status:** BLOCKED — neither schema artifact was generated.
**Evidence time:** 2026-11-10, 10:57–11:01 CET.
**Author:** Manus AI

## Scope and methodology

The intended comparison is between a Supabase CLI pg-delta declarative schema tree and an independent schema-only SQL dump from production `cmdglabohpttgfofcmqc`. The pinned CLI help was inspected locally at version `2.122.1`. No database URL was supplied and no extraction was run. This is therefore a coverage-readiness report, not a semantic comparison of actual artifacts.

## Confirmed findings

The pinned help supports `supabase db schema declarative generate --db-url --schema --output-dir --strict-coverage --experimental`. The dump command supports `--db-url`, `--schema`, and `--file`; schema output is the default and there is no `--schema-only` flag. The help does not disclose a separate pg-delta runtime version. The previous method comparison identifies managed-schema and platform-object limitations that must be resolved against real outputs. [1] [2]

No SQL dump or declarative tree exists, so there are no matching-only or method-specific objects to enumerate. Coverage is unverified for tables, columns, keys/constraints, indexes, views and view options, materialized views, functions, triggers, RLS policies, direct and default grants, ownership, domains/types, sequences, extensions, publication membership, `auth.users` custom triggers, Storage policies, and platform-managed customizations. Unsupported pg-delta objects and strict-coverage warnings are unknown. No cross-method equivalence claim can be made from table or catalog counts.

## Security implications

A default schema dump and a declarative schema tree may differ in managed-schema treatment and privilege fidelity. A schema-only label does not authorize publishing or restoring raw output. Both future artifacts must remain private and be scanned for data statements, bucket configuration/rows, Vault material, secrets, unexpected role/ownership statements, and platform internals. Production data and storage bytes are excluded.

## Limitations and next action

The required verified read-only database URL was not available; system `pg_dump` is absent. Until authorized capture is possible, reconciliation is blocked. After capture, compare object definitions and security properties class-by-class, include unsupported and intentionally excluded objects in the manifest, and have an independent reviewer inspect the private artifacts. No staging restore is authorized by this report.

## References

[1]: https://supabase.com/docs/reference/cli/supabase-db-dump "Supabase CLI Database Dump Reference"
[2]: https://supabase.com/docs/guides/local-development/declarative-database-schemas "Supabase Declarative Database Schemas"
