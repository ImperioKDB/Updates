# File

`/tmp/scholars-a03-snapshot/scholars-41573f5/supabase/migrations/0091_seed_kawef_scholarship_2026.sql`

The file is a 77-line PostgreSQL migration that publishes or refreshes one named scholarship and ensures five associated eligibility rules exist.

# Scope

This review is limited strictly to `0091_seed_kawef_scholarship_2026.sql`. No other migration is inspected, and this review performs no SQL execution, Supabase startup, hosted-service access, or modification of the snapshot.

The migration consists of one anonymous `DO $migration$ ... $migration$;` PL/pgSQL block. It selects an existing scholarship by application email URL or case-insensitive title, inserts a scholarship when no match is found, otherwise updates the selected row, and then conditionally inserts five scholarship-rule rows. It is seed/content migration logic rather than schema-definition logic.

# Objects and mutations

## DDL

No DDL is present. The file does not create, alter, drop, truncate, or otherwise define tables, columns, indexes, constraints, functions, types, schemas, policies, triggers, or extensions.

## DML

The block declares a local UUID variable, `v_id`.

1. It performs a `SELECT id INTO v_id` from `public.scholarships`, matching either:
   - `application_url = 'mailto:kawefscholarship@gmail.com'`; or
   - `lower(title) = lower('Kunle Ade Wahab Educational Foundation Scholarship 2026')`.

   The match is ordered by `created_at DESC` and limited to one row.

2. If no matching row is found, it inserts one row into `public.scholarships` with the following content: title, provider, a detailed description, a textual support/award description, deadline `2026-11-30`, a `mailto:` application URL, `undergrad` level, null discipline, `verified = true`, research notes, application instructions, null `opens_at`, `awards_available = 10`, and `last_verified_at = now()`. The generated row ID is returned into `v_id`.

3. If a matching row is found, it updates that selected `public.scholarships` row. It overwrites the title, provider, description, amount, deadline, application URL, level, discipline, verification flag, research notes, application instructions, awards count, and `last_verified_at`; it explicitly sets `opens_at = null`.

4. It conditionally inserts five rows into `public.scholarship_rules`, each guarded by `IF NOT EXISTS` and scoped to the selected `scholarship_id`:
   - nationality equals JSONB string `"Nigerian"`, gating true;
   - state of origin equals JSONB string `"Lagos"`, gating true;
   - year of study greater than or equal to JSONB number `300`, gating true;
   - year of study less than or equal to JSONB number `500`, gating true;
   - discipline in a JSONB array containing Architecture, Building Technology, Quantity Surveying, Estate Management, and Civil Engineering, gating true.

No `DELETE` is present. No existing rule is updated or removed; only missing exact matches are inserted.

## Grants and revokes

No `GRANT`, `REVOKE`, role, ownership, or privilege changes are present.

# Dependencies

The migration assumes these existing application objects and compatible columns/types:

- `public.scholarships` table, including at least `id` (UUID-compatible), `application_url`, `title`, `created_at`, `provider_name`, `description`, `amount`, `deadline`, `level`, `discipline`, `verified`, `research_notes`, `how_to_apply`, `opens_at`, `awards_available`, and `last_verified_at`.
- `public.scholarship_rules` table, including at least `scholarship_id` (compatible with `scholarships.id`), `field`, `operator`, `value` (compatible with JSONB), and `gating`.
- A PostgreSQL/PL/pgSQL environment supporting anonymous `DO` blocks, local declarations, `SELECT ... INTO`, conditional branching, `INSERT ... RETURNING`, `IF NOT EXISTS` query checks, `lower()`, `now()`, JSONB casts, ordering, and `LIMIT`.
- The migration role must be able to read and insert/update `public.scholarships` and read/insert `public.scholarship_rules`. The file itself does not grant those privileges.

The rule checks rely on exact equality of all listed identifying fields and JSONB values. Any uniqueness constraints, foreign keys, triggers, defaults, RLS policies, or generated-column behavior on these tables are external dependencies not defined here. The `scholarship_rules` foreign-key relationship, if present, requires the scholarship row to exist first; this file does establish that ordering locally by selecting/inserting the scholarship before rule inserts.

