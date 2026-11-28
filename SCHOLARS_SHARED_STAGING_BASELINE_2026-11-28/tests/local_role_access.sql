begin;

create function pg_temp.assert_true(p_result boolean, p_message text) returns void language plpgsql as $$
begin
  if p_result is distinct from true then raise exception '%', p_message; end if;
end;
$$;

create function pg_temp.expect_denied(p_statement text) returns void language plpgsql as $$
begin
  execute p_statement;
  raise exception 'Expected insufficient privilege for %', p_statement;
exception when insufficient_privilege then
  null;
end;
$$;

select pg_temp.assert_true(not exists (
  select 1 from pg_class c join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public' and c.relkind in ('r', 'p') and not c.relrowsecurity
), 'Every foundation and pinned public table must have RLS');

select pg_temp.assert_true(not exists (
  select from (values ('anon'), ('authenticated')) api(role_name)
  cross join (values ('announcement_log'), ('broadcast_delivery_log'), ('workflow_jobs'),
    ('notification_deliveries'), ('push_tokens'), ('deadline_email_attempts'), ('deadline_reminder_run'),
    ('deadline_tracked_listings'), ('broadcast_campaigns'), ('broadcast_submissions'), ('broadcast_targets'),
    ('broadcast_provider_windows'), ('broadcast_provider_state')) t(table_name)
  cross join (values ('SELECT'), ('INSERT'), ('UPDATE'), ('DELETE'), ('TRUNCATE'), ('REFERENCES'), ('TRIGGER')) p(privilege)
  where has_table_privilege(api.role_name, 'public.' || t.table_name, p.privilege)
), 'Browser roles inherited a private table privilege');

select pg_temp.assert_true(not exists (
  select from (values ('profiles'), ('scholarships'), ('opportunities'), ('scholarship_rules'), ('saved_scholarships'),
    ('saved_opportunities'), ('applications'), ('notifications'), ('announcement_log'), ('broadcast_delivery_log'),
    ('workflow_jobs'), ('notification_deliveries'), ('push_tokens'), ('web_push_subscriptions')) t(table_name)
  cross join (values ('SELECT'), ('INSERT'), ('UPDATE'), ('DELETE')) p(privilege)
  where not has_table_privilege('service_role', 'public.' || t.table_name, p.privilege)
), 'Service role needs explicit DML on all foundational tables');

select pg_temp.assert_true(not exists (
  select from (values ('anon'), ('authenticated'), ('service_role')) api(role_name)
  cross join (values ('USAGE'), ('SELECT'), ('UPDATE')) p(privilege)
  where has_sequence_privilege(api.role_name, 'public.deadline_email_attempts_id_seq', p.privilege)
), 'Deadline reservation sequence must be accessible only to the owner');

select pg_temp.assert_true(
  has_sequence_privilege('service_role', 'public.broadcast_targets_id_seq', 'USAGE')
  and not has_sequence_privilege('service_role', 'public.broadcast_targets_id_seq', 'UPDATE')
  and not has_sequence_privilege('authenticated', 'public.broadcast_targets_id_seq', 'USAGE')
  and not has_table_privilege('service_role', 'public.broadcast_targets', 'DELETE')
  and not has_table_privilege('service_role', 'public.deadline_reminder_run', 'SELECT'),
  'Pinned worker access must not depend on broad default privileges');

select pg_temp.assert_true(not exists (
  select from (values ('is_admin'), ('community_role'), ('xp_total'), ('profile_completeness'),
    ('referred_by'), ('created_at'), ('updated_at'), ('profile_reminder_count'), ('profile_reminder_last_sent_at')) p(column_name)
  where has_column_privilege('authenticated', 'public.profiles', p.column_name, 'INSERT')
     or has_column_privilege('authenticated', 'public.profiles', p.column_name, 'UPDATE')
), 'Privileged profile INSERT or UPDATE grants must be revoked');

set local role supabase_auth_admin;
insert into auth.users (id, email, raw_user_meta_data) values
  ('00000000-0000-4000-8000-000000000001', 'student@example.invalid', '{"full_name":"Student","is_admin":true}'),
  ('00000000-0000-4000-8000-000000000002', 'admin@example.invalid', '{"full_name":"Administrator"}'),
  ('00000000-0000-4000-8000-000000000003', 'profile-recreate@example.invalid', '{}');
reset role;

set local role service_role;
select pg_temp.assert_true((select count(*) = 3 and not bool_or(is_admin) from public.profiles), 'Auth signup is unprivileged');
update public.profiles set is_admin = true, community_role = 'founder' where id = '00000000-0000-4000-8000-000000000002';
delete from public.profiles where id = '00000000-0000-4000-8000-000000000003';
select pg_temp.assert_true(public.is_admin('00000000-0000-4000-8000-000000000002'), 'Service role can verify admin authorization');
insert into public.opportunities (type, title, provider_name, slug, verified, research_notes) values
  ('internship', 'Verified opportunity', 'Synthetic', 'verified-opportunity', true, 'Internal notes'),
  ('internship', 'Draft opportunity', 'Synthetic', 'draft-opportunity', false, 'Draft notes');
insert into public.scholarships (title, provider_name, slug, verified) values
  ('Verified scholarship', 'Synthetic', 'verified-scholarship', true),
  ('Draft scholarship', 'Synthetic', 'draft-scholarship', false);
insert into public.notifications (profile_id, type) values
  ('00000000-0000-4000-8000-000000000001', 'new_match'),
  ('00000000-0000-4000-8000-000000000002', 'new_match');
insert into public.workflow_jobs (kind, idempotency_key) values ('synthetic-qualification', 'test-service-write');
insert into public.notification_deliveries (profile_id, campaign_key, channel, schedule_bucket, dedupe_key, template_version)
values ('00000000-0000-4000-8000-000000000001', 'synthetic-qualification', 'push', 'test', 'test-service-write', 'test');
update public.notification_deliveries set status = 'accepted' where dedupe_key = 'test-service-write';
select pg_temp.assert_true((select status = 'accepted' from public.notification_deliveries where dedupe_key = 'test-service-write'),
  'Service role can persist provider outcomes');
select pg_temp.assert_true((public.broadcast_overview('00000000-0000-4000-8000-000000000002')->>'recent') is not null,
  'Service role can call the pinned broadcast API for an admin');
select pg_temp.expect_denied($sql$select public.broadcast_overview('00000000-0000-4000-8000-000000000001')$sql$);
select pg_temp.assert_true((public.deadline_reminder_stats()->>'daily_email_attempts') = '0',
  'Service role can call the pinned deadline API');
reset role;

set local role anon;
select pg_temp.assert_true((select array_agg(slug) = array['verified-opportunity'] from public.opportunities),
  'Anon sees the verified opportunity only');
select pg_temp.assert_true((select array_agg(slug) = array['verified-scholarship'] from public.scholarships),
  'Anon sees the verified scholarship only');
select pg_temp.expect_denied('select research_notes from public.opportunities');
select pg_temp.expect_denied('select id from public.profiles');
select pg_temp.expect_denied('select * from public.scholarship_rules');
select pg_temp.expect_denied('delete from public.opportunities');
select pg_temp.expect_denied($sql$select public.is_admin('00000000-0000-4000-8000-000000000002')$sql$);
reset role;

set local role authenticated;
set local request.jwt.claims = '{"sub":"00000000-0000-4000-8000-000000000001","role":"authenticated"}';
select pg_temp.assert_true((select count(*) = 1 from public.profiles), 'Students can see their own profile only');
select pg_temp.assert_true((select array_agg(slug) = array['verified-opportunity'] from public.opportunities),
  'Student cannot read draft opportunities');
select pg_temp.assert_true(not public.is_admin(auth.uid()) and not public.is_admin('00000000-0000-4000-8000-000000000002'),
  'Students cannot use is_admin to probe other users');
select pg_temp.expect_denied($sql$insert into public.opportunities (type, title, provider_name, slug)
  values ('internship', 'Unauthorized', 'Synthetic', 'unauthorized')$sql$);
with affected as (update public.opportunities set verified = false returning id)
select pg_temp.assert_true(not exists (select from affected), 'Student cannot update catalog rows');
with affected as (delete from public.opportunities returning id)
select pg_temp.assert_true(not exists (select from affected), 'Student cannot delete catalog rows');
insert into public.profiles (id, full_name, deadline_email_enabled) values (auth.uid(), 'Updated Student', true)
on conflict (id) do update set id = excluded.id, full_name = excluded.full_name,
  deadline_email_enabled = excluded.deadline_email_enabled;
select pg_temp.assert_true((select full_name = 'Updated Student' and deadline_email_enabled from public.profiles),
  'The signed-in profile upsert and pinned deadline preference work');
with affected as (update public.profiles set full_name = 'Unauthorized' where id <> auth.uid() returning id)
select pg_temp.assert_true(not exists (select from affected), 'Student cannot update another profile');
select pg_temp.expect_denied($sql$update public.profiles set id = '00000000-0000-4000-8000-000000000003' where id = auth.uid()$sql$);
select pg_temp.expect_denied('update public.profiles set is_admin = true where id = auth.uid()');
select pg_temp.expect_denied($sql$update public.profiles set community_role = 'founder' where id = auth.uid()$sql$);
select pg_temp.expect_denied($sql$insert into public.profiles (id) values ('00000000-0000-4000-8000-000000000003')$sql$);
select pg_temp.expect_denied('select * from public.notification_deliveries');
select pg_temp.expect_denied('select public.deadline_reminder_stats()');
select pg_temp.expect_denied('select public.broadcast_due_jobs()');
update public.notifications set read_at = now();
select pg_temp.assert_true((select count(*) = 1 and bool_and(read_at is not null) from public.notifications),
  'Student can mark only their own inbox item read');
select pg_temp.expect_denied($sql$update public.notifications set metadata = '{}'::jsonb$sql$);

set local request.jwt.claims = '{"sub":"00000000-0000-4000-8000-000000000003","role":"authenticated"}';
select pg_temp.expect_denied('insert into public.profiles (id, is_admin) values (auth.uid(), true)');
insert into public.profiles (id, full_name) values (auth.uid(), 'Recreated profile');
select pg_temp.assert_true((select not is_admin from public.profiles), 'An owner can recreate an unprivileged profile');

set local request.jwt.claims = '{"sub":"00000000-0000-4000-8000-000000000002","role":"authenticated"}';
select pg_temp.assert_true(public.is_admin(auth.uid()), 'Administrator can evaluate their own role');
select pg_temp.assert_true((select count(*) = 3 from public.profiles), 'Administrator RLS can read other profiles');
select pg_temp.assert_true((select count(*) = 2 from public.opportunities), 'Administrator can read draft opportunities');
insert into public.opportunities (type, title, provider_name, slug) values ('internship', 'New draft', 'Synthetic', 'new-draft');
update public.opportunities set title = 'Revised draft' where slug = 'new-draft';
select pg_temp.assert_true((select title = 'Revised draft' from public.opportunities where slug = 'new-draft'),
  'Administrator can manage a draft opportunity');
with affected as (delete from public.opportunities where slug = 'new-draft' returning id)
select pg_temp.assert_true((select count(*) = 1 from affected), 'Administrator can delete a draft opportunity');
select pg_temp.expect_denied('update public.profiles set is_admin = false where id = auth.uid()');

rollback;
select 'Anon, authenticated student and administrator, and service_role access checks passed.';
