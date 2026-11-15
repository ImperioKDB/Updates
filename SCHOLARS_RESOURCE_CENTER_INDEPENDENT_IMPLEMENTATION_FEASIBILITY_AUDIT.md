# Scholars Resource Centre
## Independent Implementation Feasibility Audit
### Pre-Reconstruction Architecture Decision Gate

**Audit date:** 2026-11-15  
**Organisation:** ImperioKDB  
**Primary repository:** `ImperioKDB/Scholars`  
**Documentation repository:** `ImperioKDB/Updates`  
**Inspected Scholars commit:** `142146a67cb21eeec8d74832bc326c1fcd5dd5f4`  
**Inspected Updates commit before this audit:** `80110361fdc1edbe894cbc7e79fbdd372fdbaa24`  
**Target staging project:** `scholars-staging` / `aqhktriwaglvvrchxmtd`

> **Status: Read-only audit.** No Scholars source files, database objects, rows, migrations, secrets, environment variables, staging configuration, production configuration, deployment, or staging reconstruction was changed. The only intended modifications are these audit documents in Updates.

## 1. Executive decision summary

The Resource Centre can be developed and integrated without reconstructing the entire Scholars database. The current implementation already demonstrates the most important independence property: its public routes are repository-backed and can render the six launch articles and six categories without requiring student profiles, scholarship applications, XP, community records, or a populated Supabase application schema. The optional Supabase public projection is additive and is deliberately merged only when available (`lib/resource-center.ts:157-219`).

The safest target is therefore a **logical module inside the existing Scholars repository and domain**, not a separate application and not a full Scholars staging replay. The module should retain its location at `/resources`, use the existing Next.js/Vercel deployment, keep public reading unauthenticated, and treat Supabase as an isolated content backend for editorial growth rather than as a prerequisite for the public MVP.

The existing `scholarship-platform` production architecture has already served this public module successfully according to the prior production verification report: production deployment of PR #29 was READY, the public routes returned HTTP 200, the sitemap contained the resource URLs, and advertising was disabled. That prior report is historical evidence reviewed here, not a new live deployment claim.

The database-backed editorial schema is feasible as a dedicated set of tables and projection views, but it is **not yet implementation-ready for staging validation**. Task 12 verified that `scholars-staging` is isolated and empty, while the 136-file migration history is not a proven clean-install baseline. Reconstructing unrelated Scholars infrastructure would be disproportionate to the Resource Centre’s needs. Instead, the next gated step should be a separately approved, standalone Resource Centre staging bundle containing only the required tables/views/policies plus explicitly supplied authorization dependencies, followed by synthetic-identity RLS tests.

The main security condition is the existing `public.is_admin(uuid)` dependency in `20261107130100_resource_center_schema.sql:129-150`. The migration reuses the existing admin model; it does not establish a new authorization system. This is acceptable as a controlled first-release integration only if the live function definition, grants, profile policy, MFA behavior, and admin route behavior are verified in staging before any editorial write path is enabled. No replacement admin function should be introduced by assumption.

## 2. Scope, method, and evidence discipline

### 2.1 Requested questions

This audit answers whether the Resource Centre can be independently developed, tested, and integrated without reproducing the whole Scholars database; whether it needs a dedicated content schema or separate Supabase project; whether public access can remain unauthenticated; how existing admin authorization can be reused safely; what staging strategy is practical; and what additive production changes would eventually be required.

### 2.2 Inspected evidence

The audit inspected the current Scholars source at commit `142146a67cb21eeec8d74832bc326c1fcd5dd5f4`, the Updates documentation at commit `80110361fdc1edbe894cbc7e79fbdd372fdbaa24`, prior Resource Centre architecture/security/production reports, the Task 12 staging audit/parity/readiness reports and migration manifest, current Resource Centre routes/components/helpers/tests, the Resource Centre SQL migrations, and read-only repository/project metadata already collected in the preceding tasks.

Important current source evidence includes:

- Public routes: `app/resources/page.tsx`, `app/resources/[slug]/page.tsx`, `app/resources/category/[slug]/page.tsx`.
- Public data boundary and fallback: `lib/resource-center.ts:1-219` and `lib/resource-content.ts:1-316`.
- Public UI and ad boundary: `components/resource-center.tsx:1-101` and `components/resource-center-search.tsx`.
- Sitemap: `app/sitemap.ts:1-94` and `lib/sitemap-data.ts:58-115`.
- Admin read workspace: `app/admin/resources/page.tsx:1-20`.
- Schema and projection views: `supabase/migrations/20261107130100_resource_center_schema.sql:1-215`.
- Security-boundary remediation proposal: `supabase/migrations/20261107130000_security_boundary_remediation.sql:1-43`.
- Existing admin guards: `lib/admin/access.ts`, `lib/admin/guard.ts`, and the middleware admin boundary.
- Prior live production verification: `RESOURCE_CENTER_PRODUCTION_VERIFICATION_2026-11-12.md`.
- Prior staging gate: `reports/scholars/2026-11-15-resource-center-phase-2b-task-12-staging-readiness-assessment.md`.

The brief names `SCHOLARS_RESOURCE_CENTER_PHASE_1_IMPLEMENTATION_READINESS_2026-11-07.md`; that exact file was not found in the Updates checkout. The available `SCHOLARS_RESOURCE_CENTER_PHASE_1_ARCHITECTURE_AUDIT.md` and later production verification were used instead. No claim from the missing file is inferred.

### 2.3 Evidence labels

- **VERIFIED — SOURCE:** directly present in the inspected repository.
- **VERIFIED — PRIOR PRODUCTION RECORD:** documented in the reviewed production verification report; not re-run during this read-only audit.
- **VERIFIED — STAGING METADATA:** established by Task 12’s read-only project inspection.
- **CONDITION:** technically feasible but gated on an explicit verification or approval.
- **UNVERIFIED:** not established without executing a prohibited or unavailable test.
- **NOT AUTHORIZED:** deliberately not performed under this audit’s boundaries.

## 3. Current implementation findings

### 3.1 Public functionality is already database-independent at launch

**VERIFIED — SOURCE.** `lib/resource-content.ts` defines six local articles, six local categories, stable slugs, publication dates, review dates, author attribution, Markdown content and internal links. `getResourceArticleWithRepositoryContent()` returns a local article before attempting Supabase (`lib/resource-center.ts:179-189`). The index merges local content with optional published projection rows (`:163-176`). Category pages similarly preserve local content when the optional projection is unavailable (`:191-208`).

This means the intended public MVP—browse, search, read, navigate categories, view metadata and follow links—does not depend on a populated `profiles`, `scholarships`, `applications`, `xp`, `community`, notification, or matching table. The public pages do use the existing server Supabase client when a public configuration exists, but only to read explicit `resource_public_*` projections; they do not query private/base application tables from the browser.

### 3.2 Route and rendering boundary

**VERIFIED — SOURCE.** The routes are outside protected route groups and use server components. The article page renders Markdown through `ResourceArticleBody`, emits canonical metadata, Article/BreadcrumbList JSON-LD, and links to public catalogue routes. The category page emits CollectionPage/BreadcrumbList data. The sitemap includes `/resources`, resource categories, and resource articles through `readAllResourceRows()` and `readAllResourceCategoryRows()`.

The implementation does not require a new domain, a new Vercel project, a separate frontend runtime, or a new npm dependency for the public module. Existing Next.js App Router, Tailwind, metadata, sitemap, JSON-LD, link, and server-client patterns are sufficient.

### 3.3 Current admin capability is read-only, not a CMS

**VERIFIED — SOURCE.** `app/admin/resources/page.tsx` calls `requireAdmin()` and reads `resource_articles` with the normal server client. It displays article state and explicitly says “Publishing workflow next.” There are no Resource Centre API or server-action files under `app/api`; the only Resource Centre admin file found is the listing page. Therefore administrators can currently inspect rows if the schema exists, but cannot create, edit, publish, unpublish, schedule, or revise articles through the application.

This is a safe current state. It must not be described as an implemented editorial workflow. The next implementation must add narrowly scoped mutation routes or server actions, validation, revision creation, publish/unpublish rules, audit fields, self-approval prevention, and MFA/step-up behavior where required.

### 3.4 Public access does not require student authentication

