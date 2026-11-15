# Scholars Resource Centre — Production Verification SQL Results

## Execution metadata

- Repository: `ImperioKDB/Updates`
- Approved SQL commit: `5f4af4f2c96141a8a920288046952c3f6e189a67`
- Approved SQL path: `reports/scholars/sql/2026-11-15-resource-center-read-only-security-verification.sql`
- Supabase project: `scholarship-platform`
- Project reference: `cmdglabohpttgfofcmqc`
- Execution date: 2026-11-15
- Execution window: approximately 14:25:16–14:26:22 WAT (UTC+01:00), equivalent to 13:25:16–13:26:22 UTC
- Method: 13 individual read-only catalog SELECTs, in source order
- Safety: No mutation statements were executed. `public.is_admin(uuid)` was not called. No profile rows or personal records were read.
- Query-result bound: Each approved SELECT was executed as the inner query of `SELECT * FROM (...) AS verification_result LIMIT 1000`; the result values below are the complete returned sets.
- Errors: None.

## Section A — Schema privileges

### Q01 — A.1 Schema USAGE and CREATE on `public`

**Status:** Succeeded; 4 rows.

**Approved inner query:**

```sql
SELECT
  'anon' AS role_name,
  has_schema_privilege('anon', 'public', 'USAGE') AS schema_usage,
  has_schema_privilege('anon', 'public', 'CREATE') AS schema_create
UNION ALL
SELECT
  'authenticated',
  has_schema_privilege('authenticated', 'public', 'USAGE'),
  has_schema_privilege('authenticated', 'public', 'CREATE')
UNION ALL
SELECT
  'service_role',
  has_schema_privilege('service_role', 'public', 'USAGE'),
  has_schema_privilege('service_role', 'public', 'CREATE')
UNION ALL
SELECT
  'public',
  has_schema_privilege('public', 'public', 'USAGE'),
  has_schema_privilege('public', 'public', 'CREATE');
```

**Returned values:**

```json
[
  {"role_name":"anon","schema_usage":true,"schema_create":false},
  {"role_name":"authenticated","schema_usage":true,"schema_create":false},
  {"role_name":"service_role","schema_usage":true,"schema_create":false},
  {"role_name":"public","schema_usage":true,"schema_create":false}
]
```

## Section B — Role membership and inheritance

### Q02 — B.1 Direct role membership

**Status:** Succeeded; 9 rows.

**Approved inner query:**

```sql
SELECT
  pg_get_userbyid(m.member) AS member_role,
  pg_get_userbyid(m.roleid) AS granted_role,
  pg_get_userbyid(m.grantor) AS grantor,
  m.admin_option AS can_admin_grant,
  to_jsonb(m)->>'inherit_option' AS inherits_privileges,
  to_jsonb(m)->>'set_option' AS can_set_role
FROM pg_auth_members m
WHERE pg_get_userbyid(m.member) IN ('anon', 'authenticated', 'service_role')
   OR pg_get_userbyid(m.roleid) IN ('anon', 'authenticated', 'service_role')
ORDER BY member_role, granted_role;
```

**Returned values:**

```json
[
  {"member_role":"authenticator","granted_role":"anon","grantor":"supabase_admin","can_admin_grant":false,"inherits_privileges":"false","can_set_role":"true"},
  {"member_role":"authenticator","granted_role":"authenticated","grantor":"supabase_admin","can_admin_grant":false,"inherits_privileges":"false","can_set_role":"true"},
  {"member_role":"authenticator","granted_role":"service_role","grantor":"supabase_admin","can_admin_grant":false,"inherits_privileges":"false","can_set_role":"true"},
  {"member_role":"postgres","granted_role":"anon","grantor":"supabase_admin","can_admin_grant":true,"inherits_privileges":"true","can_set_role":"true"},
  {"member_role":"postgres","granted_role":"authenticated","grantor":"supabase_admin","can_admin_grant":true,"inherits_privileges":"true","can_set_role":"true"},
  {"member_role":"postgres","granted_role":"service_role","grantor":"supabase_admin","can_admin_grant":true,"inherits_privileges":"true","can_set_role":"true"},
  {"member_role":"supabase_realtime_admin","granted_role":"anon","grantor":"supabase_admin","can_admin_grant":false,"inherits_privileges":"false","can_set_role":"true"},
  {"member_role":"supabase_realtime_admin","granted_role":"authenticated","grantor":"supabase_admin","can_admin_grant":false,"inherits_privileges":"false","can_set_role":"true"},
  {"member_role":"supabase_realtime_admin","granted_role":"service_role","grantor":"supabase_admin","can_admin_grant":false,"inherits_privileges":"false","can_set_role":"true"}
]
```

