# File

`supabase/migrations/0077_seed_verified_user_supplied_scholarships_and_mentorship_2026.sql`

This review is based solely on the contents of this one file. No SQL was executed, no Supabase instance or hosted service was accessed, and the source snapshot was not modified.

# Scope

The file is a data-seeding migration. It contains one anonymous PostgreSQL `DO $migration$ ... $migration$;` block that conditionally inserts two scholarship records, six rules for the first scholarship, and one mentorship opportunity. It does not declare schema objects, alter existing definitions, grant or revoke privileges, or perform updates or deletes.

The conditional checks use `application_url` as the idempotency key. Each record is inserted only when no existing row in the relevant table has the same URL. The block is executed as one PostgreSQL statement and therefore normally participates in the surrounding migration transaction, although the file itself does not explicitly issue `BEGIN` or `COMMIT`.

# Objects and mutations

## `public.scholarships`

Two conditional `INSERT` operations target `public.scholarships`:

1. If no row has `application_url = 'https://forms.gle/fT1brX6sW2D2ENFF9'`, the migration inserts the AMIR Fund Medical Scholarship Program 2026/2027. It supplies title, provider, description, amount text, deadline `2026-10-30`, application URL, level `undergrad`, `discipline = NULL`, `verified = true`, research notes, application instructions, `opens_at = 2026-10-08`, and `last_verified_at = now()`.
2. If no row has `application_url = 'https://gofscholarship.candsyf.org/'`, it inserts the Pro. Dr. Gabriel Olubunmi Fakeye Scholarship & Bursary Award 2027. It supplies title, provider, description, amount text, deadline `2026-12-04`, application URL, level `undergrad`, `discipline = 'All disciplines'`, `verified = true`, research notes, application instructions, and `last_verified_at = now()`.

The first scholarship insert uses `RETURNING id INTO v_amir_id` to capture the generated identifier. No explicit conflict clause is used; duplicate prevention depends on the preceding existence test and on the database's concurrency behavior.

## `public.scholarship_rules`

When the AMIR row is newly inserted, six rows are inserted into `public.scholarship_rules` using the captured scholarship ID:

- nationality equals JSON string `"Nigerian"`;
- discipline is in JSON array `["Medicine and Surgery", "Dentistry"]`;
- GPA is greater than or equal to JSON number `3.5`;
- year of study is greater than or equal to JSON number `200`;
- financial need equals JSON boolean `true`;
- institution type is in JSON array `["federal_uni", "state_uni"]`.

There is no separate existence check for these rules. They are skipped only because the parent scholarship insert is skipped. If a pre-existing AMIR row lacks rules, this migration will not repair it.

## `public.opportunities`

If no row has `application_url = 'https://umsl.az1.qualtrics.com/jfe/form/SV_2blWkbzWN2x6hLw'`, the migration inserts one row into `public.opportunities` with `type = 'mentorship'`, the POHER Scholars Program 2027 title and provider, descriptive and eligibility text, duration, location, compensation, discipline, deadline `2026-10-31`, `opens_at = NULL`, the Qualtrics application URL, application instructions, `verified = true`, and research notes.

## No other mutation classes

The file contains no `CREATE`, `ALTER`, `DROP`, `TRUNCATE`, `GRANT`, `REVOKE`, `UPDATE`, or `DELETE` statements. It does not create indexes, constraints, triggers, functions, extensions, roles, policies, views, or schemas.

# Dependencies

The migration assumes the earlier schema already provides:

- `public.scholarships` with at least the referenced columns, an insertable/generated `id` column, and an `application_url` column usable in the existence query;
- `public.scholarship_rules` with `scholarship_id`, `field`, `operator`, and `value` columns, where `value` accepts `jsonb`;
- `public.opportunities` with every column named in the insert, including `type`, `application_url`, and the boolean `verified` column;
- compatible types for the supplied text, dates, nullable values, booleans, and JSONB casts;
- a scholarship `id` type compatible with the declared PL/pgSQL variable `v_amir_id uuid` and with `scholarship_rules.scholarship_id`;
- the standard PostgreSQL `plpgsql` language for the `DO` block, the built-in `now()` function, and the built-in `jsonb` type/casts.

