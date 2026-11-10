# Scholars Phase 2.1.1 — Security Test Specification

**Status:** Proposed test contract; no production/API calls or staging changes were made in this audit.
**Test environment required:** An isolated Scholars staging project with a versioned baseline and synthetic-only fixtures. The current `scholars-staging` project has no Scholars public tables/migration baseline and is **not ready** for this test suite.
**Credentials:** Use fresh anon and authenticated JWTs for API tests; service-role credential only in server-side test harness. Never print, commit, or expose secrets.
**Primary acceptance:** least-privilege behavior is demonstrated at both PostgREST/database and Next.js route boundaries; a `postgres` SQL session alone is not an authorization test.

## 1. Rules of engagement

Run only against a disposable, isolated staging project. Use synthetic fixture rows, fake email addresses/domains, and unique test UUIDs. Do not copy production user data, application answers, WAEC records, notification payloads, analytics, saved activity, tokens, or service keys. No production `DELETE`, `TRUNCATE`, DDL, grants, function calls, or API probing is authorized by this specification. Each test records environment/project, git SHA, migration version, JWT role (never token), request path/method, status, minimal response shape, expected result, and cleanup status.

Use independent anon, student A, student B, approved editor/admin, and service worker identities. Student A and B must not be admins. Add a second student profile with no community posts and synthetic profiles with consented public contributions. Use synthetic `scholarships`, `opportunities`, cycle data, applications, saves, notifications, candidates, claims, snapshots, WAEC grades, XP events and worker jobs only. Seed negative cases with clear marker values such as `PRIVATE_FIXTURE_DO_NOT_RETURN`.

## 2. Staging readiness gates

Before running tests, confirm that staging is isolated from production, has the complete tracked migration baseline reconciled to a live ledger, has matching generated TypeScript database types, and can be reset without production impact. Confirm exact PostgREST exposed schemas, authenticator role switching, JWT audience/role behavior, RLS/ACL/default ACL state, and any platform-managed views. Add the synthetic fixtures and expected IDs to a test manifest. A missing relation, unknown migration, or untracked production-only DDL blocks authorization tests rather than being silently treated as pass.

Capture a before snapshot of table/function/view ACLs, owners, RLS and FORCE flags, policies, role memberships, schema USAGE/CREATE, defaults and exposed schemas. Confirm `anon` and `authenticated` have no membership into service_role/owner roles. Use the actual PostgREST API key and JWT role; do not use `postgres`/service_role credentials for tests intended to represent browser access.

## 3. Table-level role test matrix

| Resource | Anon/student expected behavior | Student A/B isolation checks | Admin/service behavior |
|---|---|---|---|
| Scholarships/opportunities | Return only approved public projection for verified/current records; no research notes, reviewer fields or internal evidence. Unverified rows denied. | Do not expose hidden fields via direct table route; saved/applicant relationship must not reveal another student's state. | Admin workflow can read/write approved internal fields; service worker only for documented tasks. |
| Scholarship rules | Only approved public eligibility rules for verified parent. | No draft/unverified parent's claims. | Admin/editor CRUD restricted to workflow roles. |
| Cycle events | Only explicit public cycle facts; no `note`, `captured_by`, internal source notes, or private state. | One student's actions cannot change another's cycle. | Admin/editor access audited. |
| Applications | Anon denied. Authenticated user can access only own rows and approved columns. | A cannot read/update/delete B; forged `profile_id` insert/update denied. Test every method and field including status, reviewer/admin-only attributes and answers. | Admin read follows approved support policy; no blanket student write. |
| Saved scholarships/opportunities | Anon denied; student only own items. | A cannot read, update, delete or infer B's raw saves through direct relation. | Admin reporting uses minimum aggregates. |
| Notifications | Anon denied; own rows only. | A cannot access B's notification or set actor/recipient; authenticated update limited to `read_at`. | Service may deliver only through outbox/worker contract. |
| Discovery candidates/claims/snapshots | Anon/student denied; no candidate evidence, URL snapshots or claims. | B cannot inspect A's review material. | Distinct reviewer/approver rights; audit actor/event captured. |
| Internal no-policy tables | Anon/auth denied for SELECT/INSERT/UPDATE/DELETE; confirm REST does not expose any route. | No cross-user inference. | Workers operate through service functions, not broad public table rights. |

For each object test GET/select, insert, update, delete using the actual REST relation endpoint if exposed, plus RPC and Next routes. For CRUD, include both allowed and denied rows and each sensitive column. RLS denial and object-level privilege denial should be distinguished from a generic HTTP error. **TRUNCATE is not an ordinary PostgREST table operation**; do not claim an HTTP route can invoke it. Verify database grants by metadata, and test destructive privileges only inside isolated disposable SQL staging with a purpose-built role, never production.

## 4. Database grant, policy, and default-privilege acceptance

