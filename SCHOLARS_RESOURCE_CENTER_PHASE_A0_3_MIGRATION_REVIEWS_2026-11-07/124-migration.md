# File

`/tmp/scholars-a03-snapshot/scholars-41573f5/supabase/migrations/0103_seed_scholarshipair_10277_10287_2026.sql`

This review is a static, read-only inspection of this file only. No SQL was executed, no Supabase instance or hosted service was started or accessed, and the snapshot was not modified. No other migration was inspected.

# Scope

The file contains one anonymous PL/pgSQL block, delimited by `do $migration$ ... $migration$;`. Its stated purpose is to publish two user-supplied ScholarshipAir listings after verification:

1. A Fisayo Soyombo essay contest, stored in `public.opportunities`.
2. An M. Kukoyi Foundation scholarship, stored in `public.scholarships`.

The block attempts an application-like upsert by selecting an existing row, then inserting when no match is found or updating the selected row when a match exists. The matching logic is implemented in the block itself rather than through an explicit `INSERT ... ON CONFLICT` clause.

# Objects and mutations

## DDL

No DDL statements are present. The file does not create, alter, drop, truncate, or rename schemas, tables, columns, indexes, sequences, types, views, functions, triggers, policies, roles, or extensions.

## DML and procedural operations

The block declares two local UUID variables:

- `v_opportunity_id uuid`
- `v_scholarship_id uuid`

It uses `SELECT ... INTO`, conditional branching, `INSERT`, `UPDATE`, and `RETURNING`:

### `public.opportunities`

- Reads one `id` from `public.opportunities` into `v_opportunity_id`.
- Match predicate: `lower(title)` equals one of three case-insensitive titles:
  - `Fisayo Soyombo Essay Contest for Undergraduates 2026`
  - `Fisayo Soyombo Inter-Varsity Essay Competition 2026`
  - `9th Annual Fisayo Soyombo Inter-Varsity Essay Competition`
- Resolution: `ORDER BY created_at DESC LIMIT 1`; if multiple matching rows exist, the newest by `created_at` is selected. Ties are not deterministically broken by a unique secondary key.
- If no row is selected, inserts one row with fields `type`, `title`, `provider_name`, `description`, `eligibility_notes`, `duration`, `location`, `compensation`, `discipline`, `deadline`, `opens_at`, `application_url`, `how_to_apply`, `verified`, and `research_notes`.
- If a row is selected, updates that row by `id` and overwrites the same substantive fields. The update does not set `created_at` or explicitly update an `updated_at` column.
- The insert uses `RETURNING id INTO v_opportunity_id`, but the returned value is not used later in the block.

The inserted or updated opportunity is a competition with deadline `2026-11-22`, `verified = true`, `application_url = null`, and email-based instructions in `how_to_apply`.

### `public.scholarships`

- Reads one `id` from `public.scholarships` into `v_scholarship_id`.
- Match predicate: exact application URL equals the supplied Google Forms URL, or case-insensitive title equals `M. Kukoyi Foundation (MKF) Scholarship 2026`.
- Resolution: `ORDER BY created_at DESC LIMIT 1`; if multiple matching rows exist, the newest by `created_at` is selected. Ties are not deterministically broken by a unique secondary key.
- If no row is selected, inserts one row with `title`, `provider_name`, `description`, `amount`, `deadline`, `application_url`, `level`, `discipline`, `verified`, `research_notes`, `how_to_apply`, and `last_verified_at`.
- If a row is selected, updates that row by `id` and overwrites those fields, including `last_verified_at = now()`.
- The insert also sets `last_verified_at = now()`.
- The insert uses `RETURNING id INTO v_scholarship_id`, but the returned value is not used later in the block.

The inserted or updated scholarship has deadline `2026-11-22`, `verified = true`, `level = 'undergrad'`, a Google Forms application URL, and a one-time tuition award capped at ₦300,000.

## Grants and revokes

No `GRANT` or `REVOKE` statements are present. The migration does not change object privileges, role membership, row-level-security enablement, or policy definitions.

## Security/resource-center object inventory

Within this file, the inventory is empty: there are no `CREATE POLICY`, `ALTER POLICY`, `DROP POLICY`, `CREATE VIEW`, `CREATE FUNCTION`, `CREATE TRIGGER`, privilege, or explicit security/resource-center statements. Consequently, this file itself does not define or mutate a final security or Resource Center migration object. Because the requested audit is restricted to this one migration, objects from any other migration—including any “final two security/Resource Center migrations”—cannot be mapped here without violating the scope restriction. No claim about their runtime behavior or existence is made.

# Dependencies

The block depends on the following database objects and capabilities, inferred from textual references only:

