# File

`/tmp/scholars-a03-snapshot/scholars-41573f5/supabase/migrations/0085_seed_verified_user_requested_scholarships_2026.sql`

This review is based solely on the contents of this migration. No SQL was executed, no Supabase instance or hosted service was accessed, and the snapshot was not modified.

# Scope

The file is a single anonymous PL/pgSQL block (`do $migration$ ... $migration$;`) intended to refresh and publish a set of verified 2026 scholarship opportunities. It processes five named opportunities: Yinka & Pelumi Foundation, Carewave ASPIRE/CASP, Female Scholars Foundation, Osun Indigenes Organization USA Chapter, White Avenue Group ICON, and Prince Ukeme Ukpong Mega Foundation. The block uses lookup-or-insert/update behavior for the parent scholarship rows and conditionally inserts eligibility-rule rows.

It is a data seeding/refresh migration, not a schema-definition migration. The opening comments also say that a Pension Literacy competition is already represented in `public.opportunities` by migration 0083 and is deliberately not duplicated, but that other migration is not inspected here.

# Objects and mutations

## DDL

No DDL is present. The file does not create, alter, drop, truncate, or rename schemas, tables, columns, indexes, constraints, functions, triggers, types, policies, or other database objects.

## DML

All mutations target two existing tables in the `public` schema:

- `public.scholarships`: queried by `id`, `application_url`, `title`, `provider_name`, and (for White Avenue) `slug`; inserted when a matching row is not found; otherwise updated with current title, provider, descriptive text, amount, deadline, application URL, level/discipline, verification notes, application instructions, opening date, award count where applicable, and `last_verified_at = now()`.
- `public.scholarship_rules`: queried for an exact combination of `scholarship_id`, `field`, `operator`, and JSONB `value`; missing rules are inserted with `gating = true`.

The mutation pattern is:

1. `select id into v_id ... order by created_at desc limit 1` to choose a current matching scholarship, based on application URL, title/provider patterns, or slug.
2. Insert a new scholarship and capture its generated `id` with `returning id`, or update the selected existing row.
3. Add missing eligibility rules using `if not exists`; existing rules are not updated or removed.

The rule rows added are:

- Yinka & Pelumi: discipline in Electrical Engineering/Mechanical Engineering; year of study from 100 through 500.
- Carewave: Nigerian nationality; age 18 through 25; financial need true; institution type `federal_uni`.
- Female Scholars: female gender; age at most 20; Nigerian nationality; institution type in `federal_uni`/`state_uni`; JAMB score at least 240; WAEC credit count at least 5.
- Osun Indigenes: state of origin Osun; financial need true.
- Prince Ukeme Ukpong: state of origin Akwa Ibom; financial need true.

White Avenue is update-only: if no matching row is found, the block makes no insert and adds no rules for it. No rule rows are added for White Avenue in this file.

## Grants and revokes

No `GRANT`, `REVOKE`, role change, ownership change, or row-level-security/policy operation is present.

# Dependencies

The migration assumes that the following schema already exists and is compatible:

- `public.scholarships` with at least `id`, `created_at`, `application_url`, `title`, `provider_name`, `slug`, `description`, `amount`, `deadline`, `level`, `discipline`, `verified`, `research_notes`, `how_to_apply`, `opens_at`, `awards_available`, and `last_verified_at` columns, plus an insertable/generated UUID `id` suitable for `returning id`.
- `public.scholarship_rules` with `scholarship_id`, `field`, `operator`, JSONB-compatible `value`, and `gating` columns.
- PostgreSQL/PLpgSQL support for an anonymous `DO` block, UUID variables, `now()`, JSONB casts, and the referenced operators.
- The executing migration role must have the required table read/write privileges.

There is an implicit parent-child dependency: each scholarship row must be inserted or resolved before its rules can be inserted. The block satisfies that ordering within each opportunity. It also relies on the lookup columns and data conventions being established before this migration. Its comments refer to prior verification and to migration 0083, but this audit does not inspect or validate those other files.

