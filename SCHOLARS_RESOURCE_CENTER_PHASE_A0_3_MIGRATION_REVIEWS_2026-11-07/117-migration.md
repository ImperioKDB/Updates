# File

`/tmp/scholars-a03-snapshot/scholars-41573f5/supabase/migrations/0098_seed_verified_user_supplied_opportunities_2026.sql`

This review is based only on the specified migration. No SQL was executed, no Supabase instance or hosted service was accessed, and the snapshot was not modified.

# Scope

The migration is a PostgreSQL `DO` block named `$migration$`. Its purpose is to seed or refresh two verified opportunity records:

1. An Anthony Udokwu's Foundation-Yahweh 2027/2028 university scholarship in `public.scholarships`.
2. The Stories From Nigeria Annual Writing Competition 2026 in `public.opportunities`.

The opening comments state that the records were verified on 2026-10-25 against official provider pages and that the Foundation listing is a scholarship while the Stories From Nigeria listing is a writing competition. The block declares one local UUID variable, `v_id`, and performs conditional DML only. There are no explicit transaction-control statements, extensions, functions, triggers, policies, schema changes, or permissions statements in this file.

# Objects and mutations

## DDL

No DDL is present. The migration does not create, alter, drop, rename, or truncate any table, column, constraint, index, view, function, type, schema, policy, or other database object.

## DML against `public.scholarships`

The first branch looks up one existing scholarship by either:

- exact `application_url` equal to `https://anthonyudokwufoundationyahweh.co.uk/2028-Scholarship/`; or
- case-insensitive `title` equal to `Anthony Udokwu's Foundation-Yahweh 2027/2028 University Scholarship`.

The lookup orders matching rows by `created_at desc` and takes one row. If no row is found, it inserts a scholarship with the following substantive values: the Foundation title and provider name, a narrative description, an amount stating that the award may be full or partial and that no fixed amount is published, deadline `2027-02-28`, the official application URL, level `undergrad`, null discipline, `verified = true`, detailed research notes, detailed application instructions, null `opens_at`, and `last_verified_at = now()`.

If a matching row is found, it updates that one row with the same content fields, sets `verified = true`, sets `last_verified_at = now()`, and explicitly sets `discipline` and `opens_at` to null. It does not update `created_at` or any other columns not listed in the update. Because the selection is by URL or title and chooses the newest matching row, pre-existing duplicates are not consolidated; only one selected row is refreshed.

## DML against `public.opportunities`

The second branch checks for any row in `public.opportunities` whose `application_url` is `https://storiesfromnigeria.org/submissions/` or whose case-insensitive title is `Stories From Nigeria Annual Writing Competition 2026`. If no match exists, it inserts one row with type `competition`, title/provider, description, eligibility notes, duration, location, compensation, discipline, deadline `2026-11-12`, opening date `2026-10-21`, the official submissions URL, application instructions, `verified = true`, and research notes. If a matching row already exists, the branch performs no update.

The check includes `limit 1`, but because it is an existence test the limit does not materially change the result. This branch is therefore insert-if-absent rather than a full refresh/upsert.

## Grants and revokes

No `GRANT` or `REVOKE` statements are present. The migration does not change table, schema, sequence, function, role, or row-level-security privileges.

# Dependencies

The migration depends on the following pre-existing database objects and schema contracts:

- `public.scholarships` table, readable and writable by the migration execution role.
- `public.scholarships.id`, used as a UUID selected into `v_id` and used in the update predicate.
- `public.scholarships.application_url`, `title`, and `created_at`, used by the matching query.
- The scholarship insert/update columns: `title`, `provider_name`, `description`, `amount`, `deadline`, `application_url`, `level`, `discipline`, `verified`, `research_notes`, `how_to_apply`, `opens_at`, and `last_verified_at`.
- `public.opportunities` table, readable and writable by the migration execution role.
- `public.opportunities.application_url` and `title`, used by the existence query.
- The opportunity insert columns: `type`, `title`, `provider_name`, `description`, `eligibility_notes`, `duration`, `location`, `compensation`, `discipline`, `deadline`, `opens_at`, `application_url`, `how_to_apply`, `verified`, and `research_notes`.
- PostgreSQL procedural SQL support for `DO`, PL/pgSQL variable declaration, conditional branches, `SELECT ... INTO`, `IF`, `EXISTS`, and `INSERT ... RETURNING`.
- Compatible data types and constraints for UUID identifiers, timestamps, nullable text-like fields, date/date-compatible deadline fields, and the literal values supplied.
- A `created_at` value on scholarship rows (or a compatible column) because the lookup orders by it.

