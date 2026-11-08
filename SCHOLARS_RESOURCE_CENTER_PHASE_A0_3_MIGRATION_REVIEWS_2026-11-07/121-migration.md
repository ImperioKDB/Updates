# File

`/tmp/scholars-a03-snapshot/scholars-41573f5/supabase/migrations/0102_fix_waaw_gender_age_rules.sql`

# Scope

This audit covers only `0102_fix_waaw_gender_age_rules.sql`. The file contains one anonymous PL/pgSQL `DO` block (`$migration$ ... $migration$`) that attempts to restore two eligibility rules for the WAAW Foundation Scholarship 2026/2027. Its stated intent is to repair rules that were documented elsewhere but omitted from `scholarship_rules`.

No other migration was inspected. No SQL was executed, no Supabase instance or hosted service was accessed, and the snapshot was not modified.

# Objects and mutations

## DDL

There is no DDL. The migration does not create, alter, drop, truncate, or otherwise redefine tables, columns, indexes, constraints, functions, triggers, policies, roles, schemas, or extensions.

## DML

The block performs the following reads and conditional writes:

1. It selects one `id` from `public.scholarships` into the local variable `v_scholarship_id`. A row qualifies when either `application_url` exactly equals `https://waawfoundation.org/scholarship/` or `lower(title)` equals `lower('WAAW Foundation Scholarship 2026/2027')`. If multiple rows qualify, `order by created_at desc limit 1` chooses the newest by `created_at`.
2. If no qualifying scholarship is found, it raises the exception `WAAW Foundation Scholarship 2026/2027 was not found`; the block does not proceed to inserts.
3. It checks `public.scholarship_rules` for an existing rule for that scholarship with `field = 'gender'`, `operator = 'eq'`, and JSONB value `"female"`. If none exists, it inserts a row with `gating = true`.
4. It checks for an existing rule with `field = 'age'`, `operator = 'lte'`, and JSONB value `31`. If none exists, it inserts a row with `gating = true`.

The intended writes are therefore up to two `INSERT` operations into `public.scholarship_rules`; there is no `UPDATE` or `DELETE`. The `if not exists` checks make the operation logically idempotent for the exact rule predicates, although the file does not itself establish a unique constraint or otherwise guarantee concurrency-safe deduplication.

# Dependencies

The migration depends on these database objects and capabilities:

- `public.scholarships.id`, selected into a UUID variable.
- `public.scholarships.application_url`, used for the exact URL match.
- `public.scholarships.title`, used through `lower(...)` for a case-insensitive title match.
- `public.scholarships.created_at`, used to select the newest matching scholarship.
- `public.scholarship_rules.scholarship_id`, used for association and existence checks.
- `public.scholarship_rules.field`, `operator`, `value`, and `gating`, used in predicates and inserts.
- PostgreSQL `jsonb` support, because the inserted/checking values are explicitly cast from JSON literals (`'"female"'::jsonb` and `'31'::jsonb`).
- PL/pgSQL anonymous `DO` block support.

The referenced tables and all referenced columns must already exist, and the executing role must have sufficient privileges to read from both tables and insert into `public.scholarship_rules`. The selected scholarship row must have an `id` compatible with UUID. Existing schema defaults, generated values, non-null constraints, foreign keys, check constraints, RLS, and triggers on `public.scholarship_rules` may affect whether the inserts succeed; none of those definitions are present in this file.

# Data/external-side-effect assessment

This is data-bearing migration logic, not schema-only logic. If applied to a populated database, it can mutate real application data by inserting the two WAAW rules. It also deliberately fails when the target scholarship cannot be found, so it is not safe to apply against an empty or differently seeded database without adaptation.

The external URL `https://waawfoundation.org/scholarship/` is only a string literal used for matching the local `application_url` column. The migration does not perform an HTTP request, fetch remote content, validate the URL, or otherwise contact an external service. The title and rule values are similarly hard-coded local data. The comments assert that the female and under-32 rules are verified, but the file itself does not independently verify that claim.

The data selection is potentially ambiguous if duplicate scholarship rows share the URL or case-insensitive title: the newest `created_at` row wins, and ties are not deterministically broken. The exact existence checks also consider only the specified scholarship, field, operator, and value; another row differing in `gating` or other columns would not prevent insertion. The age rule encodes “under 32” as `age <= 31`, which assumes integer/whole-year age semantics in the consuming application.

# Security/ordering implications

There are no explicit `GRANT` or `REVOKE` statements and no role, ownership, RLS-policy, or security-definer changes. Nevertheless, execution requires the migration role to have the necessary table privileges, and row-level security or triggers (if enabled elsewhere) could reject or transform the writes. The block runs transactionally as part of the migration transaction under normal PostgreSQL migration behavior: an exception aborts the transaction, and the inserts do not persist if the migration fails.

Ordering is material. The migration must run after the `public.scholarships` and `public.scholarship_rules` tables and their required columns/types exist, and after the WAAW scholarship data row has been seeded if the migration is expected to succeed. It is not a self-contained seed: it neither creates the scholarship nor creates the rules table. If a prior migration or seed changes the target title, URL, or `created_at` availability, this block can fail or select a different row. Because the `NOT EXISTS` checks are followed by separate inserts and no explicit locking or database-level uniqueness is shown, concurrent application of the same repair could still produce duplicate logical rules unless an external unique constraint prevents them.

# Reconstruction recommendation

For a synthetic schema reconstruction whose goal is only to reproduce database structure, this migration can be omitted: it contains no DDL, grants, revokes, or schema-level dependency that defines the shape of the database.

For a reconstruction intended to reproduce application behavior, representative seeded data, or migration-history semantics, preserve it or model its effect explicitly by seeding a matching WAAW scholarship and the two `gating = true` rules. Do not blindly replay it against an empty synthetic database, because it intentionally raises an exception when no matching scholarship exists. If replayability is required, adapt the data-loading order and consider deterministic targeting and a uniqueness strategy outside this file.

# Verdict

**Omit from synthetic schema reconstruction; retain only for data/behavioral fidelity.** This is a narrowly targeted, conditionally idempotent DML repair with no DDL, grants, revokes, or external network side effects. It has a real-data mutation and a required dependency on an already-seeded matching scholarship, so omitting it is appropriate for schema-only reconstruction but would omit the WAAW eligibility behavior from a data-faithful reconstruction.
