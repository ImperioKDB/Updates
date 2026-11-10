# Scholars Phase 2.1.2 — API Object and Application Dependency Matrix

**Application baseline:** `cf3682ce35912df7b9b9352193630fc404427c7c`
**Production project:** `cmdglabohpttgfofcmqc` (`eu-west-1`)
**Evidence date:** 2026-11-09
**Status:** Read-only inventory; no application or database changes were made.

## Object exposure matrix

The production catalog confirms 45 public tables and four public Resource Center views. The matrix below focuses on the Phase 2.1.1 audited relations and the adjacent internal tables specifically requested by Phase 2.1.2.

| Database object | Expected HTTP path | Browser ACL / RLS evidence | API evidence | Sensitivity | Future action |
|---|---|---|---|---|---|
| `public.scholarships` | `/rest/v1/scholarships` | `anon`/`authenticated`: `arwdDxtm`; RLS on, not forced; verified/admin/own-retained SELECT | Anonymous safe no-match request returned 200 `[]` | Public catalogue plus internal research/competitiveness fields | Project exact public columns; revoke broad browser DML |
| `public.scholarship_rules` | `/rest/v1/scholarship_rules` | Broad browser ACL; verified-parent/admin RLS | Not tested | Eligibility data; draft/unverified parents internal | Public normalized projection only |
| `public.opportunities` | `/rest/v1/opportunities` | Broad browser ACL; verified-row SELECT; RLS on, not forced | Anonymous safe no-match request returned 200 `[]` | Public catalogue plus `research_notes`/author metadata | Explicit projection; revoke broad browser DML |
| `public.cycle_events` | `/rest/v1/cycle_events` | Broad browser ACL; `USING (true)` public read; admin writes | Not tested | Public dates/source may be safe; note/actor may be internal | Approved projection excluding note/actor by default |
| `public.applications` | `/rest/v1/applications` | Broad browser ACL; owner/admin RLS | Impossible profile UUID request returned 200 `[]` | Student-private application and draft content | Keep private; owner-scoped API/RPC and column restrictions |
| `public.saved_scholarships` | `/rest/v1/saved_scholarships` | Broad browser ACL; owner/admin RLS | Not tested | Student-private activity | Owner-only access; no raw aggregate exposure |
| `public.saved_opportunities` | `/rest/v1/saved_opportunities` | Broad browser ACL; owner/admin RLS including update | Not tested | Student-private activity | Owner-only access; remove unused update capability |
| `public.notifications` | `/rest/v1/notifications` | Broad browser ACL; own-row SELECT/UPDATE | Not tested | Private notification metadata | Only `read_at` update or mark-read RPC |
| `public.scholarship_discovery_candidates` | `/rest/v1/scholarship_discovery_candidates` | Broad browser ACL; admin-only SELECT/UPDATE RLS | Impossible UUID request returned 200 `[]` | Editorial/private source and candidate data | Remove browser table exposure; scoped editorial/server API |
| `public.scholarship_discovery_candidate_claims` | `/rest/v1/scholarship_discovery_candidate_claims` | Broad browser ACL; admin-only RLS | Not tested | Internal evidence and claims | Private/editorial schema or narrow functions |
| `public.scholarship_discovery_fetch_snapshots` | `/rest/v1/scholarship_discovery_fetch_snapshots` | Broad browser ACL; admin-only SELECT | Not tested | Fetch metadata and source snapshots | Private/editorial schema; retention controls |
| `public.announcement_log` | `/rest/v1/announcement_log` | Broad browser ACL; RLS on with no policies | Not tested | Operational delivery history | Worker/server-only; revoke browser ACL |
| `public.auth_rate_limits` | `/rest/v1/auth_rate_limits` | Broad browser ACL; RLS on with no policies | Not tested | Security/operational state | Worker/server-only; revoke browser ACL |
| `public.broadcast_delivery_log` | `/rest/v1/broadcast_delivery_log` | Broad browser ACL; RLS on with no policies | Not tested | Operational delivery history | Worker/server-only; revoke browser ACL |
| `public.notification_deliveries` | `/rest/v1/notification_deliveries` | Broad browser ACL; RLS on with no policies | Not tested | Notification outbox/worker data | Worker-only functions; revoke browser ACL |
| `public.workflow_jobs` | `/rest/v1/workflow_jobs` | Broad browser ACL; RLS on with no policies | Impossible UUID request returned 200 `[]` | Worker queue and payloads | Worker-only; revoke browser ACL |
| `public.resource_public_editorial_identities` | `/rest/v1/resource_public_editorial_identities` | View owned by `postgres`; anonymous/authenticated SELECT | Not directly probed | Approved public identity projection | Keep only after ownership/RLS tests |
| `public.resource_public_categories` | `/rest/v1/resource_public_categories` | View owned by `postgres`; anonymous/authenticated SELECT | Impossible slug request returned 200 `[]` | Public category projection | Retain with allowlisted fields |
| `public.resource_public_articles` | `/rest/v1/resource_public_articles` | View owned by `postgres`; anonymous/authenticated SELECT | Impossible slug request returned 200 `[]` | Published editorial content | Test unpublished-row denial and field allowlist |
| `public.resource_public_article_categories` | `/rest/v1/resource_public_article_categories` | View owned by `postgres`; anonymous/authenticated SELECT | Not directly probed | Public article/category joins | Retain after join leakage tests |

The direct database ACL string `arwdDxtm` means INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, and MAINTAIN. Every audited table is owned by `postgres`, has RLS enabled, and has `FORCE ROW LEVEL SECURITY` disabled. Browser roles have public schema USAGE but not CREATE.

## Function matrix

The live catalog reports 42 `public` functions. The important application-facing groups are:

| Function group | Examples | Current dependency | Proposed future access |
|---|---|---|---|
| Public catalogue/community reads | `get_scholarship_discussions`, `get_scholarship_social_proof`, `get_trending_scholarship_ids`, contributor profile functions | Community loader, dashboard, contributor pages | Narrow public projections with bounded inputs and approved fields |
| Admin analytics | `get_admin_metrics_summary`, `get_provider_analytics`, `get_daily_visitor_metrics`, confirmation-email analytics | Admin dashboard and analytics pages/routes | Authenticated admin only, with unconditional guard and bounded windows |
| Discovery publication | `publish_discovery_candidate` | Admin discovery route | Approved publisher/approver capability; keep atomic gates and audit events |
| Student self-service | `replace_waec_results` | `/api/profile/waec` | Authenticated self-target only; preserve explicit caller/target equality |
| Achievement triggers | `check_achievements`, `check_application_submitted`, community/referral trigger functions | Database triggers | Trigger execution only; remove unnecessary direct RPC grants after staging regression tests |
| Worker functions | `award_xp`, `claim_notification_delivery`, `claim_workflow_job`, `complete_workflow_job`, rate-limit and visitor functions | Cron/integration/email/push workers | Service-side only |
| Risky browser-executable helper | `is_admin(uuid)`, `run_achievement_checks(uuid)` | RLS helper and achievement code | Replace arbitrary-target helper; self-only or service-only achievement check |
| Stale route dependency | `exec_sql` | Admin schema-check route attempts call then falls back | No SQL RPC; keep safe fallback and remove stale assumption when separately approved |

No RPC was executed during this phase. Catalog and advisor evidence are not treated as successful HTTP invocation.

## Application feature dependency matrix

| Application feature | Current object/API dependency | Execution context at baseline | Permission change impact | Required replacement/access path |
|---|---|---|---|---|
| Scholarship browse | `scholarships`, `scholarship_rules`, public client, sitemap readers | Anonymous public client and server components | Direct table revocation would break browse and sitemap | `api` public scholarship/rule projections or reviewed server route |
| Scholarship matching | `scholarships`, `scholarship_rules`, `cycle_events`, saved/applications visibility | Authenticated server client | Revoking base-table SELECT breaks matching | Authenticated matching function or server route with exact columns |
| Opportunity browse | `opportunities`, saved opportunities | Anonymous public client and authenticated pages | Direct table revocation breaks catalog/detail pages | Public opportunity projection plus owner-scoped save API |
| Scholarship details | `scholarships`, applications, saved scholarships, community RPCs | Server client; some public client detail pages | Must preserve public detail and private relationship checks | Split public detail projection from authenticated relationship endpoint |
| Saves | `saved_scholarships`, `saved_opportunities`, parent catalogue tables | Authenticated server routes/pages | Broad revoke can break insert/delete flows | Owner-scoped routes/RPCs; parent existence/read projection |
| Applications | `applications`, parent catalogue records, draft fields | Authenticated server routes and pages | Direct table revocation breaks draft/status/check-in flows | Validated owner-scoped application API/RPCs |
| Notifications | `notifications`, `notification_deliveries` | Authenticated routes; service workers | Table-wide UPDATE currently overbroad; outbox revoke can break workers | Mark-read function/column update plus service-only delivery functions |
| Profile and WAEC | `profiles`, `waec_results`, `replace_waec_results` | Authenticated browser/server routes | Profile grants and WAEC RPC must remain self-scoped | Explicit profile columns and self-target WAEC function |
| Discussions | `scholarship_discussions`, reactions/reports/prompts, public discussion RPCs | Authenticated server/client mix | Community reads and reaction writes need separated permissions | Public discussion projection; authenticated write routes; bounded RPC |
| Achievements and XP | `user_achievements`, `xp_events`, `award_xp`, trigger functions | Server routes plus database triggers | Removing trigger EXECUTE must not break trigger execution | Keep trigger path; service-only XP award; self/service check recompute |
| Admin dashboard | profiles, scholarships, applications aggregates, metrics RPCs | Authenticated admin route/page | Direct revocation requires replacement for admin reads/writes | Admin server routes plus guarded admin RPCs |
| Scholarship discovery | discovery candidates/claims/snapshots/review events, publication RPC, worker jobs | Admin routes and integration workers | Private editorial data cannot remain browser-addressable | Scoped editorial API and service worker calls |
| Resource Center | Four public views | Anonymous/authenticated server reads | View owner semantics require negative tests | Keep allowlisted public views, preferably invoker or narrow owner |
| Background workers | workflow/outbox tables, service-only claim/complete functions, storage | Server cron/integration clients | Browser ACL revoke should not break service role | Explicit service-only functions and server credential isolation |
| Storage and uploads | Public `avatars` and `site` buckets; storage policies | Browser uploads and public reads | Bucket changes are outside this investigation and must be separately reviewed | Preserve bucket contracts; audit policies before any change |

## Existing calls that would break under a blanket revoke

A blanket `REVOKE ALL` from `anon` and `authenticated` on the original tables would break current catalogue reads, matching, details, saves, applications, notifications, profile/WAEC, community, Resource Center, admin pages, and some server-side routes that use the session-aware client. It could also break RLS policy evaluation because several policies call `is_admin(auth.uid())` and the current migration history restores EXECUTE for policy use.

The safe order is additive: create and test replacement projections/functions, update every call site, regenerate types, run role-based staging tests, then revoke only the legacy grants that are no longer required.

## References

[1]: https://github.com/ImperioKDB/Scholars/commit/cf3682ce35912df7b9b9352193630fc404427c7c "Scholars application baseline"
[2]: https://github.com/ImperioKDB/Updates/commit/7f7eb680562b6e89c0172b5534848f2b576002c0 "Phase 2.1.1 audit handoff"
