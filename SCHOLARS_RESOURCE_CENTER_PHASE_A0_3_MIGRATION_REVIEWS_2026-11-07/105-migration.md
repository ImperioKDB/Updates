# File

`/tmp/scholars-a03-snapshot/scholars-41573f5/supabase/migrations/0087_seed_oyo_state_2025_2026_bursary.sql`

This review covers only the specified migration file. No other migration was inspected, and no SQL was executed.

# Scope

The file is a data-seeding and data-refresh migration for one Oyo State bursary record and two associated scholarship eligibility rules. It contains a PL/pgSQL anonymous `DO` block (`$migration$`) that:

1. Looks up one existing row in `public.scholarships` by either the official application URL or a case-insensitive title match.
2. Inserts a scholarship row if no match is found, or updates the selected row if a match exists.
3. Conditionally inserts two rows into `public.scholarship_rules` for Oyo state of origin and permitted institution types.

There is no schema definition, table creation, column alteration, index creation, function creation, trigger creation, policy definition, role/grant change, or revoke statement in this file.

# Objects and mutations

## DDL

No DDL is present. The migration does not create or alter database objects.

## DML

The anonymous block declares a UUID variable, `v_id`, and performs the following mutations:

- `SELECT ... INTO v_id` from `public.scholarships`, matching `application_url = 'https://app.bursary.oyostate.gov.ng/bursary/apply'` or `lower(title) = lower('Oyo State Scholarship Bursary Award 2026')`, ordered by `created_at DESC`, limited to one row.
- If no row is found, `INSERT INTO public.scholarships` with the title, provider, long-form description, amount text, deadline, application URL, level, discipline, verification flag, research notes, application instructions, `opens_at = NULL`, and `last_verified_at = now()`. The inserted UUID is returned into `v_id`.
- If a row is found, `UPDATE public.scholarships` by that UUID, replacing the same content fields and setting `opens_at = NULL` and `last_verified_at = now()`.
- If a matching `public.scholarship_rules` row does not exist, `INSERT` a gating rule for `field = 'state_of_origin'`, `operator = 'eq'`, and JSONB value `"Oyo"`.
- If a matching rule does not exist, `INSERT` a gating rule for `field = 'institution_type'`, `operator = 'in'`, and JSONB value `["federal_uni", "state_uni", "polytechnic", "college_of_education"]`.

The two rule checks are narrowly idempotent for the exact scholarship ID, field, operator, and JSONB value. The scholarship selection/update is not fully deterministic in all duplicate-data situations because it selects the newest matching row rather than enforcing uniqueness or reconciling all matches.

## Grants and revokes

No `GRANT`, `REVOKE`, ownership change, role change, or RLS/policy statement is present.

# Dependencies

The migration requires the following pre-existing database objects and column/type behavior, as inferred from its references:

- `public.scholarships` table.
- `public.scholarships.id`, usable as a UUID and assignable to the local `v_id UUID` variable.
- `public.scholarships.application_url`, `title`, and `created_at` for lookup.
- Writable scholarship columns: `title`, `provider_name`, `description`, `amount`, `deadline`, `application_url`, `level`, `discipline`, `verified`, `research_notes`, `how_to_apply`, `opens_at`, and `last_verified_at`.
- A compatible `scholarships.id` return value for `INSERT ... RETURNING id`.
- `public.scholarship_rules` table.
- `public.scholarship_rules.scholarship_id`, `field`, `operator`, `value`, and `gating` columns; `value` must accept JSONB values.
- PostgreSQL PL/pgSQL anonymous `DO` block support and the `lower`, `now`, and JSONB cast behavior used by the statements.

The file itself does not establish whether these tables, columns, constraints, defaults, foreign keys, indexes, or row-level-security policies exist; those must be supplied by the surrounding schema. The rule inserts implicitly depend on `scholarship_rules.scholarship_id` accepting the selected scholarship ID, typically through a compatible type and possibly a foreign key. The lookup's `ORDER BY created_at DESC` also assumes `created_at` exists and is orderable.