**VERIFIED — SOURCE / VERIFIED — PRIOR PRODUCTION RECORD.** Public routes do not call `requireAdmin`, `assertAdmin`, or a student profile authorization flow. The existing production verification recorded HTTP 200 for the index, seven articles, six categories and the sitemap with no login redirect. That evidence is consistent with the current source. Search is a client-side enhancement over server-provided article data; reading remains public.

The public data contract is intentionally narrow: projection views expose approved fields, exclude draft status and private identity links, and filter to active/published/future-safe rows (`20261107130100_resource_center_schema.sql:152-214`).

### 3.5 Ads and storage are optional

**VERIFIED — SOURCE / VERIFIED — PRIOR PRODUCTION RECORD.** `ResourceAdSlot` renders no ad network script or credential when `NEXT_PUBLIC_RESOURCE_ADS_ENABLED` is not exactly `true` or either public identifier is absent (`components/resource-center.tsx:29-35`; `.env.example:5-9`). The current launch content has no featured image paths (`lib/resource-content.ts:280-287`), so it does not require Storage. If images are later used, `getResourceImageUrl()` restricts paths to `resource-center/featured/` and uses the existing public `site` bucket (`lib/resource-center.ts:130-139`). Storage therefore remains an optional integration, not a launch dependency.

## 4. Dependency classification

| Dependency | Classification | Evidence and decision |
|---|---|---|
| Next.js App Router and React server components | A — essential | Public routes are implemented under `app/resources`; retaining the existing app is the least complex deployment. |
| Existing Tailwind/design components and `Link` | A — essential for current UI, not an architectural lock-in | `components/resource-center.tsx` and page files use existing primitives. No new package is required. |
| Repository-backed `lib/resource-content.ts` | A — essential for resilient public MVP | It supplies all launch content and allows public operation without a populated database. |
| Normal server Supabase client | B — optional integration for database-backed published content | `lib/resource-center.ts` reads only `resource_public_*` projections when public config is available. |
| Dedicated Resource Centre tables/views | B for MVP; A for a maintained editorial CMS | Required for database-backed drafts, revisions, categories, identities and future admin publishing; not required for current static launch. |
| `profiles`, `scholarships`, applications, matching, XP, community, notifications | C — unnecessary coupling | No public Resource Centre path needs them. Do not reuse them as an article system. |
| Existing Supabase Auth for admins | D — security-sensitive | Required only for future administration, not public reading. Reuse must be gated by a verified admin model. |
| `public.is_admin(uuid)` | D — security-sensitive and conditional | Current schema policies depend on it. Its live definition/grants and staging behavior must be verified; do not assume it is safe solely because it exists in migrations. |
| `requireAdmin()` / `assertAdmin()` / middleware `/api/admin` checks | D — security-sensitive | Existing layered controls are suitable for the admin surface, but write routes must call them server-side and must not rely on UI hiding. |
| Service-role client | D — security-sensitive | Must remain server-only; never use it in public page/browser code. A public read path should use projections and the normal server client or local content. |
| `resource_public_*` projection views | A for database-backed public reads; B for static launch | They provide the intended published-only and column allowlist boundary. Their live grants and ownership/security posture require staging/production verification before new data is inserted. |
| Existing Storage `site` bucket | B — optional | Only needed if approved featured images are introduced. No launch article requires it. |
| AdSense identifiers/consent stack | B — later optional integration | Ads are disabled by default. Enabling them requires separate privacy, consent, policy and performance approval. |
| Vercel/GitHub deployment path | A for same-domain integration | Current production deployment already serves the module; separate hosting adds complexity without a demonstrated need. |
| Full Scholars schema reconstruction | C — unnecessary coupling for public Resource Centre | Task 12 found staging empty and the 136-file history not clean-install authoritative. A bounded module baseline is safer. |
| Current live Supabase schema state | E — unknown for the next write phase | Repository migrations are not proof of live application state. Read-only metadata and a controlled staging bundle must establish parity for Resource Centre objects before editorial writes. |

## 5. Central independence answer

**Can the Resource Centre deliver intended public functionality without existing student profiles, scholarship applications, XP, community records or unrelated subsystems?**

