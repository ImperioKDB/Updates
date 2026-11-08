# File

`/tmp/scholars-a03-snapshot/scholars-41573f5/supabase/migrations/0078_add_web_push_subscriptions.sql`

This review is limited to this migration file only. No SQL was executed, no Supabase instance or hosted service was accessed, and the source snapshot was not modified.

# Scope

The migration adds storage and row-level access control for browser Web Push subscriptions. Its stated intent is to store subscriptions per account, let an authenticated account owner manage only that account's devices, and remove subscriptions automatically when the referenced account is deleted. The comment explicitly says existing Expo `push_tokens` remain unchanged.

The file contains DDL and privilege/policy statements only. It does not contain seed or application data operations.

# Objects and mutations

- Creates `public.web_push_subscriptions` if it does not already exist.
  - `id uuid PRIMARY KEY`, defaulting to `gen_random_uuid()`.
  - `profile_id uuid NOT NULL`, with a foreign key to `public.profiles(id)` and `ON DELETE CASCADE`.
  - `endpoint text NOT NULL`, constrained by `CHECK (endpoint LIKE 'https://%')`.
  - Required Web Push key material fields `p256dh text NOT NULL` and `auth text NOT NULL`.
  - `enabled boolean NOT NULL DEFAULT true`.
  - `last_seen_at` and `created_at` as non-null `timestamptz` values defaulting to `now()`.
  - `updated_at` as a non-null `timestamptz` defaulting to `now()`; the migration does not create a trigger or other automatic update mechanism for it.
  - A table-level uniqueness constraint on `(profile_id, endpoint)`.
- Creates `public.idx_web_push_subscriptions_profile_enabled` if absent. It indexes `(profile_id, last_seen_at DESC)` and is partial, covering only rows where `enabled = true`. The index name is supplied explicitly and is schema-qualified through its table reference.
- Enables row-level security on `public.web_push_subscriptions`.
- Grants `SELECT`, `INSERT`, `UPDATE`, and `DELETE` on the table to the `authenticated` role.
- Drops and recreates four named policies, making reruns replace policy definitions rather than leave stale definitions:
  - `web_push_subscriptions_select_own`: authenticated users may select rows where `auth.uid() = profile_id`.
  - `web_push_subscriptions_insert_own`: authenticated users may insert only rows whose `profile_id` equals `auth.uid()`.
  - `web_push_subscriptions_update_own`: authenticated users may update only their own rows, and the resulting row must still have their own `profile_id`.
  - `web_push_subscriptions_delete_own`: authenticated users may delete only their own rows.

There are no `ALTER TABLE` column changes, `DROP TABLE`, `REVOKE`, `INSERT`, `UPDATE`, or `DELETE` data statements in the file. The only `DROP` statements are conditional policy drops used before policy recreation.

# Dependencies

The migration depends on the following earlier schema/runtime objects or platform conventions:

1. `public.profiles` must exist with an `id` column compatible with `uuid`; the foreign key cannot be created otherwise. The cascade behavior assumes that deleting a profile should delete its browser subscriptions.
2. `gen_random_uuid()` must be available and executable in the database. In common PostgreSQL/Supabase setups this is provided by the `pgcrypto` extension (or by the relevant PostgreSQL version's built-in function support). This file does not create or verify that extension.
3. The `authenticated` database role must exist. The explicit grant and all four policies target that role.
4. `auth.uid()` must exist and return a value comparable to `profile_id` (normally a UUID). This is a Supabase authentication helper, not defined by this migration.
5. The `public` schema must exist, and the executing migration role must have permission to create the table/index, alter RLS, grant privileges, and create/drop policies.
6. Any application code using this feature may additionally assume the named table, columns, uniqueness rule, and policy behavior. Those application dependencies are not proven by this file.

Because only this migration was inspected, the existence, exact types, ownership, grants, and prior definitions of those dependencies are not independently verified here. No dependency on an earlier migration number is stated in the file itself.

# Data/external-side-effect assessment

The migration creates an empty table and an empty index; it does not insert, update, or delete rows. It does not include seed data, embedded credentials, tokens, keys, or other real data values. The column names `p256dh` and `auth` describe Web Push subscription key material, but no key material is supplied by the migration.

There are no external URLs or network calls. The string `https://%` is only a local CHECK constraint requiring stored endpoint values to begin with `https://`; it is not an external destination accessed during migration. `gen_random_uuid()` and `now()` are local database defaults.

The migration can nevertheless have database-side effects when executed: it changes schema, privileges, RLS state, policy definitions, and future delete behavior through the foreign key cascade. It does not alter existing Expo `push_tokens`, as stated in the comment and reflected by the absence of any statement targeting that object.

# Security/ordering implications

RLS is enabled before the policies are installed, while the table privileges are granted to `authenticated`. The policy set is owner-scoped for all four CRUD operations, and the update policy protects against changing `profile_id` to another user's identity. The `CHECK` constraint limits endpoints to HTTPS-looking values, but it does not validate a complete URL, host, subscription protocol details, or the cryptographic contents of `p256dh` and `auth`.

The migration does not grant access to `anon`, does not define a service-role policy, and does not revoke any pre-existing privileges. Table owners and elevated/service roles can generally bypass RLS according to PostgreSQL/Supabase role configuration; the file does not audit those roles. The `authenticated` grant is broad at the SQL privilege layer, so the intended isolation depends on RLS remaining enabled and the policies remaining intact.

Ordering matters: `public.profiles(id)`, `gen_random_uuid()`, `authenticated`, and `auth.uid()` must be available before this migration runs. If the table already exists, `CREATE TABLE IF NOT EXISTS` does not reconcile its existing columns, constraints, or foreign key definition; the subsequent index/RLS/grant/policy statements can therefore operate on a pre-existing but incompatible table or fail. The migration also has no trigger to maintain `updated_at`, so callers or a later migration must update that field explicitly if it is expected to track modifications.

# Reconstruction recommendation

For a synthetic local schema reconstruction, this migration is **safe to omit only when browser Web Push subscriptions are explicitly outside the reconstructed feature surface** and no tests or application paths expect `public.web_push_subscriptions`, its index, or its policies. Omitting it avoids an optional capability and does not omit real data or a data transformation.

It is **not safe to omit for schema fidelity or for a reconstruction that claims to support Web Push**. In that case, reproduce the table, foreign key cascade, uniqueness constraint, partial index, RLS enablement, authenticated grant, and all four owner policies. Before execution in any environment, verify the listed dependencies and inspect any pre-existing object with the same name; this review did not inspect those objects.

# Verdict

**PARTIALLY VERIFIED** — the file's statements and direct effects are fully characterized from the single-file read, and it contains no data or external-network side effects. However, dependency existence and compatibility were not verified because the audit was restricted to this migration. The migration is structurally suitable for a Supabase-style schema when those dependencies are present; it is conditionally omittable only for an intentionally feature-reduced synthetic reconstruction, not for a faithful or Web-Push-capable one.
