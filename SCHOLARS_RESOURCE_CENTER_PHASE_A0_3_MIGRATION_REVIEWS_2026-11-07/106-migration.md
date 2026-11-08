# File

- **Path:** `/tmp/scholars-a03-snapshot/scholars-41573f5/supabase/migrations/0087_seed_taiwo_bankole_scholarship_2026.sql`
- **Migration name:** `0087_seed_taiwo_bankole_scholarship_2026.sql`
- **Inspection mode:** Strictly read-only inspection of this file only. No SQL was executed, no Supabase instance or hosted service was accessed, and the snapshot was not modified.

# Scope

This migration publishes one scholarship record for the Taiwo Bankole Prize 2026. It wraps a conditional `INSERT` in a PostgreSQL `DO $migration$ ... $migration$` procedural block. The condition checks whether an existing row matches either the official application URL or the provider name (case-insensitively), and inserts the record only when neither match exists.

The file is a data-seeding/content-publication migration rather than a schema-definition migration. Its comments and inserted research fields describe an external verification performed on 2026-10-16, but the migration itself does not perform HTTP requests or otherwise contact those external pages.

# Objects and mutations

## DDL

- **None.** There is no `CREATE`, `ALTER`, `DROP`, `TRUNCATE`, `CREATE INDEX`, or other schema-changing statement.
- The `DO` block creates no persistent database function or other durable object; it is an anonymous procedural block.

## DML

- **Target table:** `public.scholarships`.
- **Operation:** Conditional `INSERT` of at most one row.
- **Predicate:** The insert is skipped if any row has `application_url = 'https://taiwobankole.com/application-form/'` or `lower(provider_name) = 'taiwo bankole prize'`.
- **Inserted columns:** `title`, `provider_name`, `description`, `amount`, `deadline`, `application_url`, `level`, `discipline`, `verified`, `research_notes`, `how_to_apply`, `last_verified_at`, and `awards_available`.
- **Inserted values:** One named 2026 prize, deadline `2026-11-06`, official application URL, undergraduate level, STEM-or-Law discipline, `verified = true`, `last_verified_at = now()`, and `awards_available = 2`, together with descriptive eligibility, documentation, and application instructions.
- **No `UPDATE` or `DELETE`** is present.
- The operation is idempotent only with respect to the two stated duplicate checks; it does not establish a database-level unique constraint and may not prevent all duplicates under concurrent execution or where equivalent data uses different provider/URL representations.

## Grants and revokes

- **None.** The migration does not issue `GRANT`, `REVOKE`, role changes, policy changes, or ownership changes.

# Dependencies

- Requires the `public.scholarships` table to exist before this migration runs.
- Requires the target table to expose all 13 referenced columns with compatible types and nullability: `title`, `provider_name`, `description`, `amount`, `deadline`, `application_url`, `level`, `discipline`, `verified`, `research_notes`, `how_to_apply`, `last_verified_at`, and `awards_available`.
- The predicate depends on `application_url` being comparable to the supplied text URL and on `provider_name` being usable with `lower()`; unusual types, generated columns, or restrictive constraints could make the statement fail.
- The literal `2026-11-06` must be accepted by the `deadline` column (for example, a date or compatible timestamp type). `now()` must be compatible with `last_verified_at`.
- Any existing triggers, defaults, check constraints, RLS policies, or audit mechanisms on `public.scholarships` may affect whether the insert succeeds or what side effects it produces.
- There is no explicit dependency on another migration visible in this file, but normal migration ordering requires the `scholarships` table and its referenced columns to have been created before this seed migration.
- The file contains external URLs as stored content and comments, but has no runtime dependency on network availability or on the external sites being reachable.

# Data/external-side-effect assessment

This is real-world, publication-oriented seed data rather than synthetic schema metadata. It names the Taiwo Bankole Prize 2026 and stores eligibility, deadline, application instructions, award-count information, verification notes, and official URLs. The inserted text states that the individual award amount is not stated and therefore stores a descriptive string in `amount` rather than a numeric amount; reconstruction must respect the target column's actual type.

The data includes these external URLs in the stored `application_url` and `research_notes`: `https://taiwobankole.com/`, `/about/`, `/application/`, and `/application-form/`. The comments also refer to checking those pages. No external request is made by the SQL, so there is no network side effect at migration execution time. The database side effect is the insertion of one scholarship row, subject to the duplicate predicate and any table triggers or policies.

The content includes personal-adjacent eligibility and community references (young people, age range, low-income families, Ajegunle residency, public-university admission, required documents and recommendations), but it does not insert applicant records, credentials, uploaded documents, contact details, or other individual application data.

# Security/ordering implications

- Because the block reads and writes `public.scholarships`, execution requires whatever table privileges, RLS behavior, and function execution context apply to that table. The migration does not grant itself permissions or alter RLS.
- The `DO` block normally runs with the privileges of the executing migration role. If RLS is enabled, policy behavior may block the existence check or insert, depending on the role and policies; this file provides no bypass or policy change.
- The duplicate check is application-level and not an atomic uniqueness guarantee. Concurrent executions can both observe no matching row and attempt inserts unless a separate unique constraint or trigger prevents it. The check also treats provider name case-insensitively but compares the application URL exactly.
- The insert is enclosed in the anonymous block's statement context and will fail as a unit if a referenced column, type, constraint, trigger, or policy rejects it. There is no explicit exception handling, so errors are not converted into warnings or ignored.
- Ordering matters: run only after the `public.scholarships` table and all referenced columns exist. It should generally run after any schema migration that establishes the table's constraints and supporting defaults, but before any downstream process that expects this particular seed row.
- `last_verified_at = now()` records execution time rather than the stated research date. The research date is embedded in text, so reproducibility of the exact timestamp is not guaranteed across environments.

# Reconstruction recommendation

For a **synthetic schema reconstruction**, this migration can be omitted. It contributes no DDL, privileges, policies, or persistent database object needed to reconstruct the schema. Reconstruct the `public.scholarships` table and its relevant column types/constraints from the schema-defining migrations instead.

If the reconstruction goal includes representative fixture data, demo content, or migration-history fidelity, preserve it separately as an optional seed/fixture. Do not treat this row as required schema state. If retained as a fixture, validate the `amount` type, deadline type, RLS behavior, and duplicate/unique-key behavior in the reconstructed schema, and label the external URLs and real-world content as imported reference data rather than synthetic data.

# Verdict

**Omit from the synthetic schema reconstruction.** This migration is a conditional DML seed for one externally sourced, real-world scholarship listing. It has no DDL, grants, revokes, or security-definition changes. Its only required schema dependency is the pre-existing `public.scholarships` table with the listed columns. Retain only when reproducing publication data, fixtures, or exact migration behavior is an explicit objective.
