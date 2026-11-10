# File

`/tmp/scholars-a03-snapshot/scholars-41573f5/supabase/migrations/0100_support_opportunity_applications.sql`

# Scope

This review covers only migration `0100_support_opportunity_applications.sql`. The migration changes the shared `public.applications` table so that an application may refer to either a scholarship or an opportunity, and adds uniqueness enforcement for profile/opportunity pairs. The review is strictly static and read-only; no SQL was executed, no Supabase instance or hosted service was accessed, and no snapshot content other than this migration was inspected.

# Objects and mutations

The migration contains DDL only; it contains no `INSERT`, `UPDATE`, `DELETE`, `MERGE`, or other DML statements, and no transaction, function, trigger, view, sequence, policy, role, grant, or revoke statements.

It makes the following schema changes:

1. `ALTER TABLE public.applications ALTER COLUMN scholarship_id DROP NOT NULL` changes `scholarship_id` from mandatory to nullable. This is required to permit opportunity-only applications.
2. `ALTER TABLE public.applications ADD CONSTRAINT applications_one_listing_check CHECK (...)` adds a table constraint requiring exactly one of `scholarship_id` and `opportunity_id` to be non-null. The expression casts each null/non-null test to an integer and requires their sum to equal `1`; therefore, both null and both populated are rejected.
3. `CREATE UNIQUE INDEX IF NOT EXISTS applications_profile_opportunity_unique ON public.applications (profile_id, opportunity_id) WHERE opportunity_id IS NOT NULL` adds conditional uniqueness for each `(profile_id, opportunity_id)` pair among opportunity applications. Scholarship rows are excluded from this uniqueness index because their `opportunity_id` is null. `IF NOT EXISTS` makes creation idempotent with respect to an object of the same index name, but does not guarantee that an existing same-named index has the intended definition.

No grants or revokes are present. The migration does not directly write or delete application data, but PostgreSQL validates the new constraint and builds the unique index against existing rows as part of applying the DDL.

# Dependencies

The migration depends on an already-existing table named `public.applications` with at least these columns:

- `scholarship_id`, currently defined as `NOT NULL` (or otherwise capable of accepting the `DROP NOT NULL` alteration);
- `opportunity_id`, present before the check constraint is added;
- `profile_id`, present before the partial unique index is created.

The referenced columns are used only by the constraint and index; this file does not create them or establish foreign keys. Any foreign keys, types, or tables behind `scholarship_id` and `opportunity_id` must therefore have been established elsewhere and in an earlier ordering position. The migration also assumes the executing role has ownership or sufficient `ALTER TABLE` and `CREATE INDEX` privileges on `public.applications`.

There is no explicit dependency on a particular scholarship or opportunity table in the SQL text, because no foreign key is declared here. There is likewise no dependency on application row values for successful parsing, but existing values matter when PostgreSQL validates the check constraint and unique index during application.

# Data/external-side-effect assessment

The migration contains no embedded real records, seed values, personal data, secrets, or external URLs. It does not call external services, use network resources, or reference files. It does not perform explicit DML.

It does have database-side effects on existing data validation and indexing: adding the check constraint can fail if any existing row has both listing IDs null or both listing IDs populated; creating the partial unique index can fail if duplicate non-null `(profile_id, opportunity_id)` pairs already exist. Dropping `NOT NULL` itself does not rewrite application rows, but it broadens the accepted value set. If the migration succeeds, future writes are constrained by the new check and conditional uniqueness rules.

# Security/ordering implications

No access-control behavior is changed: there are no `GRANT`, `REVOKE`, row-level-security, policy, role, or ownership statements. The migration changes integrity rules rather than authorization rules. The check constraint prevents ambiguous applications that point to zero or two listing types, while the partial unique index prevents one profile from having duplicate applications for the same opportunity. Because the index is partial, it does not impose uniqueness on scholarship applications or on null opportunity IDs.

Ordering is significant. The `applications` table and all three referenced columns must exist before this migration runs, and `opportunity_id` must be present before the constraint is added. The migration should run after any migration that introduces `opportunity_id` and before application writes that rely on opportunity-only rows or on profile/opportunity uniqueness. It should be applied only after existing data has been checked or remediated for the exact-one-listing invariant and duplicate opportunity pairs; otherwise application can fail during constraint/index creation. The file does not provide a cleanup or backfill step, so it is not self-sufficient for a dataset containing invalid or duplicate legacy rows.

The `IF NOT EXISTS` clause reduces repeat-application errors for the index name but can conceal a pre-existing index with a different key, predicate, or uniqueness definition. A reconstruction that depends on exact integrity semantics should verify the existing object rather than treating the clause as proof of equivalence.

# Reconstruction recommendation

For a synthetic schema reconstruction intended to model the shared applications tracker and its opportunity support, retain this migration's resulting schema semantics: make `scholarship_id` nullable, require exactly one of `scholarship_id` and `opportunity_id`, and create the partial unique index on `(profile_id, opportunity_id)` for non-null opportunity IDs. The migration itself can be omitted only if the reconstruction deliberately omits opportunity applications and uses a scholarship-only `applications` model, or if those same resulting constraints are recreated directly in the baseline schema. Omitting it while retaining `opportunity_id` and claiming support for both listing types would materially under-represent the source schema and permit invalid or duplicate rows.

Because this is DDL with no seed data, no external integration, and no access-control configuration, it is generally safe to omit as a historical migration in a clean synthetic build provided its final schema effects are represented where required. It must not be omitted from a faithful reconstruction of opportunity-aware application integrity.

# Verdict

**Conditionally retain; safe to omit only when its final integrity semantics are intentionally reproduced or opportunity support is out of scope.** This migration is a small, data-free schema evolution with no grants, revokes, external URLs, or explicit DML. Its substantive effects are important integrity rules on `public.applications`, and applying it to populated data requires preflight checks for invalid listing references and duplicate profile/opportunity pairs. For an opportunity-aware synthetic schema, preserve the three resulting DDL effects; for a scholarship-only synthetic schema, omission is acceptable and consistent with the reduced scope.
