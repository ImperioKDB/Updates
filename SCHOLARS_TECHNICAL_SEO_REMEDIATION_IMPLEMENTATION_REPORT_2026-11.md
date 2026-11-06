# Scholars Technical SEO Remediation Implementation Report

**Implementation date:** 2026-11-06  
**Source repository:** https://github.com/ImperioKDB/Scholars  
**Implementation branch:** `seo/remediation-2026-11`  
**Commit:** `828df42` — `feat: implement approved technical SEO remediation`  
**Pull request link:** https://github.com/ImperioKDB/Scholars/pull/new/seo/remediation-2026-11  
**Production deployment:** Not performed, per the approval gate.

## 1. Executive summary

The approved technical SEO improvements were implemented on a dedicated branch and pushed to GitHub. The implementation preserves the existing architecture, authentication boundaries, active-listing behavior, visual design, and Supabase schema. Verified closed scholarships and opportunities now remain publicly accessible as historical detail pages with HTTP 200 and visible “Applications closed” messaging, while expired records remain excluded from active collection feeds.

The sitemap now reads verified public records in 500-row batches instead of silently stopping at 1,000 rows. It includes verified public detail URLs, including closed pages that remain useful, uses canonical host construction, validates database errors through a logged failure path, and excludes protected application routes by construction. Scholarship and opportunity collection pages now use deterministic, crawlable pagination. The public reviews page uses the same bounded pagination approach. Detail-page breadcrumbs now link to the relevant public collections, and the homepage/footer now expose canonical collection links rather than directing public discovery to the protected `/discover` route.

No Supabase migration, record mutation, status change, RLS change, storage change, authentication change, Vercel configuration change, or production deployment was performed.

## 2. Files modified

- `app/sitemap.ts`
- `app/scholarship/[slug]/page.tsx`
- `app/opportunity/[slug]/page.tsx`
- `app/s/[id]/page.tsx`
- `app/page.tsx`
- `app/scholarships-in-nigeria/page.tsx`
- `app/opportunities-for-students/page.tsx`
- `app/reviews/page.tsx`
- `components/Footer.tsx`
- `lib/public-pagination.ts`
- `lib/public-pagination.test.ts`

## 3. Exact changes made

### Closed-content lifecycle

The public scholarship detail query now loads verified records by slug or UUID without filtering them out solely because `deadline` or `last_cycle_closed_at` has passed. The public opportunity detail query now loads verified records without filtering them out solely because `deadline` has passed. The legacy `/s/[id]` scholarship resolver likewise preserves verified closed records and redirects them to their canonical slug.

The detail templates use the existing `isClosedListing` helper. When a record is closed, the page displays a visible “Applications closed” notice and keeps the original deadline and available historical information. Opportunity application links use historical-detail wording when closed, and the tracking call to action changes to a save/history-oriented message. Active homepage and collection queries retain their existing deadline and cycle filters, so closed records are not presented as active opportunities.

No reopening date, replacement opportunity, rating, eligibility fact, award, or other missing content was invented.

### Sitemap scalability and accuracy

`app/sitemap.ts` now reads verified rows in 500-record batches with deterministic `updated_at` and `id` ordering. It requires a non-null slug, includes all verified public scholarship levels supported by the existing schema, and keeps canonical `www` URL construction. Closed detail pages are included because the approved lifecycle makes verified historical pages publicly accessible; protected plural routes are not selected.

Supabase query errors are logged and cause sitemap generation to fail rather than silently returning an incomplete dynamic sitemap. The output continues to use Next.js `MetadataRoute.Sitemap`, so XML serialization remains framework-managed.

### Collection pagination

`app/scholarships-in-nigeria/page.tsx` and `app/opportunities-for-students/page.tsx` now:

- Use a shared page size of 24.
- Use `count: "exact"` and deterministic ordering.
- Use range-based reads for distinct pages.
- Preserve current verification, level, deadline, and cycle filters.
- Render ordinary HTML Previous/Next links.
- Add page-specific titles and canonical URLs.
- Mark subsequent pages `noindex, follow` while keeping them crawlable, avoiding unnecessary thin indexable surfaces.
- Keep JSON-LD item positions aligned with the page offset.

The scholarship collection remains an undergraduate-focused collection because that is its visible title and existing product intent. The sitemap now covers verified postgraduate records without inventing a separate postgraduate landing page.

### Reviews query safety

