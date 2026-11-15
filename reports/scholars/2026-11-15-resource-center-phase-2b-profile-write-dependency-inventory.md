# Scholars Resource Centre — Phase 2B Profile-Write Dependency Inventory

**Assessment date:** 2026-11-15
**Source baseline:** `ImperioKDB/Scholars` `main` at `142146a`
**Method:** read-only source and migration inspection; no runtime request or database write was performed.

## Evidence legend

- **VERIFIED — SOURCE:** directly observed in the checked-out Scholars source or migration.
- **VERIFIED — DATABASE (PRIOR REPORT):** reused from the published Task 9/10 production verification.
- **INFERRED:** follows from source/data-flow analysis but was not runtime-tested.
- **UNVERIFIED:** requires staging or live application execution.
- **BLOCKED:** cannot be safely closed under the current read-only scope.

## Executive result

The application has one broad generic profile-write path plus several narrower direct writes. Removing table-level `INSERT` and `UPDATE` from `authenticated` may break the generic upsert even if ordinary column grants are restored, because migration `0029_fix_profiles_upsert_table_privileges.sql` explicitly says PostgREST upserts require table-level privileges. That compatibility claim is **VERIFIED — SOURCE**, not a current runtime result. Therefore the safe cutover must first prove the actual PostgREST/Supabase behavior in staging or replace the generic upsert with an allow-listed mutation operation before removing the broad grant.

## Application dependency matrix

| Path | Source evidence | Operation / fields | Authority and compatibility impact |
|---|---|---|---|
| Registration and account creation | `app/(auth)/signup/page.tsx`; Auth callback; `0001_init.sql`, `0021_add_user_presence.sql` | Supabase Auth signup/OTP/Google; Auth trigger provisions `profiles`; callback sets `referred_by` and attribution fields | **INFERRED:** profile bootstrap should remain trusted trigger/service path. Callback needs authenticated updates to `referred_by`, `referral_source`, `campaign_id`, `ambassador_code`, `utm_source`, `utm_medium`, and `utm_campaign`; verify exact final grants. |
| Password authentication | `app/(auth)/login/page.tsx` | Supabase Auth sign-in; no direct profile write | **VERIFIED — SOURCE:** no profile DML in password sign-in. Profile read/guard follows authentication. |
| OTP authentication | `app/(auth)/login/page.tsx`, `signup/page.tsx`, `components/AuthOtp.tsx` | `verifyOtp`; no direct profile DML | **VERIFIED — SOURCE:** no direct profile DML; callback/session provisioning remains relevant. |
| Google authentication | `signup/page.tsx`, `login/page.tsx`, `app/auth/callback/route.ts` | OAuth exchange; callback attribution updates | **VERIFIED — SOURCE:** callback has two authenticated profile updates, both keyed to `data.user.id`; do not remove required attribution columns without a replacement. |
| Generic profile create/edit | `app/api/profile/route.ts` POST | `.upsert({ id: user.id, ...parsed.data }, { onConflict: 'id' })`; full name, academic and eligibility fields, document flags, avatar, WhatsApp reminder fields, onboarding fields | **VERIFIED — SOURCE:** central compatibility risk. The schema excludes `is_admin` and `community_role`, but the upsert still needs a proven privilege contract. |
| Profile read/settings | `app/api/profile/route.ts` GET; `app/settings/page.tsx`; `lib/supabase/currentUser.ts` | Own-row `SELECT`, including `is_admin` for UI/guards | **VERIFIED — SOURCE:** retain own-row reads and admin guard reads; selection of `is_admin` is not itself a write authority. |
| Onboarding | `app/onboarding/page.tsx`; `/api/profile` POST; `/api/onboarding/prompts` PATCH | Generic profile upsert; onboarding step/activity; PWA and push prompt timestamps | **VERIFIED — SOURCE:** migrations `0069` and `0080` document added grants. These columns must remain writable through the approved path. |
| JAMB and academic information | `/api/profile` POST; `app/onboarding/page.tsx`; profile settings UI | `jamb_score`, `year_of_study`, institution, institution type, discipline, GPA and related fields | **VERIFIED — SOURCE:** included in the generic profile upsert; preserve explicit safe-column writes. |
| WAEC information | `app/api/profile/waec/route.ts` | Calls `replace_waec_results` RPC; trigger recomputes profile summary fields | **VERIFIED — SOURCE:** no direct profile flag write; RPC/trigger must be tested after profile privilege cutover. |
| Presence heartbeats | `app/api/heartbeat/route.ts`; `app/api/presence/heartbeat/route.ts` | Own-row updates to `last_seen_at` | **VERIFIED — SOURCE:** preserve explicit update grant or move to a fixed endpoint/function. |
| Referral attribution | `app/auth/callback/route.ts` | Own-row updates to `referred_by` and attribution columns, null-only conditions | **VERIFIED — SOURCE:** authenticated session-bound write; preserve or replace with a server-side fixed operation. |
| Community profile editing | `app/api/profile/route.ts`; `community_bio` | Generic upsert includes `community_bio`; migration `0061` grants update | **VERIFIED — SOURCE:** preserve `community_bio` ordinary update; do not conflate it with `community_role`. |
| Community invitation consent | `app/api/profile/whatsapp-community-invitation/route.ts` | Service-role updates consent columns and normalized WhatsApp number after authenticated user check | **VERIFIED — SOURCE:** ordinary roles must not receive these sensitive columns. Trigger `guard_community_invitation_consent` requires the intended service-role path. |
| Referral completion | `0094/0095` trigger and `0058` logic | Trigger reads profile/referral state and may award XP | **VERIFIED — SOURCE:** not an application profile writer of `is_admin`; verify trigger behavior after grants change. |
| Profile deletion | `app/api/profile/route.ts` DELETE; `components/DeleteAccountButton.tsx` | Own-row delete cascades application data; Auth user is not deleted | **VERIFIED — SOURCE:** retain own-row delete. Decide and test whether a last administrator may self-delete; do not silently remove privacy deletion. |
| Admin dashboard reads | `app/admin/*`, `lib/admin/access.ts`, `lib/admin/guard.ts`, `middleware.ts` | Reads profiles and `is_admin`; some paths use service-role after guard | **VERIFIED — SOURCE:** all reviewed admin routes ultimately trust `profiles.is_admin`; source review found no direct `is_admin` setter. Access remains unsafe until the database authority is protected. |
| Admin member-role update | `app/api/admin/member-roles/route.ts` | Updates `community_role`, not `is_admin` | **VERIFIED — SOURCE:** retain as a separate role operation and verify it cannot assign `founder` without the intended policy. |
| Server-side service-role operations | admin routes, `lib/admin/community-invitations.ts`, email/push jobs | Cross-user profile reads and delivery/log writes | **VERIFIED — SOURCE:** service-role client is `server-only`; reviewed routes guard before protected service work. Runtime ordering and side effects remain **UNVERIFIED**. |
| Supabase/PostgREST direct writes | `/api/profile` and browser Supabase client patterns | Upsert/update requests can bypass application schema if grants permit | **INFERRED:** database guard must be final enforcement. No exploit or direct write was attempted. |

