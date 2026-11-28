-- SCHOLARS shared staging baseline: foundational schema only
-- Reconstructed 2026-11-28 from read-only production catalog metadata and the
-- verified ImperioKDB/Scholars migration definitions.
--
-- This file is intentionally included inside 00_initialization.sql's outer
-- transaction. It contains DDL only: no rows, seed data, credentials,
-- provider destinations, webhooks, cron jobs, external integrations,
-- transaction-control statements, or either pinned PR migration.
--
-- Managed prerequisites supplied by Supabase and deliberately not recreated:
-- auth.users, auth.identities, auth.uid(), auth.role(), and the managed
-- supabase_migrations bookkeeping schema.

set local search_path = public, extensions, pg_catalog;

create schema if not exists extensions;
create extension if not exists "pgcrypto" with schema extensions;
create extension if not exists "uuid-ossp" with schema extensions;

-- Enum closure used by the shared catalog and the two pinned migrations.
do $$ begin
  create type public.institution_type as enum
    ('federal_uni', 'state_uni', 'private_uni', 'polytechnic', 'college_of_education');
exception when duplicate_object then null; end $$;
do $$ begin
  create type public.scholarship_level as enum ('undergrad', 'postgrad', 'both');
exception when duplicate_object then null; end $$;
do $$ begin
  create type public.rule_operator as enum ('eq', 'gte', 'lte', 'in', 'exists');
exception when duplicate_object then null; end $$;
do $$ begin
  create type public.notification_type as enum
    ('deadline_reminder', 'new_match', 'checkin_reminder', 'new_scholarship',
     'new_opportunity', 'discussion_reply', 'discussion_helpful',
     'opportunity_deadline_passed');
exception when duplicate_object then null; end $$;
do $$ begin
  create type public.application_status as enum
    ('in_progress', 'submitted', 'accepted', 'rejected', 'not_applied');
exception when duplicate_object then null; end $$;
do $$ begin
  create type public.competitiveness_tier as enum ('low', 'medium', 'high', 'very_high');
exception when duplicate_object then null; end $$;
do $$ begin
  create type public.opportunity_type as enum
    ('fellowship', 'internship', 'competition', 'mentorship', 'training');
exception when duplicate_object then null; end $$;
do $$ begin
  create type public.community_role as enum ('founder', 'contributor', 'student');
exception when duplicate_object then null; end $$;

-- Profiles and catalog foundation. The columns below are the production
-- definitions required by the deadline and broadcast code paths.
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  discipline text,
  gpa numeric,
  nationality text default 'Nigerian',
  gender text,
  financial_need boolean not null default false,
  career_goals text,
  is_admin boolean not null default false,
  profile_completeness integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  date_of_birth date,
  state_of_origin text,
  lga_of_origin text,
  year_of_study integer check (year_of_study is null or year_of_study between 100 and 600),
  institution_name text,
  institution_type public.institution_type,
  jamb_score integer check (jamb_score is null or jamb_score between 0 and 400),
  waec_credit_count integer check (waec_credit_count is null or waec_credit_count between 0 and 9),
  has_english_maths_credit boolean not null default false,
  disability_status boolean not null default false,
  has_valid_id boolean not null default false,
  has_transcript boolean not null default false,
  has_recommendation_letter boolean not null default false,
  has_personal_statement boolean not null default false,
  has_lga_certificate boolean not null default false,
  referred_by uuid references public.profiles(id) on delete set null,
  xp_total integer not null default 0,
  avatar_url text,
  profile_reminder_last_sent_at timestamptz,
  profile_reminder_count integer not null default 0,
  whatsapp_opt_in boolean not null default false,
  whatsapp_number text,
  last_seen timestamptz,
  last_seen_at timestamptz,
  onboarding_step smallint not null default 0,
  onboarding_last_activity_at timestamptz,
  community_role public.community_role not null default 'student',
  community_bio text check (community_bio is null or char_length(community_bio) <= 280),
  referral_source text,
  campaign_id text,
  ambassador_code text,
  utm_source text,
  utm_medium text,
  utm_campaign text,
  pwa_installed_at timestamptz,
  push_enable_clicked_at timestamptz,
  whatsapp_community_invite_opt_in boolean not null default false,
  whatsapp_community_invite_consented_at timestamptz,
  whatsapp_community_invite_withdrawn_at timestamptz,
  whatsapp_community_invite_notice_version text
);

