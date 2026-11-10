# Global opportunity access control and referral conversion

## Architectural findings

Scholars has two listing tables and two public URL families:

- `public.scholarships` powers the legacy scholarship matching/detail experience and `/scholarship/[slug]`, `/s/[id]` share redirects.
- `public.opportunities` powers category-agnostic fellowships, internships, competitions, mentorships, training and future enum-backed opportunity types through `/opportunity/[slug]`, `/o/[id]` and `/opportunities/[id]`.
- Authenticated detail pages use the cookie-aware Supabase server client and may read eligibility, application, saved-state and application tracking data.
- Public pages use the cookie-free anon client and are cached/ISR-oriented.
- Registration, Google OAuth, email verification and onboarding already accept a validated `next` path. The auth callback consumes referral attribution separately from the destination.
- Community is scholarship-specific today. Its UI is client-gated, but the database currently grants anonymous read access to published discussions, prompts, social-proof RPCs and contributor profile RPCs.

## Security gaps found

1. Verified-row RLS policies expose all columns of `scholarships` and `opportunities` to `anon`, including eligibility, application URLs/instructions and internal metadata reachable through direct Supabase queries.
2. `scholarship_rules`, `scholarship_prompts`, published discussions and community RPCs have anonymous access even though community and eligibility are authenticated-only requirements.
3. Public share pages select and render application details, and the opportunity page also renders location/discipline. The public contract needs an explicit, narrow projection.
4. The opportunity share CTA currently sends users to `/signup?next=/onboarding`, losing the original opportunity destination. Scholarship sharing has the correct nested `next` pattern.
5. The public share middleware intentionally skips authenticated-route processing; authenticated visitors therefore stay on the preview unless the page redirects them to the protected detail route.

## Implementation

- Add `public.scholarship_public_previews` and `public.opportunity_public_previews` views containing only title, description and approved general listing facts plus deadline and canonical identifiers.
- Revoke anonymous base-table reads and authenticated-only access to rules, prompts, discussions and community RPCs. Keep existing authenticated ownership/admin policies intact.
- Move public catalog, legacy redirect, share detail and OG queries to the preview views.
- Remove application/eligibility/community information from anonymous HTML and redirect authenticated visitors from shared slugs to the existing protected detail pages.
- Preserve attribution (`ref`, UTM and campaign cookies) independently from a validated nested `next` destination. Use the existing `safeNextPath` plus generated internal opportunity paths; missing/invalid IDs resolve through the existing not-found behavior.
- Keep the common `opportunities` table and preview view category-agnostic so new opportunity categories inherit the same policy without category-specific security branches.

## Affected files

- `supabase/migrations/20261110140000_global_opportunity_access_control.sql`
- `lib/supabase/public.ts`
- `app/scholarship/[slug]/page.tsx`
- `app/opportunity/[slug]/page.tsx`
- `app/scholarships-in-nigeria/page.tsx`
- `app/opportunities-for-students/page.tsx`
- legacy `/s/[id]` and `/o/[id]` redirects plus OG readers
- `app/auth/callback/route.ts`, signup/login/onboarding flow where destination validation is involved
- focused access-control tests and final delivery report

## Risks and mitigations

- **View/schema drift:** the migration is additive and public selectors are centralized in `lib/supabase/public.ts`; authenticated detail queries remain on base tables.
- **Cache contamination:** authenticated shared-page redirects happen in the page component while public data comes only from narrow preview views; public pages do not render session-specific data.
- **Referral loss:** nested `next` is generated from the canonical internal path and continues through signup, verification/OAuth and onboarding; referral attribution remains cookie-based and separate.
- **Future categories:** the opportunity preview view selects from `opportunities` without enumerating types, and authenticated detail access remains table-based.
