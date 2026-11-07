# SCHOLARS RESOURCE CENTER — PUBLIC FRONTEND PRE-IMPLEMENTATION VERIFICATION

**Investigation date:** 2026-11-07  
**Repositories:** `ImperioKDB/Scholars`, `ImperioKDB/Updates`  
**Production:** `https://scholars.com.ng`  
**Scope:** Read-only verification and implementation planning. No frontend code, branch, database object, storage object, security setting, content record, or deployment was changed.

## 1. Executive verdict

The public Resource Center frontend is **READY WITH CONDITIONS** for a dedicated implementation branch. The current Scholars `main` branch is clean at commit `cf3682ce35912df7b9b9352193630fc404427c7c` (`feat: add scholarship application details`). The Resource Center foundation landed at `41573f5`, and the three public route files have not changed since that foundation commit. There is no Resource Center-specific branch or open Resource Center pull request. The recommended eventual branch is:

```text
feature/resource-center-public-frontend
```

Do not create that branch during this verification.

The public data boundary is usable without schema changes. Four public projection views exist, the production project grants public SELECT on those views, and their publication predicates exclude drafts, future-scheduled rows, and archived rows. Production currently contains zero Resource Center articles, categories, editorial identities, revisions, and eligible public articles. Therefore the first public implementation must make empty states a primary path, not a test-only fallback.

The principal conditions are image-path semantics, public shell composition, error handling, article rendering capability, SEO completion, and the sitemap scope decision. The database does not currently establish a featured flag, editorial sort field, image bucket, related-content view, or inline-image contract. The implementation must use deterministic publication order and explicit, documented image conventions rather than inventing fields or prototype content.

The editorial dashboard, editor, publishing, approval, review, revision, and write paths remain **BLOCKED** by the separate security review. The owner-context versus `security_invoker=true` view decision is outside this frontend task and must not be altered here.

## 2. Repository state

### Verified current state

The current default branch is `main`. The local checkout is clean and synchronized with `origin/main`:

- Current `main` head: `cf3682c` / `cf3682ce35912df7b9b9352193630fc404427c7c`.
- Commit: `feat: add scholarship application details`.
- Current Resource Center route files last changed in `41573f5` / `feat: add resource center foundation`.
- Changes after the foundation are unrelated scholarship application work in `app/scholarship/[slug]/page.tsx` and `lib/public-application*`.
- No Resource Center-specific remote branch exists.
- No open pull request targets Resource Center work.
- The working tree is clean.

The open pull requests currently visible on GitHub are unrelated conversion, dependency, and scholarship work. The eventual implementation should branch from the latest reviewed `main` only after confirming that `main` has not advanced again.

### Existing Resource Center implementation

Verified route files:

- `app/resources/page.tsx`
- `app/resources/category/[slug]/page.tsx`
- `app/resources/[slug]/page.tsx`

There is no `app/resources/layout.tsx`, `loading.tsx`, or route-specific `error.tsx`. The routes therefore inherit the root layout and global CSS. They do not currently render the shared `Footer`, despite `components/Footer.tsx` existing and being used on the main homepage. There is no Resource Center masthead or mobile navigation component.

The homepage currently queries up to 50 articles ordered by `published_at DESC` and up to 30 active categories ordered by `display_order ASC`. The category route reads up to 50 article-category links and then up to 50 matching articles. The article route reads one article and up to 20 category links. These are bounded, but the category route uses a two-step `IN` query and has no pagination or deterministic tie-breaker.

The current routes match the baseline at a foundation level, but not the accepted production design. They provide a basic hero, category chips, card grid, article header, author sidebar, and empty copy. They do not yet provide the approved editorial shell, featured image, reading progress, table of contents, related articles, Scholars CTA, footer integration, visual motion composition, or complete responsive interaction model.

### CI and local verification

GitHub Actions `ci` for `cf3682c` completed successfully. The workflow runs `npx tsc --noEmit`, `npm test`, and `npm run build` with placeholder public Supabase variables [14]. The local checkout did not contain `node_modules`, so local `npm test`, `npx tsc --noEmit`, and `npm run build` could not start; each stopped with the expected missing-command error (`vitest`/`next` not found). This is an environment limitation, not a source failure. The implementation phase must run the full commands after dependencies are installed.

Live checks performed without mutation:

