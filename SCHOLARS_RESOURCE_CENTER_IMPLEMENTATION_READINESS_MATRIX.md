# Scholars Resource Centre
## Implementation Readiness Matrix

**Assessment date:** 2026-11-15  
**Scholars source assessed:** `142146a67cb21eeec8d74832bc326c1fcd5dd5f4`  
**Updates history assessed:** `80110361fdc1edbe894cbc7e79fbdd372fdbaa24`  
**Staging target:** `scholars-staging` / `aqhktriwaglvvrchxmtd`

> Statuses use the required decision vocabulary: **VERIFIED**, **VERIFIED WITH CONDITIONS**, **UNVERIFIED**, and **NOT FEASIBLE**. This matrix is a planning gate, not authorization to implement or migrate.

## 1. Decision snapshot

| Decision | Status | Evidence | Next action / owner |
|---|---|---|---|
| Stop full Scholars staging reconstruction for Resource Centre work | **VERIFIED WITH CONDITIONS** | Task 12 found the 136-file history is not a proven clean-install baseline; current public content is repository-backed. | Product/engineering owner approves bounded Resource Centre-only staging strategy. |
| Independently implement public Resource Centre | **VERIFIED** | Current routes, local content and production verification support public operation without unrelated student data. | Engineering preserves route/data boundaries. |
| Use existing isolated staging project | **VERIFIED WITH CONDITIONS** | Project identity/isolation passed; schema, auth baseline and Preview binding are absent/unverified. | Platform owner creates approved bounded module baseline and staging-only Preview configuration. |
| Dedicated tables for editorial CMS | **VERIFIED WITH CONDITIONS** | Additive migration defines five Resource Centre table families and projection views. | Database owner reviews standalone migration, live drift and authorization dependency. |
| Separate Supabase project required | **VERIFIED WITH CONDITIONS** | No demonstrated physical-isolation requirement; same-project logical isolation is adequate. | Revisit only if independent ownership/compliance/scaling requirement appears. |
| Public access without student authentication | **VERIFIED** | Public route source and prior production HTTP verification; no protected-route dependency. | Add regression tests for anonymous route access. |
| Existing admin authorization reusable | **VERIFIED WITH CONDITIONS** | `requireAdmin`, `assertAdmin`, middleware and MFA infrastructure exist; schema calls `public.is_admin`. | Verify function definition/grants/RLS and add server-only write routes. |
| Additive production integration | **VERIFIED WITH CONDITIONS** | Resource schema/views are separate; current public code avoids unrelated tables. | Perform staged migration review, backup and rollback planning. |
| Ads at launch | **VERIFIED** — disabled | Env defaults false/blank; component has no network script when disabled. | Keep disabled until separate privacy/consent/policy approval. |

## 2. Readiness matrix

