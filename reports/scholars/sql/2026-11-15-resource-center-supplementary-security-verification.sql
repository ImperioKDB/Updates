-- =============================================================================
-- Scholars Resource Centre — Supplementary Read-Only Security Verification SQL
-- =============================================================================
-- Scope: catalog and effective-privilege inspection only.
-- This file does not call application functions, retrieve profile rows, or read
-- authentication records. Every statement is a bounded SELECT.
-- =============================================================================

--------------------------------------------------------------------------------
-- A.1: Every public routine named is_admin, including all overloads.
--------------------------------------------------------------------------------
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

--------------------------------------------------------------------------------
-- A.2: Same routine name in every schema, to check alternate-schema resolution.
--------------------------------------------------------------------------------
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

--------------------------------------------------------------------------------
-- B.1: All public.profiles RLS policies, including permissive/restrictive mode.
--------------------------------------------------------------------------------
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

--------------------------------------------------------------------------------
-- C.1: All triggers attached to public.profiles and referenced function metadata.
--------------------------------------------------------------------------------
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

--------------------------------------------------------------------------------
-- C.2: Definitions of only the trigger functions attached to public.profiles.
--------------------------------------------------------------------------------
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

--------------------------------------------------------------------------------
-- D.1: Constraints attached to public.profiles.
--------------------------------------------------------------------------------
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

--------------------------------------------------------------------------------
-- D.2: Non-internal rules attached to public.profiles.
--------------------------------------------------------------------------------
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

--------------------------------------------------------------------------------
-- E.1: Reconfirm effective table-level INSERT/UPDATE privileges.
--------------------------------------------------------------------------------
SELECT
  role_name,
  has_table_privilege(role_name, 'public.profiles', 'INSERT') AS table_level_insert,
  has_table_privilege(role_name, 'public.profiles', 'UPDATE') AS table_level_update
FROM (VALUES ('anon'), ('authenticated'), ('service_role'), ('public')) AS roles(role_name)
ORDER BY role_name
LIMIT 1000;

--------------------------------------------------------------------------------
-- E.2: Reconfirm effective column privileges for is_admin and ordinary fields.
--------------------------------------------------------------------------------
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

--------------------------------------------------------------------------------
-- E.3: Reconfirm information_schema table and is_admin column grants.
--------------------------------------------------------------------------------
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

--------------------------------------------------------------------------------
-- E.4: Reconfirm RLS and FORCE RLS status.
--------------------------------------------------------------------------------
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

-- =============================================================================
-- END OF SUPPLEMENTARY READ-ONLY SQL
-- =============================================================================