- `https://scholars.com.ng/resources` returned HTTP 200 HTML.
- `https://scholars.com.ng/sitemap.xml` returned HTTP 200 XML.
- `https://scholars.com.ng/resources/category/uncategorized` returned HTTP 404, which is correct for a nonexistent category.
- With zero production Resource Center rows, the sitemap currently contains no Resource Center article entries. It also does not include `/resources` or category URLs, as detailed below.

## 3. Existing implementation assessment

| Area | Verified state | Classification |
|---|---|---|
| Public route patterns | All three required route patterns exist in App Router | READY WITH CONDITIONS |
| Public projection reads | Routes query `resource_public_*` views through the server Supabase client | READY |
| Publication filtering | Views filter to active identities/categories and published, time-eligible articles | READY WITH CONDITIONS |
| Resource Center shell | No route-specific shell, masthead, mobile navigation, or footer integration | READY WITH CONDITIONS |
| Typography | Local Fraunces and Manrope are loaded in `app/layout.tsx` | READY |
| Design tokens | Parchment, navy, emerald, amber, rose, hairline, font aliases, and motion variables exist | READY |
| Article body | Existing lightweight markdown block renderer supports headings and unordered lists only | READY WITH CONDITIONS |
| Article images | No featured or inline image rendering exists | BLOCKED FOR IMAGE ROLLOUT |
| Author avatars | Field is selected but not rendered; existing avatar helper is for user profile URLs | READY WITH CONDITIONS |
| Error handling | Supabase errors are ignored; missing data becomes empty content or `notFound()` | READY WITH CONDITIONS |
| Metadata | Homepage/category/article metadata is partial; Article JSON-LD exists without BreadcrumbList | READY WITH CONDITIONS |
| Sitemap | Published articles are read; homepage/categories are omitted | READY WITH CONDITIONS |
| Motion | Existing native-scroll and reduced-motion foundation is reusable | READY |
| CMS/dashboard | No approved implementation in this phase | BLOCKED |

## 4. Verified public data contract

The production Supabase project is `scholarship-platform` (`cmdglabohpttgfofcmqc`). Read-only inspection verified the four public views and their exact information-schema columns. View columns are reported nullable by PostgreSQL because view output nullability is not inferred as the base-table constraint; the underlying base constraints are noted where relevant.

### `resource_public_articles`

| Column | Type | View nullable | Meaning and source |
|---|---|---:|---|
| `id` | `uuid` | YES | Base article primary key; base table `NOT NULL` |
| `slug` | `text` | YES | Base article unique slug; base table `NOT NULL` and lowercase-hyphen check |
| `title` | `text` | YES | Base title; base table `NOT NULL`, 1–220 characters |
| `excerpt` | `text` | YES | Optional base excerpt, max 500 characters |
| `content_markdown` | `text` | YES | Base markdown body, default empty, max 500,000 characters |
| `article_type` | `text` | YES | Base enum-like check: `guide`, `news`, `deadline`, or `opportunity` |
| `canonical_url` | `text` | YES | Optional HTTPS canonical URL |
| `featured_image_path` | `text` | YES | Optional path-like text; no bucket is encoded in the view |
| `reading_time_minutes` | `integer` | YES | Optional 1–240 minute read time |
| `published_at` | `timestamptz` | YES | Required by the published status check in the base table |
| `last_reviewed_at` | `timestamptz` | YES | Optional review timestamp |
| `author_name` | `text` | YES | Active joined editorial identity `display_name` |
| `author_bio` | `text` | YES | Active joined identity `bio`, optional |
| `author_avatar_path` | `text` | YES | Active joined identity `avatar_path`, optional |

Relationships: the view joins `resource_articles.author_identity_id` to an active `resource_editorial_identities` row. It does not include category data. Category relationships require the separate article-category view.

Existing filters, verified in `20261107130100_resource_center_schema.sql` and the live security clarification:

- `a.status = 'published'`.
- `a.published_at IS NOT NULL`.
- `a.published_at <= now()`.
- The joined author identity must be active.
- Draft, in-review, scheduled, archived, future-dated, and inactive-author rows are excluded.

### `resource_public_categories`

| Column | Type | View nullable | Meaning and source |
|---|---|---:|---|
| `id` | `uuid` | YES | Base category primary key |
| `slug` | `text` | YES | Base unique lowercase-hyphen slug |
| `name` | `text` | YES | Base category name, 1–100 characters |
| `description` | `text` | YES | Optional description, max 500 characters |
| `display_order` | `integer` | YES | Base non-negative ordering value |

