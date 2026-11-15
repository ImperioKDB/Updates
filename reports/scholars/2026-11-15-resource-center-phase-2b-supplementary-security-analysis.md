# Scholars Resource Centre — Phase 2B Supplementary Production Security Analysis

## Executive summary

Task 10 supplementary read-only verification was completed against the required Scholars production Supabase project, `scholarship-platform` (`cmdglabohpttgfofcmqc`). The investigation resolved the Task 9 E.1/E.2/E.3 inconsistency.

The live database contains exactly one routine named `public.is_admin`: OID `17620`, identity `is_admin(uuid)`, with the declared argument name `uid`. PostgreSQL's `pg_get_function_identity_arguments(p.oid)` returns **`uid uuid`**, not the bare string **`uuid`**. Task 9's E.1 and E.3 predicates compared that value to `'uuid'`, so they excluded the real function. E.2 used the function identity string `public.is_admin(uuid)`, which resolved the actual routine and correctly returned effective EXECUTE = `true` for all tested role labels.

The function is owned by `postgres`, is `SECURITY DEFINER`, has `search_path = ''`, and has raw ACL `{postgres=X/postgres,service_role=X/postgres,=X/postgres}`. The empty grantee before `=X/postgres` denotes PUBLIC. The function is therefore directly confirmed as executable by PUBLIC, anon, authenticated, and service_role through effective privilege checks. The function was not called.

The supplementary checks also confirm that all six `public.profiles` policies are permissive, the own-row update policy remains present, four enabled row-level triggers exist but none protects `is_admin`, no non-internal rules are attached to `profiles`, and the constraints cover identity, profile ranges, referral, and invitation-consent fields but do not constrain `is_admin` authorization. Task 9's critical privilege findings remain current.

**Conclusion:** the live database still has a database-level route for an ordinary authenticated user to attempt changing their own `is_admin` value. This is an effective-privilege and RLS configuration finding, not an experimentally demonstrated exploit; no write was attempted.

## 1. Project identity and execution

- Supabase project: `scholarship-platform`
- Project reference: `cmdglabohpttgfofcmqc`
- Status: `ACTIVE_HEALTHY`
- Region: `eu-west-1`
- Database: PostgreSQL 17.6.1.155
- Task 9 report/results source commit: `38431b7b2fc548377380c481189019355260a080`
- Approved SQL baseline commit: `5f4af4f2c96141a8a920288046952c3f6e189a67`
- Supplementary SQL: `reports/scholars/sql/2026-11-15-resource-center-supplementary-security-verification.sql`
- Execution window: approximately 16:18:07–16:19:07 WAT (UTC+01:00)
- Final supplementary statements: 11
- Database executions including corrected C.1 rerun: 12
- Successful executions: 12
- Failed executions: 0
- Remediation/deployment/source changes: none

The separate `serena` project and `scholars-staging` were not used.

## 2. Investigation A — function identity and E.1/E.2/E.3 discrepancy

### 2.1 Exact live routine identity

The live catalog returned one and only one routine named `is_admin` across all schemas:

| Field | Live value |
|---|---|
| OID | `17620` |
| Schema | `public` |
| Routine name | `is_admin` |
| Fully qualified identity | `is_admin(uuid)` |
| `pg_get_function_identity_arguments` | `uid uuid` |
| `prokind` | `f` (function) |
| Owner | `postgres` |
| SECURITY DEFINER | `true` |
| Configuration | `search_path=""` |
| Raw ACL | `{postgres=X/postgres,service_role=X/postgres,=X/postgres}` |

No overload exists in another schema or under another argument list.

**Classification:** VERIFIED — DATABASE.

### 2.2 Why Task 9 E.1 and E.3 returned empty

Task 9 E.1 and E.3 used:

```sql
pg_get_function_identity_arguments(p.oid) = 'uuid'
```

For this function, the live return value is `uid uuid` because the input argument is named `uid`. The equality predicate therefore evaluates false and excludes OID `17620`. The function did exist; the predicate was too narrow.

Task 9 E.2 used:

```sql
has_function_privilege('role', 'public.is_admin(uuid)', 'EXECUTE')
```

That target string identifies the routine by schema, name, and data type, without requiring the argument name. It resolved OID `17620` and returned `true` for PUBLIC, anon, authenticated, and service_role.

The inconsistency is therefore **resolved**, not a live privilege anomaly:

- E.1 empty: caused by comparing `uid uuid` to `uuid`.
- E.2 true: correctly resolved `public.is_admin(uuid)`.
- E.3 empty: caused by the same overly narrow identity-argument predicate.

