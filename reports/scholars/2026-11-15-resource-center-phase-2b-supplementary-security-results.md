# Scholars Resource Centre — Phase 2B Supplementary Security Verification Results

## Execution metadata

- Supabase project: `scholarship-platform`
- Project reference: `cmdglabohpttgfofcmqc`
- Project status: `ACTIVE_HEALTHY`
- Database: PostgreSQL 17.6.1.155, `eu-west-1`
- Supplementary SQL path: `reports/scholars/sql/2026-11-15-resource-center-supplementary-security-verification.sql`
- Execution date: 2026-11-15
- Execution window: approximately 16:18:07–16:20:07 WAT (UTC+01:00), equivalent to 15:18:07–15:20:07 UTC
- Final supplementary statements: 11
- Database executions including one corrected rerun: 12
- Successful executions: 12
- Failed executions: 0
- Function calls: none
- Profile/authentication records retrieved: none

The SQL file was statically inspected before execution. Every final statement was a bounded `SELECT`; no function was invoked and no mutation statement was present. The C.1 trigger query was safely rerun once after correcting the projection labels for PostgreSQL `tgtype` event bits. The first execution returned the same four triggers and was superseded because its derived event-label columns were mapped incorrectly; the corrected result below is authoritative.

## Query A.1 — all public `is_admin` overloads

**Status:** Succeeded; 1 row.

**Query:**

```sql
SELECT
  p.oid AS routine_oid,
  n.nspname AS schema_name,
  p.proname AS routine_name,
  p.oid::regprocedure::text AS fully_qualified_identity,
  pg_get_function_identity_arguments(p.oid) AS identity_arguments,
  p.prokind AS routine_kind,
  pg_get_userbyid(p.proowner) AS routine_owner,
  p.prosecdef AS security_definer,
  p.proconfig AS routine_configuration,
  p.proacl AS raw_acl,
  has_function_privilege('public', p.oid, 'EXECUTE') AS public_execute,
  has_function_privilege('anon', p.oid, 'EXECUTE') AS anon_execute,
  has_function_privilege('authenticated', p.oid, 'EXECUTE') AS authenticated_execute,
  has_function_privilege('service_role', p.oid, 'EXECUTE') AS service_role_execute
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND p.proname = 'is_admin'
ORDER BY p.oid
LIMIT 1000;
```

**Returned rows:**

```json
[
  {
    "routine_oid": 17620,
    "schema_name": "public",
    "routine_name": "is_admin",
    "fully_qualified_identity": "is_admin(uuid)",
    "identity_arguments": "uid uuid",
    "routine_kind": "f",
    "routine_owner": "postgres",
    "security_definer": true,
    "routine_configuration": ["search_path=\"\""],
    "raw_acl": "{postgres=X/postgres,service_role=X/postgres,=X/postgres}",
    "public_execute": true,
    "anon_execute": true,
    "authenticated_execute": true,
    "service_role_execute": true
  }
]
```

## Query A.2 — `is_admin` in every schema

**Status:** Succeeded; 1 row.

**Query:**

```sql
SELECT
  p.oid AS routine_oid,
  n.nspname AS schema_name,
  p.proname AS routine_name,
  p.oid::regprocedure::text AS fully_qualified_identity,
  pg_get_function_identity_arguments(p.oid) AS identity_arguments,
  p.prokind AS routine_kind,
  pg_get_userbyid(p.proowner) AS routine_owner,
  p.prosecdef AS security_definer,
  p.proconfig AS routine_configuration,
  p.proacl AS raw_acl
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE p.proname = 'is_admin'
ORDER BY n.nspname, p.oid
LIMIT 1000;
```

**Returned rows:**

```json
[
  {
    "routine_oid": 17620,
    "schema_name": "public",
    "routine_name": "is_admin",
    "fully_qualified_identity": "is_admin(uuid)",
    "identity_arguments": "uid uuid",
    "routine_kind": "f",
    "routine_owner": "postgres",
    "security_definer": true,
    "routine_configuration": ["search_path=\"\""],
    "raw_acl": "{postgres=X/postgres,service_role=X/postgres,=X/postgres}"
  }
]
```

## Query B.1 — complete `public.profiles` RLS policies

**Status:** Succeeded; 6 rows.

**Query:**

