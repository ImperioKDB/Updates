# Scholars Resource Center — Phase 1
## Read-Only Codebase Audit and Architecture Assessment

**Repository:** `ImperioKDB/Scholars`  
**Website:** `https://scholars.com.ng`  
**Audit date:** 2026-11-06  
**Audit scope:** Source-tree, migration-history, configuration, CI/CD and routing inspection only

> **Status:** Audit complete. No implementation was performed. No application files, database records, migrations, environment variables, branches, deployments or dependencies were changed.

## 1. Executive summary

Scholars is an existing Next.js App Router application with TypeScript, Supabase authentication/database/storage, server and browser Supabase clients, a public scholarship catalogue, authenticated student flows, administrative operations, Vercel deployment configuration, GitHub Actions CI, and a substantial database migration history.

A public Resource Center at `/resources` is technically feasible inside the existing application. The safest Phase 1 is additive: create a public route group under `app/resources`, add a small server-rendered article/content model, extend metadata and sitemap generation, and add navigation links. The Resource Center should not be placed behind the existing authenticated route group, should not reuse scholarship eligibility or matching tables as a content system, and should not modify the matching engine, onboarding authorization, or admin security boundary.

The current repository does **not** contain a Resource Center, a general article CMS, article categories/tags/authors/publishing tables, an `/resources` route, AdSense integration, or an `ads.txt` file. Existing `article` terms are mostly semantic HTML or JSON-LD for individual scholarship pages; they are not evidence of a general publishing system.

The recommended architecture is a separate, public content subsystem that initially uses a small normalized schema or a repository-backed static content source. Because the requested center is intended to grow into a maintained publishing area, a Supabase content schema is the more extensible long-term option, but it should be introduced only after independent approval. A first implementation should include explicit editorial status, publication timestamps, slugs, canonical paths, category, author attribution, review metadata, and revision history. It should not expose draft content through public queries.

The existing SEO foundation is good enough to extend: the app has root metadata, public metadata helpers, canonical URL support, JSON-LD, `robots.ts`, `sitemap.ts`, and public catalogue pages. It needs Resource Center-specific metadata, sitemap entries, breadcrumb/article structured data, and a clear internal-linking plan. AdSense is not yet integrated. It can be added later with route-scoped placements, but approval is never guaranteed and privacy/consent, content quality, ad labeling, page experience, and policy compliance must be addressed before activation.

## 2. Audit method and limitations

This was a read-only inspection of the checked-out `ImperioKDB/Scholars` repository and its tracked configuration/migration files. The checkout was cloned into `/tmp/scholars-repo`; the Updates repository was cloned into `/tmp/updates-repo` for report publication.

The audit did not connect to or mutate Supabase, did not execute migrations, did not deploy to Vercel, did not change environment variables, did not install dependencies, and did not edit the Scholars source repository. The local Scholars checkout did not contain `node_modules`, so TypeScript, tests and the production build were not run because installing dependencies was explicitly outside scope. Findings are therefore source-level findings, not a live production verification or a live database-schema confirmation.

Migration files were treated as the authoritative repository record of intended schema evolution, not as proof that every migration has been applied to the live Supabase project. The live database must be checked separately during an approved implementation phase.

## 3. Verified application architecture

### Framework and language

- Next.js 14.2.5 with App Router, as declared in `package.json`.
- TypeScript 5.4.5 with strict mode enabled in `tsconfig.json`.
- React 18.3.1 and React DOM 18.3.1.
- Tailwind CSS 3.4.7 with PostCSS and Autoprefixer.
- Supabase JavaScript 2.45.4 and `@supabase/ssr` 0.5.2.
- Zod 3.23.8 for request/input validation.
- Inngest 3.27.0 is present for durable event/function integration, although the inspected email functions are deliberately disabled.
- `web-push` is present for browser push notifications.
- Vitest, Testing Library and jsdom are present for tests.

### Directory and entry-point structure

The principal application boundary is the `app/` directory. Important areas include:

