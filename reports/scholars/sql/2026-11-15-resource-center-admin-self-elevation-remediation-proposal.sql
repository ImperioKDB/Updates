-- Scholars Resource Centre Phase 2B / Task 11
-- PROPOSAL ONLY — DO NOT EXECUTE
--
-- Proposed source-sequence timestamp: 20261115180000
-- The latest timestamped Scholars migration inspected was
-- 20261111100000_seed_totalenergies_and_chevron_2027.sql. This file is
-- published in Updates for review and is not present in ImperioKDB/Scholars.
-- It has not been run against production or staging.
--
-- Preconditions before any implementation:
--   1. Approve a representative, schema-only Scholars staging baseline.
--   2. Capture exact live/staged profile columns, grants, default privileges,
--      policies, trigger definitions, function owners, and all dependencies.
--   3. Create a dedicated NOLOGIN controller role through the approved owner
--      process; do not substitute service_role, postgres, a JWT claim, or a
--      caller-controlled setting.
--   4. Generate the complete policy/routine replacement set from the approved
--      staging catalog. The placeholder below is intentionally not executable
--      as a production cutover until that generated set is reviewed.
--   5. Prove the current PostgREST upsert contract, or deploy the fixed
--      allow-listed profile mutation endpoint/RPC first.
--
-- Safety boundary: this document contains DDL/DCL for review. No statement in
-- this file was executed by the assessment that published it.

BEGIN;

-- Replace this identifier with the exact approved, non-login owner after the
-- staging owner/recovery process is documented. Do not create it casually.
-- CREATE ROLE scholars_admin_controller NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT;

-- 1. Remove the privilege regression before re-granting only verified columns.
-- A column REVOKE alone cannot cancel a table-level DML grant.
REVOKE INSERT, UPDATE ON TABLE public.profiles FROM anon, authenticated;
REVOKE INSERT (is_admin), UPDATE (is_admin)
  ON TABLE public.profiles FROM anon, authenticated;

-- 2. Safe ordinary columns. This list must be reconciled with the exact
-- staging schema and the dependency inventory before execution. Do not add
-- authority, role, audit, consent, or trigger-maintained fields here.
GRANT INSERT (
  id, full_name, discipline, gpa, nationality, gender, financial_need,
  career_goals, community_bio, date_of_birth, state_of_origin, lga_of_origin,
  year_of_study, institution_name, institution_type, jamb_score,
  waec_credit_count, has_english_maths_credit, disability_status,
  has_valid_id, has_transcript, has_recommendation_letter,
  has_personal_statement, has_lga_certificate, avatar_url, whatsapp_opt_in,
  whatsapp_number, referred_by, onboarding_step, onboarding_last_activity_at
) ON TABLE public.profiles TO authenticated;

GRANT UPDATE (
  full_name, discipline, gpa, nationality, gender, financial_need,
  career_goals, community_bio, date_of_birth, state_of_origin, lga_of_origin,
  year_of_study, institution_name, institution_type, jamb_score,
  waec_credit_count, has_english_maths_credit, disability_status,
  has_valid_id, has_transcript, has_recommendation_letter,
  has_personal_statement, has_lga_certificate, avatar_url, whatsapp_opt_in,
  whatsapp_number, onboarding_step, onboarding_last_activity_at,
  last_seen, last_seen_at, pwa_installed_at, push_enable_clicked_at,
  referral_source, campaign_id, ambassador_code, utm_source, utm_medium,
  utm_campaign
) ON TABLE public.profiles TO authenticated;

GRANT DELETE ON TABLE public.profiles TO authenticated;

-- The invitation-consent endpoint intentionally uses a server-side service
-- client. Do not grant these columns to ordinary authenticated callers:
-- whatsapp_community_invite_opt_in,
-- whatsapp_community_invite_consented_at,
-- whatsapp_community_invite_withdrawn_at,
-- whatsapp_community_invite_notice_version.

-- 3. Database invariant for the authority column. The exact controller role,
-- ownership, and trigger security mode must be verified in staging. A normal
-- API statement may keep the existing value or accept the false default on
-- insert; only the approved controller may change the flag.
CREATE OR REPLACE FUNCTION public.protect_profiles_is_admin()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.is_admin IS DISTINCT FROM false
       AND current_user <> 'scholars_admin_controller' THEN
      RAISE EXCEPTION 'profiles.is_admin is managed by the administrator lifecycle operation'
        USING ERRCODE = '42501';
    END IF;
  ELSIF NEW.is_admin IS DISTINCT FROM OLD.is_admin
        AND current_user <> 'scholars_admin_controller' THEN
    RAISE EXCEPTION 'profiles.is_admin is managed by the administrator lifecycle operation'
      USING ERRCODE = '42501';
  END IF;
  RETURN NEW;
