# File

`/tmp/scholars-a03-snapshot/scholars-41573f5/supabase/migrations/0088_seed_sande_poetry_prize_2026.sql`

This review covers only the specified migration file.

# Scope

The file is a short data-seeding migration for the Sande Poetry Prize 2026 competition. It does not define or alter database schema. The entire operation is wrapped in a PostgreSQL `DO $migration$ ... $migration$;` anonymous PL/pgSQL block. The block checks for an existing opportunity by exact `application_url` and inserts one row only when that URL is absent.

No SQL is executed as part of this audit, no Supabase instance or hosted service is accessed, and the snapshot is not modified.

# Objects and mutations

## DDL

None. The migration does not create, alter, drop, truncate, or otherwise change tables, columns, indexes, constraints, functions, triggers, policies, schemas, extensions, or types.

## DML

One conditional `INSERT` targets `public.opportunities`. The existence check is:

```sql
where application_url = 'https://osadolor.com/call-for-submissions-sande-poetry-prize-2026/'
```

If no matching row exists, it inserts values into these columns:

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

The inserted record is a `competition` titled `Sande Poetry Prize 2026`, with provider `Sande Poetry Prize`, deadline `2026-11-15`, opening date `2026-10-11`, `verified = true`, and the organizer URL above. The supplied values also contain the competition description, eligibility requirements, timing, location, prize amount, submission instructions, and research/source notes.

The migration has no `UPDATE`, `DELETE`, upsert syntax, sequence manipulation, or explicit transaction-control statement. The anonymous block itself executes as one database statement under the migration runner's surrounding transaction behavior, if any.

## Grants and revokes

None. There are no `GRANT`, `REVOKE`, ownership, role, or privilege changes.

# Dependencies

The direct dependency is the pre-existing table `public.opportunities`. That table must exist before this migration runs, and its schema must accept all fifteen named columns and the supplied literal types/values. In particular, the migration assumes that `application_url` is a comparable column usable in a `WHERE` predicate and that the target fields permit the text, date/date-like, boolean, and competition values supplied here.

The migration also depends on the target table's actual constraints and defaults. Any required column not listed in the insert must have a default or allow omission. Any uniqueness rule or trigger on `application_url` can affect the outcome, although no such constraint is declared or inspected here.

The anonymous block requires PL/pgSQL support, which is normally available in PostgreSQL/Supabase, but this file does not create that support itself. There is no dependency on another migration by filename or on a local file. The inserted research notes and application instructions refer to two external web URLs and an email address as stored text; the database operation does not fetch or validate either URL.

# Data/external-side-effect assessment

This is real-looking, domain content rather than synthetic fixture data. It seeds a named, dated 2026 literary competition and includes specific eligibility rules, deadline/opening dates, prize amount (`₦800,000`), submission email (`sandepoetryprize@osadolor.com`), inquiry email, organizer URL, secondary source URL, and publication-rights/source-verification claims. The values are explicitly presented in the file as verified competition information.

The only runtime side effect is a possible insertion into `public.opportunities`. There is no HTTP request, external API call, email transmission, file write, webhook, job scheduling, or hosted-service interaction in the SQL. The external URLs and email addresses are inert data stored in the inserted row. The migration therefore has no external network side effect, but it does make externally sourced contact and application information available wherever this table is exposed.

The guard is intended to make repeated application idempotent for the exact canonical application URL. It is not a full content reconciliation: if a row with that URL already exists but has stale or different fields, the migration does nothing. Conversely, absent a database uniqueness constraint, concurrent runners could theoretically both observe no matching row and attempt duplicate inserts.

# Security/ordering implications

Ordering: the migration must run after creation of `public.opportunities` and after any prerequisite schema changes that add or establish the named columns and compatible constraints. It should run before any later process that assumes this specific opportunity has been seeded. Because it contains no DDL, it cannot repair a missing table or column and will fail if the expected schema is not already present.

Security: there are no explicit privilege changes and no bypass or policy configuration in this file. The migration executes with the permissions supplied by the migration connection; whether the insert is permitted depends on that role and on existing table policies/permissions. The file does not establish RLS, grant access, or make the row public by itself. If `public.opportunities` is exposed through an API, the inserted real contact details, application instructions, and external links may become readable according to the pre-existing API/RLS configuration; that exposure is an implication of the data and existing access configuration, not a privilege mutation here.

The `verified` flag is trusted input set to `true`; no in-database verification mechanism is implemented. The exact-URL predicate is a practical deduplication check but is not a substitute for a unique constraint, and URL normalization differences could permit logically duplicate records if other rows use a different spelling or equivalent URL.

# Reconstruction recommendation

For a synthetic schema reconstruction whose goal is tables, columns, constraints, and other structural database behavior, this migration can be omitted. It contributes no DDL, grants, revokes, policies, indexes, triggers, or schema-level dependencies beyond requiring the already reconstructed `public.opportunities` table.

If the reconstruction must reproduce application-visible seed data, demo content, search results, or migration-history behavior, retain it as an optional data fixture or seed step after the `opportunities` table and its columns exist. Because the row contains real-looking competition and contact information, a synthetic environment should preferably replace it with clearly labeled synthetic values or isolate it from production-like data unless preserving the source data is specifically required. If retained, preserve the exact-url guard and consider an explicit uniqueness constraint only as a separate schema decision, not as an inferred change to this migration.

# Verdict

**Omit from a synthetic schema reconstruction; retain only as optional seed data when the reconstructed system must include the Sande Poetry Prize 2026 opportunity.** This migration is DML-only, conditionally inserts one externally sourced real-data record, has no grants/revokes or external runtime calls, and does not establish any schema object. Its required ordering dependency is the pre-existing `public.opportunities` table with the listed columns.
