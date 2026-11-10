# Scholars Phase 2.1.5 — Schema Extraction Method Comparison

**Evidence window:** 2026-11-10, 10:27–10:32 CET (UTC+01:00)
**Scope:** Compare the pinned `supabase db dump` and `supabase db schema declarative generate` methods. No production or staging extraction was executed.

## Methodology and decision

The exact approved CLI pin identified in the prior workflow review is Supabase CLI `2.122.1`. No system-installed `supabase` binary was present. The pinned npm package was invoked from `/tmp/phase215/cli` for `--version`, `db dump --help`, and `db schema declarative generate --help`; each completed with exit code 0. No project was linked, no database URL was supplied, and no Supabase database or Management API operation was made. [1]

The pinned help confirms there is **no `--schema-only` flag** for `db dump`. Its default mode is schema-only; do not add an unsupported flag. It supports `--db-url`, `--schema`, and `--file`. Data and custom-role output are separate opt-in modes (`--data-only` and `--role-only`) and are outside this task. [2]

The declarative command supports `--db-url`, `--schema`, `--output-dir`, `--strict-coverage`, and the global `--experimental` flag. The official guide describes pg-delta as experimental/pre-1.0. The CLI help does not disclose a separate bundled pg-delta version, so that version remains unknown. [1] [3] [4]

## Comparison

| Dimension | `supabase db dump` default schema output | `supabase db schema declarative generate` with pg-delta | Assessment |
|---|---|---|---|
| Tables, columns, constraints, indexes | Conventional SQL definitions for selected, non-filtered schemas | Catalog-modeled objects and dependency-aware per-object files | Both can support review; inspect actual outputs before calling either complete |
| Views and materialized views | SQL definitions subject to schema filters | Modeled by pg-delta; view options are part of current engine coverage | Compare the actual view definitions and security options |
| Functions and triggers | SQL definitions may expose full implementation details | Modeled by pg-delta; inspect each function's owner, security mode, search path, and body | Neither substitutes for a security review |
| RLS and grants | SQL output can contain policy and ACL statements for included schemas | Policies and permissions are modeled; default-privilege output still needs interpretation | Confirm roles, grants, ownership, and defaults separately |
| Roles and cluster state | Custom roles are excluded by default; `--role-only` is not authorized here | Current pg-delta documentation lists roles among modeled entities | Do not assume role memberships, platform roles, or project defaults are a portable application baseline |
| `auth` and `storage` customizations | Supabase dump excludes managed `auth` and `storage` schemas by default | pg-delta documentation confirms some managed-schema triggers and policies for initial `db pull`; the reviewed docs do not prove that declarative `generate` in CLI 2.122.1 captures every such customization | Separate capture and inspection are mandatory; do not claim parity without an artifact test |
| Buckets and application data | Default dump contains no row data; storage bucket records are not DDL | Declarative schema diffs do not capture DML, including storage bucket rows | Bucket configuration requires a separate reviewed inventory; never copy storage objects |
| Extensions | Extension-created schemas and objects are filtered by default | Extension-managed objects/configuration are not a substitute for an installed-extension manifest | Record actual installed versions separately; do not export Vault contents |
| Unsupported objects | SQL dump may contain SQL outside the desired baseline unless filtered | Warnings identify unsupported objects; `--strict-coverage` converts them to failures | Strict coverage is necessary, not proof of semantic completeness |
| Reproducibility | Pin CLI, selected schemas, target identity, command, and hash | Pin CLI/engine, schema selection, target identity, warnings, and hashes | Both need immutable execution metadata |
| Human review | Usually one SQL artifact; straightforward to scan but dense | Object-level tree is easier to diff and review | Declarative output is more reviewable when it completes without warnings |
| Security exposure of output | May contain sensitive role names, grants, function bodies, or configuration | May expose the same structural details across many files | Sanitize before repository publication |