### Q03 — B.2 Role attributes

**Status:** Succeeded; 3 rows.

**Approved inner query:**

```sql
SELECT
  rolname AS role_name,
  rolcanlogin AS can_login,
  rolinherit AS inherits_by_default,
  rolsuper AS is_superuser
FROM pg_roles
WHERE rolname IN ('anon', 'authenticated', 'service_role')
ORDER BY rolname;
```

**Returned values:**

```json
[
  {"role_name":"anon","can_login":false,"inherits_by_default":true,"is_superuser":false},
  {"role_name":"authenticated","can_login":false,"inherits_by_default":true,"is_superuser":false},
  {"role_name":"service_role","can_login":false,"inherits_by_default":true,"is_superuser":false}
]
```

## Section C — Effective privileges on `public.profiles`

### Q04 — C.1 Effective table-level INSERT/UPDATE

**Status:** Succeeded; 4 rows.

**Approved inner query:**

```sql
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
  'public',
  has_table_privilege('public', 'public.profiles', 'INSERT'),
  has_table_privilege('public', 'public.profiles', 'UPDATE');
```

**Returned values:**

```json
[
  {"role_name":"anon","table_level_insert":false,"table_level_update":false},
  {"role_name":"authenticated","table_level_insert":true,"table_level_update":true},
  {"role_name":"service_role","table_level_insert":true,"table_level_update":true},
  {"role_name":"public","table_level_insert":false,"table_level_update":false}
]
```

### Q05 — C.2 Effective `profiles.is_admin` INSERT/UPDATE

**Status:** Succeeded; 4 rows.

**Approved inner query:**

```sql
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
  'public',
  has_column_privilege('public', 'public.profiles', 'is_admin', 'INSERT'),
  has_column_privilege('public', 'public.profiles', 'is_admin', 'UPDATE');
```

**Returned values:**

```json
[
  {"role_name":"anon","column_insert_is_admin":false,"column_update_is_admin":false},
  {"role_name":"authenticated","column_insert_is_admin":true,"column_update_is_admin":true},
  {"role_name":"service_role","column_insert_is_admin":true,"column_update_is_admin":true},
  {"role_name":"public","column_insert_is_admin":false,"column_update_is_admin":false}
]
```

### Q06 — C.3 Ordinary-column comparison

**Status:** Succeeded; 2 rows.

**Approved inner query:**

```sql
SELECT
  'authenticated' AS role_name,
  'full_name' AS column_name,
  has_column_privilege('authenticated', 'public.profiles', 'full_name', 'UPDATE') AS column_update_allowed
UNION ALL
SELECT
  'authenticated',
  'is_admin',
  has_column_privilege('authenticated', 'public.profiles', 'is_admin', 'UPDATE');
```

**Returned values:**

```json
[
  {"role_name":"authenticated","column_name":"full_name","column_update_allowed":true},
  {"role_name":"authenticated","column_name":"is_admin","column_update_allowed":true}
]
```

## Section D — Row-Level Security on `public.profiles`

### Q07 — D.1 RLS and FORCE RLS status

**Status:** Succeeded; 1 row.

**Approved inner query:**

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
  AND c.relkind = 'r';