The migration is not fully idempotent in the strongest sense: repeated runs generally refresh the chosen row and avoid exact duplicate rules, but lookup collisions can cause the newest matching duplicate to be selected, and concurrent executions could race because the lookup/insert sequence is not protected by an explicit unique constraint or locking clause visible in this file. It also cannot reconstruct White Avenue if its expected pre-existing row is absent.

# Data/external-side-effect assessment

This is populated, real-world content rather than synthetic fixture data. It includes named foundations, Nigerian eligibility criteria, award amounts, deadlines, application instructions, email/contact instructions, and verification notes. The notes explicitly describe checking official pages, Google Forms, Facebook posts, PDFs, and ScholarshipAir listings on 2026-10-14; they also record that no personal data was entered and no application was submitted during those checks.

The inserted/updated text contains numerous external URLs, including official domains, Google Forms, Google Docs, a TinyURL, Facebook posts, ScholarshipAir pages, and an email address. The SQL does not fetch, validate, call, or submit to any of these URLs; they are stored as text only. Consequently, executing the migration causes no network request or external application submission by the SQL itself. A later client displaying or following the links would create the ordinary external-navigation risk associated with user-supplied URLs.

The data also contains `now()` values for `last_verified_at`, so execution time affects stored results. Deadlines and opening dates are literal 2026 dates. Some values intentionally remain unknown (`null` deadline/opening date or amount), reflecting the source notes rather than an omitted SQL expression.

# Security/ordering implications

No dynamic SQL, shell command, remote call, credential, secret, grant, revoke, security-definer declaration, or policy bypass is present. The block is therefore not an obvious privilege-escalation or exfiltration mechanism. It does write public scholarship content and should run only under the normal migration role with deliberate authorization.

The principal integrity risks are data and ordering related:

- Parent tables must exist before execution, and `scholarship_rules.scholarship_id` must accept the selected scholarship IDs.
- The block assumes the relevant scholarship columns have the stated types, including JSONB rule values and date-compatible deadline/opening fields.
- Matching uses broad title/provider predicates for several rows and selects the newest match. Existing duplicates can therefore produce an unexpected target.
- The `if not exists` tests are exact and additive. They do not remove stale or contradictory rules, normalize differently encoded equivalent JSON, or repair an existing rule whose `gating` value is wrong.
- The check-then-insert sequence is vulnerable to duplicate rule insertion under concurrent execution unless database constraints prevent it.
- `now()` makes verification timestamps change on every refresh, even when substantive content is unchanged.
- White Avenue's update-only branch silently does nothing when the expected prior row is missing, unlike the other opportunities.
- The stored application and verification URLs are untrusted content from a security perspective; consumers should escape/validate them when rendered, but this migration itself does not render or dereference them.

# Reconstruction recommendation

For a synthetic schema reconstruction whose goal is tables, columns, constraints, policies, and other structural behavior, this migration can be omitted. It contributes no DDL, grants, revokes, policies, or reusable schema logic; the required tables and columns must instead come from the schema migrations that define them.

If the reconstruction is intended to reproduce the application’s populated catalog or migration-era integration behavior, retain it as optional seed data after the parent schema and any relevant prior seed rows exist. A safer synthetic substitute would use clearly synthetic scholarship rows and URLs, or omit the real-world descriptions and verification notes while separately testing the parent/rule relationship. Do not treat the data block as necessary to establish the schema. If retained, run it only after confirming the lookup columns, generated IDs, JSONB rule representation, and any uniqueness/concurrency constraints in the reconstructed schema.

# Verdict

**Omit from a schema-only synthetic reconstruction; retain only as optional, real-data seed/refresh content.** The file is DML-only, with no DDL, grants, revokes, or external network side effects. It depends on pre-existing `public.scholarships` and `public.scholarship_rules` structures, writes substantive externally sourced scholarship records and eligibility rules, and has several ordering/idempotency caveats that are irrelevant to structural reconstruction but material to reproducing the populated application state.
