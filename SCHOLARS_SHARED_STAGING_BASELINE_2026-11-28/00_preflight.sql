-- Read-only preflight. Run before 00_initialization.sql.
-- Expected target: aqhktriwaglvvrchxmtd (scholars-staging).
-- This script contains SELECTs only.

select current_database() as database_name, current_user as login_role,
       current_setting('server_version') as server_version;

select n.nspname as schema_name, c.relname as object_name, c.relkind
from pg_class c join pg_namespace n on n.oid = c.relnamespace
where n.nspname in ('public','broadcast_private')
  and c.relkind in ('r','p','v','m','S','f')
order by 1,2;

select version, name
from supabase_migrations.schema_migrations
order by version;

select extname, extversion, n.nspname as installed_schema
from pg_extension e join pg_namespace n on n.oid=e.extnamespace
where extname in ('pgcrypto','uuid-ossp','pg_stat_statements','plpgsql')
order by 1;

select count(*) as public_object_count
from pg_class c join pg_namespace n on n.oid=c.relnamespace
where n.nspname='public' and c.relkind in ('r','p','v','m','S','f');

-- Must report absent (or zero rows) before initialization: no worker scheduler,
-- provider secrets/destinations, or qualification data are permitted.
select to_regclass('cron.job') as cron_job_catalog;

select table_schema, table_name, column_name
from information_schema.columns
where table_schema='public'
  and (column_name ilike '%secret%' or column_name ilike '%webhook%' or column_name ilike '%api_key%'
       or column_name ilike '%provider%')
order by 1,2,3
limit 200;
