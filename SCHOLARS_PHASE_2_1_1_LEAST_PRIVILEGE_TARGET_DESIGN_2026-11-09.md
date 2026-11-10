# Scholars Phase 2.1.1 — Least-Privilege Target Design

**Status:** Proposed target; requires product/security/database-owner approval. It is not deployed.
**Evidence baseline:** Updates commit `abb19a697703aab91f783b8e5258acebf35bf02a`; Scholars `cf3682ce35912df7b9b9352193630fc404427c7c`; production metadata sampled `2026-11-09 10:35:19 UTC`.

## 1. Design goals

1. Expose only intentionally public resources through PostgREST; API reachability is a separate decision from table residence in a schema.
2. Return only approved catalogue columns. Public row policies alone do not hide columns.
3. Keep source captures, extracted claims, unpublished candidates, editorial notes, review events and worker queues outside the public API surface.
4. Keep students' profile/application/save/notification records private and owner-scoped, preserving current product features.
5. Make role/action boundaries explicit for researcher, reviewer, approver, auditor, and worker; model confidence is never approval authority.
6. Make RLS and SQL ACLs mutually reinforcing. Revoke broad table grants instead of relying on row policies to compensate.
7. Pin all future default ACLs for every object-creating role, including `postgres` and any authorized `supabase_admin` migration path.

## 2. Schema and API boundary

### Recommended schema set

| Schema | PostgREST exposure | Contents / contract |
|---|---|---|
| `api` (or `api_public`) | Exposed, deliberately small | Read-only public catalogue projections and a short list of user-scoped RPCs required by the app. Explicit allowlist; no base tables, evidence tables, audit tables, or worker queue tables. |
| `public` | Transitional only; target not exposed to browser clients | Existing base tables during migration. Long-term, retain as owner-controlled storage if needed, not as the user-facing REST surface. Remove from exposed list only after all pages, API handlers, RPC callers, public resource views, and generated clients are migrated and tested. |
| `editorial` / `private` | Not exposed | Discovery sources/candidates, fetch metadata, claims/evidence excerpts, review/decision events, internal notes, private retention state. Existing rows must be migrated additively with verified references and no data deletion. |
| `worker` (or private routines) | Not exposed | Job queues, delivery outbox, rate-limit records, and worker state. Invocation only through narrowly granted service functions or server endpoints. |

Supabase metadata did not provide the deployed exposed-schema allowlist. The advisor confirms public RPC paths under `/rest/v1/rpc`; therefore `public` is exposed at least for functions. Before any schema switch, capture the full current PostgREST schema list and enumerate every exposed object. Do not assume a `public` → `api` change is drop-in: current server-rendered pages and handlers directly use `.from(...)`/`.rpc(...)` with the default schema.

### Catalogue projection policy

Create explicit projections, with no `select *`. The proposed public catalogue contract is a starting point for product review:

- Scholarships: `id`, `slug`, `title`, `provider_name`, `description`, `amount`, `deadline`, `opens_at`, `last_cycle_closed_at`, `application_url`, `how_to_apply`, `level`, `discipline`, and `verified` where the UI requires it.
- Opportunities: `id`, `slug`, `type`, `title`, `provider_name`, `description`, `eligibility_notes`, `duration`, `location`, `compensation`, `discipline`, `deadline`, `opens_at`, `application_url`, `how_to_apply`, and `verified` where needed.
- Scholarship rules: only normalized eligibility fields required to explain/match a verified scholarship (`scholarship_id`, `field`, `operator`, `value`, and `gating` if the product needs it); never include unpublished parents.
- Cycle history: approved event kind/date/source link only. Exclude `note` and `captured_by` until the owner affirmatively approves their public semantics; redact tracking/secret query parameters from URLs.

Explicitly excluded by default: `research_notes`, `created_by`, reviewer identity, candidate excerpts, claim quotes, extraction prompts/hashes, internal quality/eligibility reports, candidate verification notes, source/fetch snapshots, private audit fields, applicant text, and notification metadata. Scholarship competitiveness/acceptance-rate fields are **not** assumed public; product must approve each separately. The migration source at production version `20260907051428` explicitly says `opportunities.research_notes` is admin-only; the earlier scholarship metadata-leak fix and Phase 2.1 policy likewise treat internal research notes as private.

Prefer public read-only views in `api` with fixed predicates and only these columns. View security must be chosen deliberately:

- Preferred where feasible: `security_invoker=true`, with the caller's RLS policies applying to base rows and only the minimum underlying column SELECT grants. Keep base tables out of the exposed schema set so a browser cannot address them directly.
- If a security-definer projection is unavoidable, use a non-login owner that is neither table owner nor `BYPASSRLS`; grant that owner only required columns; add and test a role-specific RLS policy; use `security_barrier` when appropriate; encode publication predicates in the view; grant browser roles SELECT on the view only; and test bypass, joins, filters, and error paths. `security_barrier` alone is not a security boundary.
- A Next.js server endpoint is also acceptable if it authenticates where required, uses a server-only credential, selects exact columns, validates input, and has independent positive/negative tests. Never use a service-role endpoint as an unauthenticated proxy for arbitrary table queries.

