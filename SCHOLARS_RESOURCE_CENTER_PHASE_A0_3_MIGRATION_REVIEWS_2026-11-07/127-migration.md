# File

`/tmp/scholars-a03-snapshot/scholars-41573f5/supabase/migrations/0106_seed_airtel_africa_tech_scholarship_nigeria_2026_2027.sql`

This review is based solely on the contents of this migration file. No SQL was executed, no Supabase instance or hosted service was started or accessed, and no runtime verification is claimed.

# Scope

The file is a data-seeding migration for one scholarship/opportunity record: the Airtel Africa Foundation Undergraduate Tech Scholarship 2026/2027 for Nigeria. It consists of one anonymous `DO $migration$ ... $migration$` PL/pgSQL block.

The block first searches `public.opportunities` for an existing row whose title case-insensitively matches the target title or whose `application_url` equals the Airtel Foundation URL. It orders matching rows by descending `created_at` and takes one row. If no match is found, it inserts one opportunity row and captures the generated `id`; otherwise it updates the selected row with the same substantive content. The intent is an idempotent seed/update, although exact idempotence and conflict behavior depend on the unseen schema, constraints, triggers, and privileges of `public.opportunities`.

The request calls for special attention to final security/Resource Center migrations. This file itself contains no Resource Center object, security policy, privilege, view, function definition, or constraint declaration. Because the audit is restricted to this exact file, no conclusions are made about such objects in any other migration.

# Objects and mutations

## Procedural object and control flow

- `DO $migration$ ... $migration$` is an anonymous PL/pgSQL code block, not a persistent stored function. It declares one local variable, `v_id uuid`.
- The block performs a `SELECT ... INTO v_id` from `public.opportunities`, using `lower(title) = lower(...) OR application_url = ...`, then `ORDER BY created_at DESC LIMIT 1`.
- If `v_id IS NULL`, it executes an `INSERT ... RETURNING id INTO v_id`.
- Otherwise, it executes an `UPDATE public.opportunities ... WHERE id = v_id`.
- The final assignment of `v_id` after insert is not used by any later statement in the file.

## DML

The migration reads and potentially mutates `public.opportunities`:

1. **Read:** Selects `id` from rows matching either the target title (case-insensitive) or the official Airtel URL. It also reads `created_at` for ordering.
2. **Insert:** If no match exists, inserts one row with these columns:
   - `type`
   - `title`
   - `provider_name`
   - `description`
   - `eligibility_notes`
   - `duration`
   - `location`
   - `compensation`
   - `discipline`
   - `deadline`
   - `opens_at`
   - `application_url`
   - `how_to_apply`
   - `verified`
   - `research_notes`
3. **Update:** If a match exists, overwrites the same logical fields by `id` (including `type`, title, provider, descriptive fields, dates, URL, application instructions, verification flag, and research notes). The update does not modify `created_at` explicitly, and does not explicitly set an `updated_at` value; any automatic timestamp behavior would come from an unseen trigger or schema default.

There is no explicit `DELETE`, `TRUNCATE`, `ALTER`, `CREATE`, `DROP`, `COMMENT`, sequence operation, or other DDL in the file. There are no explicit `GRANT` or `REVOKE` statements. There are no explicit `CREATE POLICY`, `ALTER POLICY`, `CREATE VIEW`, `CREATE MATERIALIZED VIEW`, or persistent `CREATE FUNCTION` statements. The anonymous block should not be mistaken for creation of a reusable function.

## Values written

The inserted/updated record is marked `type = 'fellowship'`, with the title `Airtel Africa Foundation Undergraduate Tech Scholarship 2026/2027 - Nigeria`, provider `Airtel Africa Foundation`, a Nigerian location, a `deadline` of `2026-12-07`, `opens_at = NULL`, `verified = true`, and `application_url = 'https://www.airtelafricafoundation.org/airtel-africa-tech'`.

The text fields describe Nigerian public universities and technology-related disciplines, reported scholarship support, application guidance, and research notes. The migration deliberately records uncertainty: the supplied short application link is said to have returned 404, the visible Scholastica route is described as a closed 2025 cycle, and applicants are told to confirm the replacement 2026/2027 route.

# Dependencies

## Direct database dependencies

The only referenced database object is `public.opportunities`. The file assumes that this relation exists and supports:

- a readable `id` column compatible with the local `uuid` variable and `RETURNING id`;
- `title`, `application_url`, and `created_at` for lookup and ordering;
- writable columns `type`, `title`, `provider_name`, `description`, `eligibility_notes`, `duration`, `location`, `compensation`, `discipline`, `deadline`, `opens_at`, `application_url`, `how_to_apply`, `verified`, and `research_notes`;
- an insert path that supplies any other required columns through defaults or permits them to be omitted;
- an update path permitting all listed assignments.

The migration relies on the `lower(text)`-style operation for title matching, a comparison-compatible `application_url`, an ordering-compatible `created_at`, and a UUID-compatible `id`. The exact data types, nullability, defaults, indexes, unique constraints, triggers, row-level-security configuration, and foreign keys are not declared here and cannot be verified from this file.

## Ordering and idempotency dependencies

Lookup precedence is not a separate precedence rule between the two predicates; both are combined with `OR`, and the newest matching row by `created_at` is selected. If multiple rows match, the selected row is whichever has the greatest `created_at` (with no secondary tie-breaker). If `created_at` ties, the chosen row is not deterministically specified by this file.

