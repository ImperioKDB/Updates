# File

`/tmp/scholars-a03-snapshot/scholars-41573f5/supabase/migrations/0102_seed_tka_solid_foundations_2027.sql`

This review is based solely on the contents of the specified file. No other migration was inspected, no SQL was executed, no Supabase instance or hosted service was accessed, and the snapshot was not modified.

# Scope

The migration is a data-seeding/upsert-like operation for one scholarship record, implemented as an anonymous PL/pgSQL `DO` block (`DO $migration$ ... $migration$;`). It first searches `public.scholarships` for the newest matching record, using either the official application URL or a case-insensitive title match. If no match is found, it inserts one row; otherwise it updates the selected row with the supplied canonical values.

The file has no schema-definition statements (`CREATE`, `ALTER`, `DROP`, `CREATE INDEX`, or constraint changes), no explicit transaction statements, no role/privilege statements, and no external calls. The only procedural runtime operation is the anonymous block itself.

# Objects and mutations

## Objects referenced or created

- **Referenced table:** `public.scholarships`.
- **Anonymous procedural block:** one transient `DO` block named by the dollar-quote tag `$migration$`. It does not create a persistent function or procedure.
- **Local variable:** `v_scholarship_id uuid`.
- **No persistent objects created:** no table, column, index, constraint, view, trigger, policy, role, grant, revoke, or persistent function is created by this file.

## Read/query behavior

The block selects `id` into `v_scholarship_id` from `public.scholarships` where either:

1. `application_url = 'https://tkasolidfoundations.org/scholarships/2027-nigerian-scholarship'`, or
2. `lower(title) = lower('TKA Solid Foundations 2027 Nigerian College/University Scholarship')`.

It orders candidates by `created_at desc` and applies `limit 1`. Thus, if multiple records match, the newest according to `created_at` is selected. The exact tie behavior for equal `created_at` values is not deterministic because there is no secondary ordering key.

## Insert mutation

When no matching row is found, the block inserts one row into `public.scholarships` and captures the generated `id` with `returning id`. The inserted columns are:

- `title`
- `provider_name`
- `description`
- `amount`
- `deadline`
- `application_url`
- `level`
- `discipline` (explicitly `null`)
- `verified` (`true`)
- `research_notes`
- `how_to_apply`
- `opens_at`
- `last_verified_at` (`now()`)

The values describe the TKA Solid Foundations 2027 Nigerian College/University Scholarship, including a 20 December 2026 deadline, an opening date of 1 October 2026, undergraduate level, and support described as tuition/school fees, textbooks, stationery, and bursary support. No individual award amount is supplied.

## Update mutation

When a matching row is found, the block updates the selected row by `id`. It overwrites the same substantive scholarship fields listed above, including `title`, `provider_name`, `description`, `amount`, `deadline`, `application_url`, `level`, `discipline`, `verified`, `research_notes`, `how_to_apply`, `opens_at`, and `last_verified_at`.

The update does not alter `id`, `created_at`, or any columns not listed in the `set` clause. Because `last_verified_at` is assigned `now()`, rerunning the migration changes that timestamp even when the descriptive values are already identical.

## DDL, grants, revokes, policies, views, functions, and constraints

- **DDL:** none.
- **DML:** one conditional `select`, followed by exactly one `insert` or one `update` in normal execution.
- **Grants:** none.
- **Revokes:** none.
- **Row-level security policies:** none created, altered, or dropped.
- **Views/materialized views:** none.
- **Persistent functions/procedures:** none. The `DO` block is anonymous and ephemeral.
- **Constraints/indexes:** none created or changed. Existing constraints and indexes on `public.scholarships` may accept or reject the DML, but are not defined here.
- **Triggers/defaults:** not declared here; any existing table triggers or column defaults could run as a consequence of the insert/update, but their definitions were not inspected.

There are no security or Resource Center objects in this file to map. In particular, this migration does not define or modify any Resource Center table, policy, privilege, view, function, or constraint. The instruction to inspect no other migration means security/Resource Center objects potentially defined elsewhere cannot be attributed to or verified from this file.

# Dependencies

The migration depends on the pre-existing `public.scholarships` relation and on the following columns and compatible types/behavior:

- `id`, assignable to the local `uuid` variable and available from `returning id`;
- `application_url`, `title`, and `created_at` for candidate selection;
- `provider_name`, `description`, `amount`, `deadline`, `level`, `discipline`, `verified`, `research_notes`, `how_to_apply`, `opens_at`, and `last_verified_at` for insert/update;
- `lower(title)` support, normally supplied by a text-like title type or a compatible expression;
- a writable table with insert and update capability;
- `now()` and standard PL/pgSQL/SQL runtime support.

The insert additionally depends on all omitted columns having defaults or accepting nulls, unless the table schema makes them otherwise unnecessary. The update path assumes the selected `id` uniquely identifies the intended row; this is normally expected for a primary key, but that constraint is not established in this file.

