# Scholars Resource Center — Public Frontend Implementation Report

**Repository:** `ImperioKDB/Scholars`  
**Documentation repository:** `ImperioKDB/Updates`  
**Report date:** 2026-11-08  
**Scope:** Public Resource Center frontend and narrowly scoped independent-review corrections only

## 1. Original implementation summary

The original implementation added the public Resource Center frontend on the existing Next.js App Router application. It introduced a responsive Resource Center homepage, category route, article route, reusable presentation components, mobile navigation, article reading progress, table of contents, sharing interaction, safe Markdown rendering, public-projection data helpers, image-path validation, metadata, JSON-LD, breadcrumbs, related articles, and sitemap coverage.

The implementation preserved the existing editorial design language and used only the approved public Supabase projection views for public Resource Center data.

## 2. Original implementation commit

- **Commit:** `44ce8a94df59afb0eec45479352344b464d4a853`
- **Message:** `feat: build public resource center frontend`
- **Branch:** `feature/resource-center-public-frontend`

## 3. Corrective patch commit

- **Commit:** `9ed721d3b9b492fcc5db7eabda16c91dc0478a81`
- **Message:** `fix: correct Resource Center review findings`
- **Branch:** `feature/resource-center-public-frontend`
- **Branch URL:** https://github.com/ImperioKDB/Scholars/tree/feature/resource-center-public-frontend

The correction was committed on the existing branch. No reset, force-push, merge, squash, replacement branch, or production deployment was performed.

## 4. Files changed by the corrective patch

- `app/resources/[slug]/page.tsx`
- `app/resources/category/[slug]/page.tsx`
- `app/resources/page.test.ts`
- `app/resources/page.tsx`
- `components/ResourceArticleBody.test.tsx`
- `components/ResourceArticleBody.tsx`
- `components/resource-center-interactions.tsx`
- `components/resource-center.test.tsx`
- `components/resource-center.tsx`
- `lib/resource-center.test.ts`
- `lib/resource-center.ts`

## 5. Corrective changes: before / after / why

| Area | Before | After | Why |
|---|---|---|---|
| Heading IDs | Renderer looked up IDs by `level:text`, so repeated headings could reuse the last ID for every occurrence. | Heading IDs are assigned once in document order and the renderer consumes the same heading sequence. Duplicate headings receive deterministic suffixes across the entire article. | Ensures unique HTML IDs, working table-of-contents anchors, and consistent accessibility references. |
| Canonical URLs | Any HTTPS URL on the configured Scholars hostname was accepted, including unrelated routes. | Only `https://www.scholars.com.ng/resources/{current-slug}` is accepted. Query strings, fragments, alternate paths, external hosts, protocol-relative URLs, credentials, ports, malformed values, and other article slugs fall back to the exact current article route. A trailing slash is normalized. | Prevents canonical metadata from silently pointing at another route or article. |
| Category counts and listing | Category links were limited to 100 records and the rendered count was the number retrieved. | Uses an exact public-projection count and bounded range pagination in 100-record batches. All eligible public IDs are collected without silent truncation, deduplicated, fetched in bounded article batches, and deterministically sorted. | Prevents misleading totals and incomplete category listings over 100 articles without a schema change. |
| Homepage latest section | “View all” linked back to `/resources`, the same homepage route. | The circular link was removed until a genuine all-articles listing exists. | Removes a misleading/nonfunctional action without introducing unnecessary scope. |
| Featured and hero images | All Resource Center images used lazy loading. | Featured homepage and article hero images use eager/high-priority loading; below-the-fold cards remain lazy. Approved image-prefix validation and fallback geometry remain intact. | Improves above-the-fold loading while preserving layout stability and safe image boundaries. |
| Markdown blocks | Heading/paragraph boundaries depended on blank lines, and the renderer did not have regression coverage for several adjacent block forms. | A line-based safe Markdown subset preserves headings followed immediately by paragraphs, consecutive lists, mixed list types, blockquotes, emphasis, and validated links. No unrestricted HTML rendering was added. | Fixes content-shape regressions without weakening link safety or introducing arbitrary HTML. |
| Related articles | A bounded group of category links was truncated before article-date sorting, potentially excluding newer relevant articles. | Candidate IDs are read in bounded pages, shared-category frequency is counted, current article and duplicates are excluded, and candidates are ranked by shared-category count, publication date, and ID. | Improves relevance under the existing public projection contract without a migration or private-table read. |

## 6. Duplicate-heading correction

