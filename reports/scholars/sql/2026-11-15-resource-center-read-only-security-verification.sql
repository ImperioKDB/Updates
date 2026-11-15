-- =============================================================================
-- Scholars Resource Centre — Read-Only Security Verification SQL
-- =============================================================================
--
-- Purpose: Verify the effective PostgreSQL privileges on public.profiles,
--          specifically whether the "authenticated" role can structurally
--          modify profiles.is_admin through any database-supported write path.
--
-- Safety: This script contains SELECT and read-only metadata queries ONLY.
--         It does NOT:
--           - Modify any database object, privilege, or data
--           - Read actual profile rows or personal data
--           - Execute public.is_admin(uuid) with arbitrary IDs
--           - Expose secrets, credentials, or connection strings
--
-- Usage: Execute manually through the Supabase SQL Editor in the Scholars
--        production project dashboard. Do not modify the script before running.
--
-- File: reports/scholars/sql/2026-11-15-resource-center-read-only-security-verification.sql
-- Repository: ImperioKDB/Updates
-- =============================================================================

--------------------------------------------------------------------------------
-- SECTION A: Effective privileges on public.profiles
--------------------------------------------------------------------------------

-- A.1 Table-level INSERT privilege on public.profiles
-- Checks whether each role can INSERT into the profiles table at the table level.
SELECT
  'anon' AS role_name,
  has_table_privilege('anon', 'public.profiles', 'INSERT') AS table_level_insert,
  has_table_privilege('anon', 'public.profiles', 'UPDATE') AS table_level_update
UNION ALL
SELECT
  'authenticated',
  has_table_privilege('authenticated', 'public.profiles', 'INSERT'),
  has_table_privilege('authenticated', 'public.profiles', 'UPDATE')
UNION ALL
SELECT
  'service_role',
  has_table_privilege('service_role', 'public.profiles', 'INSERT'),
  has_table_privilege('service_role', 'public.profiles', 'UPDATE')
UNION ALL
SELECT
  'PUBLIC',
  has_table_privilege('PUBLIC', 'public.profiles', 'INSERT'),
  has_table_privilege('PUBLIC', 'public.profiles', 'UPDATE');

-- A.2 Column-level INSERT privilege on profiles.is_admin
-- Checks whether each role can INSERT into the is_admin column specifically.
SELECT
  'anon' AS role_name,
  has_column_privilege('anon', 'public.profiles', 'is_admin', 'INSERT') AS column_insert_is_admin,
  has_column_privilege('anon', 'public.profiles', 'is_admin', 'UPDATE') AS column_update_is_admin
UNION ALL
SELECT
  'authenticated',
  has_column_privilege('authenticated', 'public.profiles', 'is_admin', 'INSERT'),
  has_column_privilege('authenticated', 'public.profiles', 'is_admin', 'UPDATE')
UNION ALL
SELECT
  'service_role',
  has_column_privilege('service_role', 'public.profiles', 'is_admin', 'INSERT'),
  has_column_privilege('service_role', 'public.profiles', 'is_admin', 'UPDATE')
UNION ALL
SELECT
  'PUBLIC',
  has_column_privilege('PUBLIC', 'public.profiles', 'is_admin', 'INSERT'),
  has_column_privilege('PUBLIC', 'public.profiles', 'is_admin', 'UPDATE');

-- A.3 Column-level privileges on ordinary profile columns (for comparison)
-- Shows that ordinary fields have column grants while is_admin may not at column level.
SELECT
  'authenticated' AS role_name,
  'full_name' AS column_name,
  has_column_privilege('authenticated', 'public.profiles', 'full_name', 'UPDATE') AS column_update_allowed
UNION ALL
SELECT
  'authenticated',
  'is_admin',
  has_column_privilege('authenticated', 'public.profiles', 'is_admin', 'UPDATE');

--------------------------------------------------------------------------------
-- SECTION B: Row-Level Security (RLS) on public.profiles
--------------------------------------------------------------------------------

-- B.1 RLS enablement and FORCE status
-- relrowsecurity = RLS is enabled; relforcerowsecurity = FORCE RLS (applies to table owner too)
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
  AND c.relkind = 'r';

-- B.2 RLS policies on public.profiles
-- Shows policy name, command type, roles, USING expression, and WITH CHECK expression.
SELECT
  polname AS policy_name,
  polcmd AS command_type,  -- r = SELECT, a = INSERT, w = UPDATE, d = DELETE, * = ALL
  pg_get_userbyid(polroles[1]) AS policy_role,
  pg_get_expr(polqual, polrelid) AS using_expression,
  pg_get_expr(polwithcheck, polrelid) AS with_check_expression
FROM pg_policy
JOIN pg_class ON pg_class.oid = polrelid
JOIN pg_namespace ON pg_namespace.oid = pg_class.relnamespace
WHERE pg_namespace.nspname = 'public'
  AND pg_class.relname = 'profiles'
ORDER BY polname, polcmd;

-- B.3 Effective table grants on public.profiles (from information_schema)
-- Shows the grantee, privilege type, and whether it is grantable.
SELECT
  grantee AS role_name,
  privilege_type,
  is_grantable
FROM information_schema.role_table_grants
WHERE table_schema = 'public'
  AND table_name = 'profiles'
ORDER BY grantee, privilege_type;

-- B.4 Effective column grants on profiles.is_admin (from information_schema)
SELECT
  grantee AS role_name,
  column_name,
  privilege_type
FROM information_schema.column_privileges
WHERE table_schema = 'public'
  AND table_name = 'profiles'
  AND column_name = 'is_admin'
ORDER BY grantee, privilege_type;

--------------------------------------------------------------------------------
-- SECTION C: Function metadata for public.is_admin(uuid)
--------------------------------------------------------------------------------

-- C.1 Function existence, owner, SECURITY DEFINER status, and configuration
SELECT
  n.nspname AS schema_name,
  p.proname AS function_name,
  pg_get_function_identity_arguments(p.oid) AS argument_types,
  pg_get_userbyid(p.proowner) AS function_owner,
  p.prosecdef AS security_definer,
  p.proconfig AS configuration,  -- includes search_path setting
  p.prokind AS function_kind  -- f = function, p = procedure, a = aggregate
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND p.proname = 'is_admin'
  AND pg_get_function_identity_arguments(p.oid) = 'uuid'
ORDER BY p.proname;

-- C.2 Effective EXECUTE privilege on public.is_admin(uuid) for each role
-- has_function_privilege checks whether the role can execute the function.
SELECT
  'PUBLIC' AS role_name,
  has_function_privilege('PUBLIC', 'public.is_admin(uuid)', 'EXECUTE') AS execute_privilege
UNION ALL
SELECT
  'anon',
  has_function_privilege('anon', 'public.is_admin(uuid)', 'EXECUTE')
UNION ALL
SELECT
  'authenticated',
  has_function_privilege('authenticated', 'public.is_admin(uuid)', 'EXECUTE')
UNION ALL
SELECT
  'service_role',
  has_function_privilege('service_role', 'public.is_admin(uuid)', 'EXECUTE');

-- C.3 Function ACL (access control list) details from pg_proc
-- Shows the raw ACL entries for the function.
SELECT
  n.nspname AS schema_name,
  p.proname AS function_name,
  pg_get_function_identity_arguments(p.oid) AS argument_types,
  p.proacl AS function_acl_raw  -- NULL if no explicit ACL (defaults apply)
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND p.proname = 'is_admin'
  AND pg_get_function_identity_arguments(p.oid) = 'uuid';

--------------------------------------------------------------------------------
-- END OF SCRIPT
--------------------------------------------------------------------------------
