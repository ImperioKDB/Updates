# File

`supabase/migrations/0076_seed_prince_ukeme_ukpong_scholarship_2026.sql`

**Audit scope:** Strictly read-only review of this file's text. No SQL was executed, no Supabase instance or hosted service was accessed, and no other migration was inspected.

# Scope

This file is a data-seeding migration for the 2026 Prince Ukeme Ukpong Mega Foundation tertiary scholarship. It wraps its work in an anonymous PostgreSQL `DO $$ ... $$` block, checks whether a row already exists by an exact `application_url`, and conditionally inserts the scholarship and its eligibility rules. It does not define or alter schema.

# Objects and mutations

- **Anonymous block:** Executes procedural PostgreSQL code and declares a local UUID variable, `v_scholarship_id`.
- **Read:** Selects from `public.scholarships` to test whether a row already has the exact Google Forms URL.
- **Insert into `public.scholarships`:** If no matching URL exists, inserts one row with values for title, provider, description, amount text, deadline, application URL, level, discipline, verification flag, research notes, application instructions, opening date, and `last_verified_at`.
- **Generated/returned value:** Captures the inserted row's returned `id` into `v_scholarship_id`; this implies the `id` column is UUID-compatible and generated or otherwise populated by the table/default/trigger.
- **Insert into `public.scholarship_rules`:** Inserts three rows linked to the new scholarship ID:
  1. nationality equals `"Nigerian"`;
  2. state of origin equals `"Akwa Ibom"`;
  3. institution type is in the JSON array `federal_uni`, `state_uni`, `private_uni`, `polytechnic`, `college_of_education`.
- **No DDL:** No `CREATE`, `ALTER`, `DROP`, or extension changes.
- **No privilege changes:** No `GRANT` or `REVOKE`.
- **No other mutations:** No `UPDATE` or `DELETE` statements.

The block is conditionally idempotent only with respect to the exact application URL. If a matching scholarship already exists, the entire body is skipped, including rule insertion. Conversely, two concurrent executions could both pass the existence check unless a suitable unique constraint and/or conflict-handling policy exists.

# Dependencies

The file depends on earlier or pre-existing database objects that are not defined here:

- `public.scholarships` table.
- `public.scholarships.application_url`, used in the existence predicate.
- Insertable columns on `public.scholarships`: `title`, `provider_name`, `description`, `amount`, `deadline`, `application_url`, `level`, `discipline`, `verified`, `research_notes`, `how_to_apply`, `opens_at`, and `last_verified_at`.
- A returned `public.scholarships.id` column whose type is compatible with the declared `uuid` variable, and whose value is available after insert (normally via a default or trigger).
- `public.scholarship_rules` table.
- Insertable `public.scholarship_rules` columns: `scholarship_id`, `field`, `operator`, and `value`.
- A foreign-key-compatible relationship from `scholarship_rules.scholarship_id` to the scholarship ID, if such a constraint exists.
- PostgreSQL procedural-language support for `DO` blocks (normally PL/pgSQL, ordinarily installed by default in PostgreSQL), plus ordinary PostgreSQL `jsonb` casts and `now()`.

Because the audit is restricted to this file, the existence, exact types, nullability, defaults, constraints, triggers, RLS policies, and availability/order of these objects cannot be verified against the earlier schema. No custom extension, role, function, or hosted-service dependency is explicitly named. `now()` is a built-in PostgreSQL function, and the `jsonb` casts use a built-in type.

# Data/external-side-effect assessment

This is real seed data rather than placeholder-only data. It creates a scholarship listing and three structured eligibility rules if the URL is not already present. The values include a dated deadline (`2026-11-04`), opening date (`2026-10-04`), provider and eligibility claims, and a verification flag set to `true`.

The migration contains external URLs as data, not as executable network calls:

- A Google Forms application URL used as the deduplication key and stored application URL.
- A TinyURL reference in `research_notes`.
- A Facebook announcement URL in `research_notes`.
- A ScholarshipAir reference URL in `research_notes`.

The SQL does not fetch, validate, redirect through, or otherwise contact any of these URLs. It also does not send notifications, call webhooks, write files, or access external services. `last_verified_at` uses database execution time via `now()`, so replaying after the stated research date can produce a different timestamp if the row is newly inserted.

# Security/ordering implications

- **Ordering:** This migration must run after the creation of both referenced tables and all required columns, and after any prerequisite UUID/default/trigger setup. It should also run after any required enum or check-constraint definitions for values such as `undergrad`, if those columns are constrained.
- **Foreign keys:** `scholarship_rules` must accept the newly returned scholarship ID. If the rules table or its foreign key is absent, the block fails at the second insert.
- **RLS/privileges:** If row-level security is enabled, the migration execution role must be permitted to select the deduplication row and insert into both tables. Migration-time privileges and policies are not established by this file.
- **Uniqueness/race behavior:** The existence check is not a complete concurrency-safe upsert. A unique constraint on `application_url` may turn a concurrent race into a unique-violation failure; without one, duplicate rows are possible. The URL comparison is exact, so equivalent URLs with different formatting would not deduplicate.
- **Partial-repeat behavior:** If the scholarship URL already exists, no rules are added or repaired. If the scholarship insert succeeds but the rules insert fails, PostgreSQL normally rolls back the encompassing `DO` statement/transaction, but behavior still depends on the migration runner's transaction handling.
- **Trust/data quality:** The inserted content marks the listing as verified and embeds claims in free-text research notes. This is a data-integrity consideration, not an external execution risk; downstream consumers may display the external links and the deadline without further validation.
- **Security posture:** No dynamic SQL, user-supplied parameters, privilege escalation, destructive operation, or secret is present. The external URLs are ordinary string literals. Execution is therefore low risk in a correctly initialized schema, but cannot be certified safe in isolation because schema, RLS, and constraint assumptions were not inspected.

# Reconstruction recommendation

For a **synthetic local schema reconstruction whose goal is structure, relationships, and application behavior**, this migration is safe to omit: it adds no tables, columns, policies, functions, roles, or extensions. Omitting it will lose one realistic scholarship fixture and its three rule fixtures, so it should be retained or replaced with equivalent seed data when tests, demos, search results, or eligibility-rule behavior require representative content.

For a **data-faithful reconstruction**, do not silently omit it. Recreate the scholarship row and rules only after confirming the target schema's column types, defaults, constraints, and RLS behavior. If replaying, consider a uniqueness-safe upsert strategy and decide whether the historical verification timestamp should be preserved instead of recalculated with `now()`.

# Verdict

**PARTIALLY VERIFIED — safe to omit for schema-only reconstruction; not certified safe to execute blindly.**

The file is a non-destructive, conditional content seed with no schema or privilege changes and no network side effects. Its execution safety is conditional on earlier schema objects, compatible types/constraints, migration-role permissions, and ordering that cannot be verified while respecting the one-file audit restriction. It is not a required migration for reproducing the synthetic schema, but omitting it intentionally discards this scholarship fixture and its eligibility rules.
