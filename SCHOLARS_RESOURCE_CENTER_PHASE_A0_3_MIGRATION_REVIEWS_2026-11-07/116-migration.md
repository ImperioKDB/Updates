# File

`/tmp/scholars-a03-snapshot/scholars-41573f5/supabase/migrations/0097_seed_verified_tech_opportunities_2026.sql`

This review covers only this migration file. No SQL was executed, no Supabase instance or hosted service was accessed, and the snapshot was not modified.

# Scope

The file is a seed/data migration for verified technology opportunities. It begins with comments stating that the entries were verified on 2026-10-23 and that Outreachy, GSoC, and Season of KDE were intentionally omitted because their cycles were closed or date-unverified (lines 1–3).

The executable body is a PostgreSQL anonymous `DO $migration$ ... $migration$;` block (lines 4–103). It performs four independent existence checks and, when a matching row is absent, inserts one opportunity. There is no schema-definition statement in the file.

# Objects and mutations

## DDL

No DDL is present. The migration does not create, alter, drop, truncate, or otherwise define tables, columns, constraints, indexes, functions, triggers, types, schemas, or policies.

## DML

The only mutations are conditional `INSERT` statements into `public.opportunities`:

1. **Linux Foundation LFX Mentorship** (lines 6–28), with `type = 'mentorship'` and application URL `https://mentorship.lfx.linuxfoundation.org/`.
2. **CNCF Mentoring / LFX Mentorship** (lines 30–52), with `type = 'mentorship'` and the same LFX application URL.
3. **MLH Fellowship** (lines 54–76), with `type = 'fellowship'` and application URL `https://fellowship.mlh.io/apply`.
4. **Google Developer Groups on Campus** (lines 78–100), with `type = 'training'` and application URL `https://app.advocu.com/gdg/join`.

Each insert supplies values for the following columns: `type`, `title`, `provider_name`, `description`, `eligibility_notes`, `duration`, `location`, `compensation`, `discipline`, `deadline`, `opens_at`, `application_url`, `how_to_apply`, `verified`, and `research_notes`. The `deadline` and `opens_at` values are explicitly `null` for all four rows. The `verified` value is explicitly `true` for all four rows.

Each insert is guarded by `if not exists (select 1 from public.opportunities where application_url = ... and title = ... limit 1) then`. Thus, the intended behavior is idempotent for an existing row matching the exact title/application-URL pair, but it does not update an existing row or prevent all other duplicate combinations.

## Grants and revokes

No `GRANT`, `REVOKE`, role, ownership, or privilege changes are present.

# Dependencies

The direct database dependency is an existing table named `public.opportunities`. That table must exist before this migration runs and must expose every named column listed above with compatible types and any required defaults/constraints satisfied by the supplied values. The file itself does not establish the table or validate its schema.

The `DO` block requires PostgreSQL procedural-language support for PL/pgSQL, normally available as the built-in `plpgsql` language. The code uses ordinary `IF`, `SELECT`, and `INSERT` constructs and does not depend on custom functions, extensions, sequences, views, triggers, or additional application tables as shown in this file.

The existence checks rely on the ability to read `public.opportunities`; execution therefore also depends on the executing role having the necessary table privileges. The inserts require insert privilege on the table and any applicable sequence/identity privileges if the table has generated identifiers, although no identifier column is explicitly supplied here.

The file assumes that the target schema accepts `NULL` in `deadline` and `opens_at`, accepts the listed text values, and accepts the boolean literal `true` for `verified`. Any row-level security policy or trigger on `public.opportunities` could further affect execution, but no such objects are defined here.

# Data/external-side-effect assessment

This is data-seeding DML rather than live external integration. It does not issue HTTP requests, call APIs, read files, invoke shell commands, or contact any external service. The URLs are literal string values stored in the inserted rows and are also embedded in descriptive `research_notes`; they are not fetched or validated at migration runtime.

The inserted content is curated, real-world program information rather than synthetic placeholder data. It includes named organizations and programs (Linux Foundation LFX Mentorship, CNCF, Major League Hacking, and Google Developer Groups on Campus), eligibility and compensation descriptions, verification claims, and links to official program pages. The comments and research notes contain date-sensitive assertions, including a 2026-10-23 verification date and statements about passed or dynamic application windows. Because the migration stores these claims as ordinary row data, it can become stale without any database-level expiry or refresh mechanism.

The migration does not insert user records, credentials, secrets, tokens, personally identifiable information, or payment data. Its external side effect is limited to persisting these four opportunity records in the local database when they are absent. There is no network-side effect from the SQL itself.

# Security/ordering implications

Ordering is material: the `public.opportunities` table and its required columns must be created before this file. If the table is absent or its schema differs, the block will fail. This migration is therefore a seed that should follow the relevant opportunities-table schema migration and any prerequisite enum/type or policy setup, if those are used by the schema.

The four checks and inserts execute within the anonymous block's database execution context. They are sequential and do not use explicit locking. Under concurrent execution of the same migration or concurrent writers, two sessions could both observe no matching row and attempt inserts unless a suitable unique constraint exists. The predicate is not itself a database-enforced uniqueness guarantee. A uniqueness constraint on the intended natural key (for example, the title/application-URL pair) would make deduplication robust, though a conflict could then need explicit handling.

The checks use exact string equality and only the pair of `application_url` and `title`; differences in whitespace, capitalization, URL variants, or title wording would not be recognized as the same opportunity. The migration neither updates stale data nor repairs partially populated existing rows.

No privilege changes are introduced, but execution under a role subject to row-level security could fail or could see a filtered view of rows during the `NOT EXISTS` checks. Any pre-existing triggers on `public.opportunities` may add side effects or validation not visible in this file. The absence of explicit deadlines and the presence of `verified = true` are application-semantic concerns: consumers may treat these rows as verified opportunities even though the notes explicitly say some are recurring watchlist entries and current openings were not guaranteed.

# Reconstruction recommendation

For a synthetic schema reconstruction whose goal is to reproduce database structure rather than production seed content, this migration can be omitted. It defines no schema objects, constraints, policies, privileges, or reusable logic; its only database dependency is the already-defined `public.opportunities` table.

If the reconstruction also aims to reproduce representative application fixtures or seed behavior, retain it as optional fixture data, not as a schema prerequisite. The four rows can be recreated separately with synthetic or clearly labeled test values, avoiding the time-sensitive real-world claims and external links. If retained verbatim in a non-synthetic environment, the data should be treated as staleable content requiring periodic review, and the target schema should be checked for compatible nullability, types, constraints, and uniqueness behavior.

# Verdict

**Omit from the synthetic schema reconstruction.** This migration is a non-essential, real-data seed containing four conditional inserts and no DDL, grants, revokes, or schema logic. It has an ordering dependency on `public.opportunities`, but omitting it does not remove any database structure needed by later schema reconstruction. Preserve only as optional historical/fixture documentation if reproducing seeded content is explicitly required.
