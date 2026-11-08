# File

`/tmp/scholars-a03-snapshot/scholars-41573f5/supabase/migrations/0094_guard_community_invitation_consent.sql`

The inspected file is migration `0094_guard_community_invitation_consent.sql`. This review is limited strictly to that file; no other migration was inspected.

# Scope

This migration installs or replaces a PostgreSQL trigger function that protects four community-invitation consent fields on `public.profiles` from direct client-side changes. It then removes ordinary function execution privileges, removes any pre-existing trigger of the same name, and creates a row-level trigger covering profile inserts and updates.

The guard is intended to preserve otherwise-existing profile writes while requiring purpose-specific invitation-consent changes to go through an authenticated server endpoint using the service-role key. The function permits the service role to bypass the guard. For non-service-role callers, it rejects consent values on insert unless they are in the neutral initial state, and rejects updates that change any protected value.

# Objects and mutations

## DDL

- `CREATE OR REPLACE FUNCTION public.guard_community_invitation_consent()` creates or replaces a trigger-compatible PL/pgSQL function.
  - Return type: `trigger`.
  - Language: `plpgsql`.
  - Function-local `search_path`: `pg_catalog, public, auth, pg_temp`.
  - The function checks `auth.role()` and, for non-service-role execution, compares `NEW` and `OLD` values for the protected profile columns.
  - It raises an exception with SQLSTATE `42501` (`insufficient_privilege`) when an unauthorized consent mutation is attempted, then returns `NEW` when the operation is allowed.
- `DROP TRIGGER IF EXISTS guard_community_invitation_consent ON public.profiles` removes an existing trigger with that name if present.
- `CREATE TRIGGER guard_community_invitation_consent ...` creates a `BEFORE INSERT OR UPDATE`, `FOR EACH ROW` trigger on `public.profiles` that executes the guard function.

## DML

There is no standalone `INSERT`, `UPDATE`, `DELETE`, or `SELECT` statement in this migration. The trigger function performs no data mutation itself; it only either raises an exception or returns the proposed row (`NEW`). Its effect is enforcement at write time.

## Grants and revokes

- `REVOKE ALL ON FUNCTION public.guard_community_invitation_consent() FROM PUBLIC, anon, authenticated` removes all explicitly applicable function privileges from `PUBLIC`, `anon`, and `authenticated`.
- There are no `GRANT` statements.
- The migration does not alter table privileges on `public.profiles` and does not revoke the existing profile-table update capability described in the comment.

# Dependencies

The migration depends on the following objects and behaviors:

- The `public.profiles` table must already exist.
- `public.profiles` must contain all four referenced columns:
  - `whatsapp_community_invite_opt_in`
  - `whatsapp_community_invite_consented_at`
  - `whatsapp_community_invite_withdrawn_at`
  - `whatsapp_community_invite_notice_version`
- The trigger must be able to reference `NEW` and `OLD` records with those fields. `OLD` is used only for update execution; the trigger is also installed for inserts.
- PostgreSQL trigger and PL/pgSQL support is required.
- `auth.role()` must be available and return the expected role identity. The function resolves names using a controlled search path that includes `auth` and `public`.
- The role identity string `service_role` is a semantic dependency: that role is the sole bypass recognized by this function.
- The roles or role names `anon` and `authenticated` must exist for the `REVOKE` statement to succeed in the target Supabase-style database. (The trigger itself does not depend on those roles being the current caller.)
- The server-side consent endpoint referenced by the comments is an application-level dependency/context, not an object created by this file. It is expected to use the service-role key after authenticating the current user.
- Existing table-level write permissions are intentionally assumed: the guard supplements them rather than replacing them.

# Data/external-side-effect assessment

The file contains no embedded real user data, seed rows, identifiers, secrets, tokens, email addresses, phone numbers, or other records. It contains no external URLs. The phrase “authenticated consent endpoint” is descriptive text in a SQL comment and is not a URL or an invocation of an external service.

