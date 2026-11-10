-- PostgreSQL grants to PUBLIC are inherited by anon. Remove that inherited
-- access explicitly; anonymous catalog access is provided only by the two
-- narrow preview views.

revoke all on table public.scholarships, public.opportunities,
  public.scholarship_rules, public.scholarship_prompts,
  public.scholarship_discussions, public.scholarship_discussion_reactions
from public, anon;

grant select on table public.scholarship_public_previews,
  public.opportunity_public_previews to anon, authenticated;
grant select on table public.scholarships, public.opportunities,
  public.scholarship_rules, public.scholarship_prompts,
  public.scholarship_discussions, public.scholarship_discussion_reactions
to authenticated;

revoke all on function public.get_scholarship_discussions(uuid, text, integer) from public, anon;
revoke all on function public.get_scholarship_social_proof(uuid) from public, anon;
revoke all on function public.get_community_contributor_profile(uuid) from public, anon;
grant execute on function public.get_scholarship_discussions(uuid, text, integer) to authenticated;
grant execute on function public.get_scholarship_social_proof(uuid) to authenticated;
grant execute on function public.get_community_contributor_profile(uuid) to authenticated;