create table public.scholarships (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  provider_name text not null,
  description text,
  amount text,
  deadline date,
  application_url text,
  level public.scholarship_level not null default 'both',
  discipline text,
  verified boolean not null default false,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  research_notes text,
  how_to_apply text,
  awards_available integer check (awards_available is null or awards_available > 0),
  estimated_applicant_pool integer check (estimated_applicant_pool is null or estimated_applicant_pool > 0),
  competitiveness_tier public.competitiveness_tier,
  historical_acceptance_rate numeric check (historical_acceptance_rate is null or historical_acceptance_rate between 0 and 1),
  competitiveness_notes text,
  opens_at date,
  last_cycle_closed_at date,
  last_verified_at timestamptz,
  slug text not null
);

create table public.opportunities (
  id uuid primary key default gen_random_uuid(),
  type public.opportunity_type not null,
  title text not null,
  provider_name text not null,
  description text,
  eligibility_notes text,
  duration text,
  location text,
  compensation text,
  discipline text,
  deadline date,
  opens_at date,
  application_url text,
  how_to_apply text,
  verified boolean not null default false,
  created_by uuid references auth.users(id),
  research_notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  slug text not null,
  deadline_passed_at timestamptz
);

create table public.scholarship_rules (
  id uuid primary key default gen_random_uuid(),
  scholarship_id uuid not null references public.scholarships(id) on delete cascade,
  field text not null,
  operator public.rule_operator not null,
  value jsonb not null,
  created_at timestamptz not null default now(),
  gating boolean not null default true
);

create table public.saved_scholarships (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  scholarship_id uuid not null references public.scholarships(id) on delete cascade,
  saved_at timestamptz not null default now(),
  unique (profile_id, scholarship_id)
);

create table public.saved_opportunities (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  opportunity_id uuid not null references public.opportunities(id) on delete cascade,
  saved_at timestamptz not null default now(),
  unique (profile_id, opportunity_id)
);

create table public.applications (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  scholarship_id uuid references public.scholarships(id) on delete cascade,
  status public.application_status not null default 'in_progress',
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  draft_statement text,
  draft_summary jsonb,
  draft_generated_at timestamptz,
  draft_confirmed_at timestamptz,
  link_clicked_at timestamptz,
  checkin_prompted_at timestamptz,
  checkin_snoozed_until timestamptz,
  opportunity_id uuid references public.opportunities(id) on delete cascade,
  constraint applications_one_listing_check check
    (((scholarship_id is not null)::integer + (opportunity_id is not null)::integer) = 1),
  unique (profile_id, scholarship_id)
);

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  scholarship_id uuid references public.scholarships(id) on delete cascade,
  type public.notification_type not null,
  sent_at timestamptz,
  created_at timestamptz not null default now(),
  opportunity_id uuid references public.opportunities(id) on delete cascade,
  metadata jsonb not null default '{}',
  read_at timestamptz
);

create table public.announcement_log (
  profile_id uuid not null references public.profiles(id) on delete cascade,
  listing_kind text not null check (listing_kind in ('scholarship', 'opportunity')),
  listing_id uuid not null,
  created_at timestamptz not null default now(),
  primary key (profile_id, listing_kind, listing_id)
);

create table public.broadcast_delivery_log (
  id uuid primary key default gen_random_uuid(),
  broadcast_id uuid not null,
  recipient_email text not null,
  recipient_user_id uuid references auth.users(id) on delete set null,
  status text not null check (status in ('sent', 'failed')),
  attempts integer not null default 1 check (attempts > 0),
  provider_message text,
  error_message text,
  created_at timestamptz not null default now()
);

create table public.workflow_jobs (
  id uuid primary key default gen_random_uuid(),
  kind text not null,
  idempotency_key text not null unique,
  payload jsonb not null default '{}',
  status text not null default 'pending'
    check (status in ('pending', 'leased', 'succeeded', 'retryable', 'dead_letter')),
  attempts integer not null default 0 check (attempts >= 0),
  available_at timestamptz not null default now(),
  lease_until timestamptz,
  correlation_id uuid,
  last_error jsonb,
  result_metadata jsonb,
  created_at timestamptz not null default now(),
  completed_at timestamptz
);