- Schema `public`.
- Table `public.opportunities`, including at least the columns `id`, `title`, `created_at`, `type`, `provider_name`, `description`, `eligibility_notes`, `duration`, `location`, `compensation`, `discipline`, `deadline`, `opens_at`, `application_url`, `how_to_apply`, `verified`, and `research_notes`.
- Table `public.scholarships`, including at least the columns `id`, `title`, `created_at`, `provider_name`, `description`, `amount`, `deadline`, `application_url`, `level`, `discipline`, `verified`, `research_notes`, `how_to_apply`, and `last_verified_at`.
- A UUID-compatible `id` type in both tables, or at minimum values assignable to the declared local UUID variables.
- PostgreSQL/PL/pgSQL anonymous-block support for `DO`, local variable declaration, `SELECT ... INTO`, `IF ... THEN ... ELSE`, and `RETURNING ... INTO`.
- The built-in `lower(text)` function and `now()` function, plus type coercions compatible with the compared and assigned column values.
- Sufficient permissions for the executing migration identity to select from and insert/update both tables. Actual grants, ownership, RLS state, and policy outcomes are not verifiable from this file.
- Any table-level defaults, generated values, triggers, check constraints, foreign keys, or other schema rules on the referenced tables may affect whether the writes succeed; their definitions are not in this file and were not inspected.

The second block runs after the first within the same anonymous block. It does not use the first inserted/selected ID, so there is no direct object-level dependency between the two seed records. The apparent ordering dependency is only that each table and its referenced columns must already exist before this migration runs.

# Data/external-side-effect assessment

This is DML containing real-looking, user-supplied opportunity and scholarship content rather than synthetic schema-only metadata. It writes two substantive records, including provider names, eligibility rules, award amounts, dates, application instructions, verification flags, and research notes.

The content embeds external URLs as data:

- `https://www.scholarshipair.com/s/10277` in the opportunity `research_notes`.
- `https://www.scholarshipair.com/s/10287` in the scholarship `research_notes`.
- `https://docs.google.com/forms/d/e/1FAIpQLSdBIS_G50LSI211HmPOXUFZG1UMtSgnzUZmpe47tVUuT4ufvQ/viewform` in the scholarship `application_url` and `research_notes`.

The opportunity intentionally has `application_url = null`; its `how_to_apply` text includes the email address `ucjunibadan@gmail.com`. The scholarship `how_to_apply` text directs applicants to the Google Form. These are stored strings only: this migration does not perform HTTP requests, open a browser, submit a form, send email, or otherwise contact an external service.

The migration uses `now()` for the scholarship `last_verified_at` on both insert and update. Therefore the resulting value is execution-time data and is not fully deterministic for a synthetic reconstruction. It also sets both records to `verified = true`, which is a meaningful data-state assertion rather than schema structure.

The upsert-like logic is not concurrency-safe based on the text alone: two concurrent executions could both observe no match and attempt inserts unless an unseen unique constraint, transaction serialization, or other database mechanism prevents duplication. No runtime verification was performed. Existing-row updates can also overwrite manually changed content on the selected newest matching row.

# Security/ordering implications

No security objects or privilege mutations are defined by this migration. It neither enables/disables RLS nor creates, alters, or drops policies. The effective ability to run the writes depends on pre-existing grants, ownership, RLS configuration, and policies on `public.opportunities` and `public.scholarships`; those cannot be determined from this file alone.

The migration must run after the two target tables and all referenced columns exist. It may also need to run after any required enum/type definitions, defaults, or supporting schema constraints used by those columns. Since the file supplies `type = 'competition'` and `level = 'undergrad'`, those columns must accept those values; whether they are text, enum, or constrained values is not visible here.

The two table operations are sequential within one anonymous block. A failure in either branch would cause the block statement to fail according to normal PostgreSQL statement/transaction semantics, but this audit does not claim runtime verification. There is no explicit exception handler, savepoint, lock, deterministic tie-breaker, or conflict clause.

The selection predicates are broader than a single canonical key for the opportunity (three title aliases) and combine URL/title matching for the scholarship. `ORDER BY created_at DESC LIMIT 1` can select an arbitrary row when timestamps tie. The subsequent update by ID limits the mutation to that selected row, but it does not remove any duplicate rows that may already exist.

Because this file contains no final security/Resource Center definitions, it cannot establish whether a later or earlier security migration depends on these records, exposes them through a view, or applies policies to them. Such relationships would require inspecting other migrations or live catalog state, both outside this audit's permitted scope.

# Reconstruction recommendation

For a synthetic schema reconstruction, this migration can generally be omitted if the goal is only to recreate database structure, because it contains no DDL and defines no schema object, privilege, policy, view, function, trigger, or constraint.

It should not be omitted if the reconstruction is intended to reproduce the seeded application dataset, verified listings, external application links, or the exact post-migration content state. In that case, preserve it as optional fixture/seed data rather than treating it as schema definition. If replayability is important, consider separately normalizing the time-dependent `now()` value and addressing concurrency/uniqueness behavior—but those would be reconstruction design changes, not properties verified by this file.

No security or Resource Center migration should be inferred or synthesized from this file. In particular, omission of this file does not justify omitting any security objects that might exist elsewhere; conversely, this file provides no evidence that such objects exist.

# Verdict

**Mutation class:** data seed/upsert (DML only), with real-content and external-URL strings; no DDL, grants, revokes, or security-object definitions.

**Verdict:** Omissible from a synthetic schema-only reconstruction, subject to preserving its table/column prerequisites and any separately audited security migrations. Not omissible from a data-fixture reconstruction that must include the two verified ScholarshipAir-derived listings. Static review only; no runtime, hosted-service, permission, RLS, constraint, or external-URL verification was performed.