```sql
SELECT
  p.polname AS policy_name,
  p.polcmd AS command_type,
  p.polpermissive AS is_permissive,
  pg_get_userbyid(role_ids.role_oid) AS policy_role,
  pg_get_expr(p.polqual, p.polrelid) AS using_expression,
  pg_get_expr(p.polwithcheck, p.polrelid) AS with_check_expression
FROM pg_policy p
JOIN pg_class c ON c.oid = p.polrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
CROSS JOIN LATERAL unnest(p.polroles) AS role_ids(role_oid)
WHERE n.nspname = 'public'
  AND c.relname = 'profiles'
ORDER BY p.polname, p.polcmd, policy_role
LIMIT 1000;
```

**Returned rows:**

```json
[
  {"policy_name":"profiles_delete_own","command_type":"d","is_permissive":true,"policy_role":"authenticated","using_expression":"(auth.uid() = id)","with_check_expression":null},
  {"policy_name":"profiles_insert_own","command_type":"a","is_permissive":true,"policy_role":"authenticated","using_expression":null,"with_check_expression":"(auth.uid() = id)"},
  {"policy_name":"profiles_select_admin","command_type":"r","is_permissive":true,"policy_role":"unknown (OID=0)","using_expression":"is_admin(auth.uid())","with_check_expression":null},
  {"policy_name":"profiles_select_own","command_type":"r","is_permissive":true,"policy_role":"unknown (OID=0)","using_expression":"(auth.uid() = id)","with_check_expression":null},
  {"policy_name":"profiles_update_community_role_admin","command_type":"w","is_permissive":true,"policy_role":"authenticated","using_expression":"is_admin(auth.uid())","with_check_expression":"is_admin(auth.uid())"},
  {"policy_name":"profiles_update_own","command_type":"w","is_permissive":true,"policy_role":"authenticated","using_expression":"(auth.uid() = id)","with_check_expression":"(auth.uid() = id)"}
]
```

## Query C.1 — triggers on `public.profiles`

**Status:** Final corrected execution succeeded; 4 rows. A preliminary execution also succeeded but used incorrect derived `tgtype` labels; it was rerun and is not used for interpretation.

**Corrected query:**

```sql
SELECT
  t.tgname AS trigger_name,
  t.tgenabled AS enabled_state,
  (t.tgtype & 1) <> 0 AS is_row_level,
  (t.tgtype & 2) <> 0 AS fires_before,
  (t.tgtype & 64) <> 0 AS fires_instead,
  (t.tgtype & 4) <> 0 AS fires_on_insert,
  (t.tgtype & 8) <> 0 AS fires_on_delete,
  (t.tgtype & 16) <> 0 AS fires_on_update,
  (t.tgtype & 32) <> 0 AS fires_on_truncate,
  t.tgfoid AS trigger_function_oid,
  t.tgfoid::regprocedure::text AS trigger_function_identity,
  fn_ns.nspname AS trigger_function_schema,
  fn.proname AS trigger_function_name,
  pg_get_userbyid(fn.proowner) AS trigger_function_owner,
  fn.prosecdef AS trigger_function_security_definer,
  fn.proconfig AS trigger_function_configuration,
  pg_get_triggerdef(t.oid, true) AS trigger_definition
FROM pg_trigger t
JOIN pg_class c ON c.oid = t.tgrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
JOIN pg_proc fn ON fn.oid = t.tgfoid
JOIN pg_namespace fn_ns ON fn_ns.oid = fn.pronamespace
WHERE n.nspname = 'public'
  AND c.relname = 'profiles'
  AND NOT t.tgisinternal
ORDER BY t.tgname
LIMIT 1000;
```

**Returned rows:**