Operationally, the executing role needs sufficient privileges to select from, insert into, and update `public.scholarships`. No such privileges are granted here. If row-level security is enabled, applicable existing policies and the execution context will govern whether the read and mutations succeed; this file neither enables nor disables RLS and does not create bypass privileges.

The block is intended to run after the schema and any required `public.scholarships` columns have been created. It does not depend on a separate provider table, application-form table, Resource Center object, external API, or network access.

# Data/external-side-effect assessment

The migration contains real-world scholarship content rather than synthetic placeholder data. It writes a named provider, a specific scholarship title, descriptive eligibility/support text, a dated application window, and verification/application instructions. It also writes external URLs as data:

- Official application/provider page: `https://tkasolidfoundations.org/scholarships/2027-nigerian-scholarship`
- Organization homepage: `https://tkasolidfoundations.org/`
- Google Form mentioned in `research_notes`: `https://docs.google.com/forms/d/e/1FAIpQLSdjsitKhRAF3Mmw8JUUxzp9cKaCfju_J4PPl0usAV5mV43bNQ/viewform`

The Google Form URL is not written to `application_url`; it is retained only inside the research narrative, which says it required Google sign-in during verification and was not linked from the official provider page. The official provider URL is the public application URL written to the record.

There is no network request, HTTP fetch, webhook, email, file operation, payment, or other external side effect in the SQL itself. The external URLs are inert string values unless application code later follows them. The content includes a verification date (`2026-10-30`), deadline (`2026-12-20`), opening date (`2026-10-01`), and screening details for 2027; these are data assertions and are not independently verified by this read-only review.

The principal side effect is persistent mutation of one `public.scholarships` row. Because the block uses a select-then-insert/update pattern rather than a database `upsert` with a unique conflict target, concurrent executions could both observe no match and attempt duplicate inserts unless an existing unique constraint prevents them. If a unique constraint rejects one insert, the surrounding statement/block invocation will fail rather than automatically retrying the update path.

# Security/ordering implications

The file has no explicit security configuration. It neither creates policies nor changes grants, revokes, ownership, `SECURITY DEFINER`, search paths, or role settings. The anonymous block therefore executes under the normal privilege and RLS context of the migration runner. The use of schema-qualified `public.scholarships` reduces ambiguity about the target relation, but functions such as `lower` and `now` are unqualified and rely on standard resolution.

The data-selection logic has several ordering and idempotence implications:

1. Matching is by exact application URL or case-insensitive title. A pre-existing row with the same title but a different application URL is still selected and overwritten.
2. If several rows match, only the row with the greatest `created_at` is updated. Older duplicates remain untouched.
3. Equal `created_at` values have no deterministic tie-breaker.
4. The operation is not concurrency-safe in the same way as an atomic `INSERT ... ON CONFLICT`; concurrent runners can race between the select and the mutation.
5. Reruns are mostly content-idempotent for the selected row, but they refresh `last_verified_at` with the current timestamp.
6. The block does not explicitly lock the candidate row or table.
7. Existing triggers, generated columns, foreign keys, check constraints, RLS policies, and audit mechanisms may affect execution or produce additional effects; none are visible from this file and were not runtime-verified.
8. The very long free-text fields embed external URLs and user-facing instructions. They should be treated as untrusted or externally sourced content by downstream rendering code, with normal URL validation and safe-link handling. This migration itself performs no HTML rendering.

The expected migration order is after the `scholarships` table and all referenced columns exist, and after any intended security policies/privileges are in place. If run before the table or columns exist, parsing/execution will fail. If run before relevant RLS policies are configured, outcome may differ from the intended application context; the file provides no policy guarantees.

The requested “final two security/Resource Center migrations” are not present in this file: there are no security or Resource Center DDL/DML objects here. Consequently, no claim about their runtime behavior, ordering, privileges, policies, or dependencies can be made without inspecting other migrations, which this review intentionally does not do.

# Reconstruction recommendation

For a synthetic schema reconstruction, this migration can generally be omitted as **content seeding**, provided the reconstruction does not need this specific scholarship record or its externally sourced text. Retain the `public.scholarships` table shape and any security behavior from the separately authoritative schema/security migrations; this file does not supply those definitions.

If the goal is a content-faithful fixture or a test of seed idempotence, preserve it as an optional fixture after the table exists, preferably with an explicit unique key/conflict strategy or a deterministic fixture identifier. If retained in a synthetic environment, consider replacing real URLs and time-sensitive claims with clearly labeled synthetic values, or isolating the row from production-like data. Do not infer any Resource Center or security schema from this seed file.

# Verdict

**Omit from a synthetic schema reconstruction by default.** This is a single-record, real-world scholarship seed/update with no DDL, grants, revokes, policies, views, persistent functions, or Resource Center/security definitions. It is useful only when reproducing the application’s seeded content or testing the select-then-insert/update behavior. It must run after a compatible `public.scholarships` schema and applicable access policies exist, and its external URLs and time-sensitive assertions should be treated as fixture content rather than schema requirements.