**Classification:** VERIFIED — DATABASE.

### 2.3 Function security interpretation

The live function is SECURITY DEFINER, owned by `postgres`, and fixes its search path to an empty setting. Its raw ACL includes PUBLIC execution (`=X/postgres`) and explicit `service_role` execution. Effective checks confirm PUBLIC, anon, authenticated, and service_role can execute it. This establishes execution exposure as a live database fact. The function was not called and no boolean result for any user ID was obtained.

**Classification:** VERIFIED — DATABASE.

## 3. Investigation B — complete RLS policy assessment

The live database returned six policies on `public.profiles`; all six have `is_permissive = true`. No restrictive policy was returned.

| Policy | Command | Role | Permissive | USING | WITH CHECK |
|---|---|---|---|---|---|
| `profiles_delete_own` | DELETE | authenticated | true | `auth.uid() = id` | — |
| `profiles_insert_own` | INSERT | authenticated | true | — | `auth.uid() = id` |
| `profiles_select_admin` | SELECT | PUBLIC | true | `is_admin(auth.uid())` | — |
| `profiles_select_own` | SELECT | PUBLIC | true | `auth.uid() = id` | — |
| `profiles_update_community_role_admin` | UPDATE | authenticated | true | `is_admin(auth.uid())` | `is_admin(auth.uid())` |
| `profiles_update_own` | UPDATE | authenticated | true | `auth.uid() = id` | `auth.uid() = id` |

The result `unknown (OID=0)` is the catalog function's rendering for the PUBLIC pseudo-role in `polroles`; PUBLIC is not an ordinary role-membership row.

For permissive policies, qualifying policies combine with OR within the applicable command/role context. Restrictive policies, if present, would combine as additional AND conditions, but none were returned. For an ordinary authenticated user's own row, `profiles_update_own` supplies both the row visibility condition and the new-row check. Combined with the separately confirmed table-level UPDATE privilege and column-level UPDATE privilege on `is_admin`, the database configuration creates a route to **attempt** changing that user's own `is_admin` value.

This is not an exploit reproduction. No UPDATE, upsert, test user, or auth operation was performed.

**Classification:** VERIFIED — DATABASE.

## 4. Investigation C — triggers and trigger functions

Four non-internal, enabled, row-level triggers are attached to `public.profiles`:

| Trigger | Timing/events | Function | Owner | SECURITY DEFINER | Search path |
|---|---|---|---|---|---|
| `guard_community_invitation_consent` | BEFORE INSERT OR UPDATE | `guard_community_invitation_consent()` | postgres | false | `pg_catalog, public, auth, pg_temp` |
| `on_profile_referral_completion` | AFTER INSERT OR UPDATE | `check_referral_completion()` | postgres | true | `""` |
| `trg_profiles_completeness` | BEFORE INSERT OR UPDATE | `set_profile_completeness()` | postgres | false | `""` |
| `trg_profiles_updated_at` | BEFORE UPDATE | `set_updated_at()` | postgres | false | `""` |

The narrowly scoped live definitions show:

- `guard_community_invitation_consent` rejects or rewrites community invitation consent fields and may reset invitation opt-in when a WhatsApp number changes. It does not reference `is_admin`.
- `check_referral_completion` awards referral XP based on `referred_by` and `profile_completeness`. It does not reference `is_admin`.
- `set_profile_completeness` assigns `profile_completeness`. It does not reference `is_admin`.
- `set_updated_at` assigns `updated_at`. It does not reference `is_admin`.

No protective trigger was found that rejects, resets, rewrites, or restricts changes to `is_admin`. No trigger function was executed.

**Classification:** VERIFIED — DATABASE.

## 5. Investigation D — constraints and other database protections

The live database returned:

- Primary key: `profiles_pkey` on `id`.
- Foreign keys: `profiles_id_fkey` to `auth.users(id)` with `ON DELETE CASCADE`; `profiles_referred_by_fkey` to `profiles(id)`.
- CHECK constraints for JAMB score, WAEC credit count, year of study, community bio length, and community invitation consent/phone format.
- No unique or exclusion constraint was returned.
- No returned CHECK constraint references `is_admin`.
- No non-internal rewrite rules are attached to `public.profiles`.

These constraints protect identity and data-shape integrity, not administrator authorization. A Boolean, NOT NULL, or default constraint on `is_admin` would not by itself prevent an authorized SQL UPDATE; no live constraint was found that attempts to do so.