| ID | Prerequisite / gate | Current status | Evidence | Unresolved question or risk | Responsible next step |
|---|---|---|---|---|---|
| R01 | Current source and Updates SHAs recorded | **VERIFIED** | Scholars `142146a67cb21eeec8d74832bc326c1fcd5dd5f4`; Updates `80110361fdc1edbe894cbc7e79fbdd372fdbaa24`. | Branch freshness after this audit must be recorded at publication. | Audit author records publication commit. |
| R02 | Prior architecture decisions reviewed | **VERIFIED** | Phase 0, Phase 0.1, Phase 1 architecture audit, production verification and Task 12 reports reviewed. | The exact file named `SCHOLARS_RESOURCE_CENTER_PHASE_1_IMPLEMENTATION_READINESS_2026-11-07.md` is absent. | Keep the absence documented; do not infer its content. |
| R03 | Public route tree exists | **VERIFIED** | `app/resources/page.tsx`, `[slug]`, `category/[slug]`. | Mobile/browser runtime checks are historical limitations of the prior report. | Run CI and approved Preview browser checks later. |
| R04 | Public content source independent of Scholars records | **VERIFIED** | `lib/resource-content.ts` contains six articles/six categories; `lib/resource-center.ts:179-208` prioritizes local content. | Editorial updates require code review until CMS writes exist. | Retain repository fallback while adding CMS. |
| R05 | Anonymous reading/search | **VERIFIED** | No public auth guard in resource routes; prior production report recorded HTTP 200. | Need regression test against accidental middleware changes. | Add/retain anonymous route tests. |
| R06 | Public projection query boundary | **VERIFIED WITH CONDITIONS** | `lib/resource-center.ts:56-128` queries `resource_public_*`; migration grants views to anon/authenticated. | Live view ownership, grants and existence are not reverified in this audit. | Validate in bounded staging, then compare production metadata read-only. |
| R07 | Draft/future/inactive exclusion | **VERIFIED WITH CONDITIONS** | View predicates at migration lines 169-203; local source has only approved published content. | Must test real RLS/view behavior, not only inspect SQL text. | Seed synthetic draft/future/inactive rows and test anon responses. |
| R08 | Dedicated table design | **VERIFIED WITH CONDITIONS** | Migration defines identities, categories, articles, join and revisions. | Standalone clean-install bundle has not been produced/applied. | Prepare owner-approved unique migration/bundle. |
| R09 | RLS and base-table denial | **VERIFIED WITH CONDITIONS** | Tables enable RLS and revoke anon/authenticated base access at migration lines 103-127. | No live staging objects exist; view security behavior needs runtime test. | Test direct anon/authenticated base-table reads/writes. |
| R10 | Admin identity dependency | **VERIFIED WITH CONDITIONS** | Policies call `public.is_admin(auth.uid())`; app has `requireAdmin`/`assertAdmin`. | Exact helper definition, grants, profile policy, MFA and search path must be verified. | Database/security owner performs bounded staging review. |
| R11 | Admin read workspace | **VERIFIED** | `app/admin/resources/page.tsx` uses `requireAdmin()` and reads `resource_articles`; UI says publishing workflow is next. | It fails gracefully if schema absent but cannot author content. | Keep read-only until mutation workflow is separately designed. |
| R12 | Admin create/edit/publish/unpublish | **UNVERIFIED** | No `app/api/*resource*` mutation route found; no server action found. | Validation, revisioning, self-approval, schedule and rollback behavior are not implemented. | Implement only after R09/R10 pass and owner approves workflow. |
| R13 | Revision and audit integrity | **VERIFIED WITH CONDITIONS** | `resource_revisions` model and actor fields exist in schema. | No write path currently creates revisions or enforces immutable workflow. | Add guarded revision service and regression tests. |
| R14 | Admin MFA/step-up | **VERIFIED WITH CONDITIONS** | Existing `REQUIRE_ADMIN_MFA` and AAL2 support documented in prior audits. | Resource publish operation is not yet wired to explicit step-up. | Decide whether publish/schedule requires AAL2; implement server-side. |
| R15 | Service-role containment | **VERIFIED WITH CONDITIONS** | Public code uses normal server client/local content; service client is a separate server-only utility. | Future mutation code could accidentally use service role too broadly. | Review bundle/server boundaries and test browser output. |
| R16 | Storage dependency | **VERIFIED** — optional | Launch images are null; image helper restricts paths and uses `site` bucket only if configured. | Future bucket policy and licensing require review. | Keep images out of first CMS gate or add approved storage test. |
| R17 | Ad/consent dependency | **VERIFIED** — disabled | `.env.example` false/blank; `ResourceAdSlot` inert when disabled. | Consent, minors, labeling, performance and AdSense approval remain open. | Separate monetization decision; do not enable during CMS work. |
| R18 | Sitemap/SEO | **VERIFIED WITH CONDITIONS** | `app/sitemap.ts` adds resources/categories/articles; prior production report verified URLs/JSON-LD/canonicals. | Database failure and draft exclusion need regression coverage. | Test sitemap against synthetic published/draft/future rows. |
| R19 | Markdown/content safety | **VERIFIED WITH CONDITIONS** | Repository content is controlled Markdown; database schema bounds content length. | Database write path and renderer allowlist/sanitization must be verified. | Define accepted Markdown/URL rules before editorial writes. |
| R20 | Same-domain deployment | **VERIFIED** | Existing Vercel production deployment served Resource Centre according to prior report. | Preview staging variables were not proven isolated by Task 12. | Configure branch-scoped staging-only Preview environment. |
| R21 | Full staging baseline | **NOT FEASIBLE** for this module’s need / **BLOCKED** as a general prerequisite | Task 12: empty isolated project, no authoritative clean-install baseline, no Resource Centre objects. | Full replay is unsafe and unrelated to public module requirements. | Do not reconstruct all Scholars migrations; use bounded module baseline. |
| R22 | Bounded staging baseline | **UNVERIFIED** | Proposed by this audit; not applied under read-only boundaries. | Exact auth/profile fixture and role/default-privilege assumptions need approval. | Produce migration bundle and verification SQL as next authorized task. |
| R23 | Synthetic RLS/admin test identities | **UNVERIFIED** | Task 12 confirms none were created. | Need anonymous, non-admin, admin, MFA/recovery and service-only cases. | Create only after schema baseline passes and owner authorizes. |
| R24 | Production migration backup/rollback | **VERIFIED WITH CONDITIONS** | Additive object design supports feature fallback and reverse migration. | Snapshot/backup procedure, checksum and change window not yet selected. | Database owner writes release runbook before production SQL. |
| R25 | Unrelated Scholars regression protection | **VERIFIED WITH CONDITIONS** | Current Resource Centre code does not modify matching/application/profile flows. | Future admin code could accidentally cross boundaries. | Add changed-path review and regression suite. |