```

**Returned values:**

```json
[
  {"schema_name":"public","table_name":"profiles","rls_enabled":true,"force_rls":false,"table_owner":"postgres"}
]
```

### Q08 — D.2 RLS policies

**Status:** Succeeded; 6 rows.

**Approved inner query:**

```sql
SELECT
  polname AS policy_name,
  polcmd AS command_type,
  unnest_roles.policy_role,
  pg_get_expr(polqual, polrelid) AS using_expression,
  pg_get_expr(polwithcheck, polrelid) AS with_check_expression
FROM pg_policy
JOIN pg_class ON pg_class.oid = polrelid
JOIN pg_namespace ON pg_namespace.oid = pg_class.relnamespace
CROSS JOIN LATERAL (
  SELECT pg_get_userbyid(rol.rolid) AS policy_role
  FROM unnest(polroles) AS rol(rolid)
) AS unnest_roles
WHERE pg_namespace.nspname = 'public'
  AND pg_class.relname = 'profiles'
ORDER BY polname, polcmd, unnest_roles.policy_role;
```

**Returned values:**

```json
[
  {"policy_name":"profiles_delete_own","command_type":"d","policy_role":"authenticated","using_expression":"(auth.uid() = id)","with_check_expression":null},
  {"policy_name":"profiles_insert_own","command_type":"a","policy_role":"authenticated","using_expression":null,"with_check_expression":"(auth.uid() = id)"},
  {"policy_name":"profiles_select_admin","command_type":"r","policy_role":"unknown (OID=0)","using_expression":"is_admin(auth.uid())","with_check_expression":null},
  {"policy_name":"profiles_select_own","command_type":"r","policy_role":"unknown (OID=0)","using_expression":"(auth.uid() = id)","with_check_expression":null},
  {"policy_name":"profiles_update_community_role_admin","command_type":"w","policy_role":"authenticated","using_expression":"is_admin(auth.uid())","with_check_expression":"is_admin(auth.uid())"},
  {"policy_name":"profiles_update_own","command_type":"w","policy_role":"authenticated","using_expression":"(auth.uid() = id)","with_check_expression":"(auth.uid() = id)"}
]
```

The literal value `unknown (OID=0)` is preserved exactly as returned. It represents the script's `pg_get_userbyid(0)` rendering of the PostgreSQL PUBLIC pseudo-role; PUBLIC is not an ordinary `pg_auth_members` membership row.

### Q09 — D.3 Effective table grants

**Status:** Succeeded; 19 rows.

**Approved inner query:**

```sql
SELECT
  grantee AS role_name,
  privilege_type,
  is_grantable
FROM information_schema.role_table_grants
WHERE table_schema = 'public'
  AND table_name = 'profiles'
ORDER BY grantee, privilege_type;
```

**Returned values:**

```json
[
  {"role_name":"anon","privilege_type":"SELECT","is_grantable":"NO"},
  {"role_name":"authenticated","privilege_type":"DELETE","is_grantable":"NO"},
  {"role_name":"authenticated","privilege_type":"INSERT","is_grantable":"NO"},
  {"role_name":"authenticated","privilege_type":"SELECT","is_grantable":"NO"},
  {"role_name":"authenticated","privilege_type":"UPDATE","is_grantable":"NO"},
  {"role_name":"postgres","privilege_type":"DELETE","is_grantable":"YES"},
  {"role_name":"postgres","privilege_type":"INSERT","is_grantable":"YES"},
  {"role_name":"postgres","privilege_type":"REFERENCES","is_grantable":"YES"},
  {"role_name":"postgres","privilege_type":"SELECT","is_grantable":"YES"},
  {"role_name":"postgres","privilege_type":"TRIGGER","is_grantable":"YES"},
  {"role_name":"postgres","privilege_type":"TRUNCATE","is_grantable":"YES"},
  {"role_name":"postgres","privilege_type":"UPDATE","is_grantable":"YES"},
  {"role_name":"service_role","privilege_type":"DELETE","is_grantable":"NO"},
  {"role_name":"service_role","privilege_type":"INSERT","is_grantable":"NO"},
  {"role_name":"service_role","privilege_type":"REFERENCES","is_grantable":"NO"},
  {"role_name":"service_role","privilege_type":"SELECT","is_grantable":"NO"},
  {"role_name":"service_role","privilege_type":"TRIGGER","is_grantable":"NO"},
  {"role_name":"service_role","privilege_type":"TRUNCATE","is_grantable":"NO"},
  {"role_name":"service_role","privilege_type":"UPDATE","is_grantable":"NO"}
]
```

### Q10 — D.4 Effective column grants on `is_admin`

**Status:** Succeeded; 12 rows.

**Approved inner query:**

```sql
SELECT
  grantee AS role_name,
  column_name,
  privilege_type