**Classification:** VERIFIED — DATABASE.

## 6. Investigation E — reconfirmed effective privileges

The supplementary results agree with Task 9; no live privilege change was observed:

- `authenticated` table-level INSERT = `true`.
- `authenticated` table-level UPDATE = `true`.
- `authenticated` column-level INSERT on `is_admin` = `true`.
- `authenticated` column-level UPDATE on `is_admin` = `true`.
- `authenticated` column-level INSERT/UPDATE on `full_name` = `true`.
- `anon` has no table-level INSERT/UPDATE and no `is_admin` INSERT/UPDATE.
- `service_role` remains privileged.
- RLS remains enabled.
- FORCE RLS remains disabled.
- Information-schema grants agree with the effective privilege checks.

The distinction remains:

1. **Table-level SQL privileges** determine whether a role may attempt the operation.
2. **Column-level privileges** further describe column grants, but a column-level REVOKE cannot cancel an existing table-level grant.
3. **RLS policies** determine which rows and new values are permitted after SQL privilege checks pass.
4. **Triggers and constraints** are additional mechanisms, but no live mechanism found here protects `is_admin`.
5. **Application/API behavior** was not tested.
6. **Successful exploitation** was not tested or demonstrated.

**Classification:** VERIFIED — DATABASE.

## 7. Risk analysis

### Critical: self-elevation path remains live

The combination of effective authenticated table/column write privileges, the permissive own-row UPDATE policy, and the absence of a trigger or constraint protecting `is_admin` leaves a database-level route to attempt self-elevation. Task 9's critical finding remains current.

### High: function execution exposure is confirmed

`public.is_admin(uuid)` is SECURITY DEFINER and executable by PUBLIC/anon/authenticated/service_role. The fixed empty search path is a positive hardening property, but broad execution exposure remains a security concern because the function accepts an arbitrary UUID. No function invocation was performed.

### Defense-in-depth concern: FORCE RLS disabled

RLS is enabled but not forced. This does not remove the ordinary-user policy analysis above, but it leaves owner-mediated access outside forced RLS coverage.

## 8. Evidence classifications

- **VERIFIED — DATABASE:** project identity; function OID/signature/owner/SECURITY DEFINER/config/ACL; E.1/E.2/E.3 explanation; all six policy definitions and permissiveness; trigger metadata and definitions; constraints; rules; reconfirmed privileges and RLS status.
- **VERIFIED — SOURCE:** Task 9 report and approved SQL provenance; prior migration observations retained as historical source evidence only.
- **INFERRED:** an ordinary authenticated user can attempt to change their own `is_admin` value, based on effective privileges plus policy conditions. This is not a successful exploit demonstration.
- **UNVERIFIED:** application-layer behavior, PostgREST request handling beyond catalog privileges, and whether any external control rejects the operation before the database attempt.
- **BLOCKED:** none for the read-only scope of Task 10.

## 9. Remaining unknowns

1. Application/API-layer behavior was intentionally not tested.
2. No write was attempted, so successful exploitation was not established.
3. The exact behavior of any client-side or API validation was not assessed.
4. The function body of `public.is_admin(uuid)` was intentionally not retrieved because the identity, security attributes, and ACL fully resolved the Task 9 inconsistency without needing unrelated function source.

## 10. Recommended remediation priorities — not implemented

1. Remove effective table-level INSERT/UPDATE from `authenticated` on `public.profiles`; replace it with narrowly scoped grants that exclude `is_admin`, then verify effective privileges.
2. Preserve intended own-profile RLS behavior while ensuring it cannot be combined with a writable administrator flag.
3. Review `public.is_admin(uuid)` execution exposure and retain only the minimum execution path required for policy evaluation.
4. Decide whether FORCE RLS is required for the production ownership model.
5. Add regression checks for table-level grants, column-level grants, policy permissiveness, trigger coverage, and function ACLs.

No remediation was performed. No database object, privilege, policy, function, trigger, constraint, configuration, source file, or deployment was changed.

## 11. Final conclusion

The E.1/E.2/E.3 inconsistency is **resolved**: the original identity predicate omitted the named argument `uid` returned by `pg_get_function_identity_arguments`, while E.2 correctly resolved the routine by type signature.

Task 9's privilege findings remain current and are independently reconfirmed. No database-level protection against changing `is_admin` was found in the inspected policies, triggers, constraints, or rules. The critical self-elevation route remains a verified configuration risk, not an experimentally demonstrated exploit.
