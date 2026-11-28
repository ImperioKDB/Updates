-- Run as postgres on a disposable database before initializing the packet.
create schema auth authorization supabase_auth_admin;
set role supabase_auth_admin;
create table auth.users (
  id uuid primary key,
  email varchar(255) unique,
  email_confirmed_at timestamptz,
  raw_user_meta_data jsonb
);
create table auth.identities (id uuid primary key, user_id uuid not null references auth.users(id));
create function auth.uid() returns uuid language sql stable as $$
  select coalesce(nullif(current_setting('request.jwt.claim.sub', true), ''),
    nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub')::uuid;
$$;
grant usage on schema auth to anon, authenticated, service_role;
grant execute on function auth.uid() to anon, authenticated, service_role;
reset role;

create schema extensions;
create extension pg_stat_statements with schema extensions;
create schema supabase_migrations;
create table supabase_migrations.schema_migrations (version text primary key, name text);
insert into supabase_migrations.schema_migrations values ('20261125152047', 'create_better_auth_private_schema');

-- Existing Supabase projects can grant access to API roles by default. Reproduce
-- the broad table, sequence and routine grants for objects owned by postgres.
\if :legacy_grants
  alter default privileges for role postgres in schema public
    grant all on tables to anon, authenticated, service_role;
  alter default privileges for role postgres in schema public
    grant all on sequences to anon, authenticated, service_role;
  alter default privileges for role postgres in schema public
    grant execute on functions to anon, authenticated, service_role;
\endif

\if :with_cron
  create schema cron;
  create table cron.job (jobid bigint primary key, active boolean not null);
\endif