# Data/external-side-effect assessment

This is real-data/content seeding, not synthetic placeholder data. It publishes a specific 2026 scholarship attributed to the Kunle Ade Wahab Educational Foundation (KAWEF), with a Lagos State University/Ikorodu eligibility context, deadline, support description, eligibility rules, contact information, and application instructions.

The content includes external URLs in `research_notes`: an X post, a Facebook post, and an Icanstudent listing. It also includes a `mailto:kawefscholarship@gmail.com` application URL and a WhatsApp phone number (`0802 314 8777`) in textual notes/instructions. These are stored values only: the SQL does not fetch, validate, open, email, message, or otherwise contact any external service. `now()` records the database execution time as `last_verified_at` on insert/update; it is the only runtime-derived value.

The migration can expose or persist sensitive-document guidance (transcript/academic records, admission letter, school ID, personal statement, local-government identification or indigene certificate, and traditional-ruler letter) in the public-facing `how_to_apply` content. It does not itself collect applicant records, create users, or transmit documents.

# Security/ordering implications

- There are no explicit grants, revokes, row-level-security changes, security-definer declarations, or policy changes. Execution therefore inherits the privileges and transaction context of the migration runner; the file does not establish a security boundary.
- The block writes `verified = true` based on the embedded editorial claim that the listing was verified. Re-running it refreshes the row and retains that trust flag, so inclusion in a production dataset should be treated as a content approval decision.
- The lookup uses a broad `OR` between application URL and case-insensitive title, then chooses the most recently created match. If duplicate or conflicting rows already exist, the selected row is not necessarily uniquely identified by a constraint, and one arbitrary-by-`created_at` candidate is updated. If ties exist in `created_at`, selection is not fully deterministic.
- The lookup and subsequent write are not protected by an explicit advisory lock or shown to use an upsert/unique conflict target. Concurrent executions could both observe no row and insert duplicates, or race while adding rules. The `IF NOT EXISTS` checks reduce ordinary repeat-run duplication but are not a substitute for a unique constraint or concurrency control.
- The rule existence checks are exact-match checks. Pre-existing semantically similar rules with different JSONB representation, operator spelling, or gating value would not be recognized and could coexist.
- Rule insertion occurs only after the scholarship ID is established, which is the required local ordering for a foreign-key dependency. All statements are inside one anonymous block and ordinarily execute within the migration transaction, so a failure should roll back the block along with the surrounding migration transaction under normal migration-runner behavior.
- The hard-coded `deadline` is a date-like literal and `last_verified_at` is dynamic. Correct typing depends on the target column definitions and PostgreSQL coercion. The file intentionally leaves `discipline` and `opens_at` null on the scholarship row while expressing disciplines in `scholarship_rules`.
- The text instructs applicants to send sensitive documents and contact an email address. That is an operational/content risk for any reconstructed or deployed catalog, although the migration itself performs no outbound action. External URLs and contact details can become stale and should not be treated as live validation merely because they are stored.

# Reconstruction recommendation

For a synthetic schema reconstruction, omit this migration's data-seeding behavior and all of its real scholarship content. It is not needed to reconstruct tables, columns, constraints, privileges, or other schema objects because it defines none of them.

If the goal is instead to reproduce application fixtures or seed behavior, retain it only as an explicitly optional, clearly labeled fixture after reconstructing the required `public.scholarships` and `public.scholarship_rules` tables and compatible JSONB rule model. Prefer a synthetic scholarship record and synthetic contact/URL values for test environments. If preserving behavior, replace the lookup/update pattern with a deterministic unique-key upsert or add appropriate uniqueness/concurrency protections, and review the sensitive-document instructions and external links before publication.

# Verdict

**Omit from the synthetic schema reconstruction.** This file is a real-world scholarship content publication/update seed with dependent eligibility-rule inserts, not schema migration. It has no DDL, grants, or revokes and therefore contributes no required structural definition. Preserve only as an optional, separately governed fixture if realistic catalog data and its external references are explicitly required; do not treat it as necessary schema history or execute it automatically in a synthetic reconstruction.
