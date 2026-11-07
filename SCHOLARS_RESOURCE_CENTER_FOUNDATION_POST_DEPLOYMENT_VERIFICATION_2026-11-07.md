# Scholars Resource Center Foundation — Post-Deployment Verification

**Verification date:** 2026-11-07  
**Repository:** https://github.com/ImperioKDB/Scholars  
**Verified commit:** [`41573f5ec2985851ba118e8b39a47f9c54532302`](https://github.com/ImperioKDB/Scholars/commit/41573f5ec2985851ba118e8b39a47f9c54532302)  
**Commit:** `feat: add resource center foundation`  
**Production deployment:** `dpl_3tYRg8bdPCHnNncxCXp8uLz8qey3`  
**Deployment URL:** https://scholars-geeo0th1v-imperiokdbs-projects.vercel.app  
**Production aliases:** `https://scholars.com.ng`, `https://www.scholars.com.ng`  
**Supporting readiness report:** [`SCHOLARS_RESOURCE_CENTER_PHASE_0_2_FINAL_SECURITY_AND_SCHEMA_READINESS.md`](https://github.com/ImperioKDB/Updates/blob/main/SCHOLARS_RESOURCE_CENTER_PHASE_0_2_FINAL_SECURITY_AND_SCHEMA_READINESS.md)

## 1. Executive verdict

# FOUNDATION VERIFIED — AUTHORING/PUBLISHING STILL BLOCKED

The approved Resource Center foundation was applied, tested and deployed successfully. The security-boundary remediation and additive Resource Center schema are present in the Scholars repository and were applied to the connected Supabase project before deployment. GitHub CI passed typecheck, the full existing test suite and the production build. Vercel reports the production deployment as `READY` and assigns it to the verified commit above.

The public foundation is live: `https://scholars.com.ng/resources` returns HTTP 200, and the sitemap returns HTTP 200 with `application/xml`. No article content was seeded, so there is no published article or category fixture to validate. The current `/admin/resources` page is a guarded review/index surface, not an authoring, review-transition or publishing workflow.

Accordingly, this report verifies the deployed foundation only. It does **not** authorize implementation or activation of authoring, review, scheduling, publishing, archiving or correction operations.

## 2. Approval baseline

The implementation was approved against the Phase 0.2 report:

- [`SCHOLARS_RESOURCE_CENTER_PHASE_0_2_FINAL_SECURITY_AND_SCHEMA_READINESS.md`](https://github.com/ImperioKDB/Updates/blob/main/SCHOLARS_RESOURCE_CENTER_PHASE_0_2_FINAL_SECURITY_AND_SCHEMA_READINESS.md)
- Phase 0.2 classification before implementation: **C. BLOCKED BY EXISTING SECURITY FINDINGS**.
- Phase 0.2 required a separate, owner-approved security remediation for the worker RPC grants and public-schema default privileges.
- Phase 0.2 required explicit public projection views rather than exposing Resource Center base-table columns through public RLS alone.
- Phase 0.2 required immutable revision snapshots and deferred publication transitions until security boundaries were corrected and verified.

This implementation followed the approved narrow path: security remediation first, additive schema second, public projection views, and no seeded content or publication transition functions.

## 3. GitHub and CI verification

GitHub Actions run [`42370445496`](https://github.com/ImperioKDB/Scholars/actions/runs/42370445496) completed with **success** for commit `41573f5`.

Verified CI steps:

| Check | Result |
|---|---|
| `npm install` | Passed |
| `npx tsc --noEmit` | Passed |
| `npm test` | Passed — 17 test files, 69 tests |
| `npm run build` | Passed |

The repository was clean after the push and `main` matched `origin/main` at the verified commit.

## 4. Vercel deployment verification

The Vercel deployment API returned the following verified state:

- Project: `scholars` (`prj_n4Unq6wzjbjRT9TcRGKvFD9jIfBk`)
- Target: `production`
- State: `READY`
- Git ref: `main`
- Git SHA: `41573f5ec2985851ba118e8b39a47f9c54532302`
- Region: `dub1`
- Aliases: `scholars.com.ng`, `www.scholars.com.ng`, and the Vercel project aliases
- Alias error: `null`

The deployment is therefore provenance-linked to the pushed Scholars commit and is serving the production aliases.

## 5. Live route verification

Read-only HTTPS requests were made after deployment.

| URL | Result | Interpretation |
|---|---:|---|
| `https://scholars.com.ng/resources` | HTTP 200, `text/html` | Public Resource Center listing route is live |
| `https://scholars.com.ng/resources/category/uncategorized` | HTTP 404 | Expected for a nonexistent category slug; no category rows were seeded |
| `https://scholars.com.ng/sitemap.xml` | HTTP 200, `application/xml` | Sitemap remains available after the route and sitemap integration |

No content mutation, authentication action, admin action or production data insertion was performed during this verification.

## 6. Supabase and security-boundary verification

The connected Supabase project is `scholarship-platform` (`cmdglabohpttgfofcmqc`). The approved migrations were applied before deployment:

- `20261107130000_security_boundary_remediation.sql`
- `20261107130100_resource_center_schema.sql`

The live verification recorded the following:

- The worker RPC functions `claim_notification_delivery`, `claim_workflow_job` and `complete_workflow_job` are restricted to the service-role execution path after remediation.
- The public-schema default privilege correction was applied for future functions, tables and sequences.
- Resource Center base tables have RLS enabled:
  - `resource_editorial_identities`
  - `resource_categories`
  - `resource_articles`
  - `resource_article_categories`
  - `resource_revisions`
- Public reads use explicit projection views:
  - `resource_public_editorial_identities`
  - `resource_public_categories`
  - `resource_public_articles`
  - `resource_public_article_categories`
- No Resource Center article, category, identity or revision rows were seeded during this phase.
- No authoring or publication RPC was added.

The public projection boundary is therefore in place, while the workflow transition boundary remains intentionally unimplemented.

## 7. Scope of what was deployed

The pushed foundation includes:

- Public routes: `/resources`, `/resources/category/[slug]`, `/resources/[slug]`.
- Safe article-body rendering for the currently supported content representation.
- Public metadata, breadcrumbs, sitemap integration and footer navigation.
- Guarded admin Resource Center index at `/admin/resources`.
- Resource Center navigation in the existing admin shell.
- Removal of the inconsistent `announcement_log` dashboard read identified by Phase 0.2.
- The approved additive schema and security remediation migrations.

## 8. Explicit non-authorization findings

The following are not present and must not be inferred from this deployment:

1. No article authoring/editor UI is implemented.
2. No draft-to-review, review-return, approval, scheduling, publish, archive or correction transition is implemented.
3. No reviewer-separation or approval-freshness workflow is active.
4. No MFA/AAL2-gated publication operation is active.
5. No Resource Center content has been seeded.
6. No production publish action was performed.

These omissions are deliberate and consistent with the Phase 0.2 gate. Building the next workflow phase requires a separate owner authorization after review of this report and the Phase 0.2 report.

## 9. Final conclusion

The Resource Center **foundation is verified in production**: the approved security remediation and schema are deployed, CI is green, Vercel is ready on the verified commit, the public listing route responds successfully, and the sitemap remains healthy.

The system is **not yet authorized for authoring or publishing workflow implementation**. The next phase must be separately approved and must preserve the projection-view boundary, immutable revision model, guarded transitions, reviewer separation, approval freshness, scheduled-publication validation and MFA/AAL2 requirements established in Phase 0.2.
