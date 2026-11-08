# Scholars Resource Center — Phase A0.4 Backend Foundation Specification

**Assessment date:** 2026-11-08
**Repository:** `ImperioKDB/Scholars`
**Documentation repository:** `ImperioKDB/Updates`
**Pinned Resource Center source commit:** `41573f5ec2985851ba118e8b39a47f9c54532302`
**Prior assessment reference:** `85a554f60a88515942fd5ab8678272a8e93d0bc2`
**Review mode:** scoped, read-only static source review; no database or production access
**Verdict:** **BLOCKED** — the specification is complete, but backend implementation must not proceed until the authoritative `public.is_admin(uuid)` definition and its effective security contract are supplied and reviewed.

## 1. Executive assessment

The Resource Center schema and four public projection views exist in the pinned source migration `20261107130100_resource_center_schema.sql`. Per the task, they are treated as already deployed; deployment state and effective live privileges were not independently verified. The schema is a useful foundation, but it is not an editorial workflow implementation.

The current design has article state values and basic checks, a revision table, administrator-oriented RLS policies, and public views. It does **not** enforce allowed state transitions, reviewer/author separation, approval-to-revision binding, revision immutability, ordered revision allocation, transactional publication, or transition audit. The public article view reads article content and category associations from mutable base rows rather than the revision referenced by `published_revision_id`. An authorized direct update can therefore change what the public projection returns without establishing that the change was reviewed.

The central authorization dependency is unresolved. `0002_harden_functions.sql` hardens `is_admin(uuid)` and revokes its execution from API roles; `0023_lock_admin_flag.sql` later grants execution on `public.is_admin(uuid)` to `PUBLIC`. Both files lack the function body. The latter's comments describe an empty search path and `SECURITY DEFINER`, but comments are not an authoritative definition or proof of effective ownership, body, ACL, or behavior. The current source and the targeted migration-history search did not yield the function definition. Consequently, it is not possible to establish whether ordinary students can only evaluate their own administrative status in policy calls, whether they can query arbitrary UUIDs through an exposed RPC, or whether the function has a logic flaw that changes the authorization boundary. The `profiles.is_admin` column is protected from ordinary `anon`/`authenticated` column writes in migration 0023, but that fact does not resolve the function risk.

**Implementation decision:** preserve the existing schema; do not recreate it. Before any implementation, obtain and review the authoritative function definition and the effective database security facts listed in §3. Then implement editorial writes only through narrowly authorized transactional operations, with database-enforced state/revision invariants, append-only audit, and AAL2 checks. Do not use a browser-exposed service-role key or trust client-side controls.

No SQL, migration, production database, storage permission, authentication setting, frontend, or deployment was changed during this assessment.

## 2. Existing backend inventory

### 2.1 Resource Center objects in the pinned schema migration

The migration creates these five base tables:

- `resource_editorial_identities`: optional unique `user_id` mapping, public-facing name/bio/avatar path, active flag, and timestamps.
- `resource_categories`: unique slug, public metadata, display order, active flag, and timestamps.
- `resource_articles`: slug/title/excerpt/Markdown, article type and status, schedule/publication/archive/review timestamps, canonical URL and featured-image path, author/reviewer identity references, actor IDs, and nullable `published_revision_id`.
- `resource_article_categories`: current article-to-category join rows.
- `resource_revisions`: article ID, positive revision number, JSON object `state`, schema version, change summary, creator and timestamp, and `UNIQUE(article_id, revision_number)`.

The migration's checks restrict the five state strings to `draft`, `in_review`, `scheduled`, `published`, and `archived`; require a schedule timestamp for `scheduled`; require a publication timestamp for `published`; and require a reviewer identity for `in_review`, `scheduled`, and `published`. The schema has a deferred single-column foreign key from `resource_articles.published_revision_id` to `resource_revisions.id`, but it does not prove that the referenced revision belongs to the same article.

RLS is enabled on the five base tables. The migration revokes base-table privileges from `anon` and `authenticated`, grants all table privileges to `service_role`, then grants authenticated users `SELECT/INSERT/UPDATE` on identities, categories, articles, and article-category links, and `SELECT/INSERT` on revisions. Six policies are present: `FOR ALL` administrator policies on the first four base tables and administrator `INSERT`/`SELECT` policies on revisions. All use `public.is_admin(auth.uid())`; revision insertion additionally requires `created_by = auth.uid()`. These policies are declarations in source, not a runtime proof of effective RLS.

The migration creates four `security_barrier` public views: `resource_public_editorial_identities`, `resource_public_categories`, `resource_public_articles`, and `resource_public_article_categories`. They filter inactive identities/categories and article rows to `status = 'published'`, non-null `published_at`, and `published_at <= now()`. Public article fields are selected from the current `resource_articles` row; categories are selected from the current join table. The view does not use `published_revision_id` or `resource_revisions.state`. The views do not set `security_invoker`; their owner and effective runtime behavior were not verified. A `security_barrier` is not, by itself, a substitute for verifying view-owner and RLS behavior.

The A0.3 assessment reports that this migration includes no workflow triggers, transition RPCs, audit ledger, revision allocator/immutability trigger, publication worker, or storage operation. This A0.4 review did not repeat the 129-migration inventory.

### 2.2 Existing admin, authentication, and service-role patterns

At the pinned revision:

- `lib/admin/guard.ts` has `assertAdmin()`: it authenticates with `supabase.auth.getUser()`, reads `profiles.is_admin`, and optionally requires both current and next assurance level to be `aal2` when `requireAal2` is set or `REQUIRE_ADMIN_MFA=true`.
- `lib/admin/access.ts` provides the corresponding Server Component `requireAdmin()` redirect gate and the same optional AAL2 rule.
- These are useful server-side checks, but the source alone does not establish that all future editorial endpoints will call them, that the production environment flag is set, or that direct PostgREST/database writes are constrained to the same workflow.
- `lib/supabase/server.ts` creates the cookie/session-bound server client with the public anon key, so signed-in requests retain their user context and RLS applies.
- `lib/supabase/service.ts` is marked `server-only` and reads `SUPABASE_SERVICE_ROLE_KEY`; its comment correctly warns that it bypasses RLS. Its use is appropriate only behind explicit trusted server/job authorization. It must never be imported into browser code.
- The MFA routes implement TOTP enrollment, factor listing, verification, and guarded factor removal. Their existence is not evidence that every editorial operation currently requires AAL2.