The view filters `is_active = true`. It does not filter out categories with zero published articles. The frontend must decide whether empty active categories are navigable and indexable; the current route can render an empty state for a valid active category.

### `resource_public_editorial_identities`

| Column | Type | View nullable | Meaning and source |
|---|---|---:|---|
| `id` | `uuid` | YES | Identity primary key |
| `display_name` | `text` | YES | Base required display name |
| `bio` | `text` | YES | Optional biography, max 1,000 characters |
| `avatar_path` | `text` | YES | Optional path-like avatar reference |

The view filters `is_active = true`. Public article rows use the joined author fields rather than querying this view separately. No user email, auth ID, or private author field is exposed.

### `resource_public_article_categories`

| Column | Type | View nullable | Meaning |
|---|---|---:|---|
| `article_id` | `uuid` | YES | Article relationship key |
| `category_id` | `uuid` | YES | Category relationship key |
| `slug` | `text` | YES | Active category slug |
| `name` | `text` | YES | Active category name |
| `description` | `text` | YES | Active category description |
| `display_order` | `integer` | YES | Active category display order |

Relationships: this view joins `resource_article_categories` to active categories and published, time-eligible articles. It is safe for public related-category navigation, but it does not provide article title, excerpt, or read time. Related-article cards therefore require a second bounded article query or a future approved projection; no new view is proposed in this phase.

### Production state

Read-only production counts are all zero:

- Articles: 0.
- Categories: 0.
- Editorial identities: 0.
- Revisions: 0.
- Publicly eligible articles: 0.
- Featured image paths: 0.
- Author avatar paths: 0.

This means there is currently no production content against which image URL shape, markdown richness, related-article behaviour, or real editorial ordering can be empirically validated.

## 5. Featured-content strategy

No dedicated featured-content field exists in the public contract or base schema. There is no editorial priority, hero flag, or curated sort column. Do not add a migration, hardcode prototype content, or infer featured status from an unsupported article field.

### Exact fallback

Use deterministic publication order:

1. `published_at DESC`.
2. `id ASC` as a stable tie-breaker.

For the homepage, select the first published article as the lead story and the next two or three as the editorial desk/list. For a category, select the first article in that category by the same order as the featured fallback, then show the remaining bounded list. If there are no rows, render the approved empty state. If `published_at` ties, the UUID tie-breaker is deterministic but not editorially meaningful; the implementation should not claim that it is curated.

This strategy is **READY WITH CONDITIONS** because it requires no schema change but should be reflected explicitly in query ordering and copy. If the editorial team later needs manual curation, that is a future schema/product decision outside this phase.

## 6. Image URL and storage strategy

### Verified storage state

Read-only Supabase inspection found exactly two relevant public buckets:

- `avatars`: public, currently containing user avatar objects under UUID-based paths such as `<user-id>/avatar`.
- `site`: public, 5 MB limit, restricted MIME types `image/jpeg`, `image/png`, and `image/webp`, currently containing `testimonials/<uuid>.jpg` objects.

No Resource Center image object exists. No Resource Center-specific bucket exists. No article or identity row currently supplies a path. The current source tree has no Resource Center image resolver, no `next/image` usage for these fields, and no `images.remotePatterns` configuration in `next.config.js`. Existing code uses `supabase.storage.from("site").getPublicUrl(path)` for testimonials and `supabase.storage.from("avatars").getPublicUrl(path)` for user avatars.

### Exact recommended convention

This recommendation requires owner confirmation before frontend implementation because the existing schema stores only a path and does not store a bucket identifier:

1. **Featured images:** treat `featured_image_path` as a relative object path in the existing public `site` bucket, under a reserved `resource-center/featured/` prefix. Resolve with `supabase.storage.from("site").getPublicUrl(path).data.publicUrl`. Do not make the browser call a private signed-URL path.
2. **Author avatars:** treat `author_avatar_path` as a relative object path in the existing public `avatars` bucket only if the editorial identity contract intentionally reuses that bucket. Otherwise keep the avatar omitted until a bucket/path convention is approved. Do not assume an editorial identity avatar is a student profile avatar merely because both fields are named `avatar_path`.
3. **Complete URLs:** do not silently accept arbitrary remote URLs. If backward compatibility requires existing absolute HTTPS values, allow only the configured Scholars/Supabase origin after validation; reject or omit other hosts. The current contract does not establish that complete URLs are stored.
4. **Inline article images:** no inline image contract is currently supported. `ResourceArticleBody` does not parse Markdown image syntax or links into rich content. Do not promise inline images in the first implementation. If later approved, use the same public `site/resource-center/inline/` convention and an allowlisted Markdown renderer; do not render arbitrary HTML.
5. **Missing images:** render a deliberate editorial placeholder or omit the media region. Never show a broken image, invent a stock image, or use a prototype image.
6. **Dimensions and cropping:** featured media should reserve a stable 3:2 or 16:10 box on cards and a 3:2 or 16:9 box on article pages, use responsive width, `object-fit: cover`, and a safe default focal position. Author avatars should use a square box with `object-fit: cover`. Exact image dimensions should be enforced by the publishing/content contract later, not by a database change in this phase.

