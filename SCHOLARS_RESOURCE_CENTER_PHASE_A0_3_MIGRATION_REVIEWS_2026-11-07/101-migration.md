# File

`/tmp/scholars-a03-snapshot/scholars-41573f5/supabase/migrations/0083_seed_helwa_npw_and_wva_2026.sql`

This review is based only on the specified migration file. No SQL was executed, no Supabase instance or hosted service was accessed, and the source snapshot was not modified.

# Scope

The file is a single anonymous PL/pgSQL `DO` block (`do $migration$ ... $migration$;`). Its stated purpose is to publish two essay competitions and one veterinary scholarship. It performs conditional seed-data writes; it does not define or alter database schema, indexes, policies, functions, extensions, roles, or privileges.

The two competition records are inserted into `public.opportunities` only when no existing row has the corresponding `application_url`. The veterinary scholarship is inserted into `public.scholarships` only when no existing row has its corresponding `application_url`; if that insert occurs, two rows are also inserted into `public.scholarship_rules` for the newly returned scholarship ID.

# Objects and mutations

## Creates and alters

No database objects are created, altered, dropped, or renamed. There are no `CREATE`, `ALTER`, `DROP`, `TRUNCATE`, `GRANT`, `REVOKE`, `UPDATE`, or `DELETE` statements.

The block declares one local variable, `v_wva_id uuid`, and uses `now()` for timestamp fields. The `DO` block itself executes in the surrounding transaction context, subject to normal PostgreSQL transaction behavior.

## Inserts

1. **`public.opportunities` — HELWA Foundation Essay Competition 2026**
   - Guard: inserts only if no row has `application_url = 'https://wearehelwa.org/essay-competition'`.
   - Mutation: one competition row with title, provider, descriptive and eligibility text, duration, location, compensation text, deadline `2026-10-15`, opening date `2026-10-01`, application URL, instructions, `verified = true`, research notes, and both `created_at` and `updated_at` set to `now()`.

2. **`public.opportunities` — National Youth Pension Literacy Essay Competition 2026**
   - Guard: inserts only if no row has `application_url = 'https://npw.ng/youth-engagement/essay/'`.
   - Mutation: one competition row with title, provider, descriptive and eligibility text, duration, location, prize text, deadline `2026-10-20`, opening date `2026-10-01`, application URL, instructions, `verified = true`, research notes, and both `created_at` and `updated_at` set to `now()`.

3. **`public.scholarships` — WVA/MSD Veterinary Student Scholarship 2026**
   - Guard: inserts only if no row has `application_url = 'https://app.smarterselect.com/programs/112061'`.
   - Mutation: one scholarship row with title, provider, description, amount, deadline `2026-10-15`, application URL, `level = 'undergrad'`, `discipline = 'Veterinary Medicine'`, `verified = true`, research notes, application instructions, and `last_verified_at = now()`.
   - The inserted ID is captured with `RETURNING id INTO v_wva_id`.

4. **`public.scholarship_rules` — two rules for the newly inserted WVA scholarship**
   - Inserted only after the scholarship insert succeeds, using `v_wva_id`.
   - Rule 1: field `discipline`, operator `in`, JSONB value `["Veterinary Medicine", "Veterinary Medicine and Surgery"]`.
   - Rule 2: field `year_of_study`, operator `gte`, JSONB value `200`.

If any guard finds an existing matching URL, that branch does nothing. In particular, an existing scholarship with the matching URL prevents both the scholarship row and its rules from being inserted; the migration does not repair or backfill missing rules for an already-present scholarship.

# Dependencies

The file depends on the following earlier schema objects and capabilities, inferred from its qualified table references and expressions:

- `public.opportunities` must exist with all referenced columns: `type`, `title`, `provider_name`, `description`, `eligibility_notes`, `duration`, `location`, `compensation`, `deadline`, `opens_at`, `application_url`, `how_to_apply`, `verified`, `research_notes`, `created_at`, and `updated_at`. Its `application_url` must be comparable to text values, and its `type` column must accept `competition`.
- `public.scholarships` must exist with `title`, `provider_name`, `description`, `amount`, `deadline`, `application_url`, `level`, `discipline`, `verified`, `research_notes`, `how_to_apply`, `last_verified_at`, and an `id` column whose value can be assigned to a UUID variable. Its `level` column must accept `undergrad`.
- `public.scholarship_rules` must exist with `scholarship_id`, `field`, `operator`, and `value`; `value` must accept JSONB and `scholarship_id` must accept the returned scholarship ID.
- PostgreSQL PL/pgSQL must be available for the anonymous `DO` block. `now()` and the `jsonb` type/cast are required. These are standard PostgreSQL facilities in a normal Supabase database, but the file itself does not install or verify them.
- The inserted `scholarship_rules.scholarship_id` must be able to reference the inserted scholarship, whether by a foreign key or application convention. The file relies on the scholarship insert preceding the rules insert.
- The executing role needs `SELECT` on the three target tables and `INSERT` on the relevant columns/tables, plus permission to execute an anonymous `DO` block. No role or privilege setup is included here.