- `app/layout.tsx`: root layout, global metadata and application shell.
- `app/page.tsx`: public home page.
- `app/(auth)/`: login, signup and authentication-facing routes.
- `app/(protected)/`: authenticated application surfaces.
- `app/dashboard/`: student dashboard and dashboard components.
- `app/discover/`: discovery and matching experience.
- `app/scholarship/[slug]/`: public scholarship detail route.
- `app/scholarships-in-nigeria/` and `app/opportunities-for-students/`: public catalogue/SEO pages.
- `app/admin/`: authenticated administrative surfaces.
- `app/api/`: API route handlers for auth, profiles, scholarships, admin, cron, notifications, integrations and feedback.
- `components/`: reusable UI and client components.
- `lib/`: Supabase clients, matching, validation, auth, SEO, email, notifications, admin guards and domain logic.
- `supabase/migrations/`: schema evolution and seeded opportunity content.
- `.github/workflows/ci.yml`: GitHub Actions typecheck/test/build pipeline.
- `vercel.json`: Vercel region and cron configuration.

### Frontend/backend boundaries

Browser-facing code uses the browser Supabase client, for example `lib/supabase/client.ts`. Server components and route handlers use the server client, for example `lib/supabase/server.ts`. Privileged database operations use `lib/supabase/service.ts` and are confined to server-side/admin/integration code. API handlers commonly validate JSON with Zod before querying Supabase.

The middleware boundary is `middleware.ts`. It refreshes Supabase sessions, handles authentication rescue/redirect behavior, maintains referral/attribution cookies, and applies route protections. Its matcher includes protected/admin/API-sensitive paths but does not include `/resources`; a future `/resources` page can remain public if implemented outside protected route groups and without adding it to the protected matcher.

### Middleware and API inventory

The API surface includes, among other areas:

- Auth callback, password leak checking and MFA endpoints under `app/api/auth/`.
- Profile/onboarding and WAEC/profile endpoints under `app/api/profile/`.
- Scholarship listing, detail, community, application, saved and matching routes.
- Admin routes for scholarships, discovery, feedback, analytics, schema checks and user operations.
- Cron routes including `app/api/cron/deadline-check/route.ts` and `app/api/cron/notification-worker/route.ts`, both protected by `CRON_SECRET`.
- GitHub/external automation routes under `app/api/integrations/github/`, protected by bearer `CRON_SECRET` and generally rate-limited.
- Inngest endpoint at `app/api/inngest/route.ts`.

## 4. Existing functionality inventory

### Authentication and Google sign-in

The authentication layer is Supabase Auth. `app/auth/callback/route.ts:4-9` handles both Google OAuth and email-confirmation links by exchanging a code for a session. The same route protects the user-controlled `next` redirect through `safeNextPath` at lines 11-15 and handles referral/campaign attribution at lines 17-29 and 47-77.

MFA endpoints exist at `app/api/auth/mfa/factors/route.ts`, `app/api/auth/mfa/enroll/route.ts` and `app/api/auth/mfa/verify/route.ts`. Admin enforcement is staged through `REQUIRE_ADMIN_MFA`, referenced by `lib/admin/guard.ts` and `.env.example:13-15`.

### Registration, verification and recovery

Email/password registration and confirmation use Supabase Auth. The callback route is the central confirmation/OAuth session establishment point. Password recovery is implemented in `app/reset-password/page.tsx:47-99` and `app/reset-password/update/page.tsx:15-27,38-85`, including recovery OTP handling, password-strength validation, recovery-session rescue and an explicit invalid/expired-link state.

`app/api/auth/password-check/route.ts:4-18,26-50` proxies the Have I Been Pwned range API using k-anonymity and a shared rate-limit helper. It does not transmit the password or full hash to HIBP.

### Student profiles and onboarding

The profile model is stored in `profiles` with additional related tables for education and related profile data. `app/onboarding/page.tsx` implements a multi-step client flow and requires explicit profile-based matching authorization before completion; the UI explains that profile data can include academic records, date of birth, location, financial need and disability information.

This matching authorization and its withdrawal behavior are privacy-sensitive and should remain untouched by a public content-center phase.

### Discovery, matching and eligibility scoring