There is no Resource Center backend route or editorial execution path in the inspected migration/source. The general admin guard is not a substitute for role-specific author/reviewer/publisher checks.

### 2.3 What is available, what is not verified, and what is missing

| Status | Finding |
|---|---|
| Available in source | Resource Center table/view definitions; `profiles.is_admin`; Next.js admin guard and optional AAL2 check; cookie-bound Supabase server client; server-only service-role helper; existing public `site` bucket migration. |
| Assumed from task, not independently verified | Existing Resource Center objects/views have already been deployed. No production or hosted Supabase access was allowed. |
| Requires verification before implementation | Authoritative `public.is_admin(uuid)` body, owner, security mode, search path, ACL and downstream privileges; effective RLS and view-owner behavior; current deployed storage policies/limits; `REQUIRE_ADMIN_MFA` deployment setting and route coverage; database default privileges for the roles that will create new functions. |
| Requires implementation | Editorial capability/identity checks, permitted transition enforcement, immutable revisions and exact snapshot publication, cross-article reference protection, transactional publish/schedule operations, audit events, safe media contract, and the missing server-side operations. |

## 3. Admin authorization findings and blocker

### 3.1 Evidence in source

`supabase/migrations/0002_harden_functions.sql` sets an empty search path on `is_admin(uuid)` and revokes execution from `PUBLIC`, `anon`, and `authenticated`. It does not define the function or state its owner/body. `supabase/migrations/0023_lock_admin_flag.sql` revokes ordinary API-role column writes to `profiles.is_admin`, then grants `EXECUTE ON FUNCTION public.is_admin(uuid) TO public`. Its comments say the function is `SECURITY DEFINER`, has an empty search path, and is useful only to policy evaluation; those statements are not independently established by the migration because the `CREATE FUNCTION` statement is absent. The later grant is broader than the earlier revokes if no subsequent effective ACL change supersedes it: PostgreSQL's `PUBLIC` grantee includes ordinary API roles. Therefore, direct RPC reachability must be treated as possible until the live exposed schema and ACL are verified.

The `profiles.is_admin` column protection is a meaningful defense against a student setting their own flag with ordinary authenticated table writes. It is not proof that the helper is safe, that service-role/server paths are safe, or that every policy calling it is effective. The Resource Center's `FOR ALL` policies rely on this unresolved function for every direct authenticated base-table action.

The exact function definition was not found in the pinned/current Scholars source or the targeted migration history. The A0.3 assessment independently records this same unresolved dependency. No production database or credentials were accessed.

### 3.2 Answers to the required questions

| Question | Evidence-based answer |
|---|---|
| What does `public.is_admin(uuid)` actually check? | **Unknown.** No authoritative function body was found. Do not infer it from comments or policy call sites. |
| Is it `SECURITY DEFINER`? | Migration 0023 comments claim that it is, but the authoritative `CREATE FUNCTION` is absent. **Not verified.** |
| Who owns it? | **Unknown.** No function definition/ownership statement or catalog result was available. |
| What is its search path? | Migration 0002 issues `ALTER FUNCTION is_admin(uuid) SET search_path = ''`; migration 0023 comments also describe an empty path. This supports a source-level intended setting, not verification of the deployed function, exact schema resolution, or later changes. |
| What are its effective execution privileges? | Migration 0002 revokes from `PUBLIC`, `anon`, and `authenticated`; migration 0023 later grants to `PUBLIC`. Effective deployed ACL and any subsequent changes are **not verified**. The source sequence contains a broad re-grant that must be resolved. |
| Is it compatible with Resource Center policies? | **Cannot be established** without the body, owner, ACL, and runtime policy tests. Resource policies call it with `auth.uid()` and depend on a correct fail-closed result. |
| Can an ordinary student self-elevate or bypass checks? | Column-level privilege revokes in 0023 are evidence against direct writes to `profiles.is_admin` by ordinary API roles. They do not prove the function cannot be exploited or that every route/RLS path is safe. Because `PUBLIC` is granted execution in 0023 and the body is unknown, **the absence of a query/bypass issue cannot be concluded**. No evidence was found that students can set their own admin flag; no evidence sufficient to rule out a function-level bypass was found either. |

### 3.3 Exact information required to clear the blocker

Before implementation, the owner of the authoritative database function/source must provide, from an approved non-production/source artifact (production credentials are not requested):

1. The complete, exact `CREATE FUNCTION public.is_admin(uuid)` definition, including parameter name/type, language, body, volatility, `SECURITY INVOKER`/`SECURITY DEFINER`, and any configuration clauses.
2. Its owner and whether that owner has `SUPERUSER`, `BYPASSRLS`, or table-owner bypass; its `search_path` and any objects it can access.
3. The effective function ACL after all grants/revokes and the applicable role memberships/default privileges; confirm whether `PUBLIC`, `anon`, and `authenticated` can invoke it through exposed PostgREST RPC.
4. The exact intended semantics for arbitrary UUID arguments versus the authenticated caller, and evidence that a student cannot impersonate, enumerate sensitive role membership, or cause an RLS predicate to evaluate true for themselves.
5. The exact deployed `profiles` RLS/table grants relevant to reads by the function owner, or an approved sanitized catalog export from a test/staging environment.

If the definition does not exist in authoritative source, the database/security owner must approve a canonical implementation and its intended compatibility contract in a separate authorization step. This specification does not invent or replace the function.

## 4. Editorial workflow state machine

### 4.1 Role model and invariants

