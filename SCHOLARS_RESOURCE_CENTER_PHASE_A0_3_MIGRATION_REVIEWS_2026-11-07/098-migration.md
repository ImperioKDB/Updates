# File

`supabase/migrations/0080_add_prompt_action_state.sql`

# Scope

This review covers only migration `0080_add_prompt_action_state.sql` and is based on its contents as inspected. No SQL was executed, no Supabase instance or hosted service was accessed, and the source snapshot was not modified.

# Objects and mutations

The migration performs the following operations:

- Alters the existing `public.profiles` table (lines 3–5).
- Adds nullable `timestamptz` column `pwa_installed_at`, guarded by `if not exists` (line 4).
- Adds nullable `timestamptz` column `push_enable_clicked_at`, also guarded by `if not exists` (line 5).
- Adds a comment to `public.profiles.pwa_installed_at` describing when the account was observed installing Scholars (lines 7–8).
- Adds a comment to `public.profiles.push_enable_clicked_at` describing when the account clicked Enable notifications (lines 9–10).
- Grants the `authenticated` role column-scoped `UPDATE` permission on exactly those two columns of `public.profiles` (lines 14–16).

It does not create or drop tables, columns, indexes, constraints, triggers, policies, functions, types, schemas, roles, or extensions. It does not revoke privileges. It has no `INSERT`, `UPDATE`, or `DELETE` DML against rows; the only `UPDATE` wording is the table privilege grant. It does not alter existing RLS policies, despite relying on them according to the comment.

# Dependencies

The migration must run after an earlier migration or baseline schema has created:

1. The `public` schema and the `public.profiles` table.
2. A `profiles` table structure that accepts two nullable `timestamptz` columns and permits comments on those columns.
3. The predefined Supabase/PostgreSQL role `authenticated`, because the final statement grants privileges to that role.

The SQL type `timestamptz` is built into PostgreSQL and does not require a separately installed extension. No named functions, custom types, sequences, foreign keys, views, or external objects are referenced.

The comments state that existing `profiles` RLS policies constrain writes to `auth.uid() = id` and that the new fields should be available for authenticated self-service (lines 12–13). Those policies and the `auth` context are dependencies/assumptions of the intended security model, but this file neither creates nor verifies them. The grant alone is not an ownership check and does not substitute for RLS; a reconstruction that lacks the stated policies would not reproduce the intended access boundary.

Ordering is straightforward: `profiles` must exist before this migration. Any migration that consumes either new column, or application code that writes prompt-action state, must come after this migration. Because `if not exists` is used independently for both columns, a partially pre-existing schema can make the DDL succeed while still leaving possible type, nullability, or semantic drift that this migration does not validate.

# Data/external-side-effect assessment

This migration contains no real row data and performs no row-level data migration. It inserts, updates, or deletes no records. The two columns are initially `NULL` for existing profiles; nullability is intentional and represents continued eligibility until an action is recorded. No default values or backfill timestamps are introduced.

It contains no external URLs, network calls, webhooks, storage operations, secrets, or references to hosted services. The string literals are only PostgreSQL column comments. The migration's effects are limited to local database metadata, schema shape, and a role privilege.

# Security/ordering implications

The column-scoped grant is narrower than granting update access on the whole `profiles` table: `authenticated` receives `UPDATE` only for `pwa_installed_at` and `push_enable_clicked_at`. This is an intentional least-privilege measure for self-service prompt state. However, effective authorization also depends on the existing RLS policies described in the comments. If those policies are absent, overly broad, disabled, or inconsistent with `auth.uid() = id`, authenticated users could potentially update rows beyond their own account, subject to the database's full privilege/RLS configuration.

The migration does not grant `SELECT`, `INSERT`, or `DELETE`, and it does not grant access to other profile columns. It also does not revoke any pre-existing broader privileges, so a prior broad grant could still dominate the intended restriction. Reviewers reconstructing security behavior should therefore preserve or separately audit the baseline grants and RLS policies.

The DDL is additive and uses `if not exists`, which reduces failure risk when rerun against a schema that already has the columns, but it is not a complete schema validator and can conceal incompatible pre-existing definitions. The comments are metadata only. Execution should be ordered after `profiles` creation and role setup, and before any dependent application migration or code path.

# Reconstruction recommendation

For a synthetic local schema reconstruction, this migration is safe to omit only when prompt-action tracking is explicitly outside the reconstruction's scope and no reconstructed code, query, policy, or test references these two profile columns. Omitting it will make `pwa_installed_at` and `push_enable_clicked_at` unavailable and will not reproduce the column-scoped authenticated update privilege or the documented prompt-action semantics.

For a behaviorally faithful reconstruction, include the two nullable `timestamptz` columns and preserve the scoped `UPDATE` grant, while independently reproducing the intended `profiles` RLS policy (`auth.uid() = id`) and verifying any baseline grants. No data backfill or external integration is needed.

# Verdict

**PARTIALLY VERIFIED** — the file is internally clear and contains only additive schema metadata plus a narrowly scoped grant, with no row data or external side effects. It is not fully verifiable in isolation because it assumes the prior existence of `public.profiles`, the `authenticated` role, and suitable RLS policies that are only referenced in comments and are not defined here. It is safe to omit from a deliberately minimal local reconstruction only if prompt-action state is not required; omission is not safe for a faithful schema or for code that depends on these columns.