The public scholarship catalogue is represented by the `scholarships` domain and public routes such as `app/scholarship/[slug]/page.tsx`, `app/scholarships-in-nigeria/page.tsx` and `app/opportunities-for-students/page.tsx`.

Matching logic is in `lib/matching/`, with scoring and explanation helpers used by dashboard/discovery surfaces. The system also has an evidence-first discovery pipeline: GitHub integration endpoints ingest candidates, quality-score them, verify URLs/content freshness, extract claims, and run advisory eligibility review. For example, `app/api/integrations/github/scholarship-verification/route.ts:30-100` records snapshots, attempts, extraction claims and freshness; `app/api/integrations/github/scholarship-eligibility/route.ts:24-46` requires structured evidence and returns uncertainty rather than inventing eligibility.

The public Resource Center should not write to scholarship records or route guide pages through the matching engine. Guides may link to catalogue records but should not become eligibility inputs without an independently approved product rule.

### Student dashboard

`app/dashboard/page.tsx` and dashboard client components provide profile completion, match results, saved opportunities, application tracking, deadline-related state and other student actions. Existing notification and saved-item workflows are coupled to scholarship/application domain objects and should not be reused for article publication without a separate design.

### Administration

The admin area includes guards, MFA-aware access, scholarship/content operations, discovery review, feedback management, analytics, active-user views, schema checks and operational monitoring. `app/admin/discovery/page.tsx` exposes the human approval path from pending discovery candidate to approved/published catalogue opportunity; the UI states that publication requires quality, verified URLs, current evidence, reviewed eligibility, an application URL and confirmed claims.

This is scholarship catalogue content management, not a general editorial CMS. A Resource Center should receive its own editorial permissions and workflow rather than treating articles as scholarships.

### Existing scholarship content management

Existing management focuses on structured scholarship/opportunity records and their verification state. The migration history includes `scholarships`, `scholarship_discovery_candidates`, verification snapshots/attempts, candidate claims and review events. There is no verified general-purpose article table or Resource Center admin editor in the inspected repository.

## 5. Database architecture assessment

### Provider and access model

Supabase/Postgres is the database provider. The repository contains a long migration history under `supabase/migrations/`. Client access is split between browser/server clients and a server-only service-role client. RLS policies are defined throughout the migrations, and admin/service operations use guarded server-side code.

The initial migration is `supabase/migrations/0001_init.sql`; later migrations extend profiles, scholarship content, applications, discovery verification, community, notifications, analytics and operational workflows. Because this is a migration history rather than a live schema query, live table/policy state must be confirmed before implementation.

### Existing relevant table families

The inspected migrations establish or extend families including:

- `profiles` and profile/education-related data.
- `scholarships`, saved scholarships and applications.
- Discovery source/candidate, fetch snapshot, verification attempt, claim and review-event tables.
- Discussion/community tables associated with scholarships.
- Notification delivery, push subscription and workflow/job tables.
- Feedback, error/monitoring and analytics-oriented tables.
- Attribution, referral and re-engagement tables.

There are community fields/views with `category` and `author` semantics, and scholarship rows contain editorial/research fields such as `published_at`, but these are not a reusable article CMS.

### Content-related gap

No general Resource Center article/content table, article category table, tag table, author/editorial profile table, revision table, or public article route was identified. The word `article` also appears in semantic HTML and JSON-LD contexts, including individual scholarship detail pages; that does not establish a publishing model.

The Resource Center therefore should not overload `scholarships`, `discussions`, `feedback`, or discovery candidates. Doing so would create incorrect relationships, contaminate matching/search semantics, and make RLS and editorial status harder to reason about.

### Recommended future content model

For an approved implementation, a minimal normalized model could be:

- `resource_articles`: `id`, `slug`, `title`, `excerpt`, `body`/structured blocks, `article_type`, `status`, `canonical_url`, `featured_image_url`, `reading_time_minutes`, `author_id`, `reviewer_id`, `published_at`, `updated_at`, `created_at`.
- `resource_categories`: stable slug/name/description/display order.
- `resource_article_categories`: many-to-many join.
- `resource_tags` and `resource_article_tags`: optional, only if tag navigation is genuinely needed.
- `resource_revisions`: immutable revision/audit records if editors need draft history or rollback.