## 3. Minimum next implementation package

The next authorized engineering package should contain only:

1. A uniquely versioned, standalone Resource Centre staging migration/bundle for the five tables, indexes, constraints, RLS, grants and public projection views.
2. A read-only verification script that checks object names, columns, constraints, policies, grants, view definitions and absence of base-table public access.
3. A documented choice for the `is_admin`/admin fixture dependency, with no production identity or secret reuse.
4. Synthetic seed data and test identities only after schema verification.
5. Tests for anonymous public reads, non-admin denial, admin reads, draft/future/inactive exclusion, revision attribution, self-approval rejection and sitemap behavior.
6. A Vercel Preview environment bound to staging-only public and server configuration.
7. A release/rollback runbook that explicitly excludes unrelated Scholars objects.

No public production migration or deployment should be the next step. The first gate is bounded staging verification.

## 4. Explicit non-goals

The following are not prerequisites and should not be included in the next package:

- Replaying all 136 Scholars migrations.
- Seeding scholarship/opportunity data.
- Copying production Auth users or records.
- Rebuilding profiles, applications, matching, XP, community or notification infrastructure.
- Replacing `public.is_admin` without a security comparison.
- Enabling AdSense or adding consent infrastructure.
- Modifying middleware, onboarding, auth callbacks, matching, applications or existing catalogue RLS.
- Applying SQL to production or deploying a new build.

## 5. Final readiness verdict

**Public Resource Centre implementation:** **VERIFIED** as independently feasible and already supported by a repository-backed runtime path.

**Database-backed editorial CMS:** **VERIFIED WITH CONDITIONS**. The architecture is appropriate, but staging must first establish the dedicated schema, projection/RLS behavior, admin dependency and Preview isolation.

**Full Scholars staging reconstruction:** **NOT FEASIBLE as a necessary prerequisite** for this work; the existing migration history is not a safe clean-install baseline and reproducing unrelated infrastructure would add risk without improving public Resource Centre feasibility.

**Overall decision gate:** **VERIFIED WITH CONDITIONS — proceed with a bounded Resource Centre staging design, not full Scholars reconstruction.**