Expected future state: no browser-role table-wide INSERT/UPDATE/DELETE/TRUNCATE/REFERENCES/TRIGGER/MAINTAIN on private or internal tables; no public base-table SELECT where an allowlisted view/API is required; only intentional narrow anon SELECT on a documented public projection. RLS may remain defense-in-depth but must not be used to justify excess grants. `notifications` must have only `read_at` update or a narrow mark-read function. Candidates, claims, snapshots, applications, worker logs and raw save activity remain private.

Check before/after direct `relacl`, `has_table_privilege`, column ACL, policies, FORCE flags, ownership, sequence grants, function EXECUTE and default ACLs for both `postgres` and the actual supported platform object-creation role. Confirm new tables/functions/sequences created by each sanctioned creator role default to owner/service-worker only. Confirm browser roles do not inherit service-role/BYPASSRLS rights. Verify migration idempotence and that existing objects are actually corrected; a default-privilege migration alone is not a pass.

## 5. Function/API test inventory

Current production catalog has 31 public SECURITY DEFINER functions (23 browser-executable, eight service-only) plus 10 anon/auth-executable non-definer functions. Test every routine below via PostgREST using anon/student/admin/service roles as appropriate. Database ACL metadata and API behavior are separate assertions. A trigger-returning function may be rejected by PostgREST; test that outcome rather than assuming catalog EXECUTE proves HTTP invocation.

### 5.1 Sensitive analytics and helper functions

| Function | Negative cases | Positive case / expected contract |
|---|---|---|
| `is_admin(uuid)` | Anon/student must not enumerate arbitrary users' admin state; test self, other, random and known synthetic admin UUIDs. | A replacement current-user helper returns only the caller's authorization and no arbitrary UUID input. |
| `get_admin_metrics_summary(timestamptz)` | Anon/student receives denial or no outcome metrics, including when event table is empty. Test crafted since ranges and large ranges. | Admin receives bounded synthetic aggregates only; confirm application outcome counts are within intended privacy policy. |
| `get_provider_analytics(timestamptz,timestamptz,uuid)` | Anon/student denied before analytics query; student cannot select another provider/scholarship scope. | Admin receives bounded synthetic output and no raw personal data; date and scholarship parameters validated. |
| `get_daily_visitor_metrics(timestamptz,timestamptz)` | Anon/student denied; malformed/reversed/overlong ranges rejected. | Admin gets synthetic daily counts, bounded output. |
| `get_auth_confirmation_email_analytics(timestamptz,timestamptz)` | Anon/student denied; no auth-user identity, email, token, or request body returned. | Admin gets approved aggregates only; enforce date bounds and avoid email-domain cohorts below policy threshold. |
| `run_achievement_checks(uuid)` | A cannot cause cross-profile writes/achievements for B. Test anonymous, nonexistent ID, and already-awarded rows. | Self-target/service-only execution recomputes only factually earned, idempotent achievements; verify XP ledger deduplication. |
| `publish_discovery_candidate(uuid)` | Anon, student, wrong admin tier and reviewer-only cannot publish; fail each precondition individually: status, quality, verification, stale evidence, eligibility review, confirmed nationality/level claims, missing URL. Repeated/concurrent calls must not duplicate scholarship/audit event. | Approved publisher succeeds atomically, creates initially unverified scholarship, rules from confirmed claims only, candidate link and audit record. Verify rollback on any insert failure. |

### 5.2 Public/product read functions

| Function | Required checks |
|---|---|
| `get_scholarship_discussions(uuid,text,integer)` | Unpublished/deleted/unverified scholarship denied; page size/filter bounded; no anonymous author name/avatar/role/online state; non-anonymous fields only under approved consent. Online status must be removed unless explicitly approved. Prevent injection through sort/filter args. |
| `get_scholarship_social_proof(uuid)` | Test synthetic cohort sizes 0, 1, 4, 5, 6. Current production returns exact save/applicant/discussion/view counts; institution names alone have threshold >=5. Expected future output must suppress/round all small cohorts or match explicit public-data approval. |
| `get_trending_scholarship_ids(integer,integer)` | Test default, threshold 1, 0, negative, huge thresholds, zero/negative/huge days. Current function has no positive/minimum clamp and threshold <=1 can reveal IDs with a single save. Future behavior must bound inputs and enforce approved cohort threshold or deny public execution. Use synthetic saves only. |
| `get_public_contributor_profile(uuid)` / `get_community_contributor_profile(uuid)` | Test no contribution, anonymous-only contribution, unverified parent, deleted/blocked profile, consent withdrawn, and another user's UUID. Only allowlisted consented public fields; never email/phone/private profile fields. |

### 5.3 Trigger-returning definer functions (11)