```json
[
  {"trigger_name":"guard_community_invitation_consent","enabled_state":"O","is_row_level":true,"fires_before":true,"fires_instead":false,"fires_on_insert":true,"fires_on_delete":false,"fires_on_update":true,"fires_on_truncate":false,"trigger_function_oid":20610,"trigger_function_identity":"guard_community_invitation_consent()","trigger_function_schema":"public","trigger_function_name":"guard_community_invitation_consent","trigger_function_owner":"postgres","trigger_function_security_definer":false,"trigger_function_configuration":["search_path=pg_catalog, public, auth, pg_temp"],"trigger_definition":"CREATE TRIGGER guard_community_invitation_consent BEFORE INSERT OR UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION guard_community_invitation_consent()"},
  {"trigger_name":"on_profile_referral_completion","enabled_state":"O","is_row_level":true,"fires_before":false,"fires_instead":false,"fires_on_insert":true,"fires_on_delete":false,"fires_on_update":true,"fires_on_truncate":false,"trigger_function_oid":17899,"trigger_function_identity":"check_referral_completion()","trigger_function_schema":"public","trigger_function_name":"check_referral_completion","trigger_function_owner":"postgres","trigger_function_security_definer":true,"trigger_function_configuration":["search_path=\"\""],"trigger_definition":"CREATE TRIGGER on_profile_referral_completion AFTER INSERT OR UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION check_referral_completion()"},
  {"trigger_name":"trg_profiles_completeness","enabled_state":"O","is_row_level":true,"fires_before":true,"fires_instead":false,"fires_on_insert":true,"fires_on_delete":false,"fires_on_update":true,"fires_on_truncate":false,"trigger_function_oid":17618,"trigger_function_identity":"set_profile_completeness()","trigger_function_schema":"public","trigger_function_name":"set_profile_completeness","trigger_function_owner":"postgres","trigger_function_security_definer":false,"trigger_function_configuration":["search_path=\"\""],"trigger_definition":"CREATE TRIGGER trg_profiles_completeness BEFORE INSERT OR UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION set_profile_completeness()"},
  {"trigger_name":"trg_profiles_updated_at","enabled_state":"O","is_row_level":true,"fires_before":true,"fires_instead":false,"fires_on_insert":false,"fires_on_delete":false,"fires_on_update":true,"fires_on_truncate":false,"trigger_function_oid":17614,"trigger_function_identity":"set_updated_at()","trigger_function_schema":"public","trigger_function_name":"set_updated_at","trigger_function_owner":"postgres","trigger_function_security_definer":false,"trigger_function_configuration":["search_path=\"\""],"trigger_definition":"CREATE TRIGGER trg_profiles_updated_at BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION set_updated_at()"}
]
```

The four trigger definitions do not indicate a trigger dedicated to rejecting, resetting, or admin-authorizing `is_admin`. The `guard_community_invitation_consent` trigger is focused on community invitation consent fields. No trigger function was executed.

## Query C.2 — definitions of the profiles trigger functions

**Status:** Succeeded; 4 rows.

**Query:**

```sql
SELECT
  t.tgname AS trigger_name,
  t.tgfoid AS trigger_function_oid,
  t.tgfoid::regprocedure::text AS trigger_function_identity,
  pg_get_functiondef(fn.oid) AS trigger_function_definition
FROM pg_trigger t
JOIN pg_class c ON c.oid = t.tgrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
JOIN pg_proc fn ON fn.oid = t.tgfoid
WHERE n.nspname = 'public'
  AND c.relname = 'profiles'
  AND NOT t.tgisinternal
ORDER BY t.tgname
LIMIT 1000;
```

**Returned rows:**

```text
trigger_name: guard_community_invitation_consent
trigger_function_oid: 20610
trigger_function_identity: guard_community_invitation_consent()
trigger_function_definition:
CREATE OR REPLACE FUNCTION public.guard_community_invitation_consent()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog', 'public', 'auth', 'pg_temp'
AS $function$
BEGIN
  IF auth.role() IS DISTINCT FROM 'service_role' THEN
    IF TG_OP = 'INSERT' THEN
      IF NEW.whatsapp_community_invite_opt_in IS DISTINCT FROM false
        OR NEW.whatsapp_community_invite_consented_at IS NOT NULL
        OR NEW.whatsapp_community_invite_withdrawn_at IS NOT NULL
        OR NEW.whatsapp_community_invite_notice_version IS NOT NULL
      THEN
        RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'Community invitation consent must be changed through the authenticated consent endpoint';
      END IF;
    ELSE
      IF NEW.whatsapp_community_invite_opt_in IS DISTINCT FROM OLD.whatsapp_community_invite_opt_in
        OR NEW.whatsapp_community_invite_consented_at IS DISTINCT FROM OLD.whatsapp_community_invite_consented_at
        OR NEW.whatsapp_community_invite_withdrawn_at IS DISTINCT FROM OLD.whatsapp_community_invite_withdrawn_at
        OR NEW.whatsapp_community_invite_notice_version IS DISTINCT FROM OLD.whatsapp_community_invite_notice_version
      THEN
        RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'Community invitation consent must be changed through the authenticated consent endpoint';
      END IF;
      IF NEW.whatsapp_number IS DISTINCT FROM OLD.whatsapp_number
        AND OLD.whatsapp_community_invite_opt_in IS TRUE
      THEN
        NEW.whatsapp_community_invite_opt_in := false;
        NEW.whatsapp_community_invite_withdrawn_at := statement_timestamp();
      END IF;
    END IF;
  END IF;
  RETURN NEW;
END;
$function$

trigger_name: on_profile_referral_completion
trigger_function_oid: 17899
trigger_function_identity: check_referral_completion()
trigger_function_definition:
CREATE OR REPLACE FUNCTION public.check_referral_completion()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_was_below boolean;
begin
  if new.referred_by is null or new.profile_completeness < 60 then
    return new;
  end if;
  v_was_below := (tg_op = 'INSERT') or (old.profile_completeness < 60);
  if not v_was_below then
    return new;
  end if;
  perform public.award_xp(
    new.referred_by,
    'referral_confirmed',
    50,
    'referral_confirmed:' || new.id::text,
    jsonb_build_object('referred_profile_id', new.id)
  );
  return new;
end;
$function$

trigger_name: trg_profiles_completeness
trigger_function_oid: 17618
trigger_function_identity: set_profile_completeness()
trigger_function_definition:
CREATE OR REPLACE FUNCTION public.set_profile_completeness()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
begin
  new.profile_completeness := public.calculate_profile_completeness(new);
  return new;
end;
$function$

trigger_name: trg_profiles_updated_at
trigger_function_oid: 17614
trigger_function_identity: set_updated_at()
trigger_function_definition:
CREATE OR REPLACE FUNCTION public.set_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
begin
  new.updated_at = now();
  return new;
end;
$function$
```

