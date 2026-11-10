# File

`/tmp/scholars-a03-snapshot/scholars-41573f5/supabase/migrations/20261107130000_security_boundary_remediation.sql`

This review is based solely on the contents of this migration. No SQL was executed, no Supabase instance or hosted service was accessed, and the snapshot was not modified. Runtime existence, ownership, ACL state, policy state, and execution behavior were not verified.

# Scope

The file is a security-boundary remediation migration described by its comments as following Resource Center Phase 0.2. Its stated purpose is to make selected worker/server-maintenance RPCs `service_role`-only and to prevent future objects created by role `postgres` in schema `public` from receiving broad default privileges for `anon` and `authenticated`.

The migration is narrowly scoped to PostgreSQL privileges and default privileges. It does not create or drop tables, views, functions, schemas, policies, constraints, indexes, triggers, or data. It does not alter function bodies or signatures. It also does not modify existing table/function/sequence ACLs except for the five explicitly named function signatures.

# Objects and mutations

## Explicit function ACL changes

Each item below performs `REVOKE ALL` from `PUBLIC`, `anon`, and `authenticated`, followed by `GRANT EXECUTE` to `service_role`.

1. `public.claim_notification_delivery(uuid, timestamptz)` (lines 8–11).
2. `public.claim_workflow_job(text, timestamptz)` (lines 13–16).
3. `public.complete_workflow_job(uuid, boolean, jsonb, jsonb, timestamptz)` (lines 18–21).
4. `public.flag_expired_opportunities()` (lines 24–27).
5. `public.seed_scholarship_prompts()` (lines 29–32).

The `REVOKE ALL` statements remove all privileges held through the named grantees for the exact overloaded signatures, including (at minimum) `EXECUTE` and any applicable routine privilege represented by `ALL`. `PUBLIC` is PostgreSQL’s pseudo-role covering every role, so revoking from `PUBLIC` is broader than revoking only the two browser roles. The subsequent grant gives `service_role` execute access; it does not grant other privileges, change ownership, or remove privileges from unrelated roles/ACL entries not covered by the listed grantees.

These statements are ACL mutations, not function definitions. A matching function must already exist at execution time with the exact schema, name, argument types, and order. PostgreSQL overload resolution matters: a similarly named function with a different signature is a different object and is not covered.

## Default-privilege changes

The file changes default ACLs owned by role `postgres` in schema `public`:

- `ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public REVOKE ALL ON FUNCTIONS FROM anon, authenticated` (lines 37–38).
- `ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public REVOKE ALL ON TABLES FROM anon, authenticated` (lines 39–40).
- `ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public REVOKE ALL ON SEQUENCES FROM anon, authenticated` (lines 41–42).

These are future-object defaults, not retroactive ACL changes. They apply to functions, tables, and sequences subsequently created by `postgres` in `public`; they do not affect objects created by another owner/creator role, objects in another schema, or existing objects. They also do not itself establish replacement grants to `anon` or `authenticated`, and they do not change default privileges for `PUBLIC`, `service_role`, or other roles unless those roles are separately represented in the underlying default ACL.

## Objects not mutated

No view, policy, constraint, table row, sequence value, function body, function security mode (`SECURITY DEFINER`/`INVOKER`), ownership, schema, or role definition is changed. There is no `CREATE`, `ALTER FUNCTION`, `DROP`, `INSERT`, `UPDATE`, `DELETE`, `UPSERT`, or other DML in the file. There are no explicit view or RLS policy statements to map beyond confirming their absence from this migration.

# Dependencies

- The `public` schema must exist.
- All five exact-signature functions must exist before their corresponding `REVOKE`/`GRANT` statements execute. Their definitions, bodies, volatility, search path, ownership, and security mode are external dependencies and are not present here.
- PostgreSQL roles `postgres`, `anon`, `authenticated`, and `service_role` must be available with the necessary authority. In particular, the executing migration context must be allowed to alter the listed function ACLs and the default privileges owned by `postgres`.
- The default-privilege statements are tied specifically to objects created by role `postgres` in schema `public`; they do not automatically cover objects created by migration owners, extension owners, dashboard roles, or other deployment roles.
- If the functions are overloaded, only the listed argument signatures are affected. Any unlisted overload remains outside this migration’s explicit remediation.
- The migration is logically dependent on the function-creation migrations being applied first. It may be followed by separate reviewed ACL remediations for other existing objects, as the comments indicate, but those changes are not present here and were not inspected.
- No data, external URL, webhook, service call, secret, storage object, or application endpoint is referenced by the SQL.

