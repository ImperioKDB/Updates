# File

`/tmp/scholars-a03-snapshot/scholars-41573f5/supabase/migrations/0101_seed_waaw_and_fisayo_soyombo_2026.sql`

# Scope

This is a strictly read-only static audit of the one specified migration file. No SQL was executed, no Supabase instance or hosted service was started or accessed, and the snapshot was not modified. No other migration was inspected.

The file contains one anonymous PL/pgSQL `DO $migration$ ... $migration$;` block. Its stated purpose is to publish two opportunity records: the WAAW Foundation Scholarship 2026/2027 in `public.scholarships`, and the Fisayo Soyombo Inter-Varsity Essay Competition 2026 in `public.opportunities`. The block uses local UUID variables and performs an existence lookup followed by either an `INSERT` or an `UPDATE` for each record.

# Objects and mutations

## DDL

No DDL is present. The migration does not create, alter, drop, truncate, or otherwise change tables, columns, indexes, constraints, functions, triggers, types, schemas, or extensions.

## DML

The migration performs DML only:

1. **`public.scholarships` lookup and conditional mutation**
   - Declares `v_scholarship_id uuid`.
   - Reads one row from `public.scholarships`, matching either the canonical WAAW application URL (`https://waawfoundation.org/scholarship/`) or a case-insensitive title match for `WAAW Foundation Scholarship 2026/2027`.
   - Orders matching rows by `created_at desc` and takes one row with `limit 1`.
   - If no row is found, inserts one scholarship and captures its generated `id` with `returning id`.
   - If a row is found, updates that row with the supplied title, provider, description, amount, deadline, URL, level, discipline, verification flag, research notes, application instructions, opening date, and `last_verified_at = now()`.
   - The insert supplies `deadline = null`; the update explicitly resets `deadline` to null. It supplies `opens_at = '2026-10-30'` and `last_verified_at = now()`.

2. **`public.opportunities` lookup and conditional mutation**
   - Declares `v_opportunity_id uuid`.
   - Reads one row from `public.opportunities` where `application_url is null` and the title matches, case-insensitively, either `Fisayo Soyombo Inter-Varsity Essay Competition 2026` or `9th Annual Fisayo Soyombo Inter-Varsity Essay Competition`.
   - Orders matching rows by `created_at desc` and takes one row with `limit 1`.
   - If no row is found, inserts one competition and captures its generated `id` with `returning id`.
   - If a row is found, updates that row with the supplied type, title, provider, description, eligibility notes, duration, location, compensation, discipline, deadline, opening date, application URL, application instructions, verification flag, and research notes.
   - The competition has `deadline = '2026-11-22'`, `opens_at = null`, and `application_url = null` in both insert and update paths.

The operation is not a native `INSERT ... ON CONFLICT` upsert. It is an application-level lookup-then-insert/update sequence, so its deduplication and race behavior depend on the table constraints and concurrent activity in the target database.

## Grants and revokes

No `GRANT`, `REVOKE`, role change, ownership change, or other privilege/security-label statement is present.

# Dependencies

The migration depends on the following pre-existing database objects and schema contracts:

- `public.scholarships` must exist and be writable.
- `public.opportunities` must exist and be writable.
- `public.scholarships` must expose at least the referenced columns: `id`, `application_url`, `title`, `created_at`, `provider_name`, `description`, `amount`, `deadline`, `level`, `discipline`, `verified`, `research_notes`, `how_to_apply`, `opens_at`, and `last_verified_at`.
- `public.opportunities` must expose at least the referenced columns: `id`, `application_url`, `title`, `created_at`, `type`, `provider_name`, `description`, `eligibility_notes`, `duration`, `location`, `compensation`, `discipline`, `deadline`, `opens_at`, `how_to_apply`, `verified`, and `research_notes`.
- The referenced column types must accept UUID variables, text values, nulls, boolean values, date/timestamp-compatible literals, and `now()` for `last_verified_at` as applicable.
- Generated IDs or otherwise populated IDs must exist for the `returning id` clauses.
- The executing role needs `SELECT`, `INSERT`, and `UPDATE` privileges on both tables, directly or through role membership; no such privileges are granted by this file.
- Existing defaults, triggers, RLS policies, CHECK constraints, foreign keys, and unique indexes on either table may affect whether the mutations succeed or cause additional effects. Their definitions are not established by this file.