**VERIFIED WITH CONDITIONS — Yes.** The current repository-backed public implementation already does so. The conditions are that future work must preserve the local-content fallback, keep public routes outside protected groups, keep database reads projection-only, avoid service-role exposure, and avoid changing unrelated application routes or tables. Optional links to public scholarship/opportunity pages are integration links, not data dependencies or eligibility inputs.

## 6. Database architecture alternatives

### Option 1 — Dedicated Resource Centre tables in the existing Supabase project

**Recommendation: preferred for the maintained editorial phase, subject to staging gates.**

The existing schema migration is additive and names its own tables: `resource_editorial_identities`, `resource_categories`, `resource_articles`, `resource_article_categories`, and `resource_revisions`. It does not alter unrelated Scholars tables. Base tables are RLS-enabled; browser roles have no base-table privileges; public roles receive select only on explicit security-barrier projection views. The schema supports status, publication time, reviewer identity, revision state, and controlled public columns.

Advantages are same-domain deployment, one operational stack, reuse of existing authenticated admin identity/MFA, future editorial administration, and selective cross-linking. Risks are migration dependency on the existing `auth.users` and `public.is_admin` security model, live schema/grant drift, and the need to validate view ownership and grants. Operational complexity is materially lower than a second project, but it is not zero.

**Status: VERIFIED WITH CONDITIONS.** The source design is feasible and additive; live/staging application of the schema was not performed in this audit.

### Option 2 — Separate Supabase project

A separate project would provide physical database isolation and eliminate direct dependence on Scholars’ `profiles` and `is_admin` tables. It would also require separate Auth or an integration bridge, credentials, deployment variables, admin identity, Storage, backups, monitoring, RLS review and cross-domain/cross-project integration. It would complicate same-domain operation unless the module became a separately deployed frontend or API, and would create a second content-operating environment.

This is justified only if the owner requires independent organisational ownership, a separate security boundary, independent scaling/compliance, or a future product that is no longer a Scholars module. No evidence in the current codebase demonstrates that requirement.

**Status: VERIFIED WITH CONDITIONS — technically possible, not the least complicated choice.**

### Option 3 — Database-independent repository/file content

The current implementation proves that repository-backed content can satisfy the public launch. It offers the smallest attack surface, no migration, no RLS dependency, no staging database dependency, and simple review through Git/CI. It is less suitable for non-technical editors, scheduled publishing, large content volume, revision UI, or frequent unbundled updates. A future editorial workflow would either remain Git-based or add a backend.

**Status: VERIFIED — suitable for the public MVP; CONDITION — not sufficient by itself for a full non-technical CMS.**

### Logical versus physical isolation

The recommended design provides **logical isolation**: separate tables, views, routes, types, components, tests, and permissions inside the existing Scholars application and Supabase project. It does not provide physical isolation from the existing database cluster or project. That is an acceptable trade-off because the public MVP is repository-backed and the database objects can be strictly additive. A separate Supabase project would provide physical isolation but at substantially higher operational cost and with no demonstrated requirement.

## 7. Public and administrative access model

### Public access

Public users should be able to browse `/resources`, categories, published articles, search, and sitemap entries without registration. The current route and production evidence support this. Public data should come from local approved content or the `resource_public_*` views only. The views should remain explicit-column, published-only, active-identity projections. Public clients must never query base editorial tables or use `SUPABASE_SERVICE_ROLE_KEY`.

### Administrative access today

Today, administrators can access the read-only `/admin/resources` listing when `requireAdmin()` succeeds. They cannot author or publish through the product. This is not a defect in the public MVP; it is an unfinished editorial phase.

### Recommended future administrative access

Reuse the existing Scholars admin boundary rather than inventing a parallel identity system:

1. Server Component pages call `requireAdmin()`.
2. `/api/admin/resources/*` or server actions call `assertAdmin()` independently.
3. Middleware continues to protect `/api/admin/*` and existing session behavior remains unchanged.
4. Publishing/scheduling may require AAL2 explicitly, using the existing MFA model and `REQUIRE_ADMIN_MFA` policy.
5. The route validates input, writes only Resource Centre tables, creates an immutable revision, records `created_by`/`updated_by`, and prevents author self-approval unless an explicit owner-approved exception exists.
6. No browser receives service-role credentials or a privileged RPC capability.

