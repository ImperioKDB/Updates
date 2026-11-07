# SCHOLARS RESOURCE CENTER — FRONTEND IMPLEMENTATION READINESS

**Prepared:** 2026-11-07  
**Decision frame:** This is a planning assessment. It does not authorise implementation, database work, security changes, or deployment.

## Readiness classification

| Area | Classification | Assessment and gate |
|---|---|---|
| Public `/resources` route | READY WITH CONDITIONS | Route exists and reads published projection data. Refine composition only after branch and current field contracts are reverified. |
| Public `/resources/category/[slug]` route | READY WITH CONDITIONS | Route exists and uses category/article projections. Improve layout, truthful empty state, pagination decision, and actual slug links. |
| Public `/resources/[slug]` route | READY WITH CONDITIONS | Route exists with metadata, JSON-LD, markdown body, author data, and categories. Verify image URL handling, reading measure, TOC/progress, and related-content strategy. |
| Shared public shell | READY WITH CONDITIONS | Reuse existing fonts, logo/footer, global focus/motion, and breadcrumb utilities. Resource-specific masthead/nav components need design refinement. |
| Brand tokens and typography | READY | Fraunces, Manrope, parchment, navy, emerald, amber, muted red, and warm neutral are verified in the source context. |
| Motion foundation | READY | Existing CSS defines press feedback, reveal timing, reduced-motion handling, and native scroll behaviour. Avoid adding a heavy animation dependency. |
| Public Supabase access | READY WITH CONDITIONS | Fixed security-barrier projection views exist and are granted to public roles, but the deployed views are owner-context and not `security_invoker=true`. Public frontend must remain on those projections while the security model is explicitly reviewed. |
| Article images/storage | READY WITH CONDITIONS | Field exists, but browser URL/public bucket and transformation strategy require verification before UI implementation. |
| Category sitemap coverage | READY WITH CONDITIONS | Verified production state omits `/resources` from static paths and does not generate category URLs. Implementation must decide empty-category indexability, then correct the approved sitemap scope. |
| SEO metadata and JSON-LD | READY WITH CONDITIONS | Article route already emits canonical/Open Graph/Article data. Verify BreadcrumbList parity, image data, category metadata, and date semantics. |
| Responsive implementation | READY WITH CONDITIONS | Existing routes are simple enough to refine, but all ten required widths need explicit QA, especially 390px overflow. |
| Accessibility | READY WITH CONDITIONS | Global focus ring and 44px control guidance exist. Navigation, TOC, dialog, image alt, and semantic article QA remains. |
| Performance | READY WITH CONDITIONS | Server-side reads and local fonts are present. Bound queries, reserve image space, and measure mobile Web Vitals in implementation. |
| Public search/filter | NOT REQUIRED IN THIS PHASE | Prototype does not establish a search contract and projections do not document search requirements. Do not add speculative client-side search. |
| Newsletter subscription | NOT REQUIRED IN THIS PHASE | No approved storage or delivery contract is documented. Keep reader CTA linked to existing Scholars surfaces. |
| Bookmarking | NOT REQUIRED IN THIS PHASE | No approved authenticated persistence contract. Omit until architecture is approved. |
| CMS dashboard read-only shell | READY WITH CONDITIONS | Visual direction can be documented. Live metrics, queue data, calendar, and status semantics need approved contracts. |
| CMS authoring/editor | BLOCKED | Security review must resolve admin boundary, write permissions, reviewer permissions, transitions, revision integrity, and auditability. |
| Publishing/approval workflow | BLOCKED | Do not implement actions or state transitions despite schema status values. |
| New migrations/RLS/grants | BLOCKED | Phase 1 foundation exists. No schema/security changes are authorised in this assignment. |
| Content seeding | BLOCKED | Do not fabricate or seed production articles, authors, dates, images, or sample metrics. |
| Vercel deployment | NOT REQUIRED IN THIS PHASE | Documentation only; deployment is explicitly prohibited by the assignment. |

## What is safe for the next public phase

A frontend engineer can refine the public shell and pages using existing routes, local fonts, global styles, reusable utilities, and public projections. The safest order is shell, homepage, category, article, then responsive/accessibility/SEO/performance QA. Public work must not bypass projection views, invent fields, or use the prototype’s sample links and records.

Before coding, reverify the target branch and inspect any unmerged Resource Center changes. Confirm the image URL strategy, current public projection columns, category sitemap decision, and actual shared header/footer conventions. Keep the implementation additive and route-local unless a verified shared component should be improved.

## Why CMS is blocked

The Phase 1 schema contains workflow-oriented columns and revision records, but their presence is not approval for write functionality. The database migration explicitly protects base tables and exposes public projection views. A secure CMS still needs an approved answer for who may create or update articles, who may review, whether authors can review their own work, how transitions are enforced atomically, how revisions are selected for publication, how deletes/archive operations are controlled, and how audit records are retained. Until those questions are resolved, the editor and dashboard remain visual references only.

## Readiness exit criteria

Public frontend readiness can move from READY WITH CONDITIONS to READY when the branch and field contract are confirmed, image handling is verified, the sitemap category decision is recorded, and a test plan covers all required viewport widths and public states. CMS readiness can move from BLOCKED only after explicit security approval, not merely after a visual review.

## References

[1]: https://github.com/ImperioKDB/Scholars/blob/main/app/resources/page.tsx "Existing Resource Center homepage route"
[2]: https://github.com/ImperioKDB/Scholars/blob/main/app/resources/%5Bslug%5D/page.tsx "Existing Resource Center article route"
[3]: https://github.com/ImperioKDB/Scholars/blob/main/app/resources/category/%5Bslug%5D/page.tsx "Existing Resource Center category route"
[4]: https://github.com/ImperioKDB/Scholars/blob/main/supabase/migrations/20261107130100_resource_center_schema.sql "Resource Center schema and access boundary"
[5]: https://github.com/ImperioKDB/Scholars/blob/main/app/sitemap.ts "Current sitemap implementation"
[6]: https://resource-center.htmlhost.co/editorial-dashboard "Prototype dashboard visual direction"
[7]: https://github.com/ImperioKDB/Updates/blob/main/SCHOLARS_RESOURCE_CENTER_POST_DEPLOYMENT_SECURITY_CLARIFICATION_2026-11-07.md "Resource Center post-deployment security clarification"