END;
$$;

-- Change ownership to the reviewed NOLOGIN controller or another separately
-- approved owner only after staging confirms the trigger cannot be bypassed.
-- ALTER FUNCTION public.protect_profiles_is_admin() OWNER TO scholars_admin_controller;
DROP TRIGGER IF EXISTS protect_profiles_is_admin ON public.profiles;
CREATE TRIGGER protect_profiles_is_admin
  BEFORE INSERT OR UPDATE OF is_admin ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.protect_profiles_is_admin();

-- 4. Caller-bound helper. It accepts no arbitrary UUID and must be owned by a
-- dedicated least-privilege role after staging recursion tests. Fully qualify
-- all objects and keep the search path empty.
CREATE SCHEMA IF NOT EXISTS security;
REVOKE ALL ON SCHEMA security FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION security.is_admin_current()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT COALESCE((
    SELECT p.is_admin
    FROM public.profiles AS p
    WHERE p.id = auth.uid()
  ), false);
$$;

-- The final owner and exact execute ACL are environment-dependent and must be
-- applied only after staging proves the policy evaluation path. Do not grant
-- PUBLIC or anon execution. Example review statements:
-- ALTER FUNCTION security.is_admin_current() OWNER TO scholars_admin_controller;
-- GRANT USAGE ON SCHEMA security TO authenticated;
-- GRANT EXECUTE ON FUNCTION security.is_admin_current() TO authenticated;
-- REVOKE EXECUTE ON FUNCTION security.is_admin_current() FROM PUBLIC, anon;

-- 5. Replace every policy expression that currently calls
-- public.is_admin(auth.uid()) with security.is_admin_current(). Replace every
-- routine caller that checks an auth.uid()-derived actor. The complete set must
-- be generated from staging and reviewed before uncommenting/adding policy DDL.
-- This proposal deliberately does not invent the live policy definitions.
-- Required dependency classes include:
--   * all profiles, catalog, community, storage, Resource Centre, discovery,
--     analytics, and audit policies that reference the helper;
--   * get_admin_metrics_summary;
--   * get_provider_analytics;
--   * get_daily_visitor_metrics;
--   * get_auth_confirmation_email_analytics;
--   * publish_discovery_candidate;
--   * any other routine found by the exact staging body search.

-- 6. Restricted lifecycle operation. The final implementation must bind actor
-- to auth.uid(), require AAL2, reject self-grant, require an existing target
-- auth.users row, require reason/ticket and second approval where policy says
-- so, protect the last administrator, and write an immutable audit event in
-- one transaction. Its exact audit schema and owner must be approved first.
-- Do not expose a generic profile update RPC.

-- 7. Legacy helper cutover. Do not revoke this helper until every dependency
-- has been replaced and the full policy/routine matrix passes in staging.
-- If a compatibility shim is required, it must reject NULL and any target
-- distinct from auth.uid(); it must never answer for an arbitrary UUID.
-- Example final ACL action after replacement verification:
-- REVOKE ALL ON FUNCTION public.is_admin(uuid) FROM PUBLIC, anon, authenticated;
-- GRANT EXECUTE ON FUNCTION public.is_admin(uuid) TO service_role;
-- DROP FUNCTION public.is_admin(uuid); -- only after dependency proof and owner approval

-- 8. Required postconditions, to be asserted by a separate read-only
-- verification script in staging and production after a separately approved
-- change:
--   * authenticated table INSERT/UPDATE on profiles = false;
--   * authenticated is_admin INSERT/UPDATE = false;
--   * safe ordinary writes and profile upsert contract pass;
--   * direct is_admin insert/update/upsert attempts fail closed;
--   * all helper-dependent policies/routines use the replacement;
--   * PUBLIC/anon cannot execute arbitrary-subject membership checks;
--   * controller lifecycle operations, audit, last-admin protection, and AAL2
--     tests pass;
--   * public Resource Centre projection reads remain unchanged.

-- ROLLBACK NOTE: do not restore broad authenticated table DML as a rollback.
-- After commit, use a reviewed forward correction while preserving the flag
-- guard and owner recovery path.

COMMIT;