# Data/external-side-effect assessment

There is no DML and no data read or write. The migration does not seed rows despite one protected function being named `seed_scholarship_prompts`; it only changes that function’s execute ACL. There are no URLs, HTTP calls, extension calls, file operations, dynamic SQL strings, secrets, or external-service integrations in the file.

The only effects are database security metadata changes: five existing function ACLs are narrowed for named/public grantees and future default ACLs for three object classes are narrowed for two browser roles. The potential operational effect is indirect: clients using `anon` or `authenticated` may lose the ability to invoke these exact RPCs, while a server path using `service_role` is intended to retain execution access. Whether any client currently calls them cannot be established from this migration alone.

# Security/ordering implications

The security intent is least privilege for worker and maintenance operations. Revoking from both browser roles and `PUBLIC` prevents ordinary browser-role execution through those ACL paths, while granting `service_role` supports trusted server-side workers. The comments correctly distinguish revoking `PUBLIC` from revoking explicit grants to `anon`/`authenticated`; this migration handles both categories for the five functions.

Ordering is important. The function definitions must precede this migration, otherwise an ACL statement against a missing function will fail. Conversely, applying this migration before exposing those functions to application clients is the safer order because it closes the browser-role execution window. The default-privilege changes should be applied before future `postgres`-owned public-schema objects are created if they are intended to govern those objects from creation time. They are not a substitute for explicit remediation of already-created objects.

The migration does not prove that the functions are safe internally. It does not inspect or change RLS, table grants, function `SECURITY DEFINER` status, `search_path`, ownership, dynamic SQL, or the privileges of the function owner. A `service_role`-only execute boundary limits callers but does not by itself establish safe implementation or safe downstream table access. It also does not revoke `EXECUTE` from roles other than `PUBLIC`, `anon`, and `authenticated`, nor does it remove ownership-based powers.

The default-privilege changes have a narrower scope than their comments may suggest: they apply only to future objects created by role `postgres` in `public`, and only revoke defaults from `anon` and `authenticated`. Objects created by another role, or in another schema, need separate controls. Existing broad grants remain unless separately changed. The file therefore improves future-default posture but does not constitute a complete schema-wide privilege lockdown.

No runtime verification is claimed. In particular, this review does not claim that the roles exist, that the five functions exist, that the ACL changes would succeed in the target environment, or that no application path depends on browser execution.

# Reconstruction recommendation

For a synthetic schema reconstruction whose purpose is to reproduce application data structures and behavior rather than production security hardening, this migration can generally be omitted as an independent migration **only if** the reconstruction does not need production-equivalent privilege boundaries and separately documents that omission. Omitting it would not omit tables, views, policies, constraints, function bodies, or row data because none are defined here.

It should be retained or translated into the reconstruction when any of the following are goals: testing authorization boundaries; exercising `anon`/`authenticated` versus `service_role` RPC access; validating worker-only maintenance operations; reproducing production ACLs; or ensuring future `postgres`-created public objects do not receive browser-role defaults. A faithful synthetic security reconstruction would need the five functions to exist first and would need an environment-specific treatment of roles/default privileges; blindly copying these statements may fail where Supabase roles or ownership conventions differ.

Omission does not make the migration semantically irrelevant to production. For production-like deployment, it is a security remediation and should not be silently omitted without an explicit risk decision. For schema-only reconstruction, it is metadata-only and nonessential, subject to the authorization-testing caveat above.

# Verdict

**Classification: security-only ACL/default-privilege migration; no DDL object creation and no DML.** It restricts five exact `public` function signatures to `service_role` by revoking from `PUBLIC`, `anon`, and `authenticated`, and changes future `postgres`/`public` defaults for functions, tables, and sequences by revoking `anon`/`authenticated` defaults. It has no real-data or external-URL content and no direct external side effects.

**Recommendation: omittable from a synthetic schema reconstruction only when production privilege behavior is out of scope; retain or explicitly model it for security/authorization fidelity.** The key caveats are exact-signature and role dependencies, non-retroactive default privileges, possible unlisted overloads or creator roles, and the absence of any runtime verification in this review.
