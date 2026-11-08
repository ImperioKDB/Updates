# File

`/tmp/scholars-a03-snapshot/scholars-41573f5/supabase/migrations/0095_revoke_invitation_consent_on_number_change.sql`

# Scope

This review covers only migration `0095_revoke_invitation_consent_on_number_change.sql`. The migration is 43 lines long and defines or replaces one PostgreSQL trigger function. No other migration was inspected. The comments state the intended invariant: community-invitation consent is tied to the WhatsApp/phone number presented at consent time; changing that number through an ordinary profile update revokes the consent and requires re-affirmation for the replacement number.

# Objects and mutations

## DDL

The file executes one DDL statement:

- `CREATE OR REPLACE FUNCTION public.guard_community_invitation_consent()`
  - Return type: `trigger`.
  - Language: `plpgsql`.
  - Function body uses `NEW`, `OLD`, `TG_OP`, and `statement_timestamp()`.
  - The function is declared with `SET search_path = pg_catalog, public, auth, pg_temp`.

`CREATE OR REPLACE` creates the function if absent or replaces the existing function definition if the compatible function identity already exists. The file does not create a table, column, trigger, schema, role, extension, policy, index, constraint, view, or endpoint.

## DML and runtime row mutations

There are no migration-time `INSERT`, `UPDATE`, `DELETE`, or `SELECT` statements. The function does perform conditional mutation of the pending trigger row at runtime during an update:

- When a non-service-role update changes `NEW.whatsapp_number` while `OLD.whatsapp_community_invite_opt_in IS TRUE`, it sets `NEW.whatsapp_community_invite_opt_in := false`.
- In the same path it sets `NEW.whatsapp_community_invite_withdrawn_at := statement_timestamp()`.
- Because these are assignments to `NEW` in a row trigger, they affect the row write only when the function is attached to an applicable `BEFORE` row trigger. This migration itself does not attach the function to any table or trigger.

The function also rejects unauthorized consent-field changes by raising SQLSTATE `42501` (`insufficient_privilege`). On `INSERT`, a non-service-role caller must leave the consent fields at their expected initial values: opt-in must be false, and consent timestamp, withdrawal timestamp, and notice version must be null. On non-insert operations, a non-service-role caller may not directly change any of those consent fields.

## Grants/revokes

No `GRANT` or `REVOKE` statement appears. The migration does not explicitly alter function ownership, execute privileges, row-level security, or role membership. The function's effective invocation permissions and exposure therefore depend on the surrounding database defaults and on how/where a later migration attaches or calls it.

# Dependencies

The migration has the following direct or implied dependencies:

1. **PostgreSQL PL/pgSQL support.** The function is declared `LANGUAGE plpgsql`, so the language must be available in the target database.
2. **The `public` schema.** The function is created at the qualified name `public.guard_community_invitation_consent`.
3. **The `auth` namespace and `auth.role()`.** The body calls `auth.role()` and compares it to `'service_role'`. In a Supabase-style database this is normally supplied by the authentication integration. A target that lacks `auth.role()` cannot create or successfully execute this function without an equivalent compatibility function.
4. **A compatible trigger table/row shape.** At execution time, `NEW` and `OLD` must expose all of these columns: `whatsapp_number`, `whatsapp_community_invite_opt_in`, `whatsapp_community_invite_consented_at`, `whatsapp_community_invite_withdrawn_at`, and `whatsapp_community_invite_notice_version`.
5. **Trigger context.** The body expects `TG_OP` to be `INSERT` or a non-insert operation, and it is meaningful only when invoked as a row-level trigger. The file does not declare whether the eventual trigger is `BEFORE INSERT OR UPDATE`, nor does it identify the table.
6. **Execution ordering.** The referenced schema/function infrastructure and compatible table columns must exist before the function is invoked. The function itself must be created before any trigger that references it. The trigger attachment is not in this file and must be located elsewhere to establish complete behavior.
7. **Timestamp function.** `statement_timestamp()` is a PostgreSQL built-in and requires no application data dependency.