The migration has no network, hosted-service, webhook, filesystem, or external API side effect. Its only runtime side effect is transactional enforcement of profile inserts and updates: unauthorized changes to the four protected columns fail with an exception, while permitted writes continue. `CREATE OR REPLACE FUNCTION` and trigger replacement are schema changes, not data backfills.

# Security/ordering implications

The principal security effect is to close a narrow write path: non-service-role callers may retain general profile updates, but cannot create or alter community-invitation consent state through direct table writes. On insert, a non-service-role caller must leave opt-in exactly `false` and the three timestamp/version fields `NULL`. On update, any difference in any protected field is rejected, including changes to `NULL`, timestamps, version values, or the boolean. The comparisons use `IS DISTINCT FROM`, so NULL transitions are detected reliably.

The service role bypasses all four checks. This is deliberate but makes the application endpoint and service-role credential handling security-critical: the endpoint must authenticate and authorize the current user before performing the privileged write. The SQL function itself does not verify ownership of a profile, user identity, consent notice semantics, or endpoint behavior.

The function uses `SET search_path = pg_catalog, public, auth, pg_temp`, which reduces accidental name resolution through an attacker-controlled search path, although the inclusion of `pg_temp` means deployment should still follow normal PostgreSQL function-hardening practices. The function is not declared `SECURITY DEFINER`; the migration does not change function owner or `SECURITY DEFINER` status. The trigger invocation path and the existing table policies/privileges therefore remain relevant.

Revoking function privileges from `PUBLIC`, `anon`, and `authenticated` prevents ordinary direct invocation of the helper function. The trigger remains attached to the table, and trigger execution is distinct from an ordinary user calling the function directly; the revoke is therefore defense-in-depth rather than the mechanism that activates the guard.

Ordering matters. The referenced profile columns and table must exist before this migration. The migration should run after the consent columns are introduced and before untrusted profile writes are allowed to rely on this protection. It should be coordinated with deployment of the authenticated consent endpoint: installing the guard before that endpoint is available can make legitimate consent changes fail, while deploying the endpoint without this guard leaves the direct-write path open. Because the trigger is dropped and recreated, any trigger ordering relative to other `BEFORE INSERT OR UPDATE` triggers on `public.profiles` should be reviewed in a full schema context; this file does not specify an explicit trigger order or preserve any prior trigger definition beyond its name.

`CREATE OR REPLACE FUNCTION` preserves the function identity if it exists but replaces its body and attributes supplied here. The explicit drop/recreate makes the named trigger converge to the intended definition, but it may affect trigger ordering or metadata associated with an earlier trigger of the same name.

# Reconstruction recommendation

This migration can be omitted from a synthetic schema reconstruction only when the reconstruction intentionally excludes the community-invitation consent feature, its four profile columns, and the security behavior being modeled. In that limited case it has no seed data or external integration that must be represented.

If the synthetic schema includes `public.profiles` with these consent fields, or aims to model realistic authorization boundaries, it should be retained or faithfully represented. At minimum, reconstruction should include the protected columns, the trigger behavior for inserts and updates, the service-role bypass, and the rejection behavior/SQLSTATE. The application endpoint itself need not be implemented merely to reconstruct the database schema, but its privileged-write assumption should be documented. Omitting the guard while retaining the fields would materially weaken the reconstructed security model and could allow ordinary profile writers to mutate consent state.

# Verdict

**Conditional retain; safe to omit only for a deliberately feature-incomplete synthetic schema.** This is a schema-level security migration, not a data or external-side-effect migration. It performs no DML and contains no real-data or external-URL content, but it enforces an important consent-integrity boundary on `public.profiles`. For any reconstruction that includes the relevant consent fields or evaluates authorization behavior, omitting it is not semantically safe. For a minimal synthetic schema that excludes the feature and all four columns, omission is acceptable provided the exclusion is explicit.