Status should be an explicit constrained value such as `draft`, `in_review`, `scheduled`, `published`, `archived`. Public queries must filter to `published` and a publication time not in the future. Draft and revision access must be admin-only through RLS and server-side authorization.

This is a recommendation, not an executed schema change. No migration was run.

## 6. SEO infrastructure assessment

### Existing strengths

- Root metadata is defined in `app/layout.tsx`, including application title/description and site-level metadata.
- `app/robots.ts` exists and controls crawler behavior.
- `app/sitemap.ts` exists and composes public URL data through `lib/sitemap-data.ts`.
- `components/SeoJsonLd.tsx` provides structured-data support.
- Public catalogue and scholarship detail routes already have discoverable URL patterns.
- `app/scholarship/[slug]/page.tsx` emits JSON-LD for a scholarship detail page and has a canonical/public-page concept.
- Existing public pages establish internal-linking patterns into scholarship and opportunity routes.

### Gaps for `/resources`

- No `/resources` index route exists.
- No article route pattern exists, such as `/resources/[slug]` or `/resources/[category]/[slug]`.
- Sitemap data does not yet include resource articles.
- There is no verified article-specific metadata factory, Article JSON-LD, BreadcrumbList JSON-LD, author schema, or article last-reviewed signal.
- There is no resource-specific category/tag navigation or related-content linking system.
- No `ads.txt` file or AdSense integration was found.

### Recommended SEO behavior

The public index should have a stable canonical URL at `/resources`. Each published article should have a unique canonical URL, title, description, Open Graph/Twitter metadata, `Article` or `BlogPosting` JSON-LD as appropriate, and `BreadcrumbList` JSON-LD. Only published articles should enter the sitemap. Draft, preview and admin routes should be `noindex` and protected.

Resource pages should link to relevant, verified scholarship catalogue pages, official provider sources and adjacent guides. Scholarship detail pages should not be bulk-edited as part of the Resource Center phase; selective, intentional cross-links can be added later.

## 7. Deployment and CI/CD assessment

### Vercel configuration

`vercel.json:1-11` declares the Vercel schema, region `dub1`, and a daily cron at `0 8 * * *` for `/api/cron/deadline-check`.

### Build and CI

`.github/workflows/ci.yml:1-31` runs on pushes and pull requests to `main`. It installs with `npm install`, then runs `npx tsc --noEmit`, `npm test`, and `npm run build`. The CI job supplies placeholder public Supabase values and intentionally does not require production credentials.

The repository includes `DEPLOY_TRIGGER.md`, which documents that a new commit may be used to force a fresh Vercel build when a manual deployment is stuck. No deployment was triggered for this audit.

### Environment assumptions

`.env.example` documents public Supabase URL/key, app URL, public/private web-push keys, service-role key, admin MFA flag, Upstash rate limiting, Brevo email, cron secrets, Inngest keys/flags, profile reminder settings and `GEMINI_API_KEY`. Secret values were not inspected or exposed.

The Resource Center should use existing public app URL configuration for canonical/absolute URLs and should not hardcode production URLs inside content rendering. Any new server-only content query must use the correct server/service client and must not move privileged credentials into client bundles.

### Production assumptions and limits

The deployment path is GitHub-to-Vercel with CI protection, but this audit did not inspect live Vercel deployment status or production environment values. The absence of local `node_modules` prevented a local build/test run. The next implementation phase must run the repository CI and verify preview/production behavior after code and approved migrations are added.

## 8. Resource Center integration feasibility

### Safest integration

A public Resource Center can be introduced as an additive App Router route tree:

```text
app/resources/page.tsx
app/resources/[slug]/page.tsx
app/resources/[category]/page.tsx        # optional, only if needed
lib/resources/queries.ts
lib/resources/types.ts
lib/resources/metadata.ts
components/resources/...
```

This route tree should be outside authenticated route groups. It should use server-rendered published content and avoid client-side fetching for the initial page body. A small client component is acceptable for non-essential interaction such as filters or newsletter UI, but the core article content must remain crawler-visible HTML.