It relies on existing table permissions for the migration execution role. No role name, extension, custom function, or custom enum is referenced explicitly. The literal values `undergrad`, `mentorship`, `federal_uni`, and `state_uni` imply either text-compatible columns or pre-existing enum values; if those columns are enums, the enum labels must already exist. The migration also assumes the application schema accepts a nullable discipline for the AMIR record and nullable `opens_at` for the POHER record.

The file's logic does not require the external URLs to be reachable at execution time. They are stored as ordinary data and are not fetched by PostgreSQL.

# Data/external-side-effect assessment

This migration contains real-looking catalog content rather than placeholders. It inserts three externally sourced opportunity records and six structured eligibility rules. The records are marked `verified = true`, and the long descriptions/research notes assert checks against official pages and announcements dated 2026-10-08. Those claims cannot be independently validated from this file alone.

It contains these external URLs as stored data: two Google Forms/application URLs, the CANDSYF application portal, a Qualtrics application URL hosted under `umsl.az1.qualtrics.com`, AMIR official pages, CANDSYF official pages, POHER official pages, and a Facebook announcement URL. The migration does not make HTTP requests, submit forms, transmit data, or otherwise contact those services during execution. The URLs can nevertheless create downstream user-facing navigation and should be treated as untrusted external destinations by the consuming application.

Execution has a real local database side effect: it can add up to three catalog rows and six rule rows. It does not update or delete existing rows. The `now()` values make the exact `last_verified_at` insertion timestamp environment-dependent. The supplied historical dates are fixed date literals, not execution-time dates.

# Security/ordering implications

The migration must run after the migrations that create `public.scholarships`, `public.scholarship_rules`, and `public.opportunities`, including any required enum labels, constraints, and supporting columns. Running it before those objects exist will fail. It should also run after any schema changes that establish the UUID-compatible scholarship ID and JSONB rule value type.

The existence checks make normal reruns substantially safer, but they are not fully concurrency-safe: two concurrent executions could both observe no matching URL and then attempt inserts unless a unique constraint exists. A unique constraint/index on the relevant application URL key would provide stronger protection. Because the rules have no independent uniqueness guard, a repair/reconciliation migration would be needed to add missing rules for an already-present AMIR row.

The file trusts long, user-facing text and external links supplied by the migration author. Applications should escape rendered text, validate or safely handle outbound URLs, and avoid presenting `verified = true` as proof that every current eligibility detail remains valid. The POHER notes explicitly distinguish a Qualtrics host from UMSL sponsorship, which is a useful caveat, but that distinction still depends on correct downstream display.

The AMIR rules intentionally model only part of the prose eligibility criteria. The exact eligible university list and faith-based minority-community requirement remain manual checks; CANDSYF church membership is not represented as a profile rule; and the POHER 2027 criteria are described as not independently confirmed. These are data-quality and matching limitations, not privilege-escalation issues.

# Reconstruction recommendation

For a synthetic local schema reconstruction whose purpose is to recreate tables, columns, relationships, constraints, and security behavior, this migration is **safe to omit**: it introduces no schema object or permission behavior. Omitting it will only leave the catalog without these three seeded opportunities and without the six AMIR matching rules.

If the reconstruction is intended to reproduce representative catalog fixtures or application screenshots/search behavior, apply it only after the prerequisite schema migrations and with awareness that it inserts real-looking, dated content and outbound URLs. In that case, it is preferable to preserve the records as fixtures or replace them with clearly synthetic fixtures, while retaining the caveats and avoiding claims that external verification was performed locally.

# Verdict

**PARTIALLY VERIFIED** — From static inspection, the SQL is a non-destructive, conditionally idempotent data seed with no grants, revokes, schema DDL, updates, or deletes, and it is safe to omit from a schema-only synthetic reconstruction. However, the inserted rows are real catalog data marked verified and contain external URLs; the cited external claims, current availability, and downstream schema compatibility were not independently verified in this strictly read-only, single-file audit. It is not appropriate to label the data fully verified solely from this file, and execution should occur only after the dependent schema objects and any required enum values exist.
