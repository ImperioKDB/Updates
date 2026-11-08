# File

- **Path:** `/tmp/scholars-a03-snapshot/scholars-41573f5/supabase/migrations/0104_seed_dcma_coas_literary_competitions_2027.sql`
- **Inspected scope:** This review is based only on the contents of the specified migration. No other migration was inspected, and no SQL was executed.
- **Migration shape:** One anonymous PL/pgSQL block delimited by `$migration$`, with a local UUID variable and an idempotent-looking find-or-insert/update flow.

# Scope

This migration publishes or refreshes one opportunity record: **COAS Literary Competitions 2027**, classified as a competition rather than a scholarship. It searches `public.opportunities` for the newest matching record by either the canonical application URL or a case-insensitive title, inserts a complete record when no match is found, and otherwise updates the matched record's opportunity fields.

The SQL has no explicit `CREATE`, `ALTER`, `DROP`, `GRANT`, `REVOKE`, view, function, trigger, index, constraint, storage, authentication, or Resource Center DDL. It does contain DML executed from an anonymous procedural block. The block's `SELECT ... INTO`, conditional branch, `INSERT ... RETURNING`, and `UPDATE` are the only database mutations or reads visible in this file.

The comments and text values describe a researched external opportunity. They do not themselves establish that the external URLs are reachable or current; the file records the author's stated verification and caveats as stored content.

# Objects and mutations

## Referenced object

- `public.opportunities` is the sole database object referenced by the SQL.
- The migration assumes that this table exists and has at least the columns used below, with compatible types and constraints:
  - Read/matching columns: `id`, `application_url`, `title`, `created_at`.
  - Insert/update columns: `type`, `title`, `provider_name`, `description`, `eligibility_notes`, `duration`, `location`, `compensation`, `discipline`, `deadline`, `opens_at`, `application_url`, `how_to_apply`, `verified`, and `research_notes`.
- `id` must be compatible with the local `uuid` variable (`v_id uuid`) and with `INSERT ... RETURNING id`.
- `created_at` is used only to order matching rows; the migration does not create or alter it.

## Read and match operation

Lines 11–16 select one `id` into `v_id` from `public.opportunities` where either:

1. `application_url = 'https://dcma.army.mil.ng/competition'`, or
2. `lower(title) = lower('COAS Literary Competitions 2027')`.

The result is ordered by `created_at DESC` and limited to one row. If multiple rows match, the newest according to `created_at` is selected. No `FOR UPDATE` or other explicit locking clause is present. A null result leaves `v_id` null and takes the insert branch.

## Insert branch

When no matching row is selected, lines 19–51 insert one row into `public.opportunities`. The values encode:

- `type`: `competition`.
- `title`: `COAS Literary Competitions 2027`.
- Provider: Department of Civil-Military Affairs, Nigerian Army.
- Description, eligibility, process/duration, location, prize compensation, and creative disciplines.
- `deadline`: `2027-05-31`.
- `opens_at`: `2026-11-01`.
- Canonical application/landing URL: `https://dcma.army.mil.ng/competition`.
- Application instructions containing the landing page and two form URLs.
- `verified`: `true`.
- `research_notes`: a dated verification narrative, official and mirrored URLs, stale-year caveats for the two form routes, and a statement that no entry or personal data was submitted.

The insert returns the generated/stored `id` into `v_id`, but the value is not used after the insert.

## Update branch

When a match is found, lines 53–69 update that selected row by `id`. The update overwrites all of the substantive opportunity fields listed in the insert branch, including classification, title, provider, descriptive fields, dates, URLs, application instructions, `verified`, and `research_notes`. It does not update `id` or `created_at`, and it does not update any columns not listed in the assignment set.

Because the match predicate uses `OR`, a row can be selected by title even if its existing application URL differs, or by URL even if its title differs. If more than one row matches, only the row with the greatest `created_at` is updated; the migration does not deduplicate the remaining matches.

## DDL, grants, and revokes

- **DDL:** None present.
- **DML:** One conditional `SELECT`, an `INSERT` alternative, and an `UPDATE` alternative against `public.opportunities`.
- **GRANT:** None present.
- **REVOKE:** None present.
- **Views/functions/policies/triggers/constraints:** None created, altered, or dropped by this file. The anonymous block invokes standard SQL/PLpgSQL constructs and the built-in `lower` function but defines no persistent function.

# Dependencies

The direct dependency is `public.opportunities` and its existing schema. Successful application additionally depends on:

- PL/pgSQL being available for the anonymous `do` block.
- A writable database role with `SELECT`, `INSERT`, and `UPDATE` privileges on `public.opportunities` and sufficient permission to execute the block.
- The table's column types accepting the supplied text, boolean, UUID, and date-like literals. The migration does not specify casts for `deadline` or `opens_at`; compatibility therefore depends on the table's date/timestamp representation and PostgreSQL's assignment coercion rules.
- Any existing row-level security (RLS) policies or triggers on `public.opportunities`, which could permit, reject, transform, or otherwise affect the DML. Their definitions are not in this file and were not inspected.
- Any uniqueness or check constraints on `public.opportunities`, which may reject the insert or update. The SQL does not add or document such constraints.