The first version can work without a new dependency. Existing Tailwind, typography, link, card, metadata and structured-data patterns are sufficient.

### Why a separate application is not necessary

The existing Next.js app already serves public, authenticated and API routes and already has the required SEO/deployment infrastructure. A separate app would add deployment, domain, analytics, authentication, styling and content-linking complexity without solving a demonstrated boundary problem.

### Route and auth safety

Because `/resources` is not in the protected middleware matcher, a new public route can avoid authentication changes. It should not be added under `app/(protected)/`. Any content-admin route should be separate, guarded by the existing admin authorization/MFA system, and should not be publicly reachable through the article route.

### Database safety

A separate content schema prevents accidental matching, application or scholarship-state changes. Public content queries should select only published rows and should not use the service-role client in a browser component.

## 9. AdSense readiness assessment

### Current state

AdSense is not integrated. No AdSense script, `ads.txt`, `googlesyndication` reference or route-scoped ad component was found. The existing application therefore has no active ad behavior to preserve or restrict.

### Route-scoped monetization design

Ads should be opt-in on Resource Center article templates only. A future `ResourceAdSlot` component can render nothing on the home page, dashboard, discovery, onboarding, auth, application, scholarship matching and admin routes. Keep the core matching experience advertisement-free by construction rather than by scattered conditionals.

A route/layout-level Resource Center shell can provide the ad policy boundary, while individual placements should be intentionally limited to avoid poor page experience. The ad component should include stable dimensions or reserved layout space to minimize cumulative layout shift and should never be inserted inside critical form controls or eligibility explanations.

### Consent, privacy and policy work

Before enabling personalized advertising, the product needs an appropriate privacy/consent review for the jurisdictions and users it serves. The existing privacy page and client-side consent behavior should be reviewed for advertising cookies, third-party scripts, user choice, children/minor considerations, data retention, and any consent-management requirements. Ads must be clearly distinguished from editorial content, and no ad targeting should be based on sensitive profile fields such as disability, financial need, date of birth or academic records.

AdSense acceptance is not guaranteed. Approval depends on Google review, content quality, originality, navigation, policy compliance, site ownership, technical readiness and ongoing maintenance. A useful Resource Center should be built for students first; monetization should be a later, independently approved phase.

## 10. Potential regression risks

1. **Authentication regression:** placing `/resources` inside the protected route group or changing middleware matchers could redirect public readers to login.
2. **Matching contamination:** storing articles in scholarship tables or adding guide metadata to matching inputs could affect eligibility scores or catalogue behavior.
3. **RLS leakage:** public queries that omit the `published` predicate or use a service-role client could expose drafts, reviewer notes or author metadata.
4. **SEO duplication:** generating article URLs without stable slugs/canonicals could create duplicate pages and sitemap noise.
5. **Draft indexing:** preview routes or server-rendered draft pages could be crawled unless explicitly blocked and authorization-protected.
6. **Sitemap failure:** making sitemap generation depend on a production-only database connection could break CI or route generation, contrary to the existing CI design.
7. **Performance regression:** loading large article bodies, editor bundles or ad scripts on dashboard/discovery routes could increase JavaScript and layout shift.
8. **Content trust risk:** scholarship guides that imply eligibility or deadlines without authoritative source links could conflict with the evidence-first catalogue standard.
9. **Privacy/ad targeting risk:** passing profile information into analytics, recommendations or ad scripts would create a sensitive-data boundary violation.
10. **Admin authorization drift:** reusing scholarship-admin endpoints for editorial content could grant broader privileges than intended.
11. **Migration drift:** assuming the migration history equals live Supabase state could produce failed migrations or missing-column errors.
12. **Navigation regression:** adding Resource Center links without mobile testing could make existing navigation overflow or reduce access to core matching actions.

## 11. Recommended implementation architecture

### Content ownership and editorial model

Use a distinct Resource Center domain. Every article should have a stable slug, title, excerpt, body, category, optional tags, author, reviewer/last-reviewed metadata, source links where claims are externally grounded, publication status and timestamps. Guides discussing deadlines or eligibility should carry a visible “last reviewed” date and link back to the canonical opportunity/provider source.