The function's explicit search path places `pg_catalog` first, followed by `public`, `auth`, and `pg_temp`, reducing unqualified-name ambiguity for built-ins and objects in those schemas. The body uses mostly qualified or built-in names, but `auth.role()` remains an explicit dependency.

# Data/external-side-effect assessment

There is no real-data access at migration execution time: no rows are read or changed, no backfill is performed, and no data is inserted. The only runtime data effect is the trigger-row mutation and rejection behavior described above when another database operation invokes the function.

There is no external URL, HTTP call, webhook, queue publication, email/SMS action, file access, secret access, or network side effect. The literal messages are local exception text only. The function does not embed real user data, phone numbers, tokens, credentials, or environment-specific identifiers.

The timestamp written on number change is generated by the database with `statement_timestamp()`; it is not imported from external data. The function does not itself persist a consent audit record beyond changing the row's withdrawal timestamp and opt-in value through the surrounding update.

# Security/ordering implications

The function implements a security boundary around four consent-related columns. For callers whose `auth.role()` is not `service_role`, direct insertion of affirmative or populated consent state is rejected, and direct modification of consent state on non-insert operations is rejected with `42501`. This is intended to force consent changes through an authenticated consent endpoint or another privileged path.

The service-role bypass is deliberate but consequential: any execution context for which `auth.role()` returns `service_role` can bypass both the insert restrictions and update restrictions. A reconstruction must preserve the identity semantics of this check if it aims to preserve the security model; substituting a generic application user check could weaken or alter authorization.

On an ordinary non-service-role update, changing `whatsapp_number` while the old row is opted in automatically sets opt-in to false and records a withdrawal timestamp. The code does not clear `whatsapp_community_invite_consented_at` or `whatsapp_community_invite_notice_version`; those values remain unchanged unless other logic handles them. The consent state therefore becomes non-opted-in, with a withdrawal timestamp, while historical consent metadata may remain present.

The ordering of trigger execution matters. To enforce the intended invariant, this function needs to run as a `BEFORE` row trigger on the relevant profile/user table, and it must run in an order compatible with any other trigger that validates or writes the same columns. PostgreSQL trigger ordering can affect whether a later trigger sees the revoked `NEW` values. A trigger created by this migration is not present, so the function definition alone does not enforce anything.

The function's declared `search_path` is a positive hardening measure, but `pg_temp` is included and the function does not explicitly declare `SECURITY DEFINER` or `SECURITY INVOKER`. Its effective privilege behavior therefore follows the default function security mode and the privileges of the invoking statement. No explicit `EXECUTE` restriction is added here. The exception path may also be observable to callers through its message, though the message contains no sensitive data.

# Reconstruction recommendation

Do not omit this migration when reconstructing a synthetic schema intended to preserve application behavior, authorization boundaries, or consent lifecycle semantics. Recreate the function (or an explicitly equivalent trigger mechanism), preserve its role check, protected columns, SQLSTATE, and number-change revocation behavior, and separately verify/recreate the trigger attachment because this file does not contain one.

It may be omitted from a deliberately minimal structural fixture whose scope is limited to tables/columns and excludes triggers, stored procedures, authentication behavior, and runtime security policies. If omitted under that narrow scope, the omission should be recorded because the resulting fixture will not enforce consent immutability or automatic revocation on phone-number changes. The migration has no backfill, external side effect, or data dependency that would independently require execution in a synthetic dataset.

# Verdict

**Retain for behavior-faithful reconstruction; conditionally omit only for a schema-only fixture.** This is a security- and integrity-relevant trigger-function definition, not a data migration. It has no migration-time DML, grants, revokes, real-data reads, or external URLs, but it establishes important runtime protections and automatic consent revocation when the phone number changes. The file alone is incomplete as an enforcement unit because it does not attach the function to a trigger; that attachment and its ordering must be verified elsewhere without treating this function as safely disposable.
