# File

- **Path:** `/tmp/scholars-a03-snapshot/scholars-41573f5/supabase/migrations/0084_seed_nddc_local_postgraduate_scholarship_2026_2027.sql`
- **Migration type:** Conditional seed/data migration implemented as an anonymous PL/pgSQL `DO` block.
- **Lines inspected:** 1–42 of this migration only.

# Scope

This migration publishes one scholarship record for the NDDC Local Post-Graduate (Master's Degree) Scholarship 2026/2027. Its comments say the record was checked against official NDDC pages on 2026-10-13, and the inserted text intentionally leaves the award amount and detailed eligibility rules unclaimed. The migration does not create or alter schema objects, perform grants or revokes, configure extensions, or contact any external service. It conditionally inserts one row when no existing row has the same `application_url`.

# Objects and mutations

## DDL

No DDL is present. There are no `CREATE`, `ALTER`, `DROP`, `TRUNCATE`, index, constraint, type, function, trigger, policy, or extension statements.

## DML

The anonymous block reads `public.scholarships` and, if no row matches the literal application URL `https://scholarship.nddc.gov.ng/login`, performs one `INSERT` into that table. The inserted columns are:

- `title`: `NDDC Local Post-Graduate (Master's Degree) Scholarship 2026/2027`
- `provider_name`: `Niger Delta Development Commission (NDDC)`
- `description`: a narrative description of the 2026/2027 local postgraduate programme, including the Niger Delta indigene reference and the absence of published amount/details.
- `amount`: the text `Not stated on the checked official pages`
- `deadline`: `2026-11-08`
- `application_url`: `https://scholarship.nddc.gov.ng/login`
- `level`: `postgrad`
- `discipline`: `Master's degree programmes`
- `verified`: `true`
- `research_notes`: a verification narrative containing three NDDC URLs and the 2026-10-13 verification date.
- `how_to_apply`: instructions to review requirements and apply through the official portal before 8 November 2026, including a warning not to pay intermediaries.
- `last_verified_at`: `now()` evaluated during the insert.

The guard is `IF NOT EXISTS (SELECT 1 FROM public.scholarships WHERE application_url = ...)`. There is no `UPDATE` or `DELETE` path. The mutation is therefore a one-row, URL-keyed conditional insert, not a full upsert.

## Grants and revokes

No `GRANT` or `REVOKE` statements are present.

# Dependencies

- The table `public.scholarships` must already exist before this migration runs.
- The table must accept inserts into all ten named columns and must have compatible types for the supplied values, especially the textual `amount`, date-like `deadline`, boolean `verified`, timestamp-like `last_verified_at`, and the `postgrad` level value.
- The table's defaults, generated columns, `NOT NULL` constraints, check constraints, foreign keys, triggers, and RLS policies—if defined elsewhere—can affect whether the insert succeeds or what side effects occur. This migration itself does not establish or inspect those objects.
- The anonymous block requires PostgreSQL PL/pgSQL support, normally available through the standard `plpgsql` language. It uses ordinary `public` schema qualification for the table and does not depend on custom functions or extensions.
- The migration's idempotency assumption depends on `application_url` being a sufficiently stable identity for this scholarship and on concurrent executions not creating duplicate rows. The `IF NOT EXISTS` check alone is not a concurrency-safe uniqueness guarantee unless a suitable unique constraint/index exists elsewhere.
- The three URLs embedded in comments and row text are informational content only: `https://nddc.gov.ng/`, `https://www.nddc.gov.ng/WhatWeDo/Scholarship`, and `https://scholarship.nddc.gov.ng/login`. No network lookup is performed by the SQL.

# Data/external-side-effect assessment

This is seed/content data rather than structural schema. It inserts a single real-world scholarship listing with a named government provider, a specific 2026/2027 programme, a concrete deadline, a public application URL, and a `verified = true` flag. The text is time-sensitive and externally sourced according to the migration comments. The `last_verified_at` value is runtime-dependent because it uses `now()`, so repeated insertion at a later time would record a different timestamp if the URL guard did not already suppress the insert.

The migration has no direct external side effects: it does not issue HTTP requests, call a foreign data wrapper, send messages, create files, or access hosted services. It only stores external URLs and prose describing an external verification exercise performed before the migration was authored. The application URL is persisted as user-facing data and could cause an application consuming this table to link users to the external NDDC portal, but that behavior is downstream of the migration.

The record is not synthetic in subject matter: it represents an actual named scholarship and claims current verification as of 2026-10-13. It also contains an explicit deadline of 2026-11-08 and a verified boolean, both of which may become stale after the programme cycle. The amount is deliberately represented as explanatory text rather than a numeric award amount, and no detailed eligibility rule is asserted beyond the prose supplied.

# Security/ordering implications

The block performs a read followed by a conditional insert. It does not elevate privileges explicitly, but execution still requires whatever table privileges and RLS permissions apply to the migration runner. In common migration tooling, migrations run with elevated owner/service privileges; that is an operational property, not something granted here. No row-level security policy is created, changed, bypassed, or documented by this file.

The block is normally atomic within the transaction in which it runs: a failure in the insert or block aborts the statement/transaction according to the migration runner's transaction handling. `now()` is transaction-stable in PostgreSQL, so the stored verification timestamp reflects the transaction's current time rather than an external verification call.

Ordering is important. The `public.scholarships` table and all required columns/constraints/triggers/policies must exist first. If the table's allowed `level` values or column types differ, the migration can fail. It should run after the base scholarships schema and before any later migration that assumes this particular seed row exists. There is no explicit dependency on another migration named in this file, and no schema version marker is included.

The URL existence test prevents a second insert on ordinary sequential reruns, but it does not repair or refresh an existing stale or incorrect row. It also does not prevent duplicates under concurrent execution unless the database enforces uniqueness on `application_url` (or another appropriate key). The fixed deadline and current `verified` flag should not be interpreted as a durable security or eligibility control; they are informational application data.

# Reconstruction recommendation

For a synthetic schema reconstruction, this migration can be omitted. It contributes no DDL, grants, revokes, policies, functions, or other structural behavior. Reconstruct the `public.scholarships` table and its genuine schema dependencies from the structural migrations, but do not need to reproduce this one real-world seed record to recover the schema.

If the reconstruction goal includes representative fixtures, demo content, or behavioral testing of scholarship listing pages, the row may be retained as an optional fixture. In that case, preserve the conditional nature or use an explicitly constrained fixture strategy, and document that the content is time-sensitive, externally sourced, contains a public URL, uses a text placeholder for amount, and has a historical verification timestamp. It should not be treated as authoritative production data merely because `verified` is `true`.

# Verdict

**Omit from a synthetic schema reconstruction; retain only as optional, clearly labeled seed/fixture data.** The migration is a single conditional DML insert with no DDL or privilege changes. Its only material effects are insertion of one real-world, time-sensitive scholarship record and downstream availability of its external application link. Structural reconstruction does not depend on it, subject to the pre-existing `public.scholarships` table and any separately defined constraints or policies.