### Classification

Image rollout is **BLOCKED UNTIL THE PATH CONVENTION IS CONFIRMED**, not because public storage permissions are missing. The smallest safe resolution is a documented bucket/path contract and a small pure URL resolver in the eventual feature branch; do not create a bucket, change permissions, upload files, or alter the schema as part of this frontend task.

## 7. Sitemap and SEO strategy

### Verified current state

`app/sitemap.ts` defines static paths for `/`, `/about`, `/reviews`, `/scholarships-in-nigeria`, `/opportunities-for-students`, and legal routes. It does not include `/resources`. It calls `readAllResourceRows()` from `lib/sitemap-data.ts`, which selects only `slug,published_at` from `resource_public_articles` in batches of 500. Because the public article view already filters publication eligibility, drafts, scheduled rows, archived rows, future dates, and inactive authors cannot enter the dynamic article list through this path.

The current sitemap does not generate category URLs. It also cannot currently distinguish or filter empty categories because it never reads categories. The production sitemap has no Resource Center entries today because the public article view is empty.

The current article metadata includes title, description, canonical, Open Graph article type, URL, and published time. It emits `Article` JSON-LD with headline, description, canonical main entity, publication date, modification date, author name, and publisher. It does not include image metadata, `dateModified` in Open Graph, or `BreadcrumbList` JSON-LD. `Breadcrumbs` renders accessible visible navigation but does not emit structured data.

The category page has title, description, and canonical metadata. The category canonical is relative and relies on `metadataBase`; the article canonical uses an absolute base URL. The implementation should standardise this to the configured canonical `www` host. The homepage has static metadata but no Resource Center JSON-LD.

### Exact recommended sitemap strategy

1. Add `/resources` as a static indexable route.
2. Read active categories from `resource_public_categories` and join/filter against `resource_public_article_categories` so only active categories with at least one currently published article are indexable in the first release. This avoids creating permanent thin/empty search surfaces while preserving valid empty category pages for direct links.
3. Include one route per published article from `resource_public_articles`, using the stored canonical URL only for page metadata; sitemap URLs should remain the Scholars route `/resources/{slug}` unless an explicit canonical-domain decision says otherwise.
4. Exclude drafts, in-review, scheduled, archived, future-dated, inactive-author, and unpublished rows. The public projections already enforce the article portion of this rule; category eligibility must be derived from the filtered article-category projection.
5. Include `lastModified` from `last_reviewed_at` when available, otherwise `published_at`, after the sitemap data helper exposes that approved field. Do not use `updated_at` because it is not in the public article view.
6. Use the canonical production host `https://www.scholars.com.ng` consistently, matching the existing root metadata and SEO remediation convention.
7. Keep sitemap queries bounded and batched. Do not change code during this verification.

Sitemap correction is **READY WITH CONDITIONS** and requires a small frontend/SEO code change only; it does not require a database migration or security change.

## 8. Reusable component and design foundation inventory

### Reuse unchanged or nearly unchanged