The intended deduplication key is the case-insensitive title or exact application URL, but no unique index or constraint is created here. Concurrent executions could both observe no match and attempt inserts unless the underlying schema or migration runner supplies serialization/uniqueness. If a unique constraint rejects a concurrent or pre-existing duplicate, that behavior is external to this file.

The `UPDATE` is keyed only by the selected `id`, so it changes exactly one chosen row under ordinary primary-key semantics. A trigger could cause additional side effects, but no such trigger is declared or inspected here.

## External/content dependencies

The SQL embeds factual and editorial content derived from named external sources, including:

- `https://www.airtelafricafoundation.org/airtel-africa-tech`
- `https://www.airtelafricafoundation.org/education/airtel-africa-tech-fellowships`
- `https://bit.ly/4y4xVUkc`
- references to a Nigerian Scholastica portal and a public LinkedIn announcement, without storing those latter URLs as a dedicated field.

These are string values in database columns, not SQL dependencies. The migration does not perform HTTP requests, fetch a page, submit an application, enter personal information, or otherwise contact an external service. Any claim that a URL returned 404 or that a portal was closed is historical research content embedded in the row and is not verified by executing this migration.

# Data/external-side-effect assessment

This is real-world opportunity content rather than synthetic placeholder data. It contains a named foundation, a dated scholarship cycle, a Nigerian deadline, participating university names, eligibility fields, benefit descriptions, and application guidance. `verified = true` and the research notes assert verification as of 2026-11-05, while also preserving caveats about cycle mismatch and an unavailable short link.

Applying the migration would create or overwrite one catalog record and could make it visible through any application or API that reads `public.opportunities`; that visibility is a consequence of the DML and surrounding system, not an external network call in this file. It does not submit applications, transmit personal data, or modify external websites. It stores external URLs that users could later follow, including a short URL explicitly described as returning 404 at the time of research.

The update path is potentially destructive to prior edits on a matching row because it overwrites all listed content fields. It does not delete rows, but it can replace manually curated values on the selected matching record.

# Security/ordering implications

No security configuration is authored here. In particular, there are no policies, role changes, grants, revokes, security-definer declarations, views, functions, constraints, or Resource Center objects in this migration. The anonymous block normally runs with the privileges of the migration execution role; whether that role can read, insert, and update `public.opportunities`, and whether RLS applies or is bypassed, cannot be determined from this file. No runtime authorization result is claimed.

The use of a fully qualified table name (`public.opportunities`) reduces schema-search-path ambiguity. It does not remove the need for the table and its columns to exist before this migration runs. Therefore, this migration must follow the migration that creates `public.opportunities` and any required columns/defaults. It should also follow any schema changes that make the listed date, UUID, URL, verification, and text assignments valid.

The block has no explicit transaction control. A migration framework commonly executes migrations transactionally, but that framework behavior is not established by this file. Within the block, the lookup and subsequent insert/update are not protected by a file-local lock or advisory lock. Concurrent runners may race. The `OR` lookup and `ORDER BY created_at DESC LIMIT 1` can select an unintended historical duplicate when duplicates already exist, and tied timestamps lack deterministic ordering.

The branch test is `v_id IS NULL`, so a row with a null `id` would not be a normal valid match for an insert-returned UUID/primary key and could produce unexpected behavior only under an unusual schema. The file assumes conventional non-null identity semantics without declaring them.

# Reconstruction recommendation

For a **synthetic schema reconstruction**, this migration can be omitted if the reconstruction goal is to reproduce schema, security, views, functions, constraints, or Resource Center structure rather than production catalog contents. It contributes no DDL, grants, revokes, policies, views, persistent functions, or constraints. Omitting it avoids importing real organization/program names, a real deadline, external URLs, and potentially stale application guidance.

If the reconstruction needs representative opportunity data or migration behavior, preserve it only as a clearly synthetic fixture or separately reviewed seed. A faithful behavioral fixture would require an existing `public.opportunities` table with the referenced columns and should account for the conditional lookup/update, duplicate selection, overwrite behavior, and possible concurrency race. Consider replacing real URLs and claims with placeholders, and do not carry forward `verified = true` unless the synthetic environment explicitly models that status.

For a production migration review, retain the file only after confirming the target schema, required privileges/RLS behavior, duplicate policy, and whether overwriting an existing matching row is intended. A deterministic unique key or conflict strategy and a stable tie-breaker would reduce ordering/concurrency ambiguity, but adding those would be a change to the migration design, not an observation of this file.

# Verdict

**Migration class:** DML-only real-data seed/update; no DDL, grants, revokes, persistent functions, views, policies, constraints, or Resource Center/security objects authored here.

**Read-only audit result:** The file conditionally inserts or overwrites one `public.opportunities` record using a title/URL lookup. It stores external URLs and researched scholarship content but performs no external network operation itself. Its safe execution depends on the prior existence and permissions of `public.opportunities`, and its behavior is sensitive to duplicates, timestamp ties, concurrent runners, triggers, and unseen RLS/constraints.

**Reconstruction verdict:** **Omit from a synthetic schema reconstruction** unless realistic catalog seed data is specifically required. If included as a fixture, isolate and label the real-world content, preserve the table dependency, and treat the update/concurrency semantics as behavior requiring explicit review rather than as schema/security requirements.
