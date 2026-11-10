# Scholars Phase 2.1.5 — Schema Capture and Coverage Report

**Investigation date:** 2026-11-10
**Scope:** Read-only live catalog revalidation and capture readiness. This report does not claim that a dump or declarative tree was generated.

## Capture status

**Status: BLOCKED — AUTHORIZED CAPTURE NOT AVAILABLE.**

The approved Supabase CLI was not installed in the execution environment. No authorized read-only database URL was available for `supabase db dump`, and no scoped Management API credential was available for the PostgREST record. Therefore:

| Capture item | Status |
|---|---|
| Schema-only dump | Not executed |
| Declarative pg-delta generation | Not executed |
| CLI version | Not available |
| pg-delta version | Not discoverable |
| Command exit codes | Not applicable |
| Coverage warnings | Not available |
| Generated file inventory | None |
| SHA-256 artifact hashes | None |
| Manual adjustments | None |

This is an explicit access limitation, not a successful empty result.

## Verified live catalog inventory

The following counts are from bounded, read-only catalog queries against production `cmdglabohpttgfofcmqc`; they contain no production row data.

| Object category | Verified result | Evidence interpretation |
|---|---:|---|
| Production migration-ledger rows | 180 | Current ledger count; not a recovered chain claim |
| Public tables / partitioned tables | 45 | All 45 have RLS enabled |
| Public views | 4 | Four Resource Center public views |
| Public sequences | 1 | Catalog count |
| Public indexes | 157 | Catalog count |
| Public security-definer functions | 31 | Requires targeted review |
| Public force-RLS tables | 0 | RLS is enabled but not forced |
| Storage buckets | 2 | `avatars` and `site`; rows are configuration, not files |
| Non-internal public triggers | 25 | Application trigger inventory |
| Auth/storage relevant triggers | Present | Includes `auth.users` user-creation trigger and storage platform/custom triggers |
| Realtime publication membership | 1 reported table | `public.scholarship_discussions` in `supabase_realtime` |
| Installed extensions | 5 | See extension manifest below |

## Extension manifest

Production and staging both report the same five extensions and versions:

| Extension | Version | Schema | Classification |
|---|---:|---|---|
| `pg_stat_statements` | 1.11 | `extensions` | Platform/operational |
| `pgcrypto` | 1.3 | `extensions` | Application dependency candidate |
| `plpgsql` | 1.0 | `pg_catalog` | PostgreSQL built-in |
| `supabase_vault` | 0.3.1 | `vault` | Platform-managed; do not export Vault contents |
| `uuid-ossp` | 1.1 | `extensions` | Application dependency candidate |

## Coverage expected but not captured

The catalog queries verified that the live database contains tables, indexes, views, functions, triggers, RLS policies, grants, default privileges, storage policies, extensions, and publication membership. They did not generate a portable schema artifact containing all definitions. The following remain unverified in an extraction:

- Exact column definitions and constraints as emitted by the selected method.
- Full function bodies and dynamic-SQL behavior.
- Complete grant/ownership statements as a portable replay artifact.
- Unsupported-object warnings from pg-delta.
- Exact dump filtering behavior for managed schemas.
- Whether the output contains any data, bucket rows, Vault material, or sensitive configuration statements.
- Cross-method equality between dump SQL and the declarative tree.

## Repository revalidation

The application repository state is:

| Item | Result |
|---|---|
| Baseline SHA | `cf3682ce35912df7b9b9352193630fc404427c7c` |
| Current `origin/main` | `3deba708e146ceb2aa6846c4691d58ace93795b2` |
| Migration files at baseline | 129 |
| Migration files at current main | 132 |
| New migration files since baseline | 3 |

New files are dated 2026-11-09 and concern Airtel/Afara routing, Kayode/NNPC-SNEPCO source re-verification, and Airtel scholarship eligibility. They are current application changes, not historical reconstruction evidence.

## Staging readiness evidence

Staging project `aqhktriwaglvvrchxmtd` is `ACTIVE_HEALTHY`, but bounded catalog inspection returned no relations in the application schemas or `supabase_migrations` schema. It remains an empty destination, not a captured baseline.

## Security implications

A catalog inventory is useful for planning but cannot establish that a candidate artifact is safe to restore. The missing artifact inventory and hash set prevent independent review of unsupported objects, grants, function bodies, and managed-schema handling. No database or storage object was copied.

## Next capture gate

Do not generate or apply a baseline until an administrator provides the pinned CLI and a properly authorized non-writing connection. Run both methods, retain private hashes, compare coverage, and publish only sanitized conclusions.

## References

- [Supabase CLI reference](https://supabase.com/docs/reference/cli/introduction)
- [Declarative database schemas](https://supabase.com/docs/guides/local-development/declarative-database-schemas)
- [Supabase diff engines](https://supabase.com/docs/guides/local-development/diff-engines)