Use editorial identities as public byline records, not as the only authorization mechanism. `resource_editorial_identities.user_id` can map one user to one identity, but the current schema contains no author/reviewer/publisher capabilities. Add an explicit active membership/capability relation (or an equivalent reviewed role model) so that eligibility is checked by `auth.uid()` in the database. Treat `profiles.is_admin` only as a platform-level administrative override after §3 is resolved; do not silently equate every admin with an editorial author or reviewer.

Every article has an immutable author/creator attribution. A reviewer must be an active, authorized editorial identity and a different user/identity from the author. A publisher may be a distinct capability; scheduled system publication is a restricted system action. Never accept a client-supplied `actor_user_id` as authoritative: derive the actor from the signed-in Supabase JWT (`auth.uid()`) or mark the actor as the scheduler/system in a narrowly scoped job function.

### 4.2 Allowed transitions

Every successful transition must lock the article row, verify an expected version/current revision, apply all associated updates and insert an audit event in one database transaction. Disallowed transitions return a stable conflict/authorization result and make no partial state change.

| From → To | Actor and required checks | Required effect |
|---|---|---|
| New → `draft` | Authenticated user with active author capability and mapped author identity; editor may create on behalf of an explicitly assigned author. | Create article and first immutable snapshot atomically; record actor and creation event. |
| `draft` → `draft` | Assigned author or editor with edit capability; not a client direct table write. | Apply patch against expected version; create a new revision for every material change, including categories and media reference; increment version. |
| `draft` → `in_review` | Author/editor submits the exact current revision; a distinct active reviewer must be assigned. | Freeze submitted revision ID/hash; record submission and reviewer assignment. No material editing of the submitted snapshot. |
| `in_review` → `draft` (withdraw/reject) | Author may withdraw before decision; assigned reviewer may reject with a required reason. Reviewer must differ from author. | Clear pending approval; retain submitted revision and append rejection/withdrawal event. A rejection requires edits and a fresh submission before approval. |
| `in_review` → `scheduled` | Assigned distinct reviewer approves the exact submitted revision; schedule time is future; AAL2 required. | Set approval actor/time/revision and scheduled time atomically. Any material change invalidates approval and requires a new review. |
| `in_review` → `published` | Assigned distinct reviewer approves the exact submitted revision for immediate publication; AAL2 required. | Set approved revision and published revision to the same immutable snapshot, set server publication time, audit, and expose only after commit. |
| `scheduled` → `published` | System scheduler only after `scheduled_for <= now()`, or an authorized publisher's explicit immediate publish; AAL2 for the human path. | Re-check approval/revision equality and publication conditions under lock; set actual publish time and append event atomically. |
| `scheduled` → `draft` | Author/editor cancels before publication; clear schedule and invalidate approval. | Preserve revisions; record cancellation and reason. Resubmission requires a new approval. |
| `published` → `draft` (unpublish) | Publisher/editor with unpublish capability; AAL2 and reason required. | Hide immediately by changing status; preserve published snapshot/history; clear live approval for future content; audit old/new revision and reason. |
| `published` → `archived` | Publisher/editor with archive capability; AAL2 and reason required. | Remove from public projections in the same transaction and preserve revision/history. |
| `draft`, `in_review`, or `scheduled` → `archived` | Editor/publisher with archive capability; AAL2 for sensitive action. | Cancel pending review/schedule as appropriate and record why. |
| `archived` → `draft` | Editor with reopen capability; no reuse of stale approval. | Reopen as a draft, create/reselect a current revision, and require a fresh review. |

No direct transition from `published` to another published revision is allowed. An edit to published content creates a new working revision and must be reviewed before becoming the live revision; the current approved/published snapshot remains the public source until atomic replacement. Archival or unpublishing must take effect immediately in the public projection, without deleting revision records.

### 4.3 Approval invalidation, timing, failure, and concurrency

- Approval records the exact revision ID (and preferably a database-verified canonical content hash), reviewer user/identity, approval time, and decision. It is not a mutable boolean detached from content.
- Every material change—title, slug, excerpt, Markdown, article type, canonical URL, image path, reading time, author/byline assignment, or category set—creates a new revision and clears or supersedes any approval. Schedule time may be changed only through a controlled operation; changing it does not silently change reviewed content.
- `published_at` is a server-generated actual publication time, not a client input. `scheduled_for` is stored as a timezone-aware instant (UTC normalization) and must be future at scheduling. A scheduled item becomes public only after the scheduler revalidates state, approved revision, and due time.
- A failed approval/publication transaction must not leave a half-published article. A failed scheduler attempt leaves it scheduled and retryable, and writes a bounded safe failure record with attempt time/code. Do not put secrets or full exception traces into public responses. Persist failure reporting in a transaction that can commit independently of a rolled-back publish attempt.
- Require `expected_version`/`If-Match` on updates and transitions. Lock the article row with `FOR UPDATE`; allocate the next revision number while holding that lock. `UNIQUE(article_id, revision_number)` remains the final collision guard. Use an idempotency key for create/submit/approve/publish actions so retries do not duplicate revisions/events or publish twice.
- For multiple due articles, a scheduler claims work with row locks (e.g. `FOR UPDATE SKIP LOCKED`) and processes idempotently. A worker may not publish an arbitrary client-selected article. A stale schedule or revision mismatch is a recorded failure requiring an explicit corrective action, never automatic publication of unapproved content.

## 5. Revision and content integrity design

The current revision table is a useful immutable-snapshot *shape*, but the current migration does not enforce immutability or complete linkage:

- It permits authenticated `INSERT` and `SELECT` (subject to the admin policy), has no update/delete prohibition trigger or grant boundary against privileged actors, and defines no allocator. The unique constraint prevents duplicate numbers but does not allocate them deterministically under concurrent writes.
- Article mutation is not required to create a revision. The public views read mutable article and category-link fields rather than snapshot JSON.
- The article's `published_revision_id` foreign key checks only that a revision ID exists, not that it belongs to that article.
- No approval revision/user/time/hash is stored as a separate fact. `reviewer_identity_id` and `last_reviewed_at` cannot prove what exact content was approved.

### Required additive design

1. Preserve the existing tables and add fields/tables in a new forward-only migration; do not edit historical migration files or recreate the base schema. Add an optimistic `lock_version` (or equivalent), approval revision/actor/time/hash fields, and any narrowly required workflow metadata. Add a composite unique key on `(article_id, id)` for revisions and a composite foreign key from `(resource_articles.id, resource_articles.published_revision_id)` to `(resource_revisions.article_id, resource_revisions.id)`; do the same for the approved revision reference. Validate existing rows before adding constraints.
2. Make a revision snapshot contain every field that changes the public article payload and its category assignments. Serialize a versioned JSON object with a documented schema; include slug, title, excerpt, content, type, canonical URL, featured-image object path, reading-time value, author/byline identity reference or snapshot fields, and category identifiers/required public labels. A snapshot is immutable once inserted. Use a DB-owned allocation rule under article-row lock; keep `UNIQUE(article_id, revision_number)`.
3. Remove direct authenticated write routes/grants to the base tables once new operations are ready. Insert revisions only through a controlled transaction. Add database enforcement that rejects update/delete of a committed revision, including attempted service-role table updates (ordinary RLS alone does not constrain service-role bypass). Privileged maintenance exceptions must be explicit, non-routine, and audited.
4. Bind approval and publication to revision IDs. On publish, verify approved revision belongs to article and is still the desired revision. A material edit cannot change the public revision pointer or public projection before a fresh approval. The public article/category views must be replaced additively (`CREATE OR REPLACE VIEW`, preserving column contract) to read the published snapshot rather than mutable draft fields/current category joins.
5. Perform revision insertion, article update, category snapshot, approval or publication pointer change, timestamps, and audit insertion in the same database transaction. If any step fails, all content/state changes roll back. `published_revision_id` must never point to another article's revision.

A JSON snapshot hash is recommended for drift verification, but the implementation must specify canonicalization and where the hash is generated/checked. Do not assume `pgcrypto` or add an extension without verifying availability; if a hash is used, calculate it in trusted database code or verify a supplied hash there rather than trusting the browser.

## 6. Security architecture

### 6.1 Write boundary

- Public and authenticated readers use only the existing public projection views. Anonymous users receive no base-table access. Editorial users use authenticated, session-bound server actions/API routes for management and a narrow database operation surface.
- Do not rely on hiding buttons, a React route guard, `requireAdmin()`, or a client-provided role. The database must enforce the state machine, actor/capability check, author/reviewer separation, revision binding, AAL2 where required, and transaction/audit invariants.
- Revoke general authenticated `INSERT/UPDATE` (and any unnecessary `SELECT`) on Resource Center base tables in a reviewed forward migration, and replace broad `FOR ALL` admin policies with explicit least-privilege read policies plus authorized RPCs. RLS and SQL grants are separate controls; both must be checked. Keep service-role access server-only.
- Prefer session-bound RPC calls from the Next.js server Supabase client so `auth.uid()` and JWT claims survive to PostgreSQL. If a trusted server path uses a service-role client for a task such as validated file upload, re-authenticate the user with `getUser()`, perform an explicit capability/AAL2 check, constrain the exact operation/path, and do not pass a caller-supplied actor ID. Never use the service role as a shortcut for user-facing editorial authorization.

### 6.2 Privileged database functions

For every privileged editorial RPC, require:

- `auth.uid()` derived from the verified request JWT; fail closed for null, anon, or service-role invocation except a separately named due-publication worker function.
- A database lookup of an active editorial membership/identity and the exact capability needed for that action. Do not trust an input `is_admin`, role, reviewer ID, creator ID, or actor ID. Validate any requested reviewer is active/authorized and distinct from the author.
- `auth.jwt()->>'aal' = 'aal2'` for approval, schedule, immediate publication, unpublish, archive, membership changes, and category/identity administration (final threshold should be confirmed by owner). The corresponding Next.js guard is defense in depth, not the sole enforcement point.
- Row locks, expected-version/revision validation, transactional audit insert, and structured stable failure codes.
- If `SECURITY DEFINER` is required, use a dedicated `NOLOGIN` non-superuser/non-`BYPASSRLS` owner with only the privileges needed; schema-qualify objects; set a fixed safe search path (prefer no implicit mutable schemas and keep `pg_temp` out); avoid dynamic SQL; revoke execute from `PUBLIC`/`anon`; grant only the intended `authenticated` or restricted job role. A function that must bypass RLS still has to enforce the caller identity and authorization itself.
- Explicit grants/revokes for every signature and `ALTER DEFAULT PRIVILEGES` for every role that creates functions. Do not assume the existing default-privilege migration covers other creators/roles or retroactively changes existing functions. Verify actual owner/ACL after deployment in a controlled environment.

### 6.3 Audit and accountability

Add an append-only `resource_article_audit_events` ledger (or equivalent) for create, revision, category changes, submit, reviewer assignment, approve, reject, schedule, publish, failed publish attempt, unpublish, archive/reopen, identity/capability administration, and featured-media replacement/removal. Store actor user/identity (or explicit system actor), event type, old/new status, revision IDs, reason, UTC time, idempotency/request ID, and carefully bounded metadata. Do not store access tokens, MFA secrets, or unnecessary personal information.

Only controlled functions may insert successful transition records; ordinary actors cannot update/delete them. For denied or failed attempts that must survive a rolled-back transaction, record a sanitized attempt in a separate committed operation. Audit reads are restricted to authorized editors/security reviewers. Keep the scheduler's job run ID and safe error code so repeated failures can be diagnosed without changing publication state.

### 6.4 MFA and admin authorization

The pinned application has optional AAL2 enforcement, not evidence of a universal guarantee. Require AAL2 for all high-impact editorial operations in both the Next.js guard and the database boundary. Confirm that the AAL2 check is based on current verified assurance, that relevant routes use it, and that `REQUIRE_ADMIN_MFA` is enabled if retained as an app-level control. Do not modify auth settings in this phase.

Resolve §3 first. Do not silently replace `is_admin`, infer its body from comments, or make a production authorization change based on this document. Any final authorization design must ensure ordinary students cannot set `profiles.is_admin`, call a helper to become an admin, or perform direct table/RPC writes that skip the workflow.

## 7. Media and storage contract

### 7.1 Existing source configuration

The pinned `0013_add_site_assets_bucket.sql` defines public bucket `site`, 5 MiB maximum file size, and MIME types `image/jpeg`, `image/png`, and `image/webp`. It defines public object reads and authenticated admin insert/update/delete policies calling `is_admin(auth.uid())`. Those policies are bucket-wide in the source excerpt; they do not constrain object keys to `resource-center/featured/`. The schema checks that the image path does not contain a `..` segment/backslash, but it does not enforce the required prefix or prohibit a URL. The deployed bucket, actual current policies, MIME limits, and current objects were not queried. No bucket or permission was created/changed in this phase.

### 7.2 Required Resource Center behavior

- Use the existing `site` bucket only; canonical featured object keys must be generated server-side under `resource-center/featured/<article-uuid>/<random-uuid>.<ext>`. Do not accept a raw object key from a browser without parsing and validating it. Reject absolute URLs, schemes, leading slashes, encoded traversal, `..`, backslashes, control characters, unexpected prefixes, and unrecognized extensions.
- Allow only JPEG, PNG, and WebP, at most 5 MiB (5,242,880 bytes). Verify file signatures/content on the server, not only the client `Content-Type` or file extension. SVG, HTML, and arbitrary executable formats are not allowed. Reject oversized uploads before storing.
- Authenticate the actor, verify active editorial media/edit capability and AAL2, rate-limit, and enforce the generated path in a server endpoint. Return the bucket-relative path and/or a generated public URL. Since the bucket is public, assume anyone can fetch published objects; do not upload private drafts or secrets to it.
- Use immutable, random object names for replacements; do not overwrite an existing key. Attach the new path to a draft snapshot and require review if it changes a published article. Keep the old asset while any retained revision or published snapshot references it. Delete only after an explicit audited cleanup confirms no retained revision/published pointer references it; failed DB updates may leave an unreferenced object for later cleanup.
- Generate display URLs with Supabase Storage's public-URL helper from a validated `site`-bucket-relative key. Do not accept arbitrary external featured-image URLs or server-fetch a user-controlled URL. `canonical_url` is a separate content field, not an image path; validate HTTPS and do not dereference it server-side.
- The existing broad bucket admin policies mean an API-only path rule would not constrain an authenticated administrator who writes directly through Storage. A future authorized storage-policy review must resolve this conflict (including broad legacy policies) before claiming database-enforced path restrictions. Do not change storage permissions in A0.4.

Storage is not transactionally atomic with Postgres. Upload/validate first, then bind the object path into an immutable revision transaction; if that transaction fails, retain the object temporarily and clean it up only after reference checks.

## 8. Backend API and data contracts

All routes below are proposals, not existing endpoints. Use App Router route handlers, the existing cookie/session Supabase server client, schema validation, request-size limits, stable JSON errors, and idempotency keys for mutations. Successful DB writes should call one transaction-owning RPC; no route should perform a sequence of independently committed table writes. The server guard provides an early rejection; the database repeats authorization and invariants.

| Operation / route | Input → output | Authentication and authorization | Database objects, transaction and expected failures |
|---|---|---|---|
| Create article `POST /api/admin/resource-center/articles` | `authorIdentityId`, initial slug/title/excerpt/content/type/canonical URL/image path/category IDs, `idempotencyKey` → article ID, status `draft`, lock version, revision number. | Authenticated active author/editor; actor derived from session; author identity must map to actor unless creating on behalf with explicit editor capability. AAL2 recommended for on-behalf creation. | Insert article, revision 1, category snapshot, audit in one transaction. Fail: 401/403, invalid fields, inactive identity/category, duplicate slug, idempotency conflict. |
| Update draft / create revision `PATCH /api/admin/resource-center/articles/{id}` | `expectedVersion`, material field patch, category IDs, `changeSummary`, `idempotencyKey` → new version and immutable revision ID/number. | Assigned author or editor with edit capability; only editable draft/work-in-progress revision. | Lock article; verify version/status/ownership; persist immutable snapshot; update working fields; audit atomically. Fail 404, 409 stale version/state, 422 validation, 403 actor mismatch. No direct “overwrite revision” API. |
| Assign categories | Prefer `categoryIds` in create/update draft; optional `PUT .../{id}/categories` with `expectedVersion` → new revision and selected IDs. | Same author/editor rule as draft edits; only active categories may be assigned. | Update draft association and snapshot atomically; assignment change invalidates approval. Fail missing/inactive category, duplicate/foreign article, stale version. |
| Submit for review `POST .../{id}/submit` | `expectedVersion`, exact current `revisionId`, distinct `reviewerIdentityId`, `idempotencyKey` → status `in_review`, submitted revision, assignment. | Author/editor submits; reviewer must be active and have reviewer capability and must not be the author. Submission assignment must not be self-selected in a way that defeats separation; enforce policy in DB. | Lock article, verify revision belongs to article and equals current revision, store submission/assignment, audit. Fail 409 stale/edit already submitted, 403 ineligible or self-review, 422 invalid reviewer. |
| Approve/reject `POST .../{id}/review` | `decision: approve \| reject`, `expectedVersion`, `revisionId`, required rejection reason for reject, optional future `scheduledFor` / `publishNow`, idempotency key → status/approval record. | Assigned reviewer only; active distinct reviewer; AAL2. Reviewer cannot approve any changed revision or own article. | Lock and verify submitted revision equals current; approval writes exact approved revision and reviewer/time; rejection returns to draft; immediate approval+publish may be one transaction. Fail 401/403/AAL2, 409 changed/stale/already decided, 422 missing reason/time. |
| Schedule publication `POST .../{id}/schedule` | `expectedVersion`, `approvedRevisionId`, future RFC3339 instant, idempotency key → status `scheduled`, normalized UTC schedule. | Reviewer/publisher with schedule capability and AAL2; only already-approved exact revision; no self-review. | Transaction verifies approved/current revision equality and future schedule; append audit. Fail stale approval, non-future time, wrong revision/state. A content edit cancels approval and schedule. |
| Publish now `POST .../{id}/publish` | `expectedVersion`, `approvedRevisionId`, idempotency key → status `published`, actual server `publishedAt`, published revision ID. | Reviewer/publisher with publish capability and AAL2; must not be author of approved revision. | Atomic state/pointer/audit update; view reads exact approved snapshot only after commit. Fail unauthorized, no approval, revision mismatch, stale state, duplicate idempotency. |
| Scheduled publication worker (internal) | No client article ID; bounded batch size/cursor and scheduler run ID → number published/failed and opaque safe attempt IDs. | Authenticated cron/worker secret; only due-row worker RPC; no human actor spoofing. Job function claims due rows and cannot accept arbitrary actor identity or unscheduled article IDs. | Lock due rows with `SKIP LOCKED`, revalidate exact approval/revision and due time, publish and audit per article. Failure leaves scheduled state unchanged and records safe attempt separately. Retry is idempotent. |
| Unpublish `POST .../{id}/unpublish` | `expectedVersion`, reason, idempotency key → draft/unpublished status and former revision reference. | Publisher/editor with unpublish capability and AAL2. | One locked transaction removes article from public view immediately, preserves history/published revision, invalidates approval for new content, writes audit. Fail stale state, missing reason, unauthorized. |
| Archive/reopen `POST .../{id}/archive` / `POST .../{id}/reopen` | `expectedVersion`, reason; reopen may include new draft fields → new status/version/revision. | Publisher/editor; AAL2 for archive. Reopen requires edit capability. | Archive cancels schedule/review and hides published content in same transaction; reopen never reuses old approval. Fail stale state, unauthorized, already archived, invalid revision. |
| Editorial history `GET .../{id}/history` | Article ID and bounded cursor/limit → ordered immutable revision metadata, decisions, transitions, reasons and actor identities. | Authenticated editor with read/history capability; author may see only permitted own content. | Read revisions and append-only audit with stable pagination. Fail 401/403/404; never expose unrelated admin or private profile data. |
| Manage editorial identities `POST/PATCH /api/admin/resource-center/identities` | Create/update display name, bio, avatar path, linked user, active flag, capabilities → sanitized identity. | Editorial manager/platform admin; AAL2 for link/capability/activation changes. Actor cannot grant themselves stronger roles. | Identity/membership changes and audit in one transaction; deactivation blocks future actions but preserves prior history/bylines as policy allows. Fail duplicate user, invalid path, conflicting active mapping, unauthorized. |
| Manage categories `POST/PATCH /api/admin/resource-center/categories` | Slug/name/description/order/active; `expectedVersion` → category. | Category/editorial manager; AAL2 for deactivation/slug changes. | Validate slug uniqueness and preserve referenced rows; append audit. Existing article category snapshots are not silently rewritten. Fail duplicate slug, invalid fields, deactivation conflict. |
| Upload/replace featured image `POST /api/admin/resource-center/media/featured` | Multipart file plus article ID, expected version and idempotency key → validated object path and public URL; attach in a separate revision update. | Authenticated editor/media manager; `assertAdmin` or editorial capability plus AAL2; server-generated path. | Verify bytes/size/type before upload; use server-only Storage client if needed; never expose service key. Record upload outcome; attaching reference is a DB transaction. Fail unsupported MIME, >5 MiB, bad signature, path issue, unauthorized, storage error; old referenced image remains. |

Use `401` for absent/invalid session, `403` for capability/AAL2 failures, `404` for missing or intentionally concealed unauthorized records, `409` for stale version/state/idempotency conflict, `422` for schema/business-rule validation, and safe `5xx` for transient storage/database failures. Do not return raw SQL errors, JWTs, MFA secrets, or service-role details.

## 9. Required additive migrations (future, separately authorized)

Do not run or apply any of the following in A0.4. After §3 is cleared and the implementation phase is separately authorized, prepare reviewed forward-only migrations that:

1. Add explicit editorial memberships/capabilities and narrowly scoped workflow metadata (including lock version and exact approved revision/actor/time); preserve existing objects/data.
2. Add composite article/revision integrity constraints and validated immutable-revision allocation/append-only enforcement. Backfill/validate existing rows before making new fields non-null.
3. Add append-only transition/audit and safe publication-attempt records with indexes and bounded metadata.
4. Add transition, revision, approval, publish, unpublish, archive, identity/category, and due-worker RPCs/triggers. Every RPC has specified owner, fixed search path, explicit `REVOKE`/`GRANT`, and verified creator-role default privileges. Keep human session functions callable only to intended API roles; keep job execution separate.
5. Narrow or remove direct authenticated DML grants and replace `FOR ALL` policies with exact read/write boundaries. The database cannot depend on the Next.js guard alone.
6. Replace the public projection view definitions additively so they render only the exact published revision snapshot and its approved category/image data while retaining current public column compatibility. Verify view ownership/`security_invoker` policy intentionally; do not assume the present owner behavior.
7. Resolve how scheduled jobs and media path restrictions interact with existing default privileges/storage policies. No new bucket is proposed. Existing policies may require a separately reviewed change because their broad `site`-bucket scope is not path-restricted.

No historical migration should be rewritten. Migrations should be staged so the new structures/functions can be verified before application code starts using them, and the old public reader contract remains valid during rollout.

## 10. Required server-side implementation

