-- Scholars Resource Centre — Phase 2B Task 12
-- READ-ONLY VERIFICATION SQL — no DDL, DML, GRANT, REVOKE, helper call,
-- user/profile row retrieval, secret retrieval, or storage-object retrieval.
-- Run only against the approved isolated staging project after a separately
-- approved reconstruction. Every statement is metadata-only and includes a
-- bounded LIMIT as a safety guard.

-- 1. Schemas and application tables.
SELECT schema_name
FROM information_schema.schemata
WHERE schema_name IN ('public', 'auth', 'storage', 'extensions')
ORDER BY schema_name
LIMIT 20;

SELECT table_schema, table_name, table_type
FROM information_schema.tables
WHERE table_schema IN ('public', 'storage')
ORDER BY table_schema, table_name
LIMIT 500;

-- 2. Columns, without selecting application rows.
SELECT table_schema, table_name, ordinal_position, column_name,
       data_type, udt_schema, udt_name, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema IN ('public', 'storage')
ORDER BY table_schema, table_name, ordinal_position
LIMIT 2000;

-- 3. Constraints and indexes.
SELECT n.nspname AS schema_name, c.relname AS relation_name,
       con.conname AS constraint_name, con.contype AS constraint_type,
       pg_get_constraintdef(con.oid, true) AS constraint_definition
FROM pg_constraint AS con
JOIN pg_class AS c ON c.oid = con.conrelid
JOIN pg_namespace AS n ON n.oid = c.relnamespace
WHERE n.nspname IN ('public', 'storage')
ORDER BY n.nspname, c.relname, con.conname
LIMIT 2000;

SELECT schemaname, tablename, indexname, indexdef
FROM pg_indexes
WHERE schemaname IN ('public', 'storage')
ORDER BY schemaname, tablename, indexname
LIMIT 2000;

-- 4. Extensions.
SELECT extname, extversion, extnamespace::regnamespace::text AS extension_schema
FROM pg_extension
ORDER BY extname
LIMIT 100;

-- 5. Functions, owners, security mode, fixed search path, and ACL metadata.
-- pg_get_functiondef is definition metadata; this does not execute a function.
SELECT n.nspname AS schema_name, p.proname AS function_name,
       pg_get_function_identity_arguments(p.oid) AS identity_arguments,
       r.rolname AS owner_name, p.prosecdef AS security_definer,
       p.proconfig AS function_config,
       pg_get_userbyid(p.proowner) AS owner_text,
       p.proacl AS execution_acl
FROM pg_proc AS p
JOIN pg_namespace AS n ON n.oid = p.pronamespace
JOIN pg_roles AS r ON r.oid = p.proowner
WHERE n.nspname IN ('public', 'security')
ORDER BY n.nspname, p.proname, identity_arguments
LIMIT 1000;

-- 6. Search-path/function-body dependency review. This searches definitions
-- but never calls public.is_admin(uuid) or any other application routine.
SELECT n.nspname AS schema_name, p.proname AS function_name,
       pg_get_function_identity_arguments(p.oid) AS identity_arguments,
       (pg_get_functiondef(p.oid) ILIKE '%public.is_admin%') AS references_legacy_admin_helper,
       (pg_get_functiondef(p.oid) ILIKE '%is_admin%') AS references_admin_text
FROM pg_proc AS p
JOIN pg_namespace AS n ON n.oid = p.pronamespace
WHERE n.nspname IN ('public', 'security')
ORDER BY n.nspname, p.proname, identity_arguments
LIMIT 1000;

-- 7. RLS status and policies. Expressions are metadata, not policy execution.
SELECT n.nspname AS schema_name, c.relname AS table_name,
       c.relrowsecurity AS rls_enabled, c.relforcerowsecurity AS force_rls
FROM pg_class AS c
JOIN pg_namespace AS n ON n.oid = c.relnamespace
WHERE n.nspname IN ('public', 'storage') AND c.relkind IN ('r', 'p', 'v')
ORDER BY n.nspname, c.relname
LIMIT 1000;

SELECT schemaname, tablename, policyname, permissive, roles,
       cmd, qual, with_check
FROM pg_policies
WHERE schemaname IN ('public', 'storage')
ORDER BY schemaname, tablename, policyname
LIMIT 2000;

-- 8. Triggers and trigger functions.
SELECT event_object_schema, event_object_table, trigger_name,
       event_manipulation, action_timing, action_statement
FROM information_schema.triggers
WHERE event_object_schema IN ('public', 'storage')
ORDER BY event_object_schema, event_object_table, trigger_name
LIMIT 2000;

-- 9. Views and security settings.
SELECT n.nspname AS schema_name, c.relname AS view_name,
       c.reloptions, pg_get_userbyid(c.relowner) AS owner_name,
       c.relrowsecurity AS rls_enabled
FROM pg_class AS c
JOIN pg_namespace AS n ON n.oid = c.relnamespace
WHERE n.nspname IN ('public', 'storage') AND c.relkind IN ('v', 'm')
ORDER BY n.nspname, c.relname
LIMIT 500;

-- 10. Table and column ACLs. This reports grants, not data.
SELECT table_schema, table_name, grantee, privilege_type,
       is_grantable
FROM information_schema.role_table_grants
WHERE table_schema IN ('public', 'storage')
ORDER BY table_schema, table_name, grantee, privilege_type
LIMIT 5000;

SELECT table_schema, table_name, column_name, grantee,
       privilege_type, is_grantable
FROM information_schema.column_privileges
WHERE table_schema IN ('public', 'storage')
ORDER BY table_schema, table_name, column_name, grantee, privilege_type
LIMIT 10000;

-- 11. Default privileges (metadata only).
SELECT defaclrole::regrole::text AS owner_role,
       defaclnamespace::regnamespace::text AS schema_name,
       defaclobjtype, defaclacl
FROM pg_default_acl
ORDER BY owner_role, schema_name, defaclobjtype
LIMIT 500;

-- 12. Storage buckets and policies; no objects or file metadata.
SELECT id, name, public, file_size_limit, allowed_mime_types
FROM storage.buckets
ORDER BY id
LIMIT 200;

SELECT schemaname, tablename, policyname, roles, cmd, qual, with_check
FROM pg_policies
WHERE schemaname = 'storage'
ORDER BY tablename, policyname
LIMIT 500;

-- 13. Migration history, if the standard table exists after reconstruction.
-- If this relation is absent, record that fact rather than creating it here.
SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema = 'supabase_migrations'
  AND table_name = 'schema_migrations'
LIMIT 20;

-- Run the following only when the preceding query confirms the table exists:
-- SELECT version, name, statements
-- FROM supabase_migrations.schema_migrations
-- ORDER BY version, name
-- LIMIT 500;

-- 14. Explicit source-helper dependency search across policies and routines.
SELECT schemaname, tablename, policyname,
       (qual ILIKE '%public.is_admin%') AS using_legacy_helper,
       (with_check ILIKE '%public.is_admin%') AS checking_legacy_helper
FROM pg_policies
WHERE schemaname IN ('public', 'storage')
  AND (qual ILIKE '%is_admin%' OR with_check ILIKE '%is_admin%')
ORDER BY schemaname, tablename, policyname
LIMIT 1000;

-- Never append a SELECT from auth.users, public.profiles, or application rows.
-- Never call public.is_admin(uuid) as a membership test.