- `app/layout.tsx`: reuse local Fraunces and Manrope loading and root metadata base. The Resource Center should add route-specific metadata rather than replacing the root brand.
- `tailwind.config.ts`: reuse navy, parchment, emerald, amber, rose, hairline, display/sans font aliases, and existing radius/shadow tokens.
- `app/globals.css`: reuse visible emerald focus treatment, 44px form controls, native `scroll-behavior: auto`, button press feedback, and reduced-motion gates.
- `app/motion.css`: reuse the existing `ScrollReveal` transition values and avoid adding a scrolling dependency.
- `components/Logo.tsx`: reuse unchanged for the Resource Center masthead and footer link.
- `components/Footer.tsx`: reuse the existing footer structure, but refine its route links and layout only if the accepted editorial footer requires it. The current component is product-oriented and does not include Resource Center category groups.
- `components/SeoJsonLd.tsx`: reuse the safe JSON-LD escaping helper. Extend composition with a separate breadcrumb data object; do not put breadcrumb data into the Article object incorrectly.
- `components/ScrollReveal.tsx`: reuse for a small number of meaningful sections. It is SSR-visible by default, uses IntersectionObserver, and disables enhancement under reduced motion.
- `components/ShareButton.tsx`: do not reuse unchanged for Resource Center. Its current contract is scholarship/opportunity-specific and awards share XP. Create a separate low-impact article share action or a neutral abstraction only if needed; do not send article shares to scholarship XP endpoints.
- `components/ResourceArticleBody.tsx`: reuse only as a starting point. It needs refinement for safe inline links, heading IDs/TOC extraction, blockquotes, ordered lists, and the approved reading measure. Do not render arbitrary HTML.
- `components/SeoJsonLd.tsx` `Breadcrumbs`: reuse visible breadcrumb rendering, but add structured BreadcrumbList separately.

### New or refined components justified by the accepted design

- `ResourceMasthead` and `ResourceMobileNav`: no current Resource Center shell exists.
- `EditorialEyebrow`, `FieldGuideLabel`, `FeaturedStory`, `EditorialDesk`, `SubjectNav`, `ResourceCard`, and `GuideCard`: the current routes use inline markup and generic rounded cards; the approved editorial composition needs reusable primitives.
- `OpportunityBridge`: no existing public Resource Center-to-Scholars editorial CTA exists.
- `ResourceArticleHeader`, `ReadingProgress`, `ArticleTableOfContents`, `AuthorBio`, and `RelatedArticles`: none exists with the required article reading behaviour.
- `FeaturedImage`: no current Resource Center image renderer or path resolver exists.
- `ResourceEmptyState` and `ResourceErrorState`: current empty states are inline and errors are silently ignored.

Do not create a CMS editor, dashboard shell, approval control, bookmark persistence, newsletter form, or new dependency in this phase.

## 9. Identified technical risks

1. **Image path ambiguity:** the schema stores a path but not a bucket; no Resource Center object exists to validate the intended format. This is the main pre-coding blocker for media.
2. **Silent fetch failures:** all three route implementations ignore Supabase errors. A failed query can look like a legitimate empty state. The implementation must distinguish empty data from read failure without exposing internal details.
3. **Markdown limitations:** the current renderer treats content as blocks, supports only basic headings and unordered lists, and does not safely render links, ordered lists, blockquotes, images, or heading IDs. It cannot support the full prototype article experience unchanged.
4. **No related-content contract:** the article-category view has category identity but no article title fields. Related content requires bounded additional reads and deduplication.
5. **No curated featured flag:** publication order is the only safe fallback. Do not label the first article “editor’s selection” unless product language accepts deterministic newest-first selection.
6. **Metadata incompleteness:** no BreadcrumbList JSON-LD, article image metadata, or category structured data is currently emitted.
7. **Sitemap gap:** `/resources` and category URLs are omitted. Empty-category indexability needs an explicit decision.
8. **Root layout integration:** no Resource-specific layout means no local shell, loading, or error boundary. The implementation must avoid changing unrelated global authentication or monitoring behaviour.
9. **Unbounded UX assumptions:** the current 50-row limits are safe bounds but not pagination. A growing library will need a bounded pagination decision before content volume exceeds the first page.
10. **Security model dependency:** public routes must keep using projections while the owner-context versus invoker-context decision remains separate and unresolved. Do not weaken or reinterpret the existing boundary.
11. **No production content:** visual QA must use a safe non-production fixture or approved preview mechanism. Do not seed production and do not treat the `serena` project as staging without owner confirmation.
12. **Mobile overflow:** future shell/navigation and chip lists are the most likely causes of the previously observed 390px overflow. Fixed-width controls, unbounded label rows, grid children without `min-width: 0`, and modal widths must be avoided at source.

## 10. Recommended implementation architecture

Use a route-local Resource Center presentation layer over the existing server-side projection reads:

```text
app/resources/
  layout.tsx                 optional shell boundary after review
  page.tsx                   homepage composition
  category/[slug]/page.tsx   category composition
  [slug]/page.tsx            article composition
components/resource-center/
  ResourceMasthead.tsx
  ResourceMobileNav.tsx
  ResourceCard.tsx
  FeaturedStory.tsx
  SubjectNav.tsx
  ResourceArticleHeader.tsx
  ResourceArticleBody.tsx    refined safe renderer or composed existing renderer
  ReadingProgress.tsx
  ArticleTableOfContents.tsx
  RelatedArticles.tsx
  ResourceEmptyState.tsx
  ResourceErrorState.tsx
lib/resource-center/
  image-url.ts               pure allowlisted public URL resolver
  queries.ts                 typed bounded view reads, if duplication warrants it
  markdown.ts                safe parsing/heading extraction, if needed
```

This is an architecture recommendation, not code authorization. Keep server components for page data and metadata. Use client components only for mobile navigation, progress, TOC disclosure, share feedback, and scroll reveal. Keep all public reads on `createClient()`/anon-backed projection access; never import `service.ts` into public routes. Do not add a markdown or animation dependency until a concrete capability gap is demonstrated against the current renderer and dependency policy.

### Error and empty-state contract

Each query should return data plus a handled error path. A zero-row result is an editorial empty state. A Supabase/network error is a safe read-failure state with no internal error details and a retry or return-to-Resource-Center path. A missing article/category slug remains a 404. Do not convert query errors into false “coming soon” claims.

## 11. Ordered public implementation plan

### Phase 0 — branch and contract gate

1. Confirm latest `main`, clean working tree, and no relevant unmerged changes.
2. Create the eventual branch `feature/resource-center-public-frontend` only after explicit implementation authorization; do not create it during this verification.
3. Confirm the image path convention: featured images in public `site/resource-center/featured/`; editorial avatars either an approved `avatars` convention or omitted.
4. Record the sitemap decision: index `/resources`, articles, and non-empty active categories; keep empty categories direct-linkable but non-indexed if that remains the decision.
5. Confirm the canonical host and whether any article `canonical_url` may intentionally point off-site.

### Phase 1 — shared shell

1. Add a Resource Center masthead with Logo, desktop nav, Scholars CTA, and mobile disclosure.
2. Use existing tokens and fonts; do not add a brand or heavy animation dependency.
3. Integrate a footer with verified Resource Center and Scholars links.
4. Add semantic landmarks, visible focus, touch-sized controls, and local overflow fixes.
5. Add route-level loading/error boundaries only where their behaviour is understood and does not alter auth.

### Phase 2 — homepage `/resources`

1. Preserve the parchment/navy editorial composition and introduce the hero framing.
2. Select the featured story as newest-first by `published_at DESC, id ASC`.
3. Build the editorial desk from the next bounded rows.
4. Render active categories ordered by `display_order, slug`; link to actual category slugs.
5. Render the practical guide/latest sections from real article rows only.
6. Add OpportunityBridge to a verified public Scholars route.
7. Make the zero-row state explicit and truthful.
8. Add responsive and reduced-motion checks before moving on.

### Phase 3 — category `/resources/category/[slug]`

1. Load the active category and its description.
2. Read the category’s published article IDs through the public article-category view.
3. Fetch article cards with actual slugs, deterministic ordering, and a bounded limit.
4. Use first-row newest-first as the featured fallback.
5. Add related category navigation from active categories, not prototype labels.
6. Decide and implement bounded pagination only if real content volume requires it; preserve crawlable links.
7. Render a truthful empty category state.

### Phase 4 — article `/resources/[slug]`

1. Load the article through the public projection and preserve 404 for no row.
2. Add category-aware breadcrumb and metadata.
3. Resolve approved featured image paths through the pure public URL strategy; use a missing-image fallback.
4. Refine the safe markdown renderer for headings, IDs, links, lists, blockquotes, and body measure. Keep inline images out until their contract is approved.
5. Add a TOC only for articles with a useful heading count; use a mobile disclosure and desktop side rail.
6. Add non-obstructive reading progress with reduced-motion-safe behaviour.
7. Add neutral article share interaction; do not call scholarship share XP endpoints.
8. Add author information and bounded related articles using actual slugs.
9. Add end-of-article Scholars CTA.

### Phase 5 — SEO, accessibility, performance, and visual QA

1. Add complete canonical/Open Graph/article metadata and BreadcrumbList JSON-LD.
2. Correct sitemap scope without changing database/security objects.
3. Run the full visual checklist at all required widths.
4. Test empty, error, missing-image, long-title, long-link, long-article, and no-TOC fixtures.
5. Test keyboard, focus, mobile navigation, reduced motion, and native scrolling.
6. Measure body line length, overflow, LCP, CLS, and INP on a production-like build.
7. Stop before any CMS/dashboard/editor work.