`app/reviews/page.tsx` now bounds the testimonials query to the shared page size, preserves the approved-and-consented filters, uses deterministic ordering, and renders crawlable pagination when additional reviews exist. Page 1 remains the primary indexable canonical; subsequent pages are self-canonicalized and marked `noindex, follow`.

### Internal linking and breadcrumbs

Visible scholarship breadcrumbs now link to `/scholarships-in-nigeria`. Visible opportunity breadcrumbs now link to `/opportunities-for-students`. These destinations match the existing JSON-LD breadcrumb hierarchy and are canonical public routes.

The homepage’s “Browse all active scholarships” link now points to `/scholarships-in-nigeria` instead of the protected `/discover` route. The public footer now links to the scholarship collection, opportunity collection, and reviews page using ordinary canonical HTML links.

### Robots, authentication, and legacy routes

`app/robots.ts` was intentionally left unchanged. Protected plural `/scholarships/` and `/opportunities/` routes remain disallowed and protected by middleware. Public singular detail routes remain crawlable. No protected route was added to the sitemap.

The legacy scholarship resolver continues to return a genuine not-found response for missing or unverified records and permanently redirects valid verified IDs to canonical slugs. The opportunity legacy route remains unchanged because it already resolves verified records without the expired-deadline filter.

### Metadata and canonical behavior

Collection metadata now reflects page numbers when a page query is present. Page 1 retains the primary collection canonical; later pages use their page URL as canonical and are `noindex, follow`. Public detail metadata continues to use the preferred `www` host and canonical slug URLs. Structured-data breadcrumbs now agree with the visible breadcrumb destinations.

## 4. Database changes

None.

The existing schema was inspected through Supabase before implementation. The needed lifecycle fields already exist:

- `public.scholarships.deadline`
- `public.scholarships.last_cycle_closed_at`
- `public.opportunities.deadline`
- `public.opportunities.deadline_passed_at`

No production rows, statuses, enums, tables, policies, indexes, buckets, or records were changed. No migration was created or applied.

## 5. Tests performed and results

### Unit tests

`npm test` passed:

- 16 test files passed.
- 66 tests passed.
- New coverage was added for page parsing, offsets, crawlable page links, and closed-listing decisions.

### TypeScript

`npx tsc --noEmit` passed after correcting the dynamic Supabase sitemap batch cast.

### Production build

`npm run build` passed with sandbox-only public Supabase environment values and `NEXT_PUBLIC_APP_URL=https://www.scholars.com.ng`.

The build completed compilation, lint/type validity checks, page-data collection, static generation of 95 pages, trace collection, and optimization. Existing warnings were emitted for the edge runtime and fail-closed Redis behavior in routes that are unrelated to this change; they did not fail the build.

### Local runtime smoke tests

The built app was started locally and the following were checked:

- Homepage: HTTP 200 with preferred canonical metadata.
- Sitemap: valid XML, 93 URLs, no protected plural route, and no duplicate URL observed.
- Robots: preferred canonical sitemap declaration and protected-route restrictions preserved.
- Scholarship collection page 1 and page 2: HTTP 200, deterministic pagination, and no duplicate records between pages. Current data has fewer than 25 active scholarship records, so page 2 is correctly empty.
- Opportunity collection page 1 and page 2: HTTP 200 with distinct records and crawlable links.
- Reviews page 1 and page 2: HTTP 200 with page-specific metadata behavior.
- Closed UBA Foundation opportunity: HTTP 200 with visible closed status.
- Closed National Youth Pension Literacy opportunity: HTTP 200 with visible closed status.
- Closed MTN scholarship: HTTP 200 with visible closed status.
- Expired legacy scholarship UUID: HTTP 200 redirect to the canonical slug, with visible closed status at the final page.
- Valid legacy scholarship UUID: HTTP 200 redirect to the canonical slug.
- Protected plural scholarship route: redirected to login with the intended `next` parameter.
- Every URL in the local sitemap: HTTP 200, with zero redirect or 404 destinations.

### Lint

A standalone `npm run lint` was not run to completion because this repository does not currently contain an ESLint configuration and Next.js opened an interactive configuration prompt. The prompt was cancelled rather than creating an unapproved project configuration. The successful `next build` completed its own lint/type validity stage.

## 6. Implementation status

### Implemented and tested

