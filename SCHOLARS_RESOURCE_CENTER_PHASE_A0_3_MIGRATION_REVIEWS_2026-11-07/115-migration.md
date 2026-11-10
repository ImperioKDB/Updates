# File

`/tmp/scholars-a03-snapshot/scholars-41573f5/supabase/migrations/0096_seed_lca_scholarship_2026.sql`

The file is a 67-line PostgreSQL migration. Its body is a dollar-quoted `DO $migration$ ... $migration$` block. The comments state that the scholarship facts were verified on 2026-10-23 against official Liberty Career Academy pages plus supplied/secondary listings, and explain that provider-confirmed award amounts were not available.

# Scope

This migration seeds or refreshes one scholarship record for the 2026 Liberty Career Academy (LCA) Scholarship Program. It does not define or alter schema objects. It performs a lookup, then conditionally inserts or updates one row in `public.scholarships`.

The audit is limited to this migration file. No SQL was executed, no Supabase instance or hosted service was contacted, and the snapshot was not modified.

# Objects and mutations

## DDL

None. There are no `CREATE`, `ALTER`, `DROP`, `TRUNCATE`, index, type, function, trigger, policy, or other schema-definition statements.

## DML and procedural operations

The `DO` block declares a local UUID variable `v_id` and executes the following operations:

1. `SELECT id INTO v_id` from `public.scholarships`, matching either the exact application URL `https://lcaglobal.org/scholarship-application-form/` or a case-insensitive title match for `Liberty Career Academy (LCA) Scholarship Program 2026`; it uses `LIMIT 1` and has no `ORDER BY`.
2. If no matching row is found, `INSERT` adds one row with title, provider, description, amount text, deadline, application URL, level, discipline, verification flag, research notes, application instructions, opening date, and `last_verified_at = now()`. The generated row ID is captured with `RETURNING id`.
3. If a match is found, `UPDATE public.scholarships` overwrites the same substantive fields, including title, provider, description, amount, deadline, application URL, level, discipline, verification flag, research notes, application instructions, and opening date; it also sets `last_verified_at = now()`.

The mutation is therefore DML-only but is not read-only: it can insert or update persistent application data. No explicit `DELETE` occurs. `discipline` is explicitly set to SQL `NULL` in both branches.

## Grants and revokes

None. The file contains no `GRANT`, `REVOKE`, role change, row-level-security policy, or privilege-related statement.

# Dependencies

* The relation `public.scholarships` must already exist.
* The relation must expose at least the columns `id`, `application_url`, `title`, `provider_name`, `description`, `amount`, `deadline`, `level`, `discipline`, `verified`, `research_notes`, `how_to_apply`, `opens_at`, and `last_verified_at`.
* `id` must be usable as a UUID-compatible local variable and returned by the insert. The migration assumes the table's insert/default behavior can supply an ID; it does not provide one explicitly.
* The target column types must accept the supplied text, boolean, date/timestamp-like values, and `NULL` values. In particular, the literal dates are expected to coerce to the types used by `deadline` and `opens_at`, and `now()` must be compatible with `last_verified_at`.
* The executing role needs permission to select from and insert/update `public.scholarships`. The file itself does not grant those permissions.
* PostgreSQL procedural-language support for `DO` and the standard `now()` function are required. The block uses ordinary PL/pgSQL constructs (`DECLARE`, `IF`, `SELECT INTO`, and `RETURNING`).
* It logically depends on the schema migration(s) that created `public.scholarships` and established the listed columns and defaults. It must run after those definitions, but the file declares no explicit dependency metadata.

# Data/external-side-effect assessment

The migration embeds one real-world scholarship record rather than synthetic fixture data. It contains the provider name, 2026 application window, eligibility/application guidance, verification status, research notes, and several provider or listing URLs. The content includes:

* Official provider URLs for the LCA scholarship program and application pages.
* An official Gifted Hands application URL.
* A supplied ScholarshipAir listing URL and an independent After School Africa URL in `research_notes`.
* A statement that applications run from 20 October 2026 through 3 November 2026 at 11:59 PM WAT, and that applicants may apply to only one category.
* Applicant-facing requirements and the provider's statement that AI-generated personal statements cause automatic disqualification.

The migration itself performs no HTTP request, URL fetch, webhook call, file operation, email, or other network/external side effect. URLs are stored as ordinary text. The comments and research notes are provenance assertions, not runtime verification. `last_verified_at = now()` is a runtime-dependent value, so repeated execution changes that timestamp even when the substantive record is unchanged.

The insert/update is a real-data mutation in the sense that it creates or overwrites a production-style scholarship catalog row. It is not merely schema reconstruction metadata. The `amount` field intentionally stores explanatory text rather than a numeric award amount, because the source material did not provide a provider-confirmed amount.

# Security/ordering implications

The block runs with the default execution semantics of an anonymous `DO` block; it does not declare elevated `SECURITY DEFINER` behavior, alter search paths, or change privileges. It fully qualifies the target table as `public.scholarships`, which reduces ambiguity about the relation, but all referenced column types and constraints remain external assumptions.

The lookup-and-then-insert/update pattern is only conditionally idempotent and is not concurrency-safe by itself. It identifies a row by either URL or case-insensitive title, chooses an arbitrary matching row when duplicates exist because of `LIMIT 1` without `ORDER BY`, and may update one duplicate while leaving others. Concurrent executions can both observe no match and attempt inserts unless a suitable unique constraint or transaction-level coordination exists. Any unique constraints, triggers, audit columns, or update policies on `public.scholarships` could further affect the outcome; none are declared here.

The update deliberately overwrites existing editorial fields, including `amount`, `discipline`, verification/provenance text, application instructions, and dates. Thus it can replace local edits to a matching row. It does not explicitly touch an assumed primary key, creation timestamp, or unrelated columns, but triggers could produce additional effects if present. The absence of an explicit `ORDER BY` and the broad `OR` match make pre-existing duplicates or a title collision important operational risks.

Ordering is straightforward: the table and all referenced columns/defaults must be present before this migration. It should be applied after any migration that establishes the scholarship catalog schema and before any later migration that assumes this particular LCA row exists. Because it is a data seed, it need not precede unrelated table definitions, but it should not be replayed against an initialized dataset without considering overwrite behavior.

# Reconstruction recommendation

For a synthetic schema reconstruction whose goal is to reproduce database structure rather than production catalog contents, this migration can be omitted. It contributes no DDL, grants, revokes, policies, or other schema behavior; omitting it does not remove a table, column, constraint, or privilege needed to reconstruct the schema.

If the reconstruction is intended to reproduce representative seed data, the migration is optional and should be treated as a separately documented fixture/data-seeding step, not as structural schema. Before retaining it in a non-production fixture, consider replacing the real scholarship/provider content and external URLs with clearly synthetic values, or explicitly label the record as real sourced content. If retaining the exact seed, account for its time-sensitive 2026 dates, provenance claims, dynamic `now()` timestamp, and the overwrite/concurrency caveats. A safer implementation would use a declared uniqueness strategy and deterministic conflict handling, but such changes are outside this audit.

# Verdict

**Omittable for synthetic schema reconstruction: yes.** The migration contains no DDL, grants, revokes, or schema-level security configuration. It is a real-data seed/upsert for one LCA scholarship record, dependent on an already-created `public.scholarships` table. Preserve it only when reproducing catalog seed data or application behavior that expects this row; otherwise omit it from the structural reconstruction and document that the omission intentionally excludes this data mutation.