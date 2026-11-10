-- Global opportunity access boundary.
-- Anonymous users receive only narrow preview views. Authenticated users retain
-- the existing base-table access needed by matching, applications and admin.

create or replace view public.scholarship_public_previews as
select
  id,
  slug,
  title,
  provider_name,
  description,
  amount,
  deadline,
  last_cycle_closed_at,
  level,
  discipline,
  verified,
  last_verified_at,
  opens_at,
  updated_at
from public.scholarships
where verified = true;

create or replace view public.opportunity_public_previews as
select
  id,
  slug,
  type,
  title,
  provider_name,
  description,
  duration,
  location,
  compensation,
  discipline,
  deadline,
  verified,
  updated_at
from public.opportunities
where verified = true;

revoke all on table public.scholarships from anon;
revoke all on table public.opportunities from anon;
revoke all on table public.scholarship_rules from anon;
revoke all on table public.scholarship_prompts from anon;
revoke all on table public.scholarship_discussions from anon;
revoke all on table public.scholarship_discussion_reactions from anon;

grant select on table public.scholarship_public_previews to anon, authenticated;
grant select on table public.opportunity_public_previews to anon, authenticated;
grant select on table public.scholarships to authenticated;
grant select on table public.opportunities to authenticated;
grant select on table public.scholarship_rules to authenticated;
grant select on table public.scholarship_prompts to authenticated;
grant select on table public.scholarship_discussions to authenticated;
grant select on table public.scholarship_discussion_reactions to authenticated;

-- Base opportunity rows are not anonymous, even when verified. The preview view
-- above is the only anonymous opportunity projection.
drop policy if exists opportunities_select_verified on public.opportunities;
create policy opportunities_select_verified
  on public.opportunities
  for select to authenticated
  using (verified = true or public.is_admin(auth.uid()));

-- Scholarship base rows remain available to authenticated matching and to
-- admins/owners of retained application history, but never to anon.
drop policy if exists scholarships_select_verified on public.scholarships;
create policy scholarships_select_verified
  on public.scholarships
  for select to authenticated
  using (
    verified = true
    or public.is_admin(auth.uid())
    or exists (
      select 1
      from public.saved_scholarships ss
      where ss.scholarship_id = scholarships.id
        and ss.profile_id = auth.uid()
    )
    or exists (
      select 1
      from public.applications a
      where a.scholarship_id = scholarships.id
        and a.profile_id = auth.uid()
    )
  );

-- Eligibility rules and editorial prompts are registered-user content.
drop policy if exists scholarship_rules_select on public.scholarship_rules;
create policy scholarship_rules_select
  on public.scholarship_rules
  for select to authenticated
  using (
    exists (
      select 1
      from public.scholarships s
      where s.id = scholarship_rules.scholarship_id
        and (s.verified = true or public.is_admin(auth.uid()))
    )
  );

drop policy if exists scholarship_prompts_public_read on public.scholarship_prompts;
create policy scholarship_prompts_authenticated_read
  on public.scholarship_prompts
  for select to authenticated
  using (
    exists (
      select 1
      from public.scholarships s
      where s.id = scholarship_prompts.scholarship_id
        and s.verified = true
    )
  );

-- Community content and identity information must never be anonymous.
drop policy if exists scholarship_discussions_public_read on public.scholarship_discussions;
create policy scholarship_discussions_authenticated_read
  on public.scholarship_discussions
  for select to authenticated
  using (
    status = 'published'
    and exists (
      select 1
      from public.scholarships s
      where s.id = scholarship_discussions.scholarship_id
        and s.verified = true
    )
  );

revoke execute on function public.get_scholarship_discussions(uuid, text, integer) from anon;
revoke execute on function public.get_scholarship_social_proof(uuid) from anon;
revoke execute on function public.get_community_contributor_profile(uuid) from anon;
grant execute on function public.get_scholarship_discussions(uuid, text, integer) to authenticated;
grant execute on function public.get_scholarship_social_proof(uuid) to authenticated;
grant execute on function public.get_community_contributor_profile(uuid) to authenticated;

comment on view public.scholarship_public_previews is
  'Anonymous preview projection. Never add eligibility, application, rules, research, or community fields.';
comment on view public.opportunity_public_previews is
  'Anonymous preview projection. Never add eligibility, application, instructions, research, or community fields.';