## Migration dependencies

The source migration chain contains the relevant privilege history:

- `0023_lock_admin_flag.sql` removes broad grants and grants explicit ordinary columns, creates own-row policies, then restores helper execution for policy evaluation.
- `0028_fix_profiles_authenticated_update_privilege.sql` adds explicit ordinary update columns.
- `0029_fix_profiles_upsert_table_privileges.sql` restores table-level `INSERT, UPDATE` for `authenticated` and revokes only column-level `is_admin` privileges. This is the source of the privilege regression because a column revoke cannot cancel a table-level grant.
- `0056_add_community_layer.sql` adds `community_role` and admin-controlled role policy; it also grants authenticated update on that column, so its final treatment must be reviewed separately from `is_admin`.
- `0061_add_contributor_profiles.sql` adds `community_bio` and grants authenticated update.
- `0069_grant_onboarding_progress_profile_writes.sql` adds onboarding insert/update columns.
- `0070_grant_english_maths_profile_insert.sql` adds the missing insert privilege for an upsert payload.
- `0080_add_prompt_action_state.sql` grants updates for PWA/push prompt timestamps.
- `0093` adds invitation-consent columns; `0094/0095` protect them through a trigger and service-role endpoint.

## Profile column groups for review

The final staging migration must derive, not assume, the exact live column set. The source indicates these groups:

1. **Ordinary self-service:** `id`, `full_name`, `discipline`, `gpa`, `nationality`, `gender`, `financial_need`, `career_goals`, `community_bio`, `date_of_birth`, `state_of_origin`, `lga_of_origin`, `year_of_study`, `institution_name`, `institution_type`, `jamb_score`, `waec_credit_count`, `has_english_maths_credit`, disability/document fields, `avatar_url`, `whatsapp_opt_in`, `whatsapp_number`, `onboarding_step`, `onboarding_last_activity_at`, `last_seen`, `last_seen_at`, `pwa_installed_at`, and `push_enable_clicked_at`.
2. **Callback attribution:** `referred_by`, `referral_source`, `campaign_id`, `ambassador_code`, `utm_source`, `utm_medium`, and `utm_campaign`.
3. **Database-maintained or protected:** `is_admin`, `profile_completeness`, timestamps, referral/XP-derived fields, `community_role`, and invitation-consent columns. Exact ownership and write semantics require staging verification.
4. **Read-only to ordinary clients:** any field not required by a verified client write path, including protected authority and service-maintained fields.

## Outstanding checks

- Prove whether the deployed PostgREST version permits the current `/api/profile` upsert with explicit safe-column grants and no table-level grant.
- If not, replace the upsert with a fixed allow-listed RPC or server endpoint before revoking the broad table grant.
- Verify all migration-added columns exist in the representative staging schema and that no unlisted profile writer depends on broad DML.
- Test `replace_waec_results`, profile completeness, referral completion, invitation-consent trigger behavior, and account deletion after the cutover.
- Confirm no service-role endpoint accepts an end-user supplied role/actor or exposes a browser credential.

**Readiness status:** **BLOCKED** until these checks pass in isolated Scholars staging.