create table public.notification_deliveries (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  scholarship_id uuid references public.scholarships(id) on delete cascade,
  campaign_key text not null,
  channel text not null check (channel in ('email', 'whatsapp', 'push')),
  schedule_bucket text not null,
  dedupe_key text not null unique,
  template_version text not null,
  status text not null default 'pending'
    check (status in ('pending', 'leased', 'accepted', 'delivered', 'bounced', 'suppressed', 'failed', 'retryable', 'dead_letter', 'unknown')),
  attempts integer not null default 0 check (attempts >= 0),
  provider_message_id text,
  available_at timestamptz not null default now(),
  last_error jsonb,
  sent_at timestamptz,
  created_at timestamptz not null default now(),
  lease_until timestamptz
);

create table public.push_tokens (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  expo_push_token text not null,
  platform text,
  device_id text,
  app_version text,
  enabled boolean not null default true,
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create table public.web_push_subscriptions (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  endpoint text not null check (endpoint like 'https://%'),
  p256dh text not null,
  auth text not null,
  enabled boolean not null default true,
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (profile_id, endpoint)
);

-- Durable ledgers are private by default. The downstream PR migrations add
-- the broadcast-specific tables and service-role execution grants.
do $$ declare t text; begin
  foreach t in array array['profiles','scholarships','opportunities','scholarship_rules','saved_scholarships',
    'saved_opportunities','applications','notifications','announcement_log','broadcast_delivery_log',
    'workflow_jobs','notification_deliveries','push_tokens','web_push_subscriptions'] loop
    execute format('alter table public.%I enable row level security', t);
  end loop;
end $$;

create index idx_scholarship_rules_scholarship_id on public.scholarship_rules (scholarship_id);
create index idx_applications_profile_id on public.applications (profile_id);
create index idx_applications_scholarship_id on public.applications (scholarship_id);
create unique index applications_profile_opportunity_unique on public.applications (profile_id, opportunity_id) where opportunity_id is not null;
create index idx_saved_scholarships_profile_id on public.saved_scholarships (profile_id);
create index idx_saved_scholarships_scholarship_id on public.saved_scholarships (scholarship_id);
create index idx_saved_opportunities_profile_id on public.saved_opportunities (profile_id);
create index idx_saved_opportunities_opportunity_id on public.saved_opportunities (opportunity_id);
create index idx_scholarships_verified_deadline on public.scholarships (deadline, id) where verified;
create index idx_opportunities_verified_deadline on public.opportunities (deadline, id) where verified;
create unique index scholarships_slug_key on public.scholarships (slug);
create unique index opportunities_slug_key on public.opportunities (slug);
create index idx_scholarships_verified_created_at on public.scholarships (created_at desc, id) where verified;
create index idx_opportunities_verified_created_at on public.opportunities (created_at desc, id) where verified;
create index idx_announcement_log_profile_created on public.announcement_log (profile_id, created_at desc);
create index idx_broadcast_delivery_log_broadcast on public.broadcast_delivery_log (broadcast_id, created_at desc);
create index idx_broadcast_delivery_log_recipient on public.broadcast_delivery_log (recipient_email, created_at desc);
create index idx_workflow_jobs_claim on public.workflow_jobs (status, available_at, lease_until);
create index idx_workflow_jobs_kind_status on public.workflow_jobs (kind, status, created_at desc);
create index idx_notification_deliveries_claim on public.notification_deliveries (status, available_at, created_at);
create index idx_notification_deliveries_profile on public.notification_deliveries (profile_id, created_at desc);
create index idx_notification_deliveries_provider on public.notification_deliveries (provider_message_id) where provider_message_id is not null;
create index idx_notification_deliveries_lease on public.notification_deliveries (status, lease_until, available_at);
create index idx_push_tokens_profile_enabled on public.push_tokens (profile_id) where enabled;
create index idx_web_push_subscriptions_profile_enabled on public.web_push_subscriptions (profile_id, last_seen_at desc) where enabled;

-- RLS evaluates this helper as the signed-in role. Browser callers can check
-- only themselves. Trusted service calls can check a supplied user ID.
create or replace function public.is_admin(p_user_id uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.profiles p
    where p.id = p_user_id and p.is_admin is true
      and (p_user_id = (select auth.uid()) or current_setting('role', true) = 'service_role'
        or session_user = 'service_role')
  );
$$;
revoke all on function public.is_admin(uuid) from public, anon, authenticated, service_role;
grant execute on function public.is_admin(uuid) to authenticated, service_role;

create or replace function public.set_updated_at()
returns trigger language plpgsql set search_path = '' as $$
begin
  new.updated_at := now();
  return new;
end;
$$;
revoke all on function public.set_updated_at() from public, anon, authenticated, service_role;

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id, full_name)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'full_name', split_part(new.email, '@', 1)))
  on conflict (id) do nothing;
  return new;
end;
$$;
revoke all on function public.handle_new_user() from public, anon, authenticated, service_role;

create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();
create trigger scholarships_set_updated_at
before update on public.scholarships
for each row execute function public.set_updated_at();
create trigger opportunities_set_updated_at
before update on public.opportunities
for each row execute function public.set_updated_at();
create trigger applications_set_updated_at
before update on public.applications
for each row execute function public.set_updated_at();
create trigger web_push_subscriptions_set_updated_at
before update on public.web_push_subscriptions
for each row execute function public.set_updated_at();
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

create or replace function public.claim_notification_delivery(
  p_delivery_id uuid, p_lease_until timestamptz
)
returns table (id uuid, dedupe_key text)
language sql security definer set search_path = '' as $$
  update public.notification_deliveries d
  set status = 'leased', attempts = d.attempts + 1,
      available_at = now(), lease_until = p_lease_until
  where d.id = p_delivery_id
    and d.available_at <= now()
    and (d.status in ('pending', 'retryable')
      or (d.status = 'leased' and d.lease_until < now()))
  returning d.id, d.dedupe_key;
$$;
revoke all on function public.claim_notification_delivery(uuid, timestamptz)
  from public, anon, authenticated;
grant execute on function public.claim_notification_delivery(uuid, timestamptz) to service_role;

-- Public catalog reads and owner-scoped student writes. Private ledgers have
-- no browser policies; service_role and SECURITY DEFINER workers own them.
create policy profiles_select_own on public.profiles for select to authenticated
  using (auth.uid() = id or public.is_admin(auth.uid()));
create policy profiles_insert_own on public.profiles for insert to authenticated
  with check (auth.uid() = id and not is_admin);
create policy profiles_update_own on public.profiles for update to authenticated
  using (auth.uid() = id) with check (auth.uid() = id);
create policy profiles_delete_own on public.profiles for delete to authenticated
  using (auth.uid() = id);
create policy scholarships_select_verified on public.scholarships for select to anon
  using (verified is true);
create policy scholarships_select_authenticated on public.scholarships for select to authenticated
  using (verified is true or public.is_admin(auth.uid())
    or exists (select 1 from public.saved_scholarships s where s.scholarship_id = scholarships.id and s.profile_id = auth.uid())
    or exists (select 1 from public.applications a where a.scholarship_id = scholarships.id and a.profile_id = auth.uid()));
create policy opportunities_select_verified on public.opportunities for select to anon, authenticated
  using (verified is true);
create policy opportunities_admin_all on public.opportunities for all to authenticated
  using (public.is_admin(auth.uid())) with check (public.is_admin(auth.uid()));
create policy scholarship_rules_select_authenticated on public.scholarship_rules for select to authenticated
  using (true);
create policy saved_scholarships_select_own on public.saved_scholarships for select to authenticated
  using (auth.uid() = profile_id);
create policy saved_scholarships_insert_own on public.saved_scholarships for insert to authenticated
  with check (auth.uid() = profile_id);
create policy saved_scholarships_delete_own on public.saved_scholarships for delete to authenticated
  using (auth.uid() = profile_id);
create policy saved_opportunities_select_own on public.saved_opportunities for select to authenticated
  using (auth.uid() = profile_id);
create policy saved_opportunities_insert_own on public.saved_opportunities for insert to authenticated
  with check (auth.uid() = profile_id);
create policy saved_opportunities_delete_own on public.saved_opportunities for delete to authenticated
  using (auth.uid() = profile_id);
create policy applications_select_own on public.applications for select to authenticated
  using (auth.uid() = profile_id or public.is_admin(auth.uid()));
create policy applications_insert_own on public.applications for insert to authenticated
  with check (auth.uid() = profile_id);
create policy applications_update_own on public.applications for update to authenticated
  using (auth.uid() = profile_id) with check (auth.uid() = profile_id);
create policy notifications_select_own on public.notifications for select to authenticated
  using (auth.uid() = profile_id);
create policy notifications_update_own on public.notifications for update to authenticated
  using (auth.uid() = profile_id) with check (auth.uid() = profile_id);
create policy web_push_subscriptions_select_own on public.web_push_subscriptions for select to authenticated
  using (auth.uid() = profile_id);
create policy web_push_subscriptions_insert_own on public.web_push_subscriptions for insert to authenticated
  with check (auth.uid() = profile_id);
create policy web_push_subscriptions_update_own on public.web_push_subscriptions for update to authenticated
  using (auth.uid() = profile_id) with check (auth.uid() = profile_id);
create policy web_push_subscriptions_delete_own on public.web_push_subscriptions for delete to authenticated
  using (auth.uid() = profile_id);

-- Supabase projects may automatically grant broad table privileges in public.
-- Replace them on the new foundation objects before applying the role matrix.
revoke create on schema public from public, anon, authenticated;
grant usage on schema public to anon, authenticated, service_role;
revoke all on public.profiles, public.scholarships, public.opportunities, public.scholarship_rules,
  public.saved_scholarships, public.saved_opportunities, public.applications, public.notifications,
  public.announcement_log, public.broadcast_delivery_log, public.workflow_jobs,
  public.notification_deliveries, public.push_tokens, public.web_push_subscriptions
  from public, anon, authenticated, service_role;
grant select, insert, update, delete on public.profiles, public.scholarships, public.opportunities,
  public.scholarship_rules, public.saved_scholarships, public.saved_opportunities, public.applications,
  public.notifications, public.announcement_log, public.broadcast_delivery_log, public.workflow_jobs,
  public.notification_deliveries, public.push_tokens, public.web_push_subscriptions to service_role;

grant select (id, slug, title, provider_name, amount, deadline, opens_at,
  last_cycle_closed_at, level, discipline, verified, last_verified_at) on public.scholarships to anon;
grant select (id, slug, type, title, provider_name, duration, location,
  compensation, deadline, verified) on public.opportunities to anon;
grant select on public.scholarships, public.scholarship_rules to authenticated;
grant select, insert, update, delete on public.opportunities to authenticated;
grant select, insert, delete on public.saved_scholarships, public.saved_opportunities to authenticated;
grant select, insert, update on public.applications to authenticated;
grant select, update (read_at) on public.notifications to authenticated;
grant select, insert, update, delete on public.web_push_subscriptions to authenticated;
grant select, delete on public.profiles to authenticated;
-- Profile upserts include id in both the INSERT and UPDATE lists. The ownership
-- policies require the old and new id to match the authenticated user.
grant insert (id, full_name, discipline, gpa, nationality, gender, financial_need, career_goals,
  date_of_birth, state_of_origin, lga_of_origin, year_of_study, institution_name,
  institution_type, jamb_score, waec_credit_count, has_english_maths_credit,
  disability_status, has_valid_id, has_transcript, has_recommendation_letter,
  has_personal_statement, has_lga_certificate, avatar_url, whatsapp_opt_in,
  whatsapp_number, last_seen, last_seen_at, onboarding_step, onboarding_last_activity_at,
  community_bio, referral_source, campaign_id, ambassador_code, utm_source, utm_medium,
  utm_campaign, pwa_installed_at, push_enable_clicked_at, whatsapp_community_invite_opt_in,
  whatsapp_community_invite_consented_at, whatsapp_community_invite_withdrawn_at,
  whatsapp_community_invite_notice_version),
update (id, full_name, discipline, gpa, nationality, gender, financial_need, career_goals,
  date_of_birth, state_of_origin, lga_of_origin, year_of_study, institution_name,
  institution_type, jamb_score, waec_credit_count, has_english_maths_credit,
  disability_status, has_valid_id, has_transcript, has_recommendation_letter,
  has_personal_statement, has_lga_certificate, avatar_url, whatsapp_opt_in,
  whatsapp_number, last_seen, last_seen_at, onboarding_step, onboarding_last_activity_at,
  community_bio, referral_source, campaign_id, ambassador_code, utm_source, utm_medium,
  utm_campaign, pwa_installed_at, push_enable_clicked_at, whatsapp_community_invite_opt_in,
  whatsapp_community_invite_consented_at, whatsapp_community_invite_withdrawn_at,
  whatsapp_community_invite_notice_version)
on public.profiles to authenticated;

comment on table public.workflow_jobs is
  'Durable background-job ledger; workers claim with a lease and use idempotency_key.';
comment on table public.notification_deliveries is
  'Idempotent outbound notification ledger; accepted and delivered are distinct states.';

-- No PR #50 or PR #51 objects are defined here. They are included exactly
-- once, and only after this file, by 00_initialization.sql.