The migration has no dependency on another migration by filename and does not reference application code, secrets, storage, authentication tables, or external database connections. In a reconstruction, the tables and all referenced columns must already exist with compatible semantics before this file can run.

# Data/external-side-effect assessment

This is data-seeding DML containing substantial real-world catalog content, not synthetic placeholder rows. It stores named organizations, opportunity titles, eligibility and process descriptions, dates, prize/award information, and verification narratives. It does not insert identifiable applicant data, credentials, tokens, contact records, or private user submissions.

The migration embeds external URLs in both data and comments/research notes, including the Foundation scholarship page, Foundation homepage, Foundation process page, Stories From Nigeria competition page, and Stories From Nigeria submissions page. The SQL itself does not fetch or validate those URLs; it only stores them as strings. Any external effect would occur later if application code or an administrator follows the links. The comments assert verification against official provider pages as of 2026-10-25, but that assertion is not independently rechecked by this read-only audit.

The seeded values have operational content: deadlines, opening dates, verification flags, award/prize statements, eligibility rules, application instructions, and guidance about sensitive supporting evidence. The Foundation `how_to_apply` text specifically advises applicants not to upload medical, orphanhood, or abuse-related evidence at the initial stage unless requested later. Although this is not personal data, it is user-facing guidance and should be treated as content with possible staleness or policy implications.

The insert/update logic is not fully concurrency-safe in the absence of a unique constraint or other serialization: two concurrent executions could both observe no matching row and insert duplicates. The scholarship branch may update the newest among multiple matches, while the competition branch leaves an existing match untouched even if its content is stale. These are database-state side effects, not external network side effects.

# Security/ordering implications

No grants, revokes, role changes, security-definer functions, RLS policy changes, or authentication mutations are present. The block ordinarily runs with the privileges of the migration execution context; that context must have the necessary read/write rights on both public tables. The file itself does not bypass RLS or explicitly change security settings. Whether RLS affects execution depends on the surrounding deployment and role configuration, which this file does not establish.

Ordering is material. The `public.scholarships` and `public.opportunities` tables, their referenced columns, and any required enum/domain definitions must be available before this migration runs. If either table or any listed column is introduced later, the migration fails at parse/planning or execution time. Existing constraints must accept the supplied values, notably `type = 'competition'`, `level = 'undergrad'`, the date literals, null disciplines, long text fields, and true verification flags.

The scholarship lookup relies on `created_at` ordering and assumes it is non-null or at least orderable. It can select a row by title even if its URL differs, then replace that row's URL and content. The use of `lower(title)` is case-insensitive but does not normalize whitespace or other textual variations. No unique-key conflict handling is used. The competition check and scholarship select-then-insert patterns can race and produce duplicates unless external migration serialization or table constraints prevent that.

`now()` timestamps the scholarship row at execution time, so rerunning the migration changes `last_verified_at` on a matching scholarship even when its substantive content is unchanged. The competition row is not refreshed on rerun. The migration has no explicit `COMMIT`; normal migration tooling is expected to provide transaction handling.

# Reconstruction recommendation

For a **synthetic schema reconstruction**, this migration can be omitted if the objective is to reconstruct database structure, relationships, constraints, permissions, and application-facing schema rather than production catalog contents. It contains no DDL, grants, revokes, or reusable schema behavior. Omitting it avoids importing date-sensitive, externally sourced, user-facing opportunity content and avoids reproducing its non-atomic deduplication behavior.

It should not be omitted if the reconstruction is intended to reproduce the actual seeded catalog state, migration history, verified opportunity fixtures, or application screens/tests that depend on these two records. In that case, replay it only after the referenced tables and columns exist, and consider whether the target should preserve the records as fixtures or replace the external URLs/content with clearly synthetic equivalents. A faithful replay should also account for the migration's asymmetric rerun behavior: scholarship refresh versus competition insert-only behavior.

# Verdict

**Omit from a synthetic schema reconstruction; retain only for a data/state-faithful reconstruction.** The file is DML-only, with no DDL or privilege changes. Its principal effect is importing and refreshing real, externally sourced opportunity content, including official URLs, deadlines, eligibility guidance, and verification claims. It has table/column ordering dependencies and potential duplicate/race behavior, but it introduces no independent security-policy change or external network call during migration execution.
