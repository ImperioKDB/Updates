# File

- **Path:** `/tmp/scholars-a03-snapshot/scholars-41573f5/supabase/migrations/0092_seed_verified_user_requested_opportunities_2026.sql`
- **Migration form:** One anonymous PostgreSQL `DO $migration$ ... $migration$;` block.
- **Read-only audit boundary:** This review is based only on the specified file. No SQL was executed, no Supabase instance or hosted service was accessed, and the snapshot was not modified.

# Scope

This migration is a data-seeding migration for verified scholarship and training-opportunity records. It does not define or alter the database schema. The block checks for existing rows by `application_url`, inserts missing records, and, for the AfriSEED record, captures the inserted or existing scholarship ID and conditionally inserts two eligibility rules.

The data describes four opportunities:

1. EARTH University Mastercard Foundation Scholarship 2027, inserted into `public.scholarships`.
2. AfriSEED Foundation Root Initiative 2026, inserted into `public.scholarships`.
3. Émile Boutmy Scholarship 2027 — Undergraduate, inserted into `public.scholarships`.
4. CMU-Africa Certificate in Artificial Intelligence for Africa 2026, inserted into `public.opportunities` as `type = 'training'`.
5. Sycom Cybersecurity Talent Pipeline Scholarship Programme 2026/27, inserted into `public.opportunities` as `type = 'training'`.

The first three are scholarship rows; the last two are training-opportunity rows. The file comments state that the records were verified on 2026-10-20 against official provider pages and supplied ScholarshipAir pages, and explicitly explain why the Dele Awe Foundation Scholarship 2026 is excluded. That exclusion is commentary only and causes no database mutation.

# Objects and mutations

## DDL

- **None.** There is no `CREATE`, `ALTER`, `DROP`, `TRUNCATE`, sequence operation, function definition, index definition, constraint definition, or type definition.
- The anonymous `DO` block is procedural execution syntax, not a persistent schema object.

## DML

All mutations are `INSERT` statements guarded by `IF NOT EXISTS` checks. There are no `UPDATE`, `DELETE`, `MERGE`, or explicit transaction-control statements.

### `public.scholarships`

Three conditional inserts target `public.scholarships`, each checking the unique-looking business key `application_url`:

- `https://admissions.earth.ac.cr/Application`
  - Title: `EARTH University Mastercard Foundation Scholarship 2027`.
  - Includes provider, descriptive and application text, amount text, deadline `2027-01-31`, undergraduate level, discipline `Agricultural Sciences`, `verified = true`, research notes, and `last_verified_at = now()`.
- `https://forms.gle/kJSMdxUGbv45PwjM6`
  - Title: `AfriSEED Foundation Root Initiative 2026`.
  - Includes deadline `2026-11-15`, undergraduate level, `discipline = null`, `verified = true`, research/application text, and `last_verified_at = now()`.
  - Uses `RETURNING id INTO v_afriseed_id` when inserting.
- `https://www.sciencespo.fr/students/en/fees-funding/bursaries-financial-aid/emile-boutmy-scholarship/`
  - Title: `Émile Boutmy Scholarship 2027 — Undergraduate`.
  - Includes deadline `2027-01-13`, undergraduate level, `discipline = null`, `verified = true`, research/application text, and `last_verified_at = now()`.

The existence tests use `SELECT 1 ... LIMIT 1`; they do not lock or otherwise serialize competing sessions. Existing matching rows are left unchanged, including their descriptive content and verification timestamp.

### `public.scholarship_rules`

Two conditional inserts add rules associated with the AfriSEED scholarship ID:

- `field = 'nationality'`, `operator = 'eq'`, `value = '"Nigerian"'::jsonb`, `gating = true`.
- `field = 'financial_need'`, `operator = 'eq'`, `value = 'true'::jsonb`, `gating = true`.

Each rule is checked by scholarship ID, field, operator, and JSONB value. No rule is inserted if that exact combination already exists. The migration does not update or remove pre-existing rules.

### `public.opportunities`

Two conditional inserts target `public.opportunities`, also keyed by `application_url`:

- `https://pregradadmissions-afretec.engineering.cmu.edu/apply/?sr=c710f69e-de1e-4ff6-90c3-977392fc7c2c`
  - Title: `CMU-Africa Certificate in Artificial Intelligence for Africa 2026`.
  - `type = 'training'`, deadline `2026-11-15`, opens date `2026-10-15`, `verified = true`, and training/application metadata.
- `https://sycomail-dev-web.azurewebsites.net/p/sycom-scholar-2026`
  - Title: `Sycom Cybersecurity Talent Pipeline Scholarship Programme 2026/27`.
  - `type = 'training'`, deadline `2026-10-31`, opens date `2026-10-01`, `verified = true`, and training/application metadata.

No grants or revokes occur. No role changes, row-level-security changes, policy changes, or ownership changes occur.

# Dependencies

The migration assumes that the following schema objects already exist and are compatible with the referenced columns and types:

- `public.scholarships`, with at least the columns `id`, `title`, `provider_name`, `description`, `amount`, `deadline`, `application_url`, `level`, `discipline`, `verified`, `research_notes`, `how_to_apply`, and `last_verified_at`.
- `public.scholarship_rules`, with at least `scholarship_id`, `field`, `operator`, `value` (compatible with `jsonb`), and `gating`.
- `public.opportunities`, with at least `type`, `title`, `provider_name`, `description`, `eligibility_notes`, `duration`, `location`, `compensation`, `discipline`, `deadline`, `opens_at`, `application_url`, `how_to_apply`, `verified`, and `research_notes`.
- PostgreSQL procedural `DO` support and the standard `now()` function.
- UUID-compatible `public.scholarships.id`, because the local variable `v_afriseed_id` is declared as `uuid`.
- JSONB support and the ability to cast the supplied JSON literals to `jsonb`.

The AfriSEED rule inserts additionally depend on the AfriSEED scholarship row being found or inserted successfully. If the existing row for the AfriSEED URL has a non-UUID ID or if the table schema does not match the declared variable, execution fails. The migration also assumes the application URL values are stable and suitable as idempotency keys. No explicit foreign-key definition is made here, but `scholarship_rules.scholarship_id` is semantically expected to reference `scholarships.id`.

# Data/external-side-effect assessment

The migration contains real-looking, user-facing opportunity data rather than synthetic placeholders. It records provider names, eligibility descriptions, deadlines, application instructions, verification notes, and `verified = true` flags for three scholarships and two training programmes. The comments and research notes identify official provider URLs and supplied ScholarshipAir listing URLs, including:

- EARTH University admissions and Mastercard Foundation programme pages, plus a ScholarshipAir listing.
- AfriSEED Foundation’s programme page and application form, plus a ScholarshipAir listing.
- Sciences Po’s Émile Boutmy page, plus a ScholarshipAir listing.
- CMU-Africa certificate and application pages, plus a ScholarshipAir listing.
- Sycom Academy’s programme page and its linked Azure-hosted application route.

The SQL itself performs no network requests, HTTP calls, file I/O, notifications, or external service writes. URLs are stored as ordinary text values. The only runtime-generated value is `now()` for `last_verified_at` on newly inserted scholarship rows; the opportunity rows do not set a timestamp field beyond their literal dates. The data is time-sensitive and cycle-specific (2026/2027 deadlines), and the application URLs may change or become unavailable independently of the database.

The guarded checks provide basic rerun idempotency when the application URL is unique in practice. They do not reconcile changed source data: an existing row with the same URL is not refreshed. Concurrent executions could both pass an application-URL existence check if there is no database uniqueness constraint, potentially creating duplicates. The same race applies to the rule checks absent an appropriate uniqueness constraint.

# Security/ordering implications

- The migration must run after the base schema creates `public.scholarships`, `public.scholarship_rules`, and `public.opportunities` with the expected columns and types.
- It must run after any prerequisite migrations that establish the relevant foreign key or enum/domain constraints, if those exist in the surrounding schema. The file itself does not establish them.
- The three scholarship inserts precede the rule inserts. This is required for the AfriSEED ID lookup and for any foreign-key relationship from `scholarship_rules.scholarship_id`.
- The EARTH, AfriSEED, and Sciences Po inserts are independent of one another. The two opportunity inserts are also independent of the scholarship inserts, although the entire `DO` block is one procedural statement and an error aborts the statement rather than producing a partial successful completion under normal PostgreSQL statement semantics.
- No explicit privilege escalation is present. Effective security still depends on the role executing the migration having `SELECT` and `INSERT` privileges on all three tables and on any required sequence privileges or trigger-related permissions.
- The migration writes public-facing application URLs and detailed eligibility/research text. It does not insert obvious credentials, tokens, private contact information, or secrets. A downstream application should nevertheless treat URLs and descriptive claims as untrusted, potentially stale content and escape/render them safely.
- `verified = true` is a trust-sensitive flag. Reconstructing these rows without their research notes or without preserving the distinction between official and supplied URLs could misrepresent the verification basis.
- The existence checks are not guaranteed to be race-free without unique constraints on `application_url` (and an appropriate uniqueness rule for the rule columns). A synthetic reconstruction should not infer that the procedural checks substitute for constraints.

# Reconstruction recommendation

For a **synthetic schema reconstruction** whose purpose is to reproduce tables, columns, constraints, and relationships, this migration can be omitted. It contains no DDL, grants, revokes, or persistent database-object definitions; omitting it does not remove schema structure. The reconstruction should instead ensure that the base schema supports the referenced tables, UUID scholarship IDs, JSONB rule values, date/timestamp fields, and any intended uniqueness or foreign-key constraints.

If the goal is a **data-faithful fixture** or a test environment that must demonstrate populated scholarship/opportunity screens, the migration may be retained as optional seed data, but it should be treated as real, time-bound fixture content rather than synthetic schema. Consider isolating it from structural migrations, adding explicit uniqueness constraints before relying on its idempotency pattern, and deciding whether current-cycle dates and external URLs are appropriate for the target environment. Do not treat its `verified` values as proof that the external pages remain current.

# Verdict

**Omit from a synthetic schema reconstruction.** This is DML-only, real-data seed content with no DDL, grants, revokes, or required schema behavior. Preserve it only when reproducing the application’s seeded opportunity records or when a data fixture explicitly requires these 2026/2027 records and their external URLs. Its only structural significance is the set of pre-existing table/column/type assumptions and the ordering requirement that the AfriSEED scholarship exist before its two rules are inserted.