## 12. Testing strategy

### Automatable in repository CI

- `npx tsc --noEmit`.
- `npm test` and new route/query unit tests.
- `npm run build`.
- Query-selection tests verifying public projection names and bounded limits.
- Featured fallback tests verifying `published_at DESC, id ASC`.
- Slug-link tests verifying every article card uses `/resources/{actualSlug}`.
- Error/empty-state tests distinguishing a zero-row result from a Supabase error.
- Image URL resolver tests for approved relative paths, allowed absolute URLs, traversal-like paths, and missing values.
- Markdown renderer tests for safe links, heading IDs, lists, blockquotes, unsupported HTML, and inline image omission.
- Metadata tests for canonical URL, Article fields, BreadcrumbList parity, and absence of draft data.
- Sitemap tests for `/resources`, non-empty active categories, published articles, and exclusion of drafts/future/archived content.
- Route and response tests for valid pages, missing slugs, and safe error states.

### Browser-based visual and interaction verification

Use the accepted checklist as the release baseline [3]. Browser verification is required for:

- Screenshots at 320, 360, 375, 390, 414, 430, 768, 1024, 1280, and 1440px.
- `document.documentElement.scrollWidth <= document.documentElement.clientWidth` at every width.
- Mobile navigation open/close, Escape, focus return, and touch behaviour.
- Focus visibility and keyboard order.
- Reduced-motion rendering and absence of blocked interactions.
- Native anchor navigation and TOC sticky offset.
- Featured-image cropping, missing-image fallback, and layout stability under throttled network.
- Article body reading measure and long-content scroll continuity.
- Metadata/JSON-LD inspection in rendered HTML.
- Lighthouse/Web Vitals targets: LCP under 2.5s, CLS under 0.1, and INP under 200ms on representative mobile conditions.
- Live route and sitemap checks after deployment authorization; deployment is not part of this assignment.

A green build alone is not completion. The public phase is incomplete until the browser-based visual, accessibility, responsive, metadata, and overflow checks pass.

## 13. Explicit security and architecture boundaries

The eventual frontend must:

- Read public content only from `resource_public_articles`, `resource_public_categories`, `resource_public_editorial_identities`, and `resource_public_article_categories`.
- Keep all public reads server-side or through the anon-safe public client; never query protected base tables from anonymous browser code.
- Never expose service-role credentials or import the service client into public routes.
- Preserve fixed publication predicates and do not expose drafts, scheduled, archived, future-dated, or inactive-author content.
- Avoid changes to existing auth, MFA, middleware, scholarship matching, eligibility, and authorization behaviour.
- Make no migrations, table/view/function/grant/RLS changes, bucket changes, storage-policy changes, or production content writes.
- Implement no CMS authoring, approval, review, scheduling, publishing, archive, revision restore, bookmark persistence, newsletter subscription, AdSense, or dashboard write functionality.
- Leave the owner-context versus `security_invoker` decision to the separate security review.
- Stop after the public implementation plan and independent review until explicit implementation authorization is provided.

## 14. Outstanding decisions

1. Confirm the image contract: `site` bucket for featured images under `resource-center/featured/`, and whether editorial avatars may use `avatars`.
2. Confirm whether any stored `canonical_url` can point away from the Scholars route and how that should affect sitemap URLs.
3. Confirm the sitemap policy for empty active categories; this report recommends excluding them from the indexable sitemap while leaving valid pages available.
4. Confirm whether “newest-first lead story” is acceptable as the featured fallback until manual curation exists.
5. Confirm the permitted Markdown feature set, especially inline links, blockquotes, ordered lists, and images.
6. Confirm whether the first public release needs related articles; the current contract requires additional bounded reads.
7. Confirm whether the existing product footer should be reused unchanged or receive a Resource Center-specific editorial link group.
8. Provide a safe non-production content fixture for browser visual QA; do not use production seeding and do not assume `serena` is staging.
9. Resolve the separate owner-context versus invoker-context security review before CMS work, not as part of this frontend phase.

## 15. Readiness classification