`extractArticleHeadings` now creates deterministic IDs by slugifying each heading and suffixing every repeated occurrence (`same-heading`, `same-heading-2`, `same-heading-3`, and so on). The renderer no longer reconstructs IDs from a map keyed by heading text. It consumes the extracted heading list in exact document order, so H2/H3 combinations, punctuation, and empty headings remain aligned with the table of contents.

Regression coverage renders actual article content containing duplicate H2s, duplicate H3s, identical H2/H3 text, punctuation, an empty heading, and a paragraph immediately following a heading. Tests assert that every rendered ID is unique and every table-of-contents link targets a rendered heading.

## 7. Canonical URL correction

Canonical output is now owned by the current article slug. A stored value is accepted only when it is HTTPS, uses the exact approved hostname `www.scholars.com.ng`, has the exact `/resources/{slug}` path after trailing-slash normalization, and has no query, fragment, credentials, or non-default port. Invalid stored values resolve to the exact Scholars-owned article URL generated from the current slug.

Tests cover the correct route, trailing slash normalization, external hostname, non-HTTPS URL, wrong Scholars path, different article slug, query string, fragment, malformed input, protocol-relative input, and null input.

## 8. Category-count correction

The implementation reads `resource_public_article_categories` with an exact count and also pages through the same public projection in bounded 100-record ranges. It then fetches `resource_public_articles` in bounded batches and sorts the complete eligible set deterministically by publication date and ID. No migration, view, database function, RLS policy, or security-policy change was made.

Tests cover zero, one, exactly 100, and more than 100 articles, duplicate prevention across page boundaries, public projection table usage, and query failure handling.

## 9. Homepage navigation correction

The latest-articles heading no longer renders the circular `View all` link to `/resources`. The homepage still retains valid Resource Center, category, article, and first-party navigation links. A regression test confirms that the removed circular action is not present.

## 10. Featured-image loading correction

`ResourceImage` now accepts a placement-aware `priority` flag. Featured homepage cards and article hero images use `loading="eager"` and `fetchPriority="high"`; ordinary cards use lazy loading. Missing or invalid images render the existing visual fallback. The path validator still requires the `resource-center/featured/` prefix and rejects traversal, backslashes, and remote-path forms. Decorative fallback content remains `aria-hidden`, and real image alt text is meaningful for featured/hero placements.

## 11. Markdown renderer regression tests

The renderer remains a safe semantic subset and does not use unrestricted HTML or arbitrary `dangerouslySetInnerHTML`. Tests cover:

- Headings followed by paragraphs without blank lines.
- Consecutive unordered and ordered lists.
- Mixed ordered and unordered list blocks.
- Blockquotes.
- Emphasis and strong text.
- Valid internal links.
- Valid HTTPS external links.
- Unsafe protocols such as `javascript:` and `data:`.
- Protocol-relative and malformed links.
- Duplicate and empty heading text.

## 12. Related-article selection

Related candidates are collected through the approved `resource_public_article_categories` projection only. The current article is excluded, candidate IDs are deduplicated through a frequency map, shared-category count is preferred, publication date is the next deterministic criterion, and ID is the final tie-breaker. The final display remains bounded to three cards. No private base table is read and no database object was added.

## 13. Data-access architecture

All public Resource Center reads continue to use:

- `resource_public_articles`
- `resource_public_categories`
- `resource_public_article_categories`

The helper fails closed with `ResourceDataError` on public-read failures rather than presenting a false empty state. Category and related reads use bounded range/chunk operations. No direct anonymous base-table access was introduced.

## 14. Image path validation

Public image URLs are generated only after `isApprovedResourceImagePath` accepts a path beginning with `resource-center/featured/` and rejects traversal, backslashes, repeated slash path forms, null values, and remote URLs. The storage bucket and permissions were not changed.

## 15. Sitemap and SEO behavior

The original implementation’s Resource Center sitemap and SEO behavior remains in place. The homepage, category, and article routes provide route metadata, canonical URLs, Open Graph metadata, JSON-LD where applicable, and breadcrumbs. The corrective patch tightens article canonical validation without changing the sitemap architecture.

## 16. Responsive and accessibility testing

An unauthenticated ephemeral sandbox preview was tested at the requested viewport widths:

`320, 360, 375, 390, 414, 430, 768, 1024, 1280, 1440`

Observed browser facts:

- No horizontal overflow was observed at the tested widths.
- Mobile navigation opened at 390px with `aria-expanded="true"`, exposed the intended first-party links, and returned to `aria-expanded="false"` after Escape.
- The 320px accessibility snapshot exposed a semantic banner, main alert, contentinfo, cookie controls, and no clipped navigation.
- The fallback article snapshot exposed a semantic alert and a working “Back to resources” link.
- Reduced-motion emulation reported `prefers-reduced-motion: reduce` as active and did not introduce overflow.
- Homepage metadata exposed title `Resources for students | Scholars` and canonical `https://www.scholars.com.ng/resources`.
- The final homepage browser check reported zero console errors and zero warnings. Earlier fallback-route checks reported only browser font-preload warnings and no errors.

Because the safe preview used placeholder Supabase public configuration, it rendered the truthful Resource Center loading/error state. There were no published article or category records available in that isolated preview, so visual checks against real published article cards, category listings, article TOC links, hero images, and share interaction could not be performed without fabricating production content. No production fixtures were created.

### Browser screenshot evidence references

The Playwright session captured the following evidence files:

- `qa-homepage-mobile-320.png`
- `qa-homepage-360.png`
- `qa-homepage-375.png`
- `qa-homepage-390.png`
- `qa-homepage-414.png`
- `qa-homepage-430.png`
- `qa-homepage-768.png`
- `qa-homepage-1024.png`
- `qa-homepage-1280.png`
- `qa-homepage-1440.png`
- `qa-homepage-mobile-menu.png`
- `qa-category-mobile-empty-or-error.png`
- `qa-category-desktop-empty-or-error.png`
- `qa-article-desktop-fallback.png`

These are browser-session artifacts from the unauthenticated ephemeral preview, not production screenshots.

## 17. TypeScript, build, lint, and test results

- Focused corrective tests: **16 passed across 4 files**.
- Full automated suite after correction: **101 passed across 22 files**.
- TypeScript: `npm exec tsc -- --noEmit` passed.
- Production build: `npm run build` passed with CI-style placeholder public environment values. Next reported existing edge-runtime/static-generation and fail-closed Redis warnings; the build completed successfully.
- Lint: the repository still has no ESLint configuration. Running `npm run lint` attempts Next’s interactive first-run ESLint setup, so lint was not run and no unrelated ESLint configuration was generated. The production build’s built-in lint/type validity stage completed successfully.

## 18. Preview URL and accessibility

### Unauthenticated review preview

**Public preview URL:** https://3002-ifndjvqh3odf73ajk2g8o-41110972.us3.manus.computer/resources

This is an ephemeral sandbox preview running the validated production build with placeholder public Supabase configuration. It was opened directly in Playwright without a Vercel account or authentication prompt and returned the actual Resource Center error-state page with HTTP 200.

### Vercel preview status

Vercel created a branch deployment for corrective commit `9ed721d`:

- Deployment: `dpl_HuhKwK2GQTpVPATWExwC8M6t621D`
- Branch: `feature/resource-center-public-frontend`
- Commit: `9ed721d3b9b492fcc5db7eabda16c91dc0478a81`
- State at report preparation: `BUILDING`

Project inspection confirmed `ssoProtection.enabled = true` with `deploymentType = all_except_custom_domains`. Therefore the Vercel preview URL is not suitable for unauthenticated independent review. No access-control setting was changed and no bypass was attempted. Making the Vercel preview itself public would require owner action to change the protected project-level SSO setting or provide an approved custom-domain review deployment; that action remains outside this authorization.

## 19. Known limitations

1. The Vercel branch preview remains SSO-protected by the existing project setting.
2. The public review URL is ephemeral and isolated from production data.
3. Real published article/category visual QA, real image loading, article TOC navigation, and share behavior could not be exercised without an authorized data-backed preview or safe non-production fixtures.
4. Lint remains unavailable as a standalone command because the repository has no ESLint configuration and Next requires interactive first-run setup.
5. The corrective patch does not implement a new all-articles route; the misleading circular homepage action was intentionally removed.

## 20. Explicit security and production-change confirmation

The corrective work did **not** change:

- Database schema or migrations.
- Supabase RLS or security policies.
- Supabase storage buckets or permissions.
- Authentication or Vercel access-control settings.
- Environment variables or secrets.
- Service-role access or exposure.
- Production domains or DNS.
- Production deployment or the default branch.
- Production data or content.
- CMS, editorial dashboard, publishing workflow, advertising, or newsletter features.

All public Resource Center data continues to use the approved public projection views.

## Verdict

**READY WITH CONDITIONS**

The corrective patch is pushed, automated checks and production build pass, and an unauthenticated ephemeral preview is available for independent review. Independent review is conditional on accepting the documented limitations: Vercel preview SSO remains enabled, and real published-content visual verification requires an authorized data-backed preview or safe non-production fixtures.
