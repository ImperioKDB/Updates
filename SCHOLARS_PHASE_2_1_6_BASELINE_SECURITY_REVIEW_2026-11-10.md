# Scholars Phase 2.1.6 — Baseline Security Review

**Status:** No baseline available for approval; security findings remain open.
**Evidence time:** 2026-11-10, 10:57–11:00 CET.
**Author:** Manus AI

## Scope and method

This review evaluates what can be concluded from fresh Supabase security-advisor output and prior Phase 2.1.5 catalog analysis for production `cmdglabohpttgfofcmqc`. The advisor was read through its dedicated tool; project metadata was read through the project connector. No SQL, RPC, table row, secret, storage file, or production API endpoint was invoked. Function bodies, ACL definitions, policies, and default privileges were not re-extracted because no verified read-only database URL was available.

## Fresh findings

The production security advisor, observed at 2026-11-10 10:00:20 UTC, reports 23 `SECURITY DEFINER` functions executable by `anon` and the same 23 executable by `authenticated`. It also flags four postgres-owned Resource Center views as security-definer views, six RLS-enabled tables with no policies, and mutable search paths on `public.catalog_slug` and `public.set_catalog_slug`. The six no-policy relations include `announcement_log`, `auth_rate_limits`, `broadcast_delivery_log`, `notification_deliveries`, `visitor_daily_metrics`, and `workflow_jobs`. The advisor additionally reports that leaked-password protection is disabled. These are configuration/advisor findings; they do not by themselves demonstrate a successful exploit or row retrieval. [1]

## Inherited findings, not independently recaptured

Prior Phase 2.1.5 reports identify broad direct browser grants on 11 production tables and specific function concerns involving `is_admin(uuid)`, `get_admin_metrics_summary(timestamptz)`, `run_achievement_checks(uuid)`, public social-proof/trending/discussion data, and `supabase_admin` defaults. These remain review leads, not fresh DDL evidence. Prior reports also state that broad table revocation could break current application paths. The current advisor confirms broad callable function posture but does not expose complete function bodies or direct table ACLs.

## Assessment and limitations

No schema artifact exists for independent review. Current PostgREST exposed schemas, function owners/bodies, dynamic SQL, RLS expressions and OR-combinations, effective table privileges, view options, custom Auth/Storage behavior, and destination default privileges remain unverified in this pass. Security approval is therefore not granted. Do not invoke sensitive RPCs, perform production probes, blanket-revoke grants, or restore to existing staging.

## Next action

Obtain a restricted read-only database connection and sanitized PostgREST configuration through authorized channels. Capture and hash the schema artifacts privately. Then review the exact definitions and ACLs, reconcile them to this advisor snapshot and prior findings, and obtain independent security approval before any restore decision.

## References

[1]: https://supabase.com/docs/guides/database/database-linter "Supabase Database Security Advisor"
[2]: https://github.com/ImperioKDB/Updates/blob/a88ab72fcdddd58fe28315a1c04229a09511ab77/SCHOLARS_PHASE_2_1_5_BASELINE_SECURITY_REVIEW_2026-11-10.md "Phase 2.1.5 Baseline Security Review"