None of the four returned definitions references `is_admin`, assigns to it, or rejects changes to it.

## Query D.1 — constraints on `public.profiles`

**Status:** Succeeded; 8 rows.

**Query:**

```sql
SELECT
  con.oid AS constraint_oid,
  con.conname AS constraint_name,
  con.contype AS constraint_type,
  con.convalidated AS is_validated,
  con.condeferrable AS is_deferrable,
  con.condeferred AS is_deferred,
  pg_get_constraintdef(con.oid, true) AS constraint_definition
FROM pg_constraint con
JOIN pg_class c ON c.oid = con.conrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND c.relname = 'profiles'
ORDER BY con.conname
LIMIT 1000;
```

**Returned rows:**

```json
[
  {"constraint_oid":17719,"constraint_name":"jamb_score_range","constraint_type":"c","is_validated":true,"is_deferrable":false,"is_deferred":false,"constraint_definition":"CHECK (jamb_score IS NULL OR jamb_score >= 0 AND jamb_score <= 400)"},
  {"constraint_oid":19679,"constraint_name":"profiles_community_bio_check","constraint_type":"c","is_validated":true,"is_deferrable":false,"is_deferred":false,"constraint_definition":"CHECK (community_bio IS NULL OR char_length(community_bio) <= 280)"},
  {"constraint_oid":20609,"constraint_name":"profiles_community_invite_consent_check","constraint_type":"c","is_validated":true,"is_deferrable":false,"is_deferred":false,"constraint_definition":"CHECK (NOT whatsapp_community_invite_opt_in OR whatsapp_community_invite_consented_at IS NOT NULL AND whatsapp_community_invite_withdrawn_at IS NULL AND whatsapp_community_invite_notice_version IS NOT NULL AND whatsapp_number ~ '^[+]234[0-9]{10}$'::text)"},
  {"constraint_oid":17537,"constraint_name":"profiles_id_fkey","constraint_type":"f","is_validated":true,"is_deferrable":false,"is_deferred":false,"constraint_definition":"FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE"},
  {"constraint_oid":17536,"constraint_name":"profiles_pkey","constraint_type":"p","is_validated":true,"is_deferrable":false,"is_deferred":false,"constraint_definition":"PRIMARY KEY (id)"},
  {"constraint_oid":17827,"constraint_name":"profiles_referred_by_fkey","constraint_type":"f","is_validated":true,"is_deferrable":false,"is_deferred":false,"constraint_definition":"FOREIGN KEY (referred_by) REFERENCES profiles(id)"},
  {"constraint_oid":17720,"constraint_name":"waec_credit_count_range","constraint_type":"c","is_validated":true,"is_deferrable":false,"is_deferred":false,"constraint_definition":"CHECK (waec_credit_count IS NULL OR waec_credit_count >= 0 AND waec_credit_count <= 9)"},
  {"constraint_oid":17718,"constraint_name":"year_of_study_range","constraint_type":"c","is_validated":true,"is_deferrable":false,"is_deferred":false,"constraint_definition":"CHECK (year_of_study IS NULL OR year_of_study >= 100 AND year_of_study <= 600)"}
]
```