The schema currently uses `public.is_admin(auth.uid())` in RLS policies. This is a security-sensitive dependency. Before using the schema in staging, verify the exact function body/ownership/search path, effective grants, interaction with RLS, profile policy, and whether direct browser RPC execution is intended. The previously documented live project had broader-than-expected SECURITY DEFINER execution grants in unrelated and operational functions; this strengthens the case for explicit grant verification. Do not replace `is_admin` merely to avoid inspection, and do not treat the migration text as proof of live safety.

## 8. Staging strategy without full reconstruction

Task 12’s conclusion remains valid for full Scholars parity: `scholars-staging` is isolated and empty, but the 136 source migrations are not a proven clean-install baseline. The migration manifest includes duplicate numeric prefixes, a superseded initial migration, seed-heavy files and prerequisite-dependent objects. A filename-ordered replay would not be a trustworthy baseline and must not be attempted.

For the Resource Centre, full parity is not necessary. The smallest safe strategy is:

1. **Approve a bounded Resource Centre bundle.** Produce a uniquely identified, standalone migration or schema bundle containing only the five Resource Centre base tables, constraints, indexes, RLS, grants, projection views and the minimum explicitly documented authorization dependency. Do not include scholarship seeds, profiles, XP, community, notification, workflow, or unrelated functions.
2. **Choose the admin dependency explicitly.** Either provision a minimal staging `profiles`/admin authorization fixture under separate approval, or validate the existing Scholars admin dependency only after an owner-approved representative auth/profile baseline exists. Do not copy production users or secrets.
3. **Apply only the approved bundle to the isolated staging project.** This is a future authorized action, not performed here. Never reset, drop, truncate or overwrite the empty project as a shortcut.
4. **Create synthetic identities only after schema verification.** Use separate anonymous, authenticated non-admin, authenticated admin, MFA/recovery and service-role test identities, all synthetic and staging-only.
5. **Run RLS and route tests.** Verify public read of published rows; exclusion of drafts, future-scheduled rows, inactive categories and inactive authors; denial of base-table reads; denial of non-admin writes; admin listing behavior; revision attribution; publish/unpublish behavior; self-approval prevention; sitemap exclusion; and absence of service credentials in client bundles.
6. **Run CI and Preview against staging-only variables.** Vercel Preview must use staging URL/anon key and a server-only staging service credential. Task 12 found Preview-to-staging binding unverified and shared metadata concerns; this must be resolved before database-backed testing.
7. **Compare the bounded staging object inventory to the approved manifest and then compare production metadata read-only.** No production SQL or deployment is part of this audit.

**Staging decision: VERIFIED WITH CONDITIONS.** The existing isolated project can be used for Resource Centre development, but only through a bounded module baseline. It is not ready for migration or admin testing today because the schema and representative auth baseline are absent.

## 9. Production integration surface

The eventual production change set can be additive and isolated:

| Change class | Minimum eventual change | Assessment |
|---|---|---|
| Frontend | Maintain `app/resources/*`, resource components, content types and tests; add editorial UI only under `/admin/resources` | Additive; keep public routes outside protected groups. |
| Database objects | Resource editorial identities, categories, articles, article-category join and revisions | Additive; no changes to scholarship/profile/application tables. |
| Views | Published-only `resource_public_*` projections | Additive; explicit columns and grants. |
| RLS/policies | Base tables admin/editor policies; public view grants | Security-sensitive; verify helper and grants before apply. |
| Functions | Prefer no new public RPC for public reads; use guarded server routes for writes | New functions require separate review; do not expose service operations. |
| Environment | Existing public Supabase URL/anon key and app URL; no new secret for repository MVP | Do not change production variables in this task. Ads remain disabled. |
| Routing/deployment | Existing GitHub-to-Vercel build; sitemap/resource routes | Additive; run CI and Preview checks. |
| Existing Scholars functionality | Reuse admin session/MFA only; intentional public links to catalogue | No matching, application, onboarding, XP or community changes. |
| Storage | Optional approved `site` bucket paths for future images | Not required for launch. |
| Monetization | Optional later route-scoped ad configuration and consent work | Not part of the implementation gate. |