No named extension, custom function, trigger, role, or external service is explicitly referenced. Any triggers, defaults, constraints, RLS behavior, or uniqueness constraints on the target tables are implicit dependencies rather than visible in this file and cannot be verified without inspecting other migrations/schema objects, which was outside this audit's scope.

# Data/external-side-effect assessment

This is real catalog/content data, not synthetic placeholder data. It inserts three externally sourced opportunity records and two associated rule records. The text contains organization names, eligibility criteria, prize/amount claims, dates, and verification notes.

The migration contains external URLs as stored data, including:

- `https://wearehelwa.org/essay-competition`
- `https://wearehelwa.org/`
- `https://npw.ng/youth-engagement/essay/`
- `https://npw.ng/about/`
- `https://app.smarterselect.com/programs/112061`
- `https://worldvet.org/activities/msd-veterinary-student-scholarship/`
- `https://worldvet.org/msd-veterinary-student-scholarship-faq/`

Those URLs are not fetched or invoked by the SQL. The only external side effect represented by this file is persistence of URL strings and research notes; execution does not submit applications, call HTTP endpoints, or contact those organizations.

The dates and verification notes are time-sensitive. The file says the pages were checked on `2026-10-09`, while the migration records deadlines in October 2026. When evaluated after those dates, the rows may be stale or expired even though `verified` is set to true. `now()` records execution time for timestamps but does not refresh the embedded source claims or deadline fields.

# Security/ordering implications

There are no explicit grants, revokes, authentication changes, RLS policy changes, or secret values in this migration. The URLs and narrative fields are ordinary string literals; no credentials or private tokens are present. The block is not declared `SECURITY DEFINER`, so it ordinarily runs with the invoker's privileges. Nevertheless, the executing migration role must have sufficient rights to read and insert into all three tables.

Ordering matters. The target tables and all referenced columns must already exist before this migration runs. The `scholarship_rules` inserts must follow the successful scholarship insert because they use `v_wva_id`; the file preserves that order. The conditional checks and inserts are not protected by an explicit lock. If two sessions run this block concurrently and no unique constraint exists on `application_url`, duplicate rows are possible. If a unique constraint does exist, a concurrent race could raise a constraint error rather than silently deduplicate. The file also does not use `ON CONFLICT`.

The two opportunity branches are independent. The scholarship branch's rule inserts are inside the same `DO` block, so a failure in the rule insert can abort the block/transaction and roll back the scholarship insert under normal transactional execution. Existing matching rows cause no update, so rerunning the migration will not correct changed source text, stale dates, verification notes, or missing rules.

The `year_of_study` rule stores `200` as JSONB. That may be an application-specific encoded threshold rather than a literal academic year; this file provides no explanation or validation of the rule interpretation. The migration also hard-codes `verified = true` based on the stated research date, which creates a data-freshness risk rather than a direct database-security vulnerability.

# Reconstruction recommendation

For a **synthetic local schema reconstruction**, this migration is safe to omit if the objective is only to recreate tables, columns, relationships, and database structure. It contains no DDL and is not needed to establish schema objects. Omitting it will, however, omit three catalog records and two scholarship-rule records that may be useful for application fixtures, search/UI demonstrations, or behavior tests.

If the reconstruction aims to reproduce representative seed content or test scholarship-rule filtering, retain it or replace it with deterministic fixture data after the prerequisite tables exist. If it is retained in a local environment, consider using clearly labeled fixture data, reviewing the now-past deadlines, and adding explicit uniqueness/upsert handling if repeatability or concurrent execution matters. Do not treat the stored `verified` flags as proof that the URLs remain current.

# Verdict

**PASS** for read-only migration-history review: the file is syntactically structured as a straightforward conditional seed migration, has no schema or privilege mutations, and has no direct network side effects visible in the SQL.

**PASS** for omission from a synthetic local **schema-only** reconstruction, with the explicit caveat that omitting it loses real seed catalog content and scholarship rules.

**PARTIALLY VERIFIED** for dependency and runtime safety: the file clearly references the three target tables and standard PostgreSQL facilities, but the existence, exact types, constraints, RLS policies, triggers, uniqueness behavior, and permissions of those objects were not inspected because this audit was restricted to one migration.

**NOT SAFE TO EXECUTE blindly as a current production-content migration** without checking target schema compatibility and reviewing freshness of the October 2026 records. It writes real, time-sensitive data, marks rows verified based on an earlier source review, does not update existing records, and lacks explicit conflict handling. This is not a claim that the SQL is inherently malicious or that execution necessarily fails; it is a deployment-safety qualification based on the file's unverified external/schema assumptions and stale-date risk.