FROM information_schema.column_privileges
WHERE table_schema = 'public'
  AND table_name = 'profiles'
  AND column_name = 'is_admin'
ORDER BY grantee, privilege_type;
```

**Returned values:**

```json
[
  {"role_name":"anon","column_name":"is_admin","privilege_type":"SELECT"},
  {"role_name":"authenticated","column_name":"is_admin","privilege_type":"INSERT"},
  {"role_name":"authenticated","column_name":"is_admin","privilege_type":"SELECT"},
  {"role_name":"authenticated","column_name":"is_admin","privilege_type":"UPDATE"},
  {"role_name":"postgres","column_name":"is_admin","privilege_type":"INSERT"},
  {"role_name":"postgres","column_name":"is_admin","privilege_type":"REFERENCES"},
  {"role_name":"postgres","column_name":"is_admin","privilege_type":"SELECT"},
  {"role_name":"postgres","column_name":"is_admin","privilege_type":"UPDATE"},
  {"role_name":"service_role","column_name":"is_admin","privilege_type":"INSERT"},
  {"role_name":"service_role","column_name":"is_admin","privilege_type":"REFERENCES"},
  {"role_name":"service_role","column_name":"is_admin","privilege_type":"SELECT"},
  {"role_name":"service_role","column_name":"is_admin","privilege_type":"UPDATE"}
]
```

## Section E — `public.is_admin(uuid)` function metadata and privileges

### Q11 — E.1 Function existence, owner, SECURITY DEFINER, and configuration

**Status:** Succeeded; empty result set.

**Approved inner query:**

```sql
SELECT
  n.nspname AS schema_name,
  p.proname AS function_name,
  pg_get_function_identity_arguments(p.oid) AS argument_types,
  pg_get_userbyid(p.proowner) AS function_owner,
  p.prosecdef AS security_definer,
  p.proconfig AS configuration,
  p.prokind AS function_kind
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND p.proname = 'is_admin'
  AND pg_get_function_identity_arguments(p.oid) = 'uuid'
ORDER BY p.proname;
```

**Returned values:**

```json
[]
```

### Q12 — E.2 Effective EXECUTE privilege

**Status:** Succeeded; 4 rows.

**Approved inner query:**

```sql
SELECT
  'public' AS role_name,
  has_function_privilege('public', 'public.is_admin(uuid)', 'EXECUTE') AS execute_privilege
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
```

**Returned values:**

```json
[
  {"role_name":"public","execute_privilege":true},
  {"role_name":"anon","execute_privilege":true},
  {"role_name":"authenticated","execute_privilege":true},
  {"role_name":"service_role","execute_privilege":true}
]
```

This query checks privilege metadata only; it did not execute the function.

### Q13 — E.3 Raw function ACL

**Status:** Succeeded; empty result set.

**Approved inner query:**

```sql
SELECT
  n.nspname AS schema_name,
  p.proname AS function_name,
  pg_get_function_identity_arguments(p.oid) AS argument_types,
  p.proacl AS function_acl_raw
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND p.proname = 'is_admin'
  AND pg_get_function_identity_arguments(p.oid) = 'uuid';
```

**Returned values:**

```json
[]
```

## Result interpretation boundary

The values above are the complete actual results returned by the approved diagnostics. The E.1/E.2/E.3 discrepancy is intentionally preserved. E.2 directly reports effective EXECUTE as `true` for all four tested role labels, while E.1 and E.3 return no exact matching `pg_proc` row. No additional query, function call, privilege change, or remediation was performed to resolve or alter that discrepancy.