### Rendering model

Use server components for public index/category/article pages. Fetch only published content. Generate metadata from the same canonical article record used by the page. Use a controlled rich-text/structured-block representation rather than rendering arbitrary unsanitized HTML. If Markdown is introduced, sanitize the rendered output and restrict allowed elements/URLs.

### Editorial workflow

Recommended states: draft → in review → scheduled/published → archived. Provide preview only to authenticated authorized editors. Publishing should be an explicit admin action, with `published_at`, reviewer identity and an audit event. Do not automatically publish AI-generated drafts or unverified scholarship claims.

### Content taxonomy

Start with a small fixed category set aligned to the brief: application guides, essays and motivation letters, interviews, study abroad/international education, funding/financial aid, and study skills. Avoid an open-ended tag system until there is a demonstrated navigation need.

### Cross-linking

Resource articles may link to relevant public scholarship detail pages and official provider sources. Catalogue pages may link to evergreen guides through intentional component slots, but the Resource Center should not change eligibility scoring or application state.

### Observability and failure handling

Content reads should fail gracefully with a not-found or temporary-unavailable state. Publishing and notification side effects should be wrapped in `try/catch` and logged using existing logging conventions. If article data is unavailable, the route must not silently render stale or draft content as published.

## 12. Exact files and directories likely to require modification

These are recommendations for a separately authorized implementation, not changes made during this audit:

- `app/resources/page.tsx` — public Resource Center index.
- `app/resources/[slug]/page.tsx` — public article route.
- Optional `app/resources/[category]/page.tsx` — category index only if justified.
- `app/layout.tsx` — only if global navigation/footer needs a Resource Center link; avoid unrelated metadata changes.
- `app/sitemap.ts` and/or `lib/sitemap-data.ts` — published Resource Center URLs.
- `app/robots.ts` — only if preview/admin resource paths require explicit crawler rules.
- `components/SeoJsonLd.tsx` or a new `lib/resources/structured-data.ts` — Article and BreadcrumbList JSON-LD.
- A new `lib/resources/` directory — types, queries, metadata and content helpers.
- A new `components/resources/` directory — cards, breadcrumbs, article layout and optional ad-slot boundary.
- A new Supabase migration under `supabase/migrations/` — only after the schema is approved and the live schema is inspected.
- New admin Resource Center route/API files under `app/admin/resources/` and `app/api/admin/resources/` — only if editorial management is part of the approved phase.
- `app/legal/privacy/page.tsx` and related consent UI — only in a separately approved advertising/analytics phase, after a privacy review.

## 13. Files and functionality that should remain untouched

The following should remain unchanged in the initial Resource Center phase unless a narrowly scoped integration is explicitly approved:

- `middleware.ts` authentication/session refresh, auth rescue, referral attribution and protected-route behavior.
- `app/auth/callback/route.ts` and all OAuth/email confirmation behavior.
- `app/(auth)/`, password recovery and MFA routes.
- `app/onboarding/` and matching-authorization UI.
- `lib/matching/` and eligibility scoring/explanation logic.
- `app/dashboard/` core student dashboard behavior.
- Scholarship application, saved-scholarship and deadline state flows.
- Existing scholarship/discovery database tables and their RLS policies, except for deliberate, reviewed cross-link additions.
- `app/admin/discovery/` scholarship verification and publication workflow.
- Cron, Inngest and notification worker behavior.
- Supabase service-role handling and secret environment variables.
- Existing public scholarship URL contracts and current JSON-LD semantics.
- Existing CI/deployment commands, unless the new content implementation proves a build issue.

## 14. Dependencies or infrastructure changes that may be necessary

A minimal public Resource Center does not require a new npm dependency. Existing Next.js, React, Tailwind, Zod and Supabase packages are sufficient.

Potential later infrastructure changes, each requiring independent approval, are:

- A Supabase migration for resource articles/categories/tags/revisions and RLS.
- A server-side editorial API or server actions protected by the admin guard.
- Storage for approved article images, with a reviewed public bucket policy and image validation.
- A controlled Markdown/rich-text renderer only if existing primitives are insufficient; choose a maintained, security-reviewed package rather than evaluating arbitrary HTML.
- Analytics/event instrumentation for article views, reviewed for privacy and consent.
- AdSense script, `ads.txt`, consent-management changes and route-scoped ad components in a later monetization phase.
- Optional scheduled publishing or stale-content review reminders, using existing cron/infrastructure only after the editorial model is stable.

No dependency or infrastructure change was executed during this audit.

## 15. Proposed implementation sequence

### Phase 0 — approval and live-state validation

Confirm the desired editorial workflow, content ownership, category taxonomy, author/reviewer model, publication policy, image policy, privacy posture and whether the first release is static/repository-backed or Supabase-backed. Inspect the live Supabase schema and RLS state without mutation. Confirm current Vercel project/environment configuration without exposing secrets.

### Phase 1 — public shell, no publishing mutation

Add `/resources` as a public server-rendered index using a small fixture or approved read-only content source. Add the article route, responsive mobile-first layout, metadata, canonical URLs, breadcrumb/article structured data, sitemap integration and navigation link. Run CI and preview checks before adding editorial writes.

### Phase 2 — approved content model and read path

If a database-backed center is approved, add the separate content migration with RLS, seed only explicitly approved content, add published-only queries and add tests for draft exclusion, slug uniqueness and canonical metadata. Do not alter scholarship or profile tables.

### Phase 3 — editorial administration

Add admin-only article listing/editor/review/publish/archive controls, revision/audit records, validation, preview protection and role/MFA enforcement. Verify that drafts cannot be accessed through public routes or sitemap output.

### Phase 4 — content quality and internal linking

Publish a small set of genuinely useful, original guides. Add source/review metadata, related resources and selective links to verified scholarship detail pages. Validate mobile layout, accessibility, link integrity, search snippets and structured data.

### Phase 5 — optional monetization

Only after content quality, privacy review, consent, ownership verification, ad policy and page experience are ready, add route-scoped ad slots to Resource Center pages. Keep dashboards, discovery, auth, applications and matching ad-free. Monitor layout shift, performance, complaints and policy status.

### Phase 6 — operational maintenance

Establish a review cadence for deadline-sensitive content, source links, author/reviewer accountability, stale-content handling, error monitoring, sitemap freshness and rollback. Treat guides involving dates, eligibility or funding amounts as review-required content, not evergreen copy by default.

## 16. Outstanding questions and unresolved risks

1. Should the first content source be repository-backed static content or Supabase-backed editorial content?
2. Who owns editorial approval, and must every article have a named reviewer?
3. Are authors internal staff, contributors, or user/community members? What profile data may be public?
4. Which categories are required at launch, and is tagging actually needed?
5. Will articles contain user submissions, comments or community content? If so, moderation and abuse controls need a separate design.
6. Should articles link to scholarship records by stable ID, slug, or only by public URL?
7. What is the policy for deadline-sensitive guides after the linked opportunity closes or changes?
8. Which image sources and licenses are acceptable, and will Supabase Storage be used?
9. What analytics are desired, and what consent/retention rules apply to visitors and minors?
10. Is advertising a launch requirement or a later experiment? The audit recommends later.
11. What is the live Supabase schema/RLS state? Migration history alone cannot answer this.
12. What are the current Vercel environment values and deployment status? They were intentionally not inspected as part of this read-only source audit.
13. How will article previews be protected from search indexing and unauthorized sharing?
14. Is there an existing legal/editorial review process for claims about scholarships, financial aid and international education?
15. How will content originality, citations, corrections and AI-assisted drafting be governed?

## 17. Final recommendation

Proceed with an additive public Resource Center inside the existing Next.js application, but do not begin implementation until the editorial and data-model decisions above are approved. The first implementation should be deliberately narrow: public index/article routes, crawler-visible metadata and structured data, published-only content, no changes to authentication/matching/application behavior, no new dependency unless justified, and no advertising until a separate privacy and monetization review is complete.

This report is an independent architecture assessment. It is not a deployment verification, database migration approval, AdSense approval prediction, or authorization to implement Phase 2.