## 3. Role and permission matrix

| Principal | Public catalogue | Student records | Editorial sources/evidence | Review decisions/audit | Worker operations | Schema/DDL |
|---|---|---|---|---|---|---|
| `anon` | SELECT only on approved projections and intentionally public read RPCs; no base-table access. | No access. | No schema/table/view/RPC access. | No access. | No access. | No CREATE, USAGE outside required API schema. |
| `authenticated` student | Same catalogue projection; public discussion/profile fields only when consented. | Own rows only: application workflow, saves, notification read-state. Use explicit-column functions/routes; cannot inspect peers. | No access. | No access. | No access. | No CREATE. |
| Editorial researcher | Same public views; candidate/source/evidence read/write limited to assigned research scope and proposed claims. | No applicant/profile access. | Read source registry and assigned captures; create/update draft candidates/claims, not approval. | Append own research event; cannot approve own candidate. | No queue control. | No CREATE. |
| Editorial reviewer | Public views plus assigned evidence; confirm/reject claims and evidence quality with reason codes. | No applicant/profile access. | Read evidence and claims; write review outcome only in assigned scope. | Append review event. | No queue control. | No CREATE. |
| Editorial approver | Read reviewed evidence and claims; make publication disposition; cannot self-approve own research where separation is required. | No applicant/profile access. | Read only what's required for decision. | Append-only approval/rejection/supersession; publication via guarded transaction. | No worker-secret access. | No CREATE. |
| Security/privacy auditor | Read-only ACL/config/function/policy/access logs and scoped incident metadata. Evidence content only when specifically necessary/approved. | No unrelated student content. | No routine edit. | Read-only audit trail; cannot change decision. | No queue mutation. | No CREATE. |
| `service_role` / worker | No browser access; only server-side operations required by specific jobs. | No broad application browsing; no unnecessary PII. | Narrow worker calls for fetch/verification/extraction, with bounded records and minimized data. | Cannot self-approve; writes technical job events only. | Explicit service-only RPCs/queue operations; server-secret gated. | No DDL. |
| Migration owner | No runtime/student access. | No runtime access. | No runtime access. | No runtime decisions. | No runtime API use. | DDL only during reviewed migrations; owner/default ACL policy explicit. |

Editorial capabilities should be backed by server-managed `app_metadata` claims or an admin-controlled membership table, never user-editable `user_metadata`. The trusted check must identify both actor and candidate scope. A signed-in user being `authenticated` does not make them an editor. For separation of duties, reject a publication action where the approver is the candidate's researcher/reviewer when the governance decision requires independent approval. Record actor, time, action, prior/new status, reason code and evidence references in append-only audit events; do not copy source text into the audit row.

## 4. Row security and direct privilege target

### Catalog base tables

- Browser roles receive no INSERT/UPDATE/DELETE/TRUNCATE/REFERENCES/TRIGGER/MAINTAIN on catalogue base tables.
- If views use `security_invoker`, grant only the specific base columns required for those projections and maintain RLS policies that expose only published/verified/current rows. Keep `public` outside the exposed-schema list to prevent direct table routing.
- Admin write operations move to role-checked server routes or narrowly scoped RPCs; require `auth.uid()` plus a trusted editor/approver capability, field validation, cycle-state checks, and audit event insertion.
- Use explicit `WITH CHECK` expressions for INSERT and UPDATE. Prefer separate policies for student/editor/worker actions. Set `FORCE ROW LEVEL SECURITY` where it is operationally safe and does not disrupt owners/workers; do not treat FORCE as a substitute for least privilege or service-role controls.

### Personal tables

- `applications`: row access only for `auth.uid() = profile_id`. Keep draft text/private notes owner-only. Expose only student-required columns; update allowed application fields through a validated API/RPC. Prevent changing ownership or catalogue identity. Admin reporting uses aggregates or scoped, audited functions—not broad row reads.
- `saved_scholarships`, `saved_opportunities`: own-row SELECT and INSERT/DELETE; no UPDATE unless a verified call site requires it. Do not expose raw cross-user save activity. Aggregate features must enforce privacy thresholds and parameter bounds.
- `notifications`: own-row SELECT; the only student update is `read_at`. Revoke table-wide UPDATE and retain column UPDATE or a narrow `mark_notification_read(id)` function with owner check. Do not allow edits to `profile_id`, type, metadata, actor, or linked entity.
- Keep unauthenticated users out of all personal records even if they can read a public catalogue projection.

### Editorial and worker objects