- Closed verified scholarship detail pages remain public and visibly marked closed.
- Closed verified opportunity detail pages remain public and visibly marked closed.
- Valid legacy scholarship IDs preserve canonical redirects after closure.
- Active collection filters continue to exclude expired records.
- Sitemap reads are batched beyond the previous 1,000-row ceiling.
- Sitemap includes verified postgraduate scholarship records where their public slugs exist.
- Sitemap query errors are logged and not silently swallowed.
- Scholarship and opportunity collection pagination is deterministic and crawlable.
- Reviews pagination is bounded and preserves consent filters.
- Visible detail breadcrumbs link to canonical collections.
- Homepage and footer expose public collection links.
- Robots and protected-route behavior remain unchanged.
- Unit tests, TypeScript, production build, and local route acceptance checks pass.

### Implemented but not fully externally tested

- Google Search Console recrawl and indexation outcomes cannot be tested before deployment.
- Vercel production deployment behavior and environment values were not changed or verified from this branch.
- Field Core Web Vitals and mobile usability were not measured with Lighthouse, CrUX, or PageSpeed.
- The sitemap’s more-than-1,000-row behavior is implemented by batching but was not tested against a production-sized fixture exceeding 1,000 rows.

### Not implemented

- No new postgraduate landing page was created.
- No new database lifecycle field was added.
- No slug migration was performed for `aaaaaaaa` suffixes.
- No query-string redirect or stripping policy was added for `?SD` or `?SA`.
- No robots restriction was removed.
- No production deployment or merge was performed.

### Requires separate approval

- Merging the branch into the production branch.
- Deploying the branch to Vercel production.
- Creating a separate postgraduate SEO landing page.
- Any future migration to distinguish recurring, permanently discontinued, and historically useful records with explicit database status fields.

## 7. Remaining issues and known limitations

The sitemap currently includes every verified row with a non-null slug because the schema has no explicit public lifecycle classification beyond dates and verification. This is safe for the current small inventory and current verified public-row policy, but a future lifecycle field may be appropriate if permanently discontinued or low-quality rows need distinct treatment.

The category pagination intentionally marks pages after page 1 `noindex, follow` to avoid producing many thin indexable pages. This makes all records crawlable through HTML links without treating every pagination page as a permanent search landing page.

The local build emitted existing fail-closed Redis warnings for unrelated admin and monitoring routes. These did not affect the SEO routes or build result.

## 8. Deployment instructions

Do not deploy automatically from this task. Review the branch and merge it through the project’s normal GitHub/Vercel workflow only after approval.

Recommended sequence:

1. Review branch `seo/remediation-2026-11` and commit `828df42`.
2. Open and review the pull request at https://github.com/ImperioKDB/Scholars/pull/new/seo/remediation-2026-11.
3. Confirm the Vercel preview build has the expected Supabase public environment variables and preferred app URL.
4. Run the post-deployment verification checklist below against the preview first.
5. Merge only after preview verification and explicit approval.
6. After production deployment, recheck canonical, sitemap, robots, closed pages, legacy IDs, protected routes, and page-2 metadata.
7. Request GSC validation or inspect the property only after the production deployment is confirmed healthy.

## 9. Post-deployment verification checklist

- Confirm `https://www.scholars.com.ng/sitemap.xml` returns valid XML and includes the expected closed and postgraduate detail URLs.
- Confirm sitemap URLs use only the preferred `https://www.scholars.com.ng` host.
- Confirm no sitemap URL redirects or returns 404.
- Confirm `/robots.txt` still disallows protected plural routes and declares the canonical sitemap.
- Confirm the MTN scholarship URL returns 200 and visibly says “Applications closed.”
- Confirm the two expired opportunity URLs return 200 and visibly say “Applications closed.”
- Confirm the three legacy scholarship IDs resolve only to verified canonical slugs and do not redirect to the homepage.
- Confirm `/scholarships-in-nigeria?page=2` and `/opportunities-for-students?page=2` are ordinary HTML-linked pages with distinct records where data exists.
- Confirm page 2 metadata is `noindex, follow` with deliberate page canonical behavior.
- Confirm `/reviews?page=2` is bounded and does not expose unapproved or non-consented reviews.
- Confirm visible breadcrumbs point to `/scholarships-in-nigeria` and `/opportunities-for-students`.
- Confirm the homepage/footer link to public collections and not `/discover` for public discovery.
- Confirm protected `/scholarships/<uuid>` routes still redirect unauthenticated users to login.
- Confirm Open Graph image endpoints remain `image/png` and are not added to the sitemap.
- Confirm the Vercel build and runtime logs show no new errors.

## 10. Deployment gate

Implementation is complete on the dedicated branch and has been pushed to GitHub. Production has not been merged or deployed. The next action requires explicit approval to merge and deploy.
