-- Read-only preflight. Run before 00_initialization.sql.
-- Expected target: aqhktriwaglvvrchxmtd (scholars-staging).
-- This script contains SELECTs only.

\set ON_ERROR_STOP on
\if :{?HOST}
\else
  \echo 'ERROR: psql did not expose HOST; refusing preflight without endpoint evidence'
  \quit 3
\endif

select :'HOST' as connection_host,
       case when :'HOST' = 'db.aqhktriwaglvvrchxmtd.supabase.co'
            then 'PASS' else 'FAIL' end as expected_staging_host;

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

select case when count(*) = 1
              and bool_or(version = '20261125152047'
                          and name = 'create_better_auth_private_schema')
            then 'PASS' else 'FAIL' end as expected_managed_migration_history
from supabase_migrations.schema_migrations;

select to_regclass('auth.users') as auth_users_catalog,
       to_regclass('auth.identities') as auth_identities_catalog,
       (select count(*) from auth.users) as auth_user_count,
       (select count(*) from auth.identities) as auth_identity_count;

select extname, extversion, n.nspname as installed_schema
from pg_extension e join pg_namespace n on n.oid=e.extnamespace
where extname in ('pgcrypto','uuid-ossp','pg_stat_statements','plpgsql')
order by 1;

select count(*) as public_object_count
from pg_class c join pg_namespace n on n.oid=c.relnamespace
where n.nspname='public' and c.relkind in ('r','p','v','m','S','f');

-- Send the catalog query to PostgreSQL only when pg_cron is present.
select to_regclass('cron.job') is not null as has_cron_job \gset
\if :has_cron_job
  select 'present' as cron_job_catalog, count(*) as scheduled_job_count from cron.job;
\else
  select 'absent' as cron_job_catalog, 0::bigint as scheduled_job_count;
\endif

select table_schema, table_name, column_name
from information_schema.columns
where table_schema='public'
  and (column_name ilike '%secret%' or column_name ilike '%webhook%' or column_name ilike '%api_key%'
       or column_name ilike '%provider%')
order by 1,2,3
limit 200;