### Production risks and mitigations

- **Migration drift:** compare live migration/object metadata and use a uniquely versioned additive migration; do not infer live state from filenames.
- **RLS/view leakage:** test anon/authenticated queries against drafts, future rows, inactive identities and base tables; select explicit columns only.
- **Admin privilege drift:** verify `is_admin`, grants, policies, AAL2 and route guards; require server-side authorization on every mutation.
- **Self-approval or unverifiable content:** require separate reviewer identity and immutable revision; record actor and review timestamps.
- **Search/indexing of drafts:** no public draft route; sitemap only from published projection; preview must be protected and `noindex`.
- **Public-site outage on database failure:** retain repository fallback and make failure states explicit; do not silently expose drafts or stale privileged data.
- **Unrelated regression:** do not modify middleware, profile/auth callbacks, matching, application flows, scholarship/discovery tables or generic worker functions.
- **Ad/privacy risk:** keep ads disabled until consent, policy, minor-safety, labeling, performance and ownership work is approved.

### Backup, rollback, and recovery strategy

Before any future production migration, capture an owner-approved schema/object inventory and a logical backup or provider snapshot covering the new Resource Centre objects. Record the migration checksum and expected object list. Deploy application code that can tolerate the pre-migration state, then apply the additive schema in a controlled window. Verify object presence, grants, views, RLS and route behavior. If verification fails, stop publication and revert the application feature flag/route dependency to repository-backed content; do not drop unrelated objects. Roll back only the newly added Resource Centre objects through a reviewed reverse migration if necessary, after preserving any content/revision data for recovery. Never use a destructive reset as rollback.

## 10. Required architecture decision statuses

| Question | Decision | Status |
|---|---|---|
| Can full Scholars staging reconstruction stop for this work? | Yes. It is not required for the public module or bounded Resource Centre testing. | **VERIFIED WITH CONDITIONS** |
| Can the Resource Centre be independently implemented? | Yes, as a logical module with repository-backed public content and an optional dedicated backend. | **VERIFIED** |
| Can `scholars-staging` be used? | Yes, after an approved bounded bundle and synthetic test baseline; not ready today. | **VERIFIED WITH CONDITIONS** |
| Does it need dedicated tables? | Not for the current static public MVP; yes for the maintained database-backed editorial CMS. | **VERIFIED WITH CONDITIONS** |
| Does it need a separate Supabase project? | No demonstrated need; same-project logical isolation is preferred. | **VERIFIED WITH CONDITIONS** |
| Can public access work without student authentication? | Yes. | **VERIFIED** |
| Safest admin authorization? | Existing server-side admin guard/MFA boundary, narrowed to Resource Centre writes, with explicit verification of `is_admin` and grants. | **VERIFIED WITH CONDITIONS** |
| Can production changes be additive and isolated? | Yes, if the proposed table/view/policy boundary is preserved. | **VERIFIED WITH CONDITIONS** |
| What must remain untouched? | Student auth/onboarding, profiles except approved identity linkage, matching, applications, XP, community, scholarship/discovery domain, generic worker functions, production env and unrelated RLS. | **VERIFIED** |
| Recommended sequence? | Keep public repository MVP; create bounded staging bundle; validate RLS/admin/Preview; implement editorial writes; migrate approved content; only later consider ads. | **VERIFIED WITH CONDITIONS** |

## 11. Final recommendation

Stop pursuing full Scholars staging reconstruction for the Resource Centre. Continue with the existing Scholars repository and same-domain route. Treat repository-backed content as the independent public baseline. Develop the database-backed editorial capability as a separate logical module using dedicated tables, projection views and narrowly scoped admin operations. Use `scholars-staging` only for that bounded module after an explicit schema/auth baseline is approved and created; do not replay the 136-migration Scholars history.

The next engineering task should not be another broad architecture investigation. It should be a gated Resource Centre staging bundle and verification plan, with no production SQL, no production deployment, no unrelated table changes, and no use of real user data. The current public experience is feasible and operationally simple; the unfinished work is the secure editorial write path.

**This report is an architecture decision gate, not authorization to implement, migrate, or deploy.**
