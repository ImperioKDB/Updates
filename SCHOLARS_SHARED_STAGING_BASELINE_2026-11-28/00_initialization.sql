-- SCHOLARS shared staging baseline initialization
-- Reviewed 2026-11-28. NON-DESTRUCTIVE / NOT EXECUTED.
-- Target must be aqhktriwaglvvrchxmtd. Never run against production.
-- This file intentionally does not contain production rows, secrets, credentials,
-- webhook destinations, provider allocations, or scheduled jobs.
--
-- Execution contract (psql):
--   1. Run 00_preflight.sql against the empty staging project.
--   2. Supply an independently approved schema-only baseline at the path below.
--   3. Run this file from the repository directory with ON_ERROR_STOP=1.
--
-- The schema-only baseline is a required input, not an implicit replay of the
-- legacy migration directory. It must be produced from read-only inspection,
-- reviewed for managed-schema exclusions, and hashed in the change record.

\set ON_ERROR_STOP on
\if :{?HOST}
\else
  \echo 'ERROR: psql did not expose HOST; refusing to initialize without a connection-level endpoint guard'
  \quit 3
\endif
\if :{?target_ref}
\else
  \echo 'ERROR: pass target_ref=aqhktriwaglvvrchxmtd'
  \quit 3
\endif
\if :{?schema_only_baseline}
\else
  \echo 'ERROR: pass schema_only_baseline=/absolute/path/to/approved/schema-only-baseline.sql'
  \quit 3
\endif

begin;
set local lock_timeout = '5s';
set local statement_timeout = '10min';
set local search_path = public, extensions, pg_catalog;
set local app.target_ref = :'target_ref';
set local app.connection_host = :'HOST';

do $$
begin
  if current_setting('app.connection_host', true) <> 'db.aqhktriwaglvvrchxmtd.supabase.co' then
    raise exception 'refusing unexpected connection host: %', current_setting('app.connection_host', true);
  end if;
  if current_setting('app.target_ref', true) <> 'aqhktriwaglvvrchxmtd' then
    raise exception 'refusing a non-staging target';
  end if;
end $$;

-- Fail closed if this is not the expected empty staging inventory. The only
-- expected application-side migration at qualification time is the managed
-- auth-private-schema migration; no public application table may exist yet.
do $$
declare
  has_scheduled_jobs boolean;
begin
  if current_database() is null then
    raise exception 'database identity unavailable';
  end if;
  if exists (
    select 1 from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname = 'public' and c.relkind in ('r','p','v','m','S','f')
  ) then
    raise exception 'refusing non-empty public schema; baseline is not an in-place repair';
  end if;
  if to_regclass('auth.users') is null or to_regclass('auth.identities') is null then
    raise exception 'managed Auth baseline is missing';
  end if;
  if exists (select 1 from auth.users limit 1) or exists (select 1 from auth.identities limit 1) then
    raise exception 'refusing non-empty Auth baseline';
  end if;
  if to_regclass('supabase_migrations.schema_migrations') is null then
    raise exception 'migration bookkeeping is missing';
  end if;
  if (select count(*) from supabase_migrations.schema_migrations) <> 1
     or not exists (select 1 from supabase_migrations.schema_migrations
                    where version = '20261125152047'
                      and name = 'create_better_auth_private_schema') then
    raise exception 'unexpected staging migration history';
  end if;
  if to_regclass('cron.job') is not null then
    execute 'select exists (select 1 from cron.job)' into has_scheduled_jobs;
    if has_scheduled_jobs then
      raise exception 'refusing database with scheduled jobs';
    end if;
  end if;
end $$;

-- The reviewed schema-only baseline is the only source of foundational DDL.
\ir :schema_only_baseline

-- The two supplied PR migrations are applied only after the foundational schema.
\ir pinned-pr-sql/20261127000000_complete_deadline_reminders.sql
\ir pinned-pr-sql/20261127233336_durable_admin_broadcast.sql

-- Match the worker access contract even when Supabase grants privileges on
-- newly created objects. Deadline internals are used only by their owner RPCs.
revoke all on public.deadline_tracked_listings, public.deadline_email_attempts,
  public.deadline_reminder_run from service_role;
revoke all on sequence public.deadline_email_attempts_id_seq from public, anon, authenticated, service_role;
revoke execute on function public.deadline_stage_at(date, timestamptz, integer, integer) from service_role;

revoke all on public.broadcast_campaigns, public.broadcast_submissions, public.broadcast_targets,
  public.broadcast_provider_windows, public.broadcast_provider_state from service_role;
grant select, insert, update on public.broadcast_campaigns, public.broadcast_submissions, public.broadcast_targets,
  public.broadcast_provider_windows, public.broadcast_provider_state to service_role;
revoke all on sequence public.broadcast_targets_id_seq from service_role;
grant usage on sequence public.broadcast_targets_id_seq to service_role;

-- Post-DDL structural assertions; no row data is read or imported.
do $$
declare
  _name text;
begin
  foreach _name in array array[
    'public.profiles','public.scholarships','public.opportunities',
    'public.saved_scholarships','public.saved_opportunities',
    'public.applications','public.notification_deliveries','public.notifications',
    'public.workflow_jobs','public.push_tokens','public.web_push_subscriptions',
    'public.announcement_log','public.broadcast_delivery_log',
    'public.deadline_email_attempts','public.deadline_reminder_run',
    'public.broadcast_campaigns','public.broadcast_submissions',
    'public.broadcast_targets','public.broadcast_provider_windows',
    'public.broadcast_provider_state','public.deadline_tracked_listings'
  ] loop
    if to_regclass(_name) is null then raise exception 'missing required object: %', _name; end if;
  end loop;
  if to_regnamespace('broadcast_private') is null then raise exception 'missing broadcast_private schema'; end if;
  if not exists (select 1 from pg_proc p join pg_namespace n on n.oid=p.pronamespace
                 where n.nspname='public' and p.proname='prepare_deadline_reminders') then
    raise exception 'missing deadline RPC';
  end if;
  if not exists (select 1 from pg_proc p join pg_namespace n on n.oid=p.pronamespace
                 where n.nspname='public' and p.proname='broadcast_enqueue') then
    raise exception 'missing broadcast RPC';
  end if;
end $$;

commit;
\echo 'Baseline initialized transactionally. Run the separate preflight and fixture windows; do not enable workers or cron.'
