# File

- **Path:** `/tmp/scholars-a03-snapshot/scholars-41573f5/supabase/migrations/0089_seed_yale_yyas_2027.sql`
- **Migration identifier:** `0089_seed_yale_yyas_2027`
- **File shape:** One anonymous PL/pgSQL `DO` block, lines 4–48, containing a conditional insert.
- **Audit scope:** This review covers only the specified migration file. No other migration was inspected, and no SQL was executed.

# Scope

The migration publishes one Yale Young African Scholars (YYAS) 2027 fellowship/program opportunity. It first checks whether a matching row already exists by either the exact application URL or a case-insensitive title comparison. If neither match exists, it inserts one row into `public.opportunities` with program metadata, eligibility and application instructions, dates, verification status, and research notes.

The migration is data seeding/content publication rather than schema construction. It does not create, alter, drop, or otherwise define database objects. It also does not invoke external services; the Yale and application URLs are stored as text values only.

# Objects and mutations

## DDL

No DDL is present. The file contains no `CREATE`, `ALTER`, `DROP`, `TRUNCATE`, index definition, constraint definition, function definition, trigger definition, policy definition, or extension operation.

The anonymous `DO` block is an execution construct, not a persistent schema object. It evaluates procedural logic at migration time and is not retained as a named function.

## DML

The migration performs:

1. A `SELECT 1` against `public.opportunities` to test whether any row has either:
   - `application_url = 'https://apply.globalscholars.yale.edu/apply/?sr=0d898c5f-198d-43dd-a47a-e261962b48b9'`; or
   - `lower(title) = lower('Yale Young African Scholars (YYAS) 2027')`.
2. At most one `INSERT` into `public.opportunities`, populating these columns:
   `type`, `title`, `provider_name`, `description`, `eligibility_notes`, `duration`, `location`, `compensation`, `discipline`, `deadline`, `opens_at`, `application_url`, `how_to_apply`, `verified`, and `research_notes`.

The insert uses `type = 'fellowship'`, a deadline of `2026-10-20`, `opens_at = NULL`, `verified = true`, and the supplied Yale/YYAS content. It does not update an existing row, delete rows, or otherwise mutate existing data.

## Grants and revokes

No `GRANT` or `REVOKE` statements are present. No role, ownership, privilege, row-level-security policy, or security-definer behavior is established by this file.

# Dependencies

- **Required relation:** `public.opportunities` must already exist before this migration runs.
- **Required columns:** The relation must expose the columns referenced by the existence check (`application_url`, `title`) and all 15 columns in the `INSERT` list. Their data types must accept the supplied text, boolean, date, and null values.
- **Required procedural language:** The database must support PL/pgSQL anonymous blocks, normally through PostgreSQL's built-in `plpgsql` language.
- **Required name resolution:** The migration explicitly qualifies the table as `public.opportunities`, so it depends on that schema and relation rather than a `search_path`-selected table.
- **Required privileges:** The executing migration role needs permission to read `public.opportunities` and insert into it. Any column-level privileges, RLS policies, defaults, checks, or triggers defined elsewhere can affect whether the insert succeeds or what is ultimately stored.
- **Ordering:** The table, columns, and any required supporting policies/triggers/defaults must be available before migration `0089` executes. In a synthetic reconstruction that omits this seed, only the schema and behavior required by later migrations or application code need to be retained.

The existence test is application-level/idempotency logic, not a declared uniqueness guarantee. Without a database unique constraint or equivalent concurrency control defined elsewhere, two concurrent executions could theoretically both observe no match and attempt to insert duplicates. A normal serial migration runner generally avoids that situation, but the file itself does not enforce it.

# Data/external-side-effect assessment

The file contains one substantial real-world content record, not synthetic placeholder data. It names Yale University/YYAS, describes the 2027 program, gives eligibility rules, dates, costs/benefits, application instructions, and a verification narrative. It includes these external URLs as stored content:

- Application portal: `https://apply.globalscholars.yale.edu/apply/?sr=0d898c5f-198d-43dd-a47a-e261962b48b9`
- Yale admissions: `https://africanscholars.yale.edu/admissions`
- Eligibility: `https://africanscholars.yale.edu/admissions/eligibility`
- Application requirements: `https://africanscholars.yale.edu/admissions/application-requirements`
- Timeline/deadlines: `https://africanscholars.yale.edu/admissions/application-timeline-deadlines`
- Program overview: `https://africanscholars.yale.edu/overview`

There is no HTTP client, shell command, foreign data wrapper, notification, email, file write, webhook, or other outbound operation. The URLs are literals inserted into database fields; merely running this migration does not fetch or validate them.

The record is time-sensitive: it describes the 2027 cycle, uses the Early Action deadline (`2026-10-20`) as the row's `deadline`, and retains the Regular Decision deadline (`2027-01-20`) in `how_to_apply`. Its `research_notes` state that it was verified on `2026-10-17`. Replaying it later could publish stale or already-closed opportunity information, even though the conditional predicate prevents insertion when the same URL or title is already present.

# Security/ordering implications

- The migration has no explicit security changes: no grants, revokes, roles, RLS policies, ownership changes, or security-definer declarations.
- The anonymous block executes with the privileges of the migration/session role. It therefore requires read access for the existence check and insert access for `public.opportunities`; it does not bypass ordinary table permissions by virtue of being a `DO` block.
- The inserted application URL contains a query parameter that appears to be an application identifier. It is stored verbatim and should be treated as user-facing external content. The migration does not sanitize, redirect, or dereference it; any HTML escaping or link-safety policy belongs to the consuming application.
- The existence predicate is case-insensitive only for `title`, while the URL comparison is exact. A title collision with a different opportunity/application URL suppresses insertion, and URL variants (for example, differences in case or query-string representation) may not be recognized as duplicates.
- The conditional check is not an atomic uniqueness mechanism. If this seed is expected to be safe under concurrent execution, a suitable unique constraint/index or serialized migration execution is needed elsewhere.
- The insert's success and final values can be affected by schema-level checks, triggers, defaults, generated columns, RLS, or required columns not listed here. Those are dependencies, not objects created by this migration.
- Migration ordering matters only for the pre-existing `public.opportunities` contract. Since this file has no schema DDL, it should run after the opportunity table and all required columns are established.

# Reconstruction recommendation

For a **synthetic schema reconstruction**, this migration can be omitted. It contributes no schema objects, constraints, privileges, policies, functions, or durable database behavior that must be reconstructed to represent the schema. Retain or recreate the `public.opportunities` table and its relevant column contract based on the schema-producing migrations or other authoritative schema evidence, not this seed file.

Omission is appropriate when the reconstruction goal is structural/synthetic and should avoid real-world records, external URLs, and time-sensitive content. If the goal instead includes representative application fixtures or reproduces the production opportunity catalog, the row may be retained as an explicitly marked fixture, but it should be reviewed for date freshness and external-link validity. If the seed is replayed in an environment where `public.opportunities` exists, preserve its idempotency intent and consider a database-level uniqueness rule if duplicate prevention matters.

# Verdict

**Omittable for synthetic schema reconstruction: yes.** This is a real-data/content seed with one conditional insert and no DDL, grants, revokes, external network side effects, or schema-defining behavior. Its only material dependencies are the pre-existing `public.opportunities` table/columns, PL/pgSQL support, and migration-role permissions. Keep it only when reproducing seeded catalog content is an explicit requirement; otherwise omit it to avoid importing time-sensitive Yale/YYAS data and external application URLs.