## Query D.2 — non-internal rules on `public.profiles`

**Status:** Succeeded; empty result set.

**Query:**

```sql
SELECT
  r.oid AS rule_oid,
  r.rulename AS rule_name,
  r.ev_enabled AS enabled_state,
  r.ev_type AS event_type,
  pg_get_ruledef(r.oid, true) AS rule_definition
FROM pg_rewrite r
JOIN pg_class c ON c.oid = r.ev_class
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND c.relname = 'profiles'
  AND r.rulename <> '_RETURN'
ORDER BY r.rulename
LIMIT 1000;
```

**Returned rows:**

```json
[]
```

## Query E.1 — effective table-level privileges

**Status:** Succeeded; 4 rows.

**Query:**

```sql
SELECT
  role_name,
  has_table_privilege(role_name, 'public.profiles', 'INSERT') AS table_level_insert,
  has_table_privilege(role_name, 'public.profiles', 'UPDATE') AS table_level_update
FROM (VALUES ('anon'), ('authenticated'), ('service_role'), ('public')) AS roles(role_name)
ORDER BY role_name
LIMIT 1000;
```

**Returned rows:**

```json
[
  {"role_name":"anon","table_level_insert":false,"table_level_update":false},
  {"role_name":"authenticated","table_level_insert":true,"table_level_update":true},
  {"role_name":"public","table_level_insert":false,"table_level_update":false},
  {"role_name":"service_role","table_level_insert":true,"table_level_update":true}
]
```

## Query E.2 — effective column privileges

**Status:** Succeeded; 5 rows.

**Query:**

```sql
SELECT
  role_name,
  column_name,
  has_column_privilege(role_name, 'public.profiles', column_name, 'INSERT') AS column_insert_allowed,
  has_column_privilege(role_name, 'public.profiles', column_name, 'UPDATE') AS column_update_allowed
FROM (VALUES
  ('anon', 'is_admin'),
  ('authenticated', 'is_admin'),
  ('service_role', 'is_admin'),
  ('public', 'is_admin'),
  ('authenticated', 'full_name')
) AS checks(role_name, column_name)
ORDER BY role_name, column_name
LIMIT 1000;
```

**Returned rows:**

```json
[
  {"role_name":"anon","column_name":"is_admin","column_insert_allowed":false,"column_update_allowed":false},
  {"role_name":"authenticated","column_name":"full_name","column_insert_allowed":true,"column_update_allowed":true},
  {"role_name":"authenticated","column_name":"is_admin","column_insert_allowed":true,"column_update_allowed":true},
  {"role_name":"public","column_name":"is_admin","column_insert_allowed":false,"column_update_allowed":false},
  {"role_name":"service_role","column_name":"is_admin","column_insert_allowed":true,"column_update_allowed":true}
]
```

## Query E.3 — information-schema grants

**Status:** Succeeded; 31 rows.

**Query:**

```sql
SELECT
  'table' AS grant_scope,
  grantee AS role_name,
  NULL::text AS column_name,
  privilege_type,
  is_grantable
FROM information_schema.role_table_grants
WHERE table_schema = 'public'
  AND table_name = 'profiles'
UNION ALL
SELECT
  'column' AS grant_scope,
  grantee AS role_name,
  column_name,
  privilege_type,
  NULL::text AS is_grantable
FROM information_schema.column_privileges
WHERE table_schema = 'public'
  AND table_name = 'profiles'
  AND column_name = 'is_admin'
ORDER BY grant_scope, role_name, column_name, privilege_type
LIMIT 1000;
```

**Returned rows:**

```json
[
  {"grant_scope":"column","role_name":"anon","column_name":"is_admin","privilege_type":"SELECT","is_grantable":null},
  {"grant_scope":"column","role_name":"authenticated","column_name":"is_admin","privilege_type":"INSERT","is_grantable":null},
  {"grant_scope":"column","role_name":"authenticated","column_name":"is_admin","privilege_type":"SELECT","is_grantable":null},
  {"grant_scope":"column","role_name":"authenticated","column_name":"is_admin","privilege_type":"UPDATE","is_grantable":null},
  {"grant_scope":"column","role_name":"postgres","column_name":"is_admin","privilege_type":"INSERT","is_grantable":null},
  {"grant_scope":"column","role_name":"postgres","column_name":"is_admin","privilege_type":"REFERENCES","is_grantable":null},
  {"grant_scope":"column","role_name":"postgres","column_name":"is_admin","privilege_type":"SELECT","is_grantable":null},
  {"grant_scope":"column","role_name":"postgres","column_name":"is_admin","privilege_type":"UPDATE","is_grantable":null},
  {"grant_scope":"column","role_name":"service_role","column_name":"is_admin","privilege_type":"INSERT","is_grantable":null},
  {"grant_scope":"column","role_name":"service_role","column_name":"is_admin","privilege_type":"REFERENCES","is_grantable":null},
  {"grant_scope":"column","role_name":"service_role","column_name":"is_admin","privilege_type":"SELECT","is_grantable":null},
  {"grant_scope":"column","role_name":"service_role","column_name":"is_admin","privilege_type":"UPDATE","is_grantable":null},
  {"grant_scope":"table","role_name":"anon","column_name":null,"privilege_type":"SELECT","is_grantable":"NO"},
  {"grant_scope":"table","role_name":"authenticated","column_name":null,"privilege_type":"DELETE","is_grantable":"NO"},
  {"grant_scope":"table","role_name":"authenticated","column_name":null,"privilege_type":"INSERT","is_grantable":"NO"},
  {"grant_scope":"table","role_name":"authenticated","column_name":null,"privilege_type":"SELECT","is_grantable":"NO"},
  {"grant_scope":"table","role_name":"authenticated","column_name":null,"privilege_type":"UPDATE","is_grantable":"NO"},
  {"grant_scope":"table","role_name":"postgres","column_name":null,"privilege_type":"DELETE","is_grantable":"YES"},
  {"grant_scope":"table","role_name":"postgres","column_name":null,"privilege_type":"INSERT","is_grantable":"YES"},
  {"grant_scope":"table","role_name":"postgres","column_name":null,"privilege_type":"REFERENCES","is_grantable":"YES"},
  {"grant_scope":"table","role_name":"postgres","column_name":null,"privilege_type":"SELECT","is_grantable":"YES"},
  {"grant_scope":"table","role_name":"postgres","column_name":null,"privilege_type":"TRIGGER","is_grantable":"YES"},
  {"grant_scope":"table","role_name":"postgres","column_name":null,"privilege_type":"TRUNCATE","is_grantable":"YES"},
  {"grant_scope":"table","role_name":"postgres","column_name":null,"privilege_type":"UPDATE","is_grantable":"YES"},
  {"grant_scope":"table","role_name":"service_role","column_name":null,"privilege_type":"DELETE","is_grantable":"NO"},
  {"grant_scope":"table","role_name":"service_role","column_name":null,"privilege_type":"INSERT","is_grantable":"NO"},
  {"grant_scope":"table","role_name":"service_role","column_name":null,"privilege_type":"REFERENCES","is_grantable":"NO"},
  {"grant_scope":"table","role_name":"service_role","column_name":null,"privilege_type":"SELECT","is_grantable":"NO"},
  {"grant_scope":"table","role_name":"service_role","column_name":null,"privilege_type":"TRIGGER","is_grantable":"NO"},
  {"grant_scope":"table","role_name":"service_role","column_name":null,"privilege_type":"TRUNCATE","is_grantable":"NO"},
  {"grant_scope":"table","role_name":"service_role","column_name":null,"privilege_type":"UPDATE","is_grantable":"NO"}
]
```

## Query E.4 — RLS and FORCE RLS status

**Status:** Succeeded; 1 row.

**Query:**

```sql
SELECT
  n.nspname AS schema_name,
  c.relname AS table_name,
  c.relrowsecurity AS rls_enabled,
  c.relforcerowsecurity AS force_rls,
  pg_get_userbyid(c.relowner) AS table_owner
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND c.relname = 'profiles'
  AND c.relkind = 'r'
LIMIT 1000;
```

**Returned rows:**

```json
[
  {"schema_name":"public","table_name":"profiles","rls_enabled":true,"force_rls":false,"table_owner":"postgres"}
]
```

## Errors and omissions

No final supplementary query failed. The only correction was a client-side projection-label correction for C.1; the database query itself returned successfully both times. The corrected query was executed again, and its actual result set is preserved above. No query was silently skipped, no alternate function body was retrieved, and no remediation was performed.