The WAAW branch assumes `created_at` is present and sortable. Both matching queries can select an arbitrary one of multiple same-timestamp matches because they order only by `created_at desc`; the selected record is therefore not fully deterministic in a tie. The opportunity lookup additionally requires `application_url is null`, so a pre-existing matching title with a non-null URL is not selected and a new row may be inserted instead.

# Data/external-side-effect assessment

The file contains substantial real-world content rather than synthetic placeholder data. It embeds two named 2026 opportunities and detailed eligibility, award, deadline, application, provider, and verification information.

- The WAAW record includes a real external URL (`https://waawfoundation.org/scholarship/`), a stated one-time US$500 award, an opening date of 30 October 2026, eligibility restrictions for female African undergraduate STEM students, application-material instructions, and research notes identifying verification against the official WAAW page and FAQ.
- The Fisayo Soyombo record includes a real source URL in `research_notes` (`https://www.icanstudent.com/fisayo-soyombo-inter-varsity-essay-competition-2026/`), the University of Ibadan Union of Campus Journalists as provider, a Nigerian undergraduate essay topic, a 22 November 2026 deadline, ₦400,000/₦300,000/₦200,000 prizes, and the real submission email `ucjunibadan@gmail.com`. Its `application_url` is deliberately null because the notes say no stable HTTP application portal was provided.
- The SQL itself does not perform HTTP requests, invoke external services, send email, upload data, or call a network extension. External URLs and email addresses are stored as ordinary text only.
- The `now()` calls are database-time side effects in the affected row values: they set `last_verified_at` on insert/update of the WAAW record. There is no other procedural external side effect visible in the file.

Applying this migration to a production-like database would publish or overwrite real opportunity content and could alter what end users see. Reapplying it is intended to refresh the records, but the matching logic is not guaranteed to identify one unique row in all data states.

# Security/ordering implications

There are no explicit privilege changes and no obvious injection mechanism: all values are fixed SQL literals, not user-provided concatenated SQL. Nevertheless, execution requires write access to two public tables, and any existing RLS policy, trigger, audit mechanism, or table-level security configuration will govern or augment the writes. The file does not disable RLS, bypass policies, or establish a security-definer context.

The anonymous block executes its statements as one PostgreSQL statement and, under normal migration execution, participates in the surrounding transaction. If a constraint, trigger, policy, type conversion, or privilege check fails, the block/migration can fail and its transactional writes would normally roll back with the transaction. The source file itself does not set transaction behavior or define a lock strategy.

Ordering matters: the base tables and all required columns must already exist before this migration runs. Any migration that creates or changes these tables, their columns, defaults, constraints, or RLS policies must precede it. Any later migration that expects these two records to exist can depend on this migration. Conversely, a synthetic reconstruction that only needs schema shape does not need these seed rows.

The lookup-then-write approach is not concurrency-safe as a deduplication mechanism without suitable unique constraints or serialization. Two concurrent executions could both observe no matching row and both insert. Multiple historical duplicates can also remain because the update path changes only the selected newest match; it does not merge or delete other rows. The WAAW lookup's `OR` condition may match by URL or title, while the competition lookup requires a null application URL and accepts two title aliases, producing different duplicate-handling behavior.

The data also contains sensitive-adjacent applicant instructions (school ID, transcript, references) but the migration does not insert applicant personal data. Its primary risk is publication and integrity of real opportunity information, not direct personal-data exposure.

# Reconstruction recommendation

For a **synthetic schema reconstruction**, this migration can be omitted. It contributes no DDL, grants, revokes, functions, policies, or other schema definition. Omitting it will not prevent reconstruction of the table structures, provided those structures are obtained from the relevant schema-defining migrations or another authoritative schema source.

It should not be silently treated as irrelevant if the goal is a faithful content/data reconstruction, a staging environment with representative seeded opportunities, or behavioral testing of deduplication and update paths. In those cases, preserve it as an optional data fixture or rewrite it into clearly synthetic seed data, after independently confirming the target table schema and any RLS/constraint behavior. Do not execute the original merely to reconstruct schema, because it publishes real dated content and external contact/URL data.

# Verdict

**Omit from synthetic schema reconstruction: yes.** This is a real-data DML seed/refresh migration only; it contains no DDL, grants, or revokes. Its dependencies are two pre-existing writable public tables and their columns. It has no direct network or hosted-service execution, but it does persist real external URLs, a real email address, dated opportunity details, and verification notes, while updating `last_verified_at` with the current database time. Retain or separately fixture it only when real seed content or the conditional insert/update behavior is explicitly required.