The migration uses a fixed deadline date (`2026-11-02`) and sets `last_verified_at` from database `now()`, so repeat application changes that timestamp even when the substantive values are unchanged.

# Data/external-side-effect assessment

This migration embeds real-world program content rather than synthetic placeholder data. It names the Oyo State Scholarship Board, describes eligibility and exclusions, records a fixed bursary deadline, and includes detailed application instructions. It contains external URLs in the application URL and research notes, including the official Oyo State bursary page, official application form, and a ScholarshipAir listing.

The file does not issue HTTP requests, invoke an extension, call a foreign data wrapper, submit an application, or write to any external service. The comments and research notes state that the official page/form were checked on 2026-10-15, and the text says no applicant data were entered or submitted; those are stored content assertions, not executable verification. The only runtime-generated value is `now()` for `last_verified_at`.

The inserted/updated content includes personal-eligibility and document requirements, but no applicant records, credentials, application numbers, or other person-specific data are inserted. The external URLs are still operational dependencies for users and may become stale or change behavior independently of the database.

# Security/ordering implications

The block performs privileged-looking writes to public tables, but it does not itself grant privileges or bypass RLS explicitly. Whether it can run under migration ownership and whether RLS applies depends on the migration execution context and surrounding database configuration. The report cannot infer those settings from this file alone.

The scholarship lookup uses an `OR` between URL and case-insensitive title and then selects the most recently created match. If multiple rows match either predicate, only the newest row is updated; older duplicates remain. If uniqueness constraints are absent, concurrent or repeated execution could still produce duplicate scholarship rows between the lookup and insert. The two rule `IF NOT EXISTS` checks likewise are race-prone without a suitable unique constraint or equivalent protection: concurrent executions could attempt duplicate rule inserts.

The rule existence checks compare exact JSONB values and exact field/operator combinations. Semantically equivalent but differently represented values would not be treated as matches. The rules are marked `gating = true`, so inserting them may cause downstream eligibility filtering to restrict applicants to Oyo indigenes and the listed institution types, assuming application code honors these rules.

The scholarship row is explicitly set to `opens_at = NULL` while retaining a past/fixed deadline. The migration does not set an explicit publication/status field, does not validate that the external portal is available, and does not encode all narrative eligibility constraints as rules (for example final-year status, FOSSU membership, law exclusion, public-only nuance beyond institution types, part-time exclusion, or overseas exclusion). Those remain in descriptive text/manual checks.

Ordering-wise, the scholarship row must be inserted or selected before the rule rows can be inserted because `v_id` is used as their foreign-key reference. Within the block this order is explicit. If the migration is run in the normal migration transaction, its changes are expected to commit together; the file itself does not contain explicit `BEGIN`, `COMMIT`, or rollback handling.

# Reconstruction recommendation

For a synthetic schema reconstruction, this migration can generally be omitted if the objective is to reproduce table structure, constraints, policies, and generic application behavior rather than production seed content. It contains no DDL and therefore contributes no schema objects.

If the reconstruction needs representative seed data or must exercise scholarship-rule evaluation, preserve only a synthetic equivalent: one generic scholarship row and two non-sensitive rules with the same shape. Replace the real Oyo State narrative, operational URLs, fixed real-world deadline, and research provenance with clearly synthetic fixtures, or omit the data entirely. Do not treat this file as a substitute for reconstructing the base table definitions or rule semantics, which it assumes rather than defines.

If the goal is behavioral fidelity to the production dataset, the migration is relevant and should be replayed only after its referenced tables and columns exist, with review of uniqueness/foreign-key/RLS behavior. Such replay would import time-sensitive real-world content and should not be used casually in a test environment.

# Verdict

**Omit from a synthetic schema reconstruction.** This is a real-data DML seed/update migration with external URLs and time-sensitive bursary content, not a schema migration. Retain a sanitized synthetic fixture only if tests require scholarship upsert behavior or rule evaluation. No grants, revokes, external service calls, or DDL are present; the main operational concerns are dependency on pre-existing public tables, duplicate-selection/concurrency behavior, `now()` nondeterminism, and the security/eligibility effects of the two gating rules.
