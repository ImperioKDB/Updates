# File

`/tmp/scholars-a03-snapshot/scholars-41573f5/supabase/migrations/0090_seed_au_theme_2027_logo_competition.sql`

# Scope

This review covers only the specified migration file. The file is a data-seeding migration for one African Union logo competition opportunity. It does not create, alter, or drop schema objects. It executes an anonymous PostgreSQL `DO` block in PL/pgSQL and conditionally inserts one row into `public.opportunities`.

The migration's comments describe the opportunity as verified against African Union call, terms-of-reference, and registration-form pages on 2026-10-18. Those comments and the inserted text are reviewed as file contents only; no external URLs were fetched and no hosted service, Supabase instance, or SQL execution was used.

# Objects and mutations

- **DDL:** None. There are no `CREATE`, `ALTER`, `DROP`, `TRUNCATE`, or other schema-definition statements.
- **DML:** One possible `INSERT` into `public.opportunities`.
- **Control flow:** A `DO $migration$ ... $migration$;` anonymous PL/pgSQL block checks for an existing row and inserts only when neither of two duplicate criteria is met.
- **Read predicate:** The existence check reads `public.opportunities` and looks for either:
  - `application_url = 'https://accreditation.au.int/en/form/data-form-media'`; or
  - `lower(title) = lower('AU Theme of the Year 2027 Logo Competition')`.
- **Inserted columns:** `type`, `title`, `provider_name`, `description`, `eligibility_notes`, `duration`, `location`, `compensation`, `discipline`, `deadline`, `opens_at`, `application_url`, `how_to_apply`, `verified`, and `research_notes`.
- **Inserted values:** One competition row for the African Union Commission, including a title, eligibility and submission requirements, award amounts, dates, verification flag, and three official-looking external URLs embedded in `application_url`, `how_to_apply`, and `research_notes`.
- **Grants/revokes:** None. The migration does not issue `GRANT`, `REVOKE`, role changes, or policy changes.
- **Other mutations:** No updates or deletes are present. If a matching row already exists, the block performs no mutation.

# Dependencies

The migration depends on the following pre-existing database contract:

1. A relation named `public.opportunities` must already exist and be accessible from the migration execution context.
2. The table must contain all 15 referenced columns with compatible types. In particular, `deadline` and `opens_at` must accept the supplied date literals (`2026-10-23` and `2026-09-24`), `verified` must accept a boolean, and the text fields must accept the long descriptions and URLs.
3. Any required defaults, generated-column rules, `NOT NULL` constraints, checks, foreign keys, triggers, or RLS behavior on `public.opportunities` must permit this insert. The migration supplies no values for columns not listed, so omitted columns must have acceptable defaults or be nullable.
4. PL/pgSQL and anonymous `DO` blocks must be available, as in a normal PostgreSQL/Supabase environment.
5. The existence check assumes `title` is usable with `lower()` and `application_url` is comparable to a text URL. It also assumes the relevant values are not blocked by unusual collation or type behavior.

There are no explicit dependencies on another migration named in the file, no foreign table references, no functions or views called by name, and no external API call. Runtime ordering still matters: the `public.opportunities` table and its referenced columns must be created before this seed migration runs. If the table is later changed to require additional non-default columns or stricter checks, this migration may fail.

# Data/external-side-effect assessment

This is real-world, externally sourced content rather than synthetic fixture data. It describes a specific African Union competition, names the African Union Commission, includes eligibility and submission rules, embeds monetary awards, and carries concrete opening and closing dates. The row is marked `verified = true`, and `research_notes` asserts verification against official AU pages.

The file contains these external URLs:

- `https://accreditation.au.int/en/form/data-form-media` (application URL)
- `https://www.au.int/en/newsevents/20260829/call-entries-calling-young-african-creatives-logo-competition-au-theme-year` (call page in research notes)
- `https://au.int/en/documents/20260924/tor-continental-logo-and-visual-identity-competition` (terms-of-reference page in research notes)

The migration does not perform HTTP requests, submit forms, download content, or otherwise contact those sites. Its external side effect is limited to persisting those URLs and the associated real-world claims in the database if the insert executes. It also stores applicant-facing instructions that refer to proof of nationality and age, uploaded design materials, originality/IP/AI declarations, and retaining an automated acknowledgement. No applicant records or personal data are inserted by this file.

The dates are time-sensitive. The stated deadline is 2026-10-23 at 23:59 EAT, while only a date (`2026-10-23`) is stored in the `deadline` column; the time zone and exact cutoff appear only in text. Consequently, the row can become stale or misleading after the deadline, and a synthetic reconstruction should not treat it as a timeless canonical record.

# Security/ordering implications

- The migration is data-only and introduces no privileges, policies, authentication configuration, or security-definer code.
- The `DO` block runs with the privileges of the migration executor. That executor must have permission to read from and insert into `public.opportunities`; RLS or table grants could affect whether the check or insert succeeds.
- The duplicate guard is application-level and is not an atomic uniqueness guarantee by itself. If two sessions run equivalent seed logic concurrently and no unique constraint exists on `application_url` or a normalized title, both could pass the check and insert duplicates.
- Matching is case-insensitive only for `title`, not whitespace-normalized or otherwise canonicalized. The URL comparison is exact, including scheme, host spelling, path, and any query-string differences.
- The guard treats an existing row with the same title or application URL as authoritative and does not reconcile, update, or validate its content. A stale or incorrect pre-existing row therefore suppresses the intended seed.
- The block is expected to execute transactionally as part of migration application, but the file itself does not establish an explicit transaction boundary. A failure caused by schema mismatch, constraints, permissions, or triggers prevents successful completion rather than silently degrading.
- The inserted `verified = true` value is a trust-sensitive assertion. Replaying this migration in a dataset intended for testing can unintentionally make synthetic-looking content appear verified.
- Ordering is mandatory after the `opportunities` table/columns and any applicable enum/type definitions are available. It should be omitted or skipped if the target reconstruction intentionally excludes opportunity seeds.

# Reconstruction recommendation

Omit this migration from a synthetic schema reconstruction unless the reconstruction explicitly aims to reproduce the production-like opportunity catalog, its seed data, or migration history. It contributes no schema objects, constraints, indexes, grants, revokes, or reusable database behavior. Replaying it would add one time-bound, real-world opportunity with external links and a `verified` assertion, which is inappropriate for a synthetic dataset and can create stale or misleading test content.

If a faithful content fixture is required, represent it separately as an explicitly labeled fixture and consider neutralizing or anonymizing the external URLs, verification flag, dates, and applicant-facing claims. If it is retained for production parity, apply it only after `public.opportunities` has the required shape and review whether a unique constraint or an atomic upsert is needed to make repeated/concurrent seeding safe.

# Verdict

**Omit from synthetic schema reconstruction.** This is a conditional, real-data DML seed with no DDL, grants, revokes, or schema behavior. It has a hard dependency on the existing `public.opportunities` table and writes time-sensitive externally sourced competition information, including a verified flag and external application/research URLs. Retain only for an intentional production-data or migration-history reconstruction, not for a schema-only or synthetic-data rebuild.