- Add App Router route handlers for the operations in §8. Share request schemas and capability helpers, but keep role checks both in the route and database.
- Use `createClient()` for authenticated requests and `getUser()` rather than trusting a decoded client object. Call a route-level AAL2 guard for sensitive actions and verify the AAL2 claim again inside database functions.
- Do not perform article editing or publishing through `createServiceClient()` table writes. Keep `SUPABASE_SERVICE_ROLE_KEY` server-only and use it only for isolated tasks that cannot safely use the user session (such as a validated storage upload or tightly scoped worker), never as a browser variable or response field.
- Route all content/state mutation through transaction-owning RPCs; include optimistic concurrency and idempotency. Return sanitized DTOs, not raw base rows containing internal actor IDs or drafts to public callers.
- Implement a small, idempotent scheduled worker that processes due articles, records safe failures, and observes the existing Vercel/cron conventions only after verifying their authentication and schedule configuration. A0.4 did not configure or deploy a scheduler.
- Ensure the public reader continues to use only four public projection views and that no article API accidentally exposes drafts, scheduled rows, admin fields, revision IDs, or internal actor IDs.
- Media API must enforce the contract in §7; path generation, file type/size validation, reference-aware cleanup, and error handling all occur server-side.

## 11. Testing strategy

All tests must use an isolated disposable/local or staging environment and synthetic Auth users/data. Do not use production data or credentials. Cover at least:

1. **Authorization/RLS:** anon, ordinary student, author, reviewer, publisher, editorial manager, platform admin, inactive member, and service role; try direct table DML and every RPC. Assert students cannot mutate `profiles.is_admin`, call unauthorized helpers, see drafts, or advance workflow. Verify actual function grants and RLS, not only migration text.
2. **MFA:** AAL1 denied for approval/schedule/publish/unpublish/archive/role changes; AAL2 succeeds only with appropriate membership and a valid distinct reviewer. Test route guard and DB RPC separately; test absent/failed MFA claims fail closed.
3. **State machine:** exercise every allowed transition and all forbidden skips, reviewer self-approval, stale assignment, wrong status, cancellation, archive/reopen, and required reason behavior.
4. **Revision integrity:** revision numbers deterministic under parallel updates; unique collisions impossible; every material field/category/image change creates a new snapshot; updates/deletes of prior revisions fail; approval invalidates on material change; published pointer and approved pointer must refer to the same article's revision.
5. **Public projection:** publish and verify only approved snapshot is visible; drafts, in-review, scheduled-before-due, archived, and unpublished content remain hidden. Attempt direct edits to prove public fields cannot change without a newly reviewed snapshot. Confirm view-owner/invoker semantics under anon/authenticated roles.
6. **Concurrency/idempotency:** simultaneous edits, double approval, double publish, retries after timeout, concurrent due-worker instances, and slug/category conflicts. Exactly one transition/event per idempotency key; no duplicate public effect.
7. **Atomicity/audit:** induce failures between revision/state/category/audit steps and assert rollback; failed scheduling/publication remains retryable and records a safe attempt; every successful transition has actor, revision and timestamp audit.
8. **Media:** reject >5 MiB, unsupported MIME/SVG, forged MIME/signature, path traversal/encoded traversal, wrong bucket/prefix, malicious URL, and unauthorized upload/delete. Verify immutable replacement, cache-safe key, public URL, orphan cleanup, and retention of assets referenced by old revisions.
9. **Migration/deployment:** apply additive migrations only in the isolated test target; run static lint/type checks/build for server routes; verify function owners/ACL/default privileges and public view shape; test rollback by reverting application code while retaining additive schema. No production migration in this phase.

## 12. Deployment and rollback considerations

A0.4 is specification-only. No migration, deployment, Vercel configuration, auth setting, storage policy, or production database was touched. The required document publication to `ImperioKDB/Updates` is not an application deployment.

In a future authorized implementation, use an expand/verify/activate sequence: deploy additive database objects and least-privilege functions; run isolated security/invariant tests; deploy server operations; verify public views and scheduler in staging; only then enable the editorial workflow. Preserve compatibility with existing public view columns during rollout. Feature-flag or disable editorial routes/scheduler if problems occur. Roll back application code first; retain additive schema, audit, and historical revisions. Do not drop tables, delete history/assets, or reverse data changes automatically. A production migration, auth change, or storage permission change requires its own explicit authorization and normal backup/recovery plan.

## 13. Dependencies and blockers

**Hard blocker:** authoritative definition and effective security contract for `public.is_admin(uuid)` are missing. Obtain exactly the material listed in §3.3 before relying on admin policies or altering authorization.

**Additional verification gates:**

- Confirm effective grants/RLS and actual view-owner/`security_invoker` behavior in a controlled environment; source declarations alone do not prove deployed behavior.
- Confirm `REQUIRE_ADMIN_MFA` and route coverage; the source implements optional AAL2 enforcement, not a universal control.
- Confirm existing bucket policies, public status, MIME/size limits and any changes since the pinned source. Do not query production as part of this phase.
- Decide/approve editorial membership capabilities and which roles can assign reviewers, publish, archive, manage identities/categories, and edit on behalf of authors.
- Verify function owner/default-privilege behavior for every role that will create RPCs, and whether all needed Postgres/Auth functions/extensions are available in the intended target.
- Choose and test a scheduler execution/authentication mechanism and its retry/monitoring behavior; no Resource Center publisher is present in the inspected source.

The `Updates` target repository already contains A0.3 findings. The report below reuses its schema/migration conclusions and does not repeat the 129-migration review.

## 14. Recommended implementation sequence

1. **Resolve authorization source-of-truth (gate):** obtain the authoritative helper body/owner/effective ACL and review arbitrary-UUID semantics. Confirm no student escalation path and settle how platform admin and editorial capabilities relate. Stop if evidence cannot be supplied.
2. **Controlled verification plan:** in a non-production isolated environment, verify function behavior, Resource Center RLS, public-view owner semantics, storage policy state, AAL2 claims, and role/default-privilege assumptions. Do not infer deployment state from migration text.
3. **Additive database foundation:** design and review role/membership, version/approval fields, composite references, immutable revision enforcement, audit/attempt tables, and explicit least-privilege grants. Preserve base objects and historical migrations.
4. **Database workflow operations:** implement and test state-transition/revision/audit RPCs and triggers with row locks, idempotency, AAL2, actor derivation, fixed search path, explicit owner and grants. Update public views to consume exact published snapshots.
5. **Server API layer:** implement route handlers and DTOs against the tested RPC contract; use session-bound clients for human actors and server-only service access only where strictly needed; add role/MFA checks, rate limits, and safe error handling.
6. **Media and scheduling:** implement validated immutable-key uploads and reference-aware cleanup; add a narrowly scoped due-publication worker with retries and operational monitoring. Verify schedule authentication and storage policies before enabling either.
7. **End-to-end acceptance in staging:** complete §11, especially direct RPC/table and public-view bypass tests, then conduct independent security review.
8. **Separate deployment authorization:** only after independent review and explicit implementation/deployment authorization, roll out progressively and monitor publication/audit/scheduler failures. This A0.4 request stops before implementation or deployment.