Current Supabase documentation lists tables, views, materialized views, functions, triggers, RLS policies, grants, comments, domains, partitions, and publications among pg-delta's modeled objects. It also documents unsupported classes, including casts, operators, operator classes/families, text-search objects, statistics objects, languages, transforms, and parameter ACLs. `--strict-coverage` should make these warnings fail the run rather than silently treating coverage as complete. [3] [4]

The diff-engine guide explicitly says an initial pg-delta `db pull` can capture project-owned triggers on `auth.users` and policies on `storage.objects` and `storage.buckets`. That statement is not used here as proof that declarative `generate` in CLI 2.122.1 will preserve every managed-schema customization. The actual generated output must be compared with a separately authorized catalog inventory. [4]

## Conditional recommendation

For a future authorized capture, use the declarative tree as the primary human-review candidate and the default schema-only dump as an independent SQL cross-check. This is a **conditional method recommendation**, not a captured or approved baseline. Neither output should be considered safe to restore until its unsupported-object warnings, managed-schema gaps, grants, and destination defaults are reviewed.

Prospective command shapes, not run in this phase:

```bash
npx --yes supabase@2.122.1 db schema declarative generate \
  --db-url "$READ_ONLY_DB_URL" \
  --schema "$APPROVED_SCHEMA_LIST" \
  --output-dir "$PRIVATE_CAPTURE_DIR/declarative" \
  --strict-coverage --experimental

npx --yes supabase@2.122.1 db dump \
  --db-url "$READ_ONLY_DB_URL" \
  --schema "$APPROVED_SCHEMA_LIST" \
  --file "$PRIVATE_CAPTURE_DIR/schema.sql"
```

The approved schema list must be established before execution; do not assume that `public` is the complete application schema set. Select any approved `auth` or `storage` customization for a separate review, and keep platform internals, bucket rows, production data, secrets, and Vault material out of the candidate. Use an administrator-managed secret store for the read-only URL; never place it in a report or repository.

The pinned CLI help notes that linked/Management API modes may require `database_write` scope. This phase did not use that scope. A direct `--db-url` path avoids relying on an unverified linked-project scope but still requires a properly restricted, non-writing database identity. No such URL was made available, so neither command was run.

## Status and limitations

No dump or declarative tree exists from this phase. There is no generated-file inventory, artifact hash, pg-delta runtime version, command exit code for an extraction, coverage warning list, or cross-method diff. The help-only exit codes do not count as extraction results.

## Environment, source, and evidence classification

The comparison concerns production `cmdglabohpttgfofcmqc` and staging `aqhktriwaglvvrchxmtd`. The CLI evidence source is the local, help-only invocation of the exact `2.122.1` package; documented coverage claims are taken from the linked Supabase references. No database connection was used.

- **Confirmed:** CLI version and supported help options; no extraction ran; no generated artifact or hash exists.
- **Inference/recommendation:** Declarative output is likely more reviewable and should be the primary future candidate, with SQL dump as a cross-check. This is not based on side-by-side captured artifacts.

## Unresolved questions and security implications

The actual object coverage, managed-schema behavior under `declarative generate`, ACL/default-privilege fidelity, unsupported-object set, reproducibility, and dump/declarative equivalence remain unknown until both methods are run against an approved read-only connection. Either output may expose grants, function bodies, role names, and structural information; keep raw artifacts private and scan before any publication.

## References

[1]: https://supabase.com/docs/reference/cli/introduction "Supabase CLI Reference"
[2]: https://supabase.com/docs/reference/cli/supabase-db-dump "Supabase CLI Database Dump Reference"
[3]: https://supabase.com/docs/guides/local-development/declarative-database-schemas "Supabase Declarative Database Schemas"
[4]: https://supabase.com/docs/guides/local-development/diff-engines "Supabase pg-delta and migra Diff Engines"
[5]: https://github.com/ImperioKDB/Updates/blob/3d3da285f1b076fbfebb1fdf1adbaadeb178d71f/SCHOLARS_PHASE_2_1_4_SCHEMA_ONLY_BASELINE_FEASIBILITY_2026-11-09.md "Phase 2.1.4 Baseline Feasibility"