For `check_achievements`, `check_application_submitted`, `check_community_discussion_achievements`, `check_community_reaction_achievements`, `check_first_action_achievements`, `check_referral_completion`, `handle_new_user`, `notify_discussion_helpful`, `notify_discussion_reply`, `sync_scholarship_discussion_helpful_count`, and `sync_waec_summary_fields`, attempt ordinary anon/student RPC invocation and expect no exposed callable endpoint or permission denial. Separately perform the legitimate synthetic trigger event and verify the function still runs with correct target profile, no cross-user writes, notification privacy, anonymous-reply behavior, accurate derived counts, and no duplicate XP. Revoke unnecessary browser EXECUTE only after all trigger regressions pass.

### 5.4 Service-only definer functions (8)

For `award_xp`, `check_rate_limit`, `claim_notification_delivery`, `claim_workflow_job`, `complete_workflow_job`, `flag_expired_opportunities`, `record_visitor_page_view`, and `seed_scholarship_prompts`, anon/student/admin JWTs must be denied where not explicitly intended. The server worker must get only its named capability; test invalid IDs, replay, expiry, duplicate delivery, lease contention, retry/dead-letter behavior and input bounds. Confirm service-role credentials never appear in browser bundles, logs, route responses or client state.

## 6. Non-definer functions and stale SQL RPC

| Function | Tests |
|---|---|
| `replace_waec_results(uuid,jsonb)` | Authenticated self replacement succeeds atomically; caller-supplied B UUID fails for A and makes no changes. Verify `app/api/profile/waec/route.ts` derives UUID from `auth.getUser()`, not body. |
| `calculate_profile_completeness(profiles)` | Caller-supplied composite is only calculated; no stored profile data is returned. |
| `catalog_slug(text,text)` | Pure function; arbitrary strings return bounded deterministic output and no database read. |
| Trigger-only invoker functions `set_catalog_slug`, `set_profile_completeness`, `set_updated_at`, `sync_xp_total`, `touch_scholarship_discussion_updated_at`, `touch_scholarship_prompt_updated_at`, `validate_scholarship_discussion_parent` | Ordinary anon/student RPC must fail or be unavailable; corresponding normal DB trigger continues working under the intended caller. Check no cross-user mutation is possible. |
| `exec_sql` | Current production catalog has no function of this name in any schema. Verify `app/api/admin/schema-check/route.ts` handles missing RPC safely and uses its column-probe fallback after admin authorization; test must not create an exec_sql function. |

## 7. View and Next.js route tests

For each public Resource Center view (`resource_public_editorial_identities`, `resource_public_categories`, `resource_public_articles`, `resource_public_article_categories`), verify exact approved columns and active/published filter; attempt direct table reads of underlying private rows and confirm no leakage. Exercise both anon and authenticated API roles because the views are postgres-owned with `security_barrier=true` but not `security_invoker=true`.

For `app/api/applications` routes, test missing/expired auth, user A/B IDs, forged `profile_id`, unsupported status/field changes, and error responses. For `app/api/notifications`, verify own-row read and only `read_at` mutation. For scholarship/opportunity catalogue routes, confirm explicit response allowlist excludes `research_notes`, raw review/actor fields and non-public status; compare with direct REST access. For admin analytics and discovery routes, use non-admin and admin identities; both API guards and in-function guards must enforce the same authorization. For `app/api/admin/schema-check`, confirm rate limit and `assertAdmin` precede probes, and no secret/schema details are returned to students.

## 8. Acceptance gates and evidence

| Gate | Pass condition |
|---|---|
| Role boundary | Anon/student cannot use service_role, BYPASSRLS, table-owner, or admin capabilities; no browser role membership inheritance. |
| Private rows | A cannot read or mutate B's application/save/notification/WAEC/candidate state through any exposed route or RPC. |
| Public fields | Only explicitly approved public projections; no research notes, unapproved cycle note/actor, exact small-cohort counts, private identity or presence. |
| Function grants | Every callable function has documented purpose, minimal role grant and authorization test; no unnecessary PUBLIC/browser trigger EXECUTE. |
| Admin operations | Admin-only route and RPC checks both deny anon/student; cross-profile writes denied unless explicitly authorized service operation. |
| Defaults | New objects created by every sanctioned role are least-privilege by default; existing object ACLs are separately corrected. |
| Views | Public view outputs are allowlisted and underlying owner/RLS semantics tested. |
| Rollback | Migration tested in disposable staging; rollback restores intended app behavior without broad regrant of browser roles. |
| Build/app | Next tests, typecheck, lint and Vercel Preview succeed after any separately approved app change. |

Store only sanitized metadata snapshots, request status/role labels, expected versus observed result, and test-run SHA. Do not store JWTs, service keys, user payloads, real email addresses, WAEC results, application answers, or production row values. A failed/high-risk case blocks promotion. Fixes require a separate approved implementation and migration plan; this file does not authorize production changes.