- Move `scholarship_discovery_candidates`, `scholarship_discovery_candidate_claims`, `scholarship_discovery_fetch_snapshots`, discovery source/verification/review tables and internal notes into `editorial`/`private` after an additive data-preserving migration. Remove browser-role grants; preserve only capability-scoped functions/routes and approved service-worker operations.
- Worker/outbox/rate-limit tables should be in a non-exposed schema, with no browser table ACL and no policies for anon/authenticated. A no-policy RLS table remains inaccessible to row operations only if grants also do not include the browser roles; remove the grants regardless.
- Keep evidence snapshots metadata-only by default; persist minimal excerpt/hash/source metadata with retention controls. Never use a public bucket.

## 5. Functions, views, ownership, and search paths

1. Inventory all current public functions and views, caller sites, trigger bindings, and application contracts; the live snapshot has 42 public functions and 23 browser-executable definer routines.
2. For every API function, explicitly revoke `EXECUTE` from `PUBLIC`, `anon`, and `authenticated` before granting to the intended role. PostgreSQL default `PUBLIC EXECUTE` must not be assumed absent.
3. Preserve policy-helper invocation where RLS requires function EXECUTE. Replace `is_admin(uuid)` with a current-principal helper such as `private.is_current_user_admin()` that accepts no user-supplied UUID, returns only the caller's own admin status, has a fixed empty search path and fully qualified relation names, and returns false for anon. Grant only the minimal EXECUTE needed for policy evaluation; ensure the helper's schema is not exposed as an RPC schema.
4. `get_admin_metrics_summary` requires an explicit top-level admin guard and a privacy review of every subquery; the application-status CTE must not run for non-admins. Add date-range and work-cost bounds.
5. Keep `get_auth_confirmation_email_analytics`, `get_daily_visitor_metrics`, `get_provider_analytics`, and `publish_discovery_candidate` behind explicit in-function authorization and parameter validation; execute only for authenticated admins/approvers as required. Test each guard with anon, student, researcher, reviewer, approver, and service contexts.
6. `run_achievement_checks(p_profile_id)` must either be service-only or verify `auth.uid() = p_profile_id`; it must not permit cross-user writes by ordinary callers.
7. Review `get_trending_scholarship_ids` for low threshold and broad date ranges; apply lower/upper bounds, an intended privacy threshold, and rate limiting. Review public contributor/discussion fields for consent and presence disclosure.
8. Use an empty `search_path` where possible and schema-qualify every relation/function/type. For unavoidable fixed-path code, pin it and ensure no untrusted role can create objects in that schema. Definer routines must have an explicit non-login, least-privilege owner; avoid owner `postgres` where a narrower owner can perform the operation.
9. Existing public Resource Center views are `security_barrier` but owner-executed. Retain only after validating their projections and publication predicates; move them to `api` and choose invoker/owner/RLS deliberately.

## 6. Default privileges and migration ownership

The live `postgres` defaults in `public` currently grant object access to `postgres` and `service_role`, not browser roles. Preserve this stance and explicitly revoke any earlier browser defaults. The live `supabase_admin` defaults in `public` grant all table/sequence privileges and function EXECUTE to `anon` and `authenticated`; these remain a future-object risk if objects are created under that role.

Target rule: every actual object-creating role has explicit defaults that grant nothing to `anon`/`authenticated` by default for tables, sequences, functions, and new schemas. Grant per-object/per-column access only after review. `service_role` defaults should also be considered; favor explicit per-object privileges over blanket all privileges. Validate who can execute `SET ROLE`/`ALTER DEFAULT PRIVILEGES` and which identity the migration runner uses. Do not change platform-managed `supabase_admin` defaults until an authorized owner confirms supported procedure and expected impact.

## 7. Compatibility and rollout constraints

Current routes use session-aware Supabase clients, and several server components/API handlers query base tables directly. Before removing `public` from PostgREST or revoking all base-table access, enumerate and migrate each call site (including resource views, RPCs, admin writes, matching rules, save flows, applications, and notifications). Keep the public API contract stable through a compatibility phase: add `api` projections/functions, update code and generated types, pass tests, then switch exposure/revoke direct grants. Never deploy a privilege revocation ahead of code that no longer depends on the old permission.

No exact public competitiveness/acceptance-rate field decision is made here. No editor/approver role assignment is made. Both require owner approval.

## 8. Related documents

- [Production security investigation](SCHOLARS_PHASE_2_1_1_PRODUCTION_SECURITY_INVESTIGATION_2026-11-09.md)
- [Privilege and API exposure matrix](SCHOLARS_PHASE_2_1_1_PRIVILEGE_AND_API_EXPOSURE_MATRIX_2026-11-09.md)
- [Security remediation and rollback plan](SCHOLARS_PHASE_2_1_1_SECURITY_REMEDIATION_AND_ROLLBACK_PLAN_2026-11-09.md)
- [Security test specification](SCHOLARS_PHASE_2_1_1_SECURITY_TEST_SPECIFICATION_2026-11-09.md)