There is no visible dependency on a Resource Center table, Resource Center view, security policy, role, privilege grant, revoke, or security-definer function. The requested “final two security/Resource Center migrations” cannot be mapped from this file: this migration contains no such objects or references, and no runtime verification or cross-migration inspection was performed. Any relationship would have to be established from other migration files, which are outside this audit scope.

# Data/external-side-effect assessment

The migration writes one curated opportunity record and may overwrite an existing matching record. The content is not user-generated data and contains no apparent personal data. It includes Nigerian naira prize amounts, eligibility ages, dates, descriptive copy, and a verification narrative.

External URLs are stored as text only. They include the DCMA competition page, two DCMA form routes, a `dcma.vercel.app` mirror, a Nigerian Army Facebook announcement, and the supplied official domain. The SQL does not issue HTTP requests, crawl pages, submit forms, upload files, or otherwise contact those URLs. Consequently, this file has no direct external network side effect. The comments and `research_notes` claim verification as of `2026-11-04` and explicitly say that no entry or personal data was submitted, but those claims are not independently runtime-verified by this audit.

The inserted/updated values are real-world opportunity content rather than synthetic fixture data. The `verified = true` flag and detailed research notes could affect downstream display or trust decisions if application code treats them as authoritative. The migration also stores stale-year caveats for the primary/secondary and tertiary form routes, which is useful provenance but means consumers should not assume every linked form currently represents the 2027 cycle.

# Security/ordering implications

This file introduces no security configuration. It neither creates nor changes RLS policies, roles, grants, revokes, views, functions, constraints, or privileges. It therefore cannot itself harden or weaken access control, and there is no security-definer or elevated-privilege construct visible here.

The block is a read-then-write upsert pattern implemented manually. The lookup and subsequent insert/update are not protected by an explicit row lock or an `ON CONFLICT` clause. If concurrent sessions execute the migration or equivalent logic, both could observe no matching row and attempt to insert duplicates unless a pre-existing uniqueness constraint prevents that. If a uniqueness constraint raises an error, the surrounding migration transaction would fail; if no such constraint exists, duplicate opportunity records are possible. Concurrent updates can also race, with the later write winning.

The `ORDER BY created_at DESC LIMIT 1` rule makes selection deterministic only insofar as `created_at` is populated and unique enough for the desired ordering. Ties are not broken by a second key. Null ordering behavior is PostgreSQL's default for descending order and is not explicitly documented in the SQL. A title-only match can update a record whose URL is different, while a URL-only match can replace a differently titled record; this is intentional-looking normalization but should be considered before replaying against non-fixture data.

Ordering-wise, `public.opportunities` must already exist before this migration runs, with compatible columns and permissions. Any schema migration that creates or changes this table, its relevant columns, required defaults, RLS policies, triggers, or constraints must precede this file. The migration itself creates no prerequisite objects and does not establish a dependency on later security or Resource Center migrations. If later policies or views consume `verified`, dates, URLs, or `type`, their behavior may depend on whether this seed has already run, but those consumers are not present in the inspected file.

# Reconstruction recommendation

For a **synthetic schema reconstruction**, this migration can be omitted if the objective is to reproduce schema objects, security configuration, and structural behavior rather than production opportunity content. It contains no DDL, grants, revokes, policy definitions, views, functions, or constraints that need to be reconstructed.

If representative seed data is desired, preserve it as an optional fixture rather than as schema-defining migration logic. A safer fixture should document the dependency on `public.opportunities`, decide explicitly whether the real URLs and `verified` status are appropriate, and use a deterministic conflict strategy or a synthetic identifier. Avoid importing the research narrative as proof of current external availability. If the target reconstruction is intended to reproduce application-visible production content, retain the record separately and review the stale form-route caveats and date semantics.

Because this file has no security or Resource Center objects, omitting it does not omit any such objects. Those must be assessed from their own migration files; this audit intentionally does not inspect them.

# Verdict

**Omittable for synthetic schema reconstruction: yes, with data-fixture caveat.** The migration is a real-data seed/refresh for one external opportunity, not a schema or security migration. It performs conditional DML only, has a direct dependency on an already-existing writable `public.opportunities` table, and carries no explicit grants, revokes, policies, views, functions, constraints, or Resource Center objects. Preserve it only when reproducing the curated opportunity dataset or its user-facing content; omit it when reconstructing the synthetic schema and security surface. No runtime behavior, external URL reachability, policy evaluation, or cross-migration dependency was verified.