## 15. Implementation matrix

| Component | Existing state | Required work | Security importance | Priority |
|---|---|---|---|---|
| Resource Center base schema | Five tables and four public views exist in pinned migration; task says deployed. | Preserve; add only reviewed columns/constraints/functions as required. | High | P0 verify, then P1 |
| `public.is_admin(uuid)` | Referenced by policies; no authoritative body in source; conflicting revoke/grant sequence. | Obtain body, owner, effective ACL and semantics; verify no escalation. | Critical | P0 hard gate |
| Admin flag | `profiles.is_admin` writes revoked from ordinary API roles by column privilege in migration 0023. | Verify effective grants/RLS and avoid alternate mutation path. | Critical | P0 |
| Editorial roles/identity | Identity table maps optional user to public byline; no author/reviewer/publisher capability model. | Add explicit active capabilities and assignment checks; audit grants. | High | P1 |
| Workflow transitions | Status enum-like CHECK only; no transition enforcement. | Transactional RPCs/triggers implementing §4. | Critical | P1 |
| Revisions/publication snapshot | JSON state/unique article+number exists; no allocator/immutability/approval binding; published view reads mutable row. | Immutable snapshots, lock-based allocation, approval references, composite FK, snapshot-backed views. | Critical | P1 |
| RLS/direct writes | Authenticated DML grants and admin `FOR ALL` policies; helper unresolved. | Remove broad writes, narrow policies and use database-enforced RPCs. | Critical | P1 after P0 |
| MFA | Optional server guard and TOTP routes; global guarantee not verified. | Require AAL2 in routes and DB for sensitive operations; test claims/config. | High | P1 |
| Audit | No Resource Center transition ledger in inspected schema. | Append-only event history and publication-attempt records. | High | P1 |
| Scheduler | No Resource Center publisher in inspected migration/source. | Idempotent due-only worker with safe retries and monitoring. | High | P2 |
| Storage/media | Public `site` bucket, 5 MiB, JPEG/PNG/WebP in source; broad bucket-level admin policies; deployed state unverified. | Validate uploads, immutable scoped keys, safe URLs, reference-aware cleanup; review broad policy scope. | High | P1/P2 |
| Next.js API | Generic server guard/session client/service-only helper exist; no Resource Center route. | Add validated App Router endpoints backed by session-aware RPCs. | High | P2 |
| Public projection/views | Four public views filter to published and due content but use mutable article/join rows; runtime owner behavior unknown. | Preserve column contract; render exact approved snapshot; verify anon/authenticated behavior. | Critical | P1 |
| Deployment/rollback | No A0.4 deployment authorized or performed. | Staging tests and separate reviewed deployment; retain additive schema on app rollback. | High | P3 after acceptance |

## 16. Final verdict

# BLOCKED

The existing Resource Center foundation is present and does not need recreation, and a secure implementation sequence can be specified. However, the authoritative `public.is_admin(uuid)` implementation, owner, effective privileges, and behavior cannot be established from the repository/source history inspected. Because the Resource Center's current authenticated RLS policies depend on that function—and the migrations show a broad `PUBLIC` execute grant after earlier revokes—its compatibility and resistance to student bypass cannot be responsibly certified. Obtain the exact source/owner information in §3.3 and clear the verification gates in §13 before implementation. No implementation or deployment authorization is implied by this specification.

## References

1. [Resource Center schema migration at pinned source commit](https://github.com/ImperioKDB/Scholars/blob/41573f5ec2985851ba118e8b39a47f9c54532302/supabase/migrations/20261107130100_resource_center_schema.sql)
2. [Function hardening migration](https://github.com/ImperioKDB/Scholars/blob/41573f5ec2985851ba118e8b39a47f9c54532302/supabase/migrations/0002_harden_functions.sql)
3. [Admin flag and `is_admin` grant migration](https://github.com/ImperioKDB/Scholars/blob/41573f5ec2985851ba118e8b39a47f9c54532302/supabase/migrations/0023_lock_admin_flag.sql)
4. [Existing site storage bucket migration](https://github.com/ImperioKDB/Scholars/blob/41573f5ec2985851ba118e8b39a47f9c54532302/supabase/migrations/0013_add_site_assets_bucket.sql)
5. [`assertAdmin` guard](https://github.com/ImperioKDB/Scholars/blob/41573f5ec2985851ba118e8b39a47f9c54532302/lib/admin/guard.ts) and [`requireAdmin` access helper](https://github.com/ImperioKDB/Scholars/blob/41573f5ec2985851ba118e8b39a47f9c54532302/lib/admin/access.ts)
6. [Session-bound server client](https://github.com/ImperioKDB/Scholars/blob/41573f5ec2985851ba118e8b39a47f9c54532302/lib/supabase/server.ts) and [server-only service client](https://github.com/ImperioKDB/Scholars/blob/41573f5ec2985851ba118e8b39a47f9c54532302/lib/supabase/service.ts)
7. [A0.3 migration and schema reconstruction assessment](https://github.com/ImperioKDB/Updates/blob/85a554f60a88515942fd5ab8678272a8e93d0bc2/SCHOLARS_RESOURCE_CENTER_PHASE_A0_3_MIGRATION_AND_SCHEMA_RECONSTRUCTION_ASSESSMENT_2026-11-07.md)