| Major area | Classification | Reason |
|---|---|---|
| Route foundation | READY | Required public routes exist and are live. |
| Public data reads | READY | Exact public projections exist and current routes use them. |
| Empty-state-first launch | READY WITH CONDITIONS | Production is empty; explicit states must be designed and tested. |
| Featured-content strategy | READY WITH CONDITIONS | Newest-first deterministic fallback works without schema changes. |
| Image URL strategy | BLOCKED UNTIL PATH CONTRACT | Public buckets exist, but Resource Center path/bucket semantics and image rendering are absent. |
| Author avatar strategy | READY WITH CONDITIONS | Public `avatars` exists, but editorial identity ownership/bucket semantics are unconfirmed. |
| Shared Resource Center shell | READY WITH CONDITIONS | Existing brand foundations are reusable; shell and mobile nav must be built. |
| Article rendering | READY WITH CONDITIONS | Existing renderer is safe as a base but too limited for the approved reading experience. |
| Related articles | READY WITH CONDITIONS | Requires bounded second reads and deduplication; no new schema is required. |
| Sitemap correction | READY WITH CONDITIONS | Small route/data-helper change required; no migration/security change. |
| Metadata and structured data | READY WITH CONDITIONS | Existing Article metadata is partial; BreadcrumbList/image/category coverage remains. |
| Responsive/accessibility QA | READY WITH CONDITIONS | Global foundations exist; route-specific interaction and overflow QA remains. |
| Performance | READY WITH CONDITIONS | Server reads are bounded but image and content rendering need measurement. |
| CMS dashboard/editor | BLOCKED | Security review and workflow authorization are outstanding. |
| Database/security/storage changes | NOT REQUIRED IN THIS PHASE | Explicitly outside the public frontend task. |
| Production deployment | NOT REQUIRED IN THIS PHASE | Explicitly prohibited until independent review and authorization. |

## References

[1]: https://github.com/ImperioKDB/Scholars/tree/main/app/resources "Current Resource Center route directory"
[2]: https://github.com/ImperioKDB/Scholars/blob/main/supabase/migrations/20261107130100_resource_center_schema.sql "Resource Center schema and public projection definitions"
[3]: https://github.com/ImperioKDB/Updates/blob/main/SCHOLARS_RESOURCE_CENTER_VISUAL_ACCEPTANCE_CHECKLIST_2026-11-07.md "Accepted Resource Center visual acceptance checklist"
[4]: https://github.com/ImperioKDB/Updates/blob/main/SCHOLARS_RESOURCE_CENTER_DESIGN_SYSTEM_AND_PRODUCTION_IMPLEMENTATION_SPEC_2026-11-07.md "Accepted Resource Center design specification"
[5]: https://github.com/ImperioKDB/Updates/blob/main/SCHOLARS_RESOURCE_CENTER_COMPONENT_AND_INTERACTION_INVENTORY_2026-11-07.md "Accepted Resource Center component inventory"
[6]: https://github.com/ImperioKDB/Updates/blob/main/SCHOLARS_RESOURCE_CENTER_FRONTEND_IMPLEMENTATION_READINESS_2026-11-07.md "Accepted Resource Center readiness assessment"
[7]: https://github.com/ImperioKDB/Updates/blob/main/SCHOLARS_RESOURCE_CENTER_POST_DEPLOYMENT_SECURITY_CLARIFICATION_2026-11-07.md "Resource Center post-deployment security clarification"
[8]: https://github.com/ImperioKDB/Scholars/blob/main/app/resources/page.tsx "Current Resource Center homepage route"
[9]: https://github.com/ImperioKDB/Scholars/blob/main/app/resources/category/%5Bslug%5D/page.tsx "Current Resource Center category route"
[10]: https://github.com/ImperioKDB/Scholars/blob/main/app/resources/%5Bslug%5D/page.tsx "Current Resource Center article route"
[11]: https://github.com/ImperioKDB/Scholars/blob/main/components/ResourceArticleBody.tsx "Current Resource Center article renderer"
[12]: https://github.com/ImperioKDB/Scholars/blob/main/components/SeoJsonLd.tsx "Current JSON-LD and breadcrumb helper"
[13]: https://github.com/ImperioKDB/Scholars/blob/main/app/sitemap.ts "Current sitemap route"
[14]: https://github.com/ImperioKDB/Scholars/blob/main/.github/workflows/ci.yml "Current CI workflow"
[15]: https://github.com/ImperioKDB/Scholars/blob/main/supabase/migrations/0013_add_site_assets_bucket.sql "Existing public site storage bucket convention"
[16]: https://github.com/ImperioKDB/Scholars/blob/main/supabase/migrations/0010_add_profile_avatars.sql "Existing public avatar storage bucket convention"
