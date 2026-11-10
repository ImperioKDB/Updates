# File

`/tmp/scholars-a03-snapshot/scholars-41573f5/supabase/migrations/0081_seed_fajim_scholarship_2026_2027.sql`

# Scope

This is a strictly read-only, static review of the one specified migration file only. No SQL was executed, no Supabase instance or hosted service was contacted, and the source snapshot was not modified. Because earlier migrations were not inspected, dependency conclusions below are derived from object names and SQL usage in this file rather than verified against the complete schema history.

# Objects and mutations

The file contains one anonymous PostgreSQL `DO` block (`$migration$`) with a local UUID variable, `v_scholarship_id`.

It does **not** create or alter tables, indexes, types, functions, triggers, policies, extensions, schemas, roles, or privileges. It contains no `GRANT` or `REVOKE`, and it does not explicitly delete or update rows.

Its data mutations are:

1. It checks `public.scholarships` for an existing row whose `application_url` exactly equals the supplied Google Forms URL.
2. Only when no such row exists, it inserts one row into `public.scholarships`, returning the inserted `id` into `v_scholarship_id`.
3. It then inserts six rows into `public.scholarship_rules` for that new scholarship. The rules cover Nigerian nationality, year 200, one of seven healthcare disciplines, GPA at least 5.0, financial need, and federal/state university institution type.
4. If the URL match already exists, the block performs no insert into either table. This is an application-level idempotency guard, not a demonstrated database uniqueness constraint.

The block uses `now()` for `last_verified_at`; therefore, a fresh execution produces time-dependent data. The guard is based only on `application_url`, so it does not reconcile or update an existing row with the same URL if any other field has changed.

# Dependencies

The migration requires the following earlier schema objects and capabilities, inferred from its statements:

- Schema `public`.
- Table `public.scholarships` with at least the referenced columns: `application_url`, `id`, `title`, `provider_name`, `description`, `amount`, `deadline`, `level`, `discipline`, `verified`, `research_notes`, `how_to_apply`, `opens_at`, and `last_verified_at`.
- Table `public.scholarship_rules` with writable columns `scholarship_id`, `field`, `operator`, and `value`.
- A UUID-compatible `scholarships.id` and a compatible `scholarship_rules.scholarship_id` foreign-key/reference type, because the returned ID is stored in the local UUID variable and passed to the rules insert.
- A `value` column in `scholarship_rules` accepting JSONB, since the values use JSONB casts and JSON arrays/booleans/numbers.
- Column types accepting the supplied text, boolean, date-like strings, timestamp expression, and JSONB values. The exact constraints, defaults, nullability, foreign keys, RLS policies, and triggers cannot be verified from this file.
- PostgreSQL procedural-language support for an anonymous `DO` block and the built-in `now()` function. No non-core extension is explicitly referenced.
- The migration runner’s database role must have permission to read `public.scholarships` and insert into both tables; if row-level security is enabled, applicable policies must also permit these operations. No role or privilege setup is included here.

There are no explicit references to earlier migration filenames, custom functions, extensions, roles, or external APIs. The source ordering dependency is nevertheless significant: the two tables and all referenced columns must already exist before this migration runs.

# Data/external-side-effect assessment

This is a real-data seed, not synthetic placeholder DDL. If the guard does not match an existing URL, it persists one scholarship record and six associated rule records. The record contains a provider name, eligibility and application instructions, a deadline, verification timestamp, and detailed research notes.

The file embeds external URLs as data, including:

- A Google Forms application URL: `https://docs.google.com/forms/d/e/1FAIpQLSfQI0lLkaDkBhruftNHxkSXhvqtibLFpl1Eef9y7od2KqZirg/viewform`
- The provider page: `https://fajimmf.org.ng/home/scholarship/`

The SQL itself does not fetch, validate, or call either URL; the URLs are only stored in inserted text. The comments and text state that the information was checked against those sources on 2026-10-09, but that claim is content embedded in the migration and was not independently verified during this audit. The form text also states that applicant Google account email is recorded and that applying does not guarantee an award; these are descriptive notes, not application processing performed by the migration.

The exact supplied content includes a 2026-10-11 deadline and a `now()`-generated verification timestamp, so replaying the migration later can preserve stale deadline information while changing the verification timestamp only if a new row is inserted.

# Security/ordering implications

The migration is conditionally idempotent only with respect to an exact `application_url` value. Concurrent executions could both observe no matching row and attempt duplicate inserts unless a unique constraint or equivalent concurrency protection exists. That constraint is not established here. The follow-on rules insert is tied to the freshly returned scholarship ID, so within a successful execution the rules target the inserted row.

The anonymous block is a single PostgreSQL statement and normally rolls back as a unit if an error aborts the statement, but this does not eliminate risks from triggers, policies, or pre-existing constraints. There is no explicit transaction, lock, conflict clause, or exception handler.

Security depends on the migration runner role and any RLS configuration. The migration neither grants nor revokes access and cannot be assumed to configure public visibility or protect sensitive fields. The persisted research notes mention that an external form records applicant email, but this migration does not insert applicant data.

Ordering is mandatory: the `scholarships` and `scholarship_rules` tables, their referenced columns, and any required UUID/JSONB-compatible definitions must precede this migration. Running it before those objects exist will fail. Running it after them but before required permissions or RLS policies are established may also fail or insert no rows, depending on policy behavior.

# Reconstruction recommendation

For a synthetic local schema reconstruction, this migration is safe to **omit** when the goal is structural fidelity rather than reproducing production catalog content. It contributes no schema objects, constraints, permissions, or extension setup; it is an optional, domain-specific seed for one time-bounded scholarship and its eligibility rules. The reconstruction should instead create the prerequisite tables and columns from the authoritative schema migrations, if those are being recreated.

If the local reconstruction intentionally needs representative scholarship data, the seed can be replayed only after independently recreating and checking the prerequisite schema, permissions, constraints, and RLS behavior. Consider replacing the live external URLs and time-sensitive facts with clearly synthetic fixtures in a non-production dataset. Do not treat omission as safe if downstream tests explicitly require the FAJIM record or its six rules.

# Verdict

**Status: PARTIALLY VERIFIED.** The file’s direct SQL behavior is clear from static inspection, but the prerequisite schema, constraints, roles, privileges, and RLS policies were not inspected because the audit was restricted to this one migration.

**Execution verdict: NOT SAFE TO EXECUTE in the current audit context.** It performs real inserts, depends on unverified earlier schema and permissions, contains time-sensitive externally sourced content, and lacks an explicit conflict-safe uniqueness strategy. It is reasonable to omit from a synthetic local schema reconstruction unless the specific seed data is a stated requirement.
