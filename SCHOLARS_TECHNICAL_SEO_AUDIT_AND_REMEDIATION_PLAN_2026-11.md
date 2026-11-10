# Scholars Technical SEO Audit and Remediation Plan

**Audit date:** 2026-11-06  
**Production site:** https://www.scholars.com.ng  
**Repository audited:** https://github.com/ImperioKDB/Scholars  
**Repository commit inspected:** `aa9c171` (`feat: add Google fallback to OTP verification`)  
**GSC evidence:** November 6, 2026 exports stored in the Updates repository  
**Status:** Investigation and planning only. No production code, database records, or deployment configuration was changed.

## 1. Executive summary

Scholars is currently technically crawlable on its preferred `https://www.scholars.com.ng` host. The live homepage, category pages, reviews page, public detail pages, robots file, and sitemap all returned successfully during this audit. Apex-to-`www`, HTTP-to-HTTPS, and legacy share redirects are operating as designed for valid records. The Linux Foundation LFX Mentorship page, the primary “Crawled — currently not indexed” target, returned HTTP 200, contained server-rendered content, had a unique title and description, exposed a self-referencing canonical URL, returned valid JSON-LD, and appeared in the sitemap. That GSC status is therefore not evidence of a confirmed technical failure.

The most important confirmed issue is not a broad canonical-host failure. It is a public URL lifecycle and discoverability problem: some formerly valid public detail URLs now return 404 because the page query excludes expired or cycle-closed records, while several other GSC URLs are valid and working but were classified as redirects or “discovered — currently not indexed.” The two exact Prince Ukeme Ukpong and Carewave URLs in the supplied GSC export currently redirect once from apex to `www` and then return HTTP 200 at the same canonical slug; they are not redirect errors. The three plural `/scholarships/<uuid>` URLs are intentionally protected application routes, are blocked by robots, and redirect unauthenticated users to login. That exclusion should remain.

The current sitemap contains 57 unique `www` URLs, including the Linux Foundation page and valid current opportunity pages. It excludes the two expired opportunities and the MTN page because the application code filters by deadline and `last_cycle_closed_at`. The sitemap also hard-limits each database query to 1,000 rows and excludes postgraduate-only scholarships. These are policy and scalability risks, not confirmed current indexing failures. The first implementation phase should therefore focus on explicit URL lifecycle policy, stronger internal linking, sitemap pagination and observability, and correction of any stale internal links. No change should be made to robots rules or protected-route behavior without new evidence.

## 2. Scope, evidence, and confidence

This audit used four evidence sources:

1. The current `ImperioKDB/Scholars` repository at commit `aa9c171`, including the requested App Router routes, middleware, metadata, sitemap, robots, configuration, public Supabase helper, and structured-data helper.
2. The live production HTTP responses and initial HTML for the supplied URLs, checked on 2026-11-06. Redirects were tested both without following them and with a follow-redirect request.
3. Read-only Supabase queries against the connected `scholarship-platform` project (`cmdglabohpttgfofcmqc`) to verify the named records, their slugs, verification state, deadlines, and cycle-closure state. No write query was executed.
4. The supplied November 6 GSC exports in the Updates repository. The placeholder crawl dates of `1970-01-01` were treated as export artifacts, not crawl events.

“Confirmed” below means supported by current code, live behavior, or a read-only database result. “Probable” means a risk inferred from code or URL behavior that needs product or operational confirmation. “Unverified” means the available evidence is insufficient, such as Google’s final indexing decision, Core Web Vitals, or Vercel domain settings.

## 3. Verified findings

### Confirmed positives

- `https://www.scholars.com.ng/` returns HTTP 200 and has a canonical URL on the preferred host.
- `https://scholars.com.ng/`, `http://www.scholars.com.ng/`, and `http://scholars.com.ng/` resolve to the preferred HTTPS `www` host. The apex-to-`www` and HTTP-to-HTTPS behavior is a single 308 at the host layer for the tested homepage variants.
- `robots.txt` is served as `text/plain`, allows `/`, disallows authentication, dashboard, API, and protected application prefixes, and declares the `www` sitemap.
- `sitemap.xml` is served as XML, contains 57 unique URLs, and contains no non-`www` URLs or duplicate `<loc>` values in the current response.
- The Linux Foundation LFX Mentorship detail page returns 200, has meaningful server-rendered text, a unique title, a unique description, a self-canonical URL, JSON-LD, and a sitemap entry.
- The tested Open Graph image endpoints return HTTP 200 with `image/png`. They are image resources, not ordinary HTML landing pages, and should not be forced into the web index.
- Valid legacy scholarship ID `/s/4c469077-cd38-424c-8913-463c7068d304` redirects to `/scholarship/ejiro-m-ukiri-international-scholarship-fund-4c469077`, which returns 200 with the canonical detail URL.
- The three plural `/scholarships/<uuid>` targets are protected by both middleware and robots rules. They are not present in the public sitemap.
- The current public detail templates use server-side data access through the anonymous Supabase client. The initial HTML contains the page title, key facts, description where present, links, and JSON-LD.

### Confirmed issues or behavior requiring a planned decision

- The sitemap queries scholarships with `.in("level", ["undergrad", "both"])`, so postgraduate-only records are excluded even though the public detail template supports `postgrad`.
- The sitemap limits scholarships and opportunities to 1,000 rows per query. The current response is below that ceiling, but the implementation will silently omit eligible pages when a table grows beyond it.
- The sitemap filters out records whose deadline is before the current date and scholarships whose `last_cycle_closed_at` is not after the current date. This removes expired or cycle-closed pages from the sitemap and also makes the public detail pages return 404 because their data queries use the same eligibility filters.
- The MTN record exists, is verified, and has the exact old slug from the GSC target, but its `last_cycle_closed_at` is `2026-05-31`. The current date is 2026-11-06, so the public query intentionally excludes it and the URL returns 404. This is a URL-lifecycle policy issue, not evidence that the record is missing.
- The two expired opportunity records in the GSC discovered list also exist and are verified, but their deadlines are 2026-10-23 and 2026-10-20. They are excluded by the public opportunity query and return 404. The D-Prize, Dalai Lama, ARSO, and other currently open or rolling records return 200.
- The detail-page breadcrumb UI links the intermediate “Scholarship” and “Opportunity” breadcrumb items to `/` rather than to `/scholarships-in-nigeria` and `/opportunities-for-students`. The JSON-LD breadcrumb points to the category paths, so the visible and structured breadcrumb trails are inconsistent and internal discovery is weaker than intended.
- The public reviews query has no explicit limit or pagination. This is not a confirmed indexing failure, but it is an avoidable growth/performance risk for a public route.
- The local `npm run build` could not complete without the repository’s required environment variables. The failures were `supabaseUrl is required` / `Your project's URL and API key are required` while prerendering data-backed routes. This is an environment limitation in the audit sandbox, not evidence that the deployed Vercel build is failing; production routes were live and serving successfully.

### Probable or unverified issues

- Google may be choosing not to index some thin or recently discovered pages despite their technical eligibility. This cannot be diagnosed as a code defect from the supplied GSC status alone.
- The live HTML was inspected for accessibility and metadata, but no Lighthouse, CrUX, PageSpeed Insights, or field Core Web Vitals measurement was available. No Core Web Vitals problem is claimed.
- Vercel domain configuration was not directly inspected through an authenticated Vercel project connection. The observed host behavior is consistent with the preferred host, but the dashboard-level domain configuration remains unverified.
- The exact value of `NEXT_PUBLIC_APP_URL` in Vercel was not exposed or read. Repository fallbacks consistently use `https://www.scholars.com.ng`; production output also uses the `www` host.
- Google’s internal canonical selection, crawl scheduling, and final index decision cannot be guaranteed by HTTP or sitemap checks.

## 4. URL investigation matrix

The GSC status is taken from the supplied November 6 exports. “Current HTTP status” is the status of the supplied URL before following redirects. A final 404 below means the URL reached the canonical host but the page was not eligible under the current public query.

| URL | GSC status | Current HTTP status | Final destination | Canonical | Finding | Recommended action | Priority |
|---|---|---:|---|---|---|---|---|
| `https://www.scholars.com.ng/` | Page with redirect | 200 | Same URL | `https://www.scholars.com.ng` | GSC source URL is already canonical and live; export classification is stale or based on an earlier variant. | Leave unchanged; revalidate in GSC. | P2 |
| `http://www.scholars.com.ng/` | Page with redirect | 308 | `https://www.scholars.com.ng/` | `https://www.scholars.com.ng` | Correct HTTP-to-HTTPS redirect. | Leave unchanged. | P2 |
| `http://scholars.com.ng/` | Page with redirect | 308 | `https://www.scholars.com.ng/` via apex then `www` | `https://www.scholars.com.ng` | Correct host and protocol consolidation; one host redirect is expected. | Leave unchanged; monitor chain length. | P2 |
| `https://scholars.com.ng/` | Page with redirect | 308 | `https://www.scholars.com.ng/` | `https://www.scholars.com.ng` | Correct apex-to-`www` redirect. | Leave unchanged. | P2 |
| `https://www.scholars.com.ng/opportunity/linux-foundation-lfx-mentorship-fa021582` | Crawled — currently not indexed | 200 | Same URL | Self-canonical | Confirmed useful, rendered, metadata-complete, JSON-LD-bearing page; no technical blocker found. | Improve related links and verify again; do not force indexing. | P2 |
| `https://www.scholars.com.ng/opportunity/*/opengraph-image` endpoints in GSC | Crawled — currently not indexed | 200 | Same image endpoint | Not applicable | Tested endpoints return `image/png`; these are image resources. | Keep out of sitemap; no indexing action. | P2 |
| `https://scholars.com.ng/?SD` | Crawled — currently not indexed | 308 at apex, then 200 | `https://www.scholars.com.ng/?SD` | `https://www.scholars.com.ng` | Query variant renders the homepage and canonicalizes to root. | Keep canonical consolidation; only strip query strings if campaign semantics no longer need them. | P2 |
| `https://www.scholars.com.ng/?SA` | Crawled — currently not indexed | 200 | Same query URL | `https://www.scholars.com.ng` | Query variant renders the homepage and canonicalizes to root. | Leave unchanged; monitor rather than create redirects. | P2 |
| `http://www.scholars.com.ng/2015/07/important-notice-for-all-2014-batch-c.html` | Not found (404) | 308 | Same path on HTTPS `www`, then 404 | Error-page canonical defaults to homepage; noindex present | No meaningful replacement was identified. This is an appropriate genuine 404 unless historical content is recovered. | Leave 404; optionally add a redirect only if an exact replacement is found. | P2 |
| `https://scholars.com.ng/scholarship/mtn-foundation-science-technology-scholarship-aaaaaaaa` | Not found (404) | 308 | HTTPS `www` same slug, then 404 | Error-page canonical defaults to homepage; noindex present | Record exists and is verified, but `last_cycle_closed_at=2026-05-31`; current public query intentionally excludes it. | Decide whether closed cycles should remain useful public pages. Do not invent a replacement. | P1/P2 |
| `https://scholars.com.ng/scholarship/female-scholars-foundation-university-scholarship-960fdc68` | Alternate page with proper canonical | 308 | Same URL on `www`, 200 | Self-canonical on `www` | Correct consolidation from apex to preferred host; final page is valid. | Leave unchanged; validate final URL, not the redirect source. | P2 |
| `https://scholars.com.ng/legal/terms` | Page with redirect | 200 | Same apex URL in current response; page canonical is `www` | `https://www.scholars.com.ng/legal/terms` | Current live response is valid and canonicalized in HTML. | Leave unchanged; investigate only if GSC continues to report a redirect source. | P2 |
| `https://scholars.com.ng/scholarship/the-icon-scholarship-2026` | Page with redirect | 308 | `https://www.../scholarship/the-icon-scholarship-2026`, 200 | Self-canonical on `www` | Correct host redirect; valid final detail page. | Leave unchanged. | P2 |
| `https://scholars.com.ng/scholarship/prince-ukeme-ukpong-mega-foundation-2026-tertiary-scholarship-e1a3002d` | Page with redirect | 308 | Same slug on `www`, 200 | Self-canonical on `www` | Current exact slug exists, is verified, and resolves successfully. | Leave unchanged; do not redirect the source into another slug. | P2 |
| `https://scholars.com.ng/scholarship/carewave-aspire-scholarship-programme-casp-32c773ba` | Page with redirect | 308 | Same slug on `www`, 200 | Self-canonical on `www` | Current exact slug exists, is verified, and resolves successfully. | Leave unchanged. | P2 |
| `https://scholars.com.ng/opportunities-for-students` | Redirect error | 200 | Same URL, 200 | Self-canonical | No current redirect error reproduced; page is sitemap-listed and rendered. | Revalidate in GSC; inspect only if a fresh live test reproduces failure. | P2 |
| `https://scholars.com.ng/scholarships-in-nigeria` | Redirect error | 200 | Same URL, 200 | Self-canonical | No current redirect error reproduced; page is sitemap-listed and rendered. | Revalidate in GSC. | P2 |
| `https://scholars.com.ng/s/e93e25b7-46a5-4254-b1c5-91ad56a3abf0` | Redirect error | 308 | `https://www.../s/<id>`, then 404 | Error-page canonical defaults to homepage; noindex present | Record exists and is verified but deadline `2026-10-02` has passed; legacy route correctly refuses expired public record. | Keep genuine 404 unless closed historical pages become a defined public product policy. | P2 |
| `https://scholars.com.ng/s/31cfebd0-100f-4b06-9250-52af820d74d4` | Redirect error | 308 | `https://www.../s/<id>`, then 404 | Error-page canonical defaults to homepage; noindex present | Record exists and is verified but deadline `2026-09-30` has passed; legacy route correctly refuses expired public record. | Keep genuine 404 unless a closed-page policy is approved. | P2 |
| `https://scholars.com.ng/s/4c469077-cd38-424c-8913-463c7068d304` | Redirect error | 308 | Canonical scholarship slug, 200 | Self-canonical detail URL | Valid legacy redirect; GSC “redirect error” was not reproduced. | Leave unchanged; revalidate in GSC. | P2 |
| `https://scholars.com.ng/reviews` | Redirect error / Discovered — currently not indexed | 308 | Same URL on `www`, 200 | Self-canonical | Valid page; no redirect error reproduced. Public query is unbounded. | Add a safe display limit or pagination and revalidate. | P1 |
| `https://www.scholars.com.ng/scholarships/de181847-4466-4d56-a0af-a40a7e930c99` | Blocked by robots.txt | 200 after auth redirect | `https://www.scholars.com.ng/login?next=...` | Login/page fallback; protected route | Intentional protected application route, not public scholarship detail. | Keep blocked and out of sitemap. | P2 |
| `https://www.scholars.com.ng/scholarships/64790f70-f20a-4c9c-a1f4-2efabc087dcb` | Blocked by robots.txt | 200 after auth redirect | Login with `next` parameter | Protected route | Intentional protected application route; underlying record is public elsewhere under its slug. | Keep blocked; ensure public slug is the only indexed surface. | P2 |
| `https://www.scholars.com.ng/scholarships/e1a3002d-8e6e-49a8-a685-980160b8dd94` | Blocked by robots.txt | 200 after auth redirect | Login with `next` parameter | Protected route | Intentional protected route; the public record has a separate slug. | Keep blocked and out of internal public links. | P2 |
| `https://www.scholars.com.ng/reviews` | Discovered — currently not indexed | 200 | Same URL | Self-canonical | Valid but not indexed; Google decision, not confirmed technical defect. | Strengthen links from footer/home and keep useful review content. | P2 |
| `https://www.scholars.com.ng/opportunities-for-students` | Discovered — currently not indexed | 200 | Same URL | Self-canonical | Valid category page; no current redirect problem. | Add contextual links from homepage/footer and revalidate. | P2 |
| `https://www.scholars.com.ng/opportunity/innovatex-2026-aaaaaaaa` | Discovered — currently not indexed | 200 | Same URL | Self-canonical | Verified rolling opportunity; valid despite fallback-looking slug suffix. | Do not rename without a slug migration plan; improve internal links. | P2 |
| `https://www.scholars.com.ng/opportunity/unicef-internship-programme` | Discovered — currently not indexed | 200 | Same URL | Self-canonical | Verified rolling opportunity; valid public content. | Improve internal links; no forced index request assumed. | P2 |
| `https://www.scholars.com.ng/scholarship/jg-afrika-bursary-2027-64790f70` | Discovered — currently not indexed | 200 | Same URL | Self-canonical | Verified undergraduate scholarship with no deadline; valid. | Keep slug; add category/related links. | P2 |
| `https://www.scholars.com.ng/opportunity/2027-dalai-lama-fellows-1e81e31e` | Discovered — currently not indexed | 200 | Same URL | Self-canonical | Verified opportunity, deadline 2026-11-11; valid at audit time. | Keep live while eligible; update lifecycle after deadline. | P2 |
| `https://www.scholars.com.ng/opportunity/14th-continental-essay-competition-arso` | Discovered — currently not indexed | 200 | Same URL | Self-canonical | Verified opportunity, deadline 2027-04-23; valid. | Improve internal links and metadata if needed. | P2 |
| `https://www.scholars.com.ng/opportunity/aspire-leaders-program-cohort-4-2026` | Discovered — currently not indexed | 200 | Same URL | Self-canonical | Verified rolling opportunity; valid. | Improve internal links; no slug change solely for SEO. | P2 |
| `https://www.scholars.com.ng/opportunity/zindi-data-science-competitions-aaaaaaaa` | Discovered — currently not indexed | 200 | Same URL | Self-canonical | Verified rolling opportunity; `aaaaaaaa` suffix is a fallback-looking but currently referenced slug. | Preserve until a controlled slug migration is approved. | P2 |
| `https://www.scholars.com.ng/opportunity/d-prize-global-competition-2026-6efe042f` | Discovered — currently not indexed | 200 | Same URL | Self-canonical | Verified opportunity, deadline 2026-11-15; valid at audit time. | Keep live through eligibility window; update after closure. | P2 |
| `https://www.scholars.com.ng/opportunity/aiesec-global-talent-internships-aaaaaaaa` | Discovered — currently not indexed | 200 | Same URL | Self-canonical | Verified rolling opportunity; fallback-looking suffix should not be changed casually. | Preserve and improve internal links. | P2 |
| `https://www.scholars.com.ng/opportunity/uba-foundation-national-essay-competition-2026-900828dc` | Discovered — currently not indexed | 308 from apex source in supplied list; final 404 | Canonical host error page | Error-page canonical defaults to homepage; noindex present | Record exists and is verified but deadline `2026-10-23` passed, so public query returns 404. | Keep 404 unless closed historical pages are approved. | P2 |
| `https://www.scholars.com.ng/opportunity/national-youth-pension-literacy-essay-competition-2026-c2cd644f` | Discovered — currently not indexed | 308 from apex source in supplied list; final 404 | Canonical host error page | Error-page canonical defaults to homepage; noindex present | Record exists and is verified but deadline `2026-10-20` passed, so public query returns 404. | Keep 404 unless closed historical pages are approved. | P2 |
| `https://www.scholars.com.ng/opportunity/3mtt-3-million-technical-talent-fellowship-programme-aaaaaaaa` | Discovered — currently not indexed | 200 | Same URL | Self-canonical | Verified rolling opportunity; valid despite fallback-looking suffix. | Preserve slug; improve internal links. | P2 |

## 5. Repository findings

### `app/robots.ts`

The file allows the site root and disallows `/admin`, `/api`, authenticated application surfaces, and `/scholarships/` and `/opportunities/` plural routes. This matches the middleware’s `PROTECTED_PREFIXES` and is appropriate for the three GSC robots-blocked URLs. The sitemap declaration uses `NEXT_PUBLIC_APP_URL` with a correct `www` fallback. No robots change is proposed in P0 or P1.

The only proposed improvement is an automated test that asserts protected prefixes remain disallowed and public singular routes remain allowed. Removing `/scholarships/` or `/opportunities/` would be unsafe without evidence that public pages use those prefixes.

### `app/sitemap.ts`

The file has seven static public paths and dynamically adds verified, currently open scholarship and opportunity detail URLs. It uses the anonymous public client and revalidates every hour. The current code is correct for the current public-open-page policy, but has four risks:

1. Each dataset is capped at 1,000 rows without pagination.
2. Postgraduate-only scholarships are excluded by the `level` filter.
3. Expired and cycle-closed pages disappear entirely, even when their content might retain historical search value.
4. Supabase errors are not surfaced; a failed query can silently produce a sitemap containing only static routes.

Proposed correction: establish a page-lifecycle policy first, then paginate or batch dynamic sitemap reads, include all publicly indexable levels, filter only on the approved public status, and add observable error handling. Do not add private, duplicate, or redirected routes.

### `app/layout.tsx`

The global `metadataBase` falls back to the preferred `www` host. The global title template, description, Open Graph defaults, Twitter card, and root canonical are coherent. Production HTML confirmed the preferred host. The root layout also mounts several client components on every route; no performance defect was claimed without measurement, but this should be included in Lighthouse testing after implementation.

### `middleware.ts`

The middleware permanently redirects apex and the Vercel preview hostname to the preferred host in production. It bypasses the authentication session lookup for public singular detail and legacy share routes, which is important for crawlability. It protects plural `/scholarships/` and `/opportunities/` application paths and redirects unauthenticated users to login. This behavior is consistent with robots and should remain.

The middleware preserves query strings in canonical-host redirects. That is correct for attribution and campaign parameters. The homepage query variants already canonicalize to the root; no query-stripping change is proposed without confirming the meaning of `SD` and `SA`.

### Public detail templates

`app/scholarship/[slug]/page.tsx` and `app/opportunity/[slug]/page.tsx` fetch verified public rows, render server-side content, generate unique metadata, and output JSON-LD. Scholarship pages include a `WebPage` plus breadcrumb data; opportunity pages do the same. The visible pages expose provider, title, deadline or rolling status, description where present, and application details for opportunities. They do not fabricate ratings, match scores, or unsupported eligibility facts.

The principal risk is lifecycle filtering: a page becomes a 404 when its deadline or cycle closes. That is safe for an application-only product but not necessarily optimal for historical search content. A product decision is required before changing it. The second issue is breadcrumb linking: visible intermediate breadcrumb links currently go to `/`, while structured breadcrumbs use the category pages. The visible links should be corrected in a later approved implementation.

### `app/s/[id]/page.tsx` and `app/o/[id]/page.tsx`

These routes are intentionally thin legacy resolvers. They query a verified public record by UUID and issue a permanent redirect to the canonical slug, or return 404 if the record is not currently eligible. The valid legacy scholarship route behaved correctly. The expired records returned 404 for a defensible reason. No blanket redirect or UUID-to-homepage redirect should be introduced.

### Category pages and reviews

`app/scholarships-in-nigeria/page.tsx` and `app/opportunities-for-students/page.tsx` are server-rendered, canonicalized collection pages with useful explanatory copy and up to 50 current listings. They returned 200 and are included in the sitemap. Their main scaling limitation is the fixed 50-item listing limit without pagination or a “browse all” crawl path.

`app/reviews/page.tsx` is a public, canonicalized page showing consented approved testimonials. It is technically eligible for indexing, but the query has no limit. Add a safe limit or pagination before the review collection grows materially.

### `next.config.js` and `vercel.json`

`next.config.js` configures security headers and does not contain SEO redirects or rewrites. `vercel.json` contains a cron only. The observed host redirects therefore appear to be Vercel domain behavior plus middleware, not a conflicting repository rewrite. Direct Vercel dashboard verification remains outstanding.

### Metadata and structured data

Metadata is generally unique on public pages. The public detail JSON-LD uses `WebPage` and `BreadcrumbList`, which is conservative and avoids fabricated facts. The homepage has no JSON-LD in its current initial HTML; that is not automatically a defect. The 404 response inherits a homepage-like title and canonical while exposing `noindex`; this prevents indexing but is less precise than a dedicated not-found metadata policy. A later cleanup may provide an explicit noindex 404 title and omit a misleading homepage canonical.

## 6. Sitemap and robots assessment

### Keep unchanged

Keep the current disallow rules for authenticated and internal routes. Keep the preferred `www` sitemap declaration. Keep image endpoints out of the sitemap. Keep legacy share routes out of the sitemap because canonical detail URLs are the indexable surfaces. Keep redirects as redirects; do not try to make redirect-source URLs indexable.

### Improve after approval

- Add pagination or cursor-based batching to dynamic sitemap reads so eligible pages cannot disappear after the 1,000-row ceiling.
- Decide whether `postgrad` is part of the public SEO product. If yes, include it in the sitemap and category/internal-link system; if no, document the intentional exclusion.
- Decide whether closed or expired records should be 404, 410, or a useful historical page. Apply the same policy to detail pages, legacy UUID routes, sitemap inclusion, and internal links.
- Validate that every sitemap URL is canonical, returns 200, is not a protected route, and has meaningful public content.
- Surface Supabase query errors through logging or monitoring rather than silently returning a partial sitemap.
- Use meaningful `lastModified` values. `updated_at` is acceptable only if it changes when public content meaningfully changes; otherwise add a public-content timestamp policy.

## 7. Content and indexation assessment

The pages most deserving of indexation are the homepage, the two category pages, the reviews page if it contains a meaningful number of consented reviews, and verified public detail pages with substantial descriptions, provider information, deadlines, application instructions, and current eligibility context. The Linux Foundation page meets the basic technical and content threshold observed here. Its “Crawled — currently not indexed” status should not trigger a forced-indexing workaround.

Pages that should not be forced into the index include Open Graph image endpoints, login and protected application routes, expired pages that contain no useful historical content, duplicate host variants, and query-string variants whose canonical is the homepage.

The most important content-quality risk is not that the templates fabricate facts; they generally avoid that. It is that some records may be sparse, and the current page design can render a short listing with only a title, provider, and deadline. Add provider, eligibility, amount or compensation, application instructions, source link, and last-verified information only when those facts exist in the database. Do not fill missing fields with generated claims.

### Proposed growth landing pages

| Proposed surface | Classification | Search intent and requirements | Recommendation |
|---|---|---|---|
| Scholarships in Nigeria | Permanent indexable category | Broad Nigerian scholarship discovery; requires a consistently populated collection and useful explanatory copy. | Keep `/scholarships-in-nigeria`; improve breadth and pagination. |
| Undergraduate scholarships in Nigeria | Permanent indexable category | Current category already targets this intent; needs stable current listings and clear freshness. | Keep as the current category, not a duplicate variant. |
| Postgraduate scholarships for Nigerians | Permanent indexable category only if data supports it | Requires enough verified postgraduate records and content about eligibility and study level. | Create only after public postgraduate coverage is confirmed. |
| Fully funded scholarships for Nigerian students | Category or curated landing page | Requires a reliable structured field for funding level; cannot be inferred from free text. | Do not create until the data model supports accurate classification. |
| Scholarships by discipline | Filterable experience or curated categories | Useful when each discipline has sufficient unique inventory and copy. | Avoid mass-generated thin filter pages; create only populated curated pages. |
| Scholarships by study level | Category pages | Requires stable level data and differentiated copy. | Consider after the postgraduate policy decision. |
| International scholarships open to Nigerians | Permanent category if nationality eligibility is modeled | Requires verified nationality eligibility, not assumptions from provider location. | Build only with explicit data support. |
| Internships for Nigerian students | Category page | Opportunity records already include type and location; requires enough current records. | Candidate for a curated category after inventory and Nigerian eligibility are verified. |
| Fellowships and competitions | Category page | Supported by opportunity `type`, but must avoid near-empty pages. | Candidate once each type has durable inventory. |
| Technology scholarships and opportunities | Curated category | Requires discipline/type taxonomy quality and enough distinct content. | Candidate after taxonomy cleanup; do not generate automatically from title words. |

## 8. Remediation roadmap

### P0 — Critical technical defects

**No P0 defect was confirmed in this audit.** The live site has a working canonical host, working robots and sitemap endpoints, public 200 pages, and working protected-route boundaries. If a fresh production test reproduces a redirect loop, a public 5xx, a sitemap parse failure, or a protected public page, it should be promoted to P0 immediately.

### P1 — Important technical improvements

#### P1.1 Define and implement the public URL lifecycle policy

- **Problem:** Current public queries make expired and cycle-closed records return 404, including records that still exist and may have historical value.
- **Evidence:** MTN exists and is verified but has `last_cycle_closed_at=2026-05-31`; two legacy IDs and two opportunity URLs exist but are past deadline and return 404.
- **Proposed solution:** Choose one policy: genuine 404/410 after closure; or a useful closed-page 200 with a clear closed state and likely `noindex`; or a durable historical 200 for evergreen content. Apply the policy consistently to detail pages, legacy routes, sitemap, and internal links.
- **Files affected:** `app/scholarship/[slug]/page.tsx`, `app/opportunity/[slug]/page.tsx`, `app/s/[id]/page.tsx`, `app/o/[id]/page.tsx`, `app/sitemap.ts`, category queries.
- **Risk:** Changing 404 behavior may expose stale pages or increase crawl volume.
- **Acceptance criteria:** A test fixture for open, rolling, expired, and cycle-closed records produces the approved status, canonical, robots directive, sitemap inclusion, and internal-link behavior.
- **Database changes needed:** No schema change required for the first implementation; a public lifecycle field may be useful later.

#### P1.2 Make sitemap generation scalable and observable

- **Problem:** Per-table `.limit(1000)` can omit eligible canonical pages; query errors are silently converted to an incomplete sitemap.
- **Evidence:** `app/sitemap.ts` has two hard limits and no error branch; the current sitemap has 57 URLs, so the ceiling is not yet hit.
- **Proposed solution:** Batch reads with a stable ordering and cursor/offset, validate slugs, deduplicate URLs, and log query failures. Add a test that simulates more than 1,000 rows.
- **Files affected:** `app/sitemap.ts`; tests under `app` or `lib`.
- **Risk:** More database reads and a larger sitemap response; must preserve caching and avoid private rows.
- **Acceptance criteria:** All eligible public rows are represented across one or more sitemap documents; no protected or redirected URL appears; a simulated query error is observable.
- **Database changes needed:** No.

#### P1.3 Correct visible breadcrumb internal links

- **Problem:** Visible intermediate breadcrumbs on public detail pages point to `/`, while JSON-LD points to the relevant category page.
- **Evidence:** `app/scholarship/[slug]/page.tsx` and `app/opportunity/[slug]/page.tsx` pass `{ name: "Scholarship", href: "/" }` and `{ name: "Opportunity", href: "/" }`.
- **Proposed solution:** Link the scholarship breadcrumb to `/scholarships-in-nigeria` and the opportunity breadcrumb to `/opportunities-for-students`, or use a deliberately chosen canonical parent.
- **Files affected:** The two detail page files.
- **Risk:** Low; changes visible navigation but not page identity.
- **Acceptance criteria:** Visible and JSON-LD breadcrumb URLs agree; category pages link back to detail pages; no broken links.
- **Database changes needed:** No.

#### P1.4 Bound or paginate public reviews

- **Problem:** The reviews page reads all approved consented testimonials without a limit.
- **Evidence:** `app/reviews/page.tsx` selects and orders rows without `.limit()`.
- **Proposed solution:** Add a safe display limit with pagination or a static “load more” strategy that remains crawlable if more reviews are intended to be indexable.
- **Files affected:** `app/reviews/page.tsx`, possibly `app/reviews/layout.tsx`.
- **Risk:** Pagination could hide reviews from crawlers if implemented only client-side.
- **Acceptance criteria:** Initial HTML remains useful, query size is bounded, and every intended page has stable canonical and links.
- **Database changes needed:** No.

### P2 — Content and indexation improvements

- Add contextual links from the homepage and footer to the two category pages and reviews page without adding thin navigation pages.
- Add related opportunities to public detail pages only from verified, currently public records and only when the relationship is meaningful.
- Decide whether postgraduate-only listings should have a public category and sitemap inclusion.
- Improve content completeness at the data-entry and verification layer. Do not fabricate missing award values, eligibility facts, ratings, or deadlines.
- Consider explicit 404 metadata so not-found pages do not inherit a homepage title/canonical, while preserving `noindex`.
- Revalidate the supplied GSC targets after the P1 fixes. A “discovered” or “crawled” status may remain for a period even after technical quality improves.
- Preserve fallback-looking `aaaaaaaa` slugs until a controlled migration exists. A slug change without old-slug redirects would create avoidable 404s.

### P3 — Longer-term organic growth

- Build only category pages backed by reliable structured fields and enough unique inventory.
- Add explicit taxonomy for study level, funding type, discipline, nationality eligibility, location, and opportunity type if those dimensions are to support permanent landing pages.
- Create a public “closed opportunities” policy only if historical usefulness is demonstrated and the UX clearly distinguishes closed applications.
- Measure organic performance and Core Web Vitals through GSC/CrUX/PageSpeed or equivalent before making performance claims.
- Verify Vercel domain configuration and environment values through the connected deployment account.

## 9. Testing plan

### Canonical consistency

For each public route, request the `www` HTTPS URL and each apex/HTTP variant. Assert that the preferred final URL is `https://www.scholars.com.ng/...`, that one canonical tag exists, that its absolute value matches the final public URL, and that metadata/Open Graph URLs use the same host. Test root query variants and attribution parameters separately.

### Redirect correctness

Run a no-follow request and a follow request for every legacy and host variant. Assert no loops, no more than the approved number of redirects, preservation of the path and required query parameters, and an appropriate final status. Valid public records must finish at 200; intentionally removed records must finish at the approved 404/410 policy.

### Sitemap validity

Fetch `/sitemap.xml`, parse it as XML, assert 200 and an XML content type, assert unique `<loc>` values, assert every URL uses `https://www.scholars.com.ng`, and sample every URL with a HEAD/GET request. Assert no URL is protected, redirected, duplicate, or a non-public image endpoint. Add a fixture with over 1,000 records to prove batching.

### Robots rules

Fetch `/robots.txt`, assert the sitemap declaration uses the preferred host, assert protected prefixes remain disallowed, and assert public singular detail paths are not accidentally disallowed. Test both the textual rules and the effective behavior for the three plural protected URLs.

### Public page accessibility

Fetch the homepage, both category pages, reviews, legal pages, the Linux Foundation page, one scholarship detail page, one opportunity detail page, and one valid legacy share route. Assert 200, meaningful initial HTML, an `h1`, a title, a description, and no authentication redirect.

### Metadata

Assert unique title and description values for the homepage, categories, reviews, and a representative sample of detail pages. Assert canonical, Open Graph URL, Open Graph image, and Twitter metadata all use the preferred host. Confirm 404 pages are `noindex` and do not become sitemap entries.

### Structured data

Extract every `application/ld+json` block, parse it as JSON, verify that URLs and breadcrumb items match visible content, and confirm no unsupported ratings, reviews, salary, award, or eligibility claims are present. Validate the JSON-LD with a schema parser where possible.

### Internal links

Crawl initial HTML from homepage, category pages, footer, reviews, and detail pages. Assert that important public detail URLs are reachable through ordinary `<a href>` links, category links use canonical destinations, visible breadcrumbs match JSON-LD breadcrumbs, and no public HTML links to protected plural routes or stale slugs.

### Protected routes

Request the three plural `/scholarships/<uuid>` paths and representative `/opportunities/<id>` paths without a session. Assert robots disallow them, middleware does not expose protected content, unauthenticated requests redirect to login as designed, and neither sitemap nor public HTML includes them.

### Mobile rendering

Run a mobile viewport render of the homepage, categories, reviews, and detail pages. Check overflow, readable headings, visible primary content without JavaScript interaction, image dimensions, and tap targets. Measure Lighthouse or field metrics before stating any Core Web Vitals conclusion.

### Build and deployment

Run `npm ci` and `npm run build` with the same non-secret environment variable names configured in Vercel. The audit sandbox build failed only because those variables were absent; the next implementation pass must verify the actual connected Vercel deployment and inspect logs if it fails.

## 10. Expected outcomes

After the P1 work, the site should have a documented and consistent policy for open, rolling, expired, and cycle-closed records; a sitemap that does not silently truncate at 1,000 rows; visible breadcrumbs that strengthen category-to-detail discovery; and a bounded reviews page. GSC should stop reporting false redirect concerns once it recrawls the current valid final URLs, but the timing is controlled by Google.

The work cannot guarantee that Google indexes every valid page, that a “crawled — currently not indexed” page becomes indexed, or that rankings and traffic increase. Indexation depends on Google’s quality, duplication, crawl, and canonical systems, as well as the usefulness and uniqueness of each record. The plan also cannot guarantee Core Web Vitals improvements until field or lab measurements are collected.

## 11. Approval checklist

The following changes require explicit approval before implementation:

1. Choosing whether expired and cycle-closed public records remain 404/410 or become useful closed historical pages.
2. Choosing whether postgraduate-only scholarships become public indexable surfaces.
3. Changing the sitemap query policy, including pagination, error handling, `lastModified`, and lifecycle filters.
4. Correcting visible breadcrumb destinations in the two public detail templates.
5. Adding a limit or pagination model to the public reviews page.
6. Adding or changing explicit not-found metadata and canonical behavior.
7. Adding new permanent SEO landing pages or taxonomy-backed category routes.
8. Introducing any schema or database field needed to represent lifecycle, funding type, nationality eligibility, or taxonomy dimensions.
9. Changing slugs containing `aaaaaaaa` or creating old-slug redirects.
10. Changing robots rules, protected prefixes, authentication behavior, Vercel domains, or environment configuration.

## 12. Access and verification limitations

- No Google Search Console API or live property inspection was available; the supplied exports were used as investigation targets and not treated as proof of current failures.
- Vercel domain settings and deployment logs were not directly inspected through an authenticated Vercel connection.
- The local build could not run to completion because the sandbox did not have the repository’s Supabase environment variables. No secrets were copied into this report.
- Core Web Vitals and mobile usability were not measured with Lighthouse, CrUX, or PageSpeed during this investigation.
- Supabase verification was read-only. No records, tables, policies, buckets, or configuration were modified.

## 13. Approval-gated execution order

1. Approve the public lifecycle policy for expired and cycle-closed records.
2. Approve sitemap scalability and postgraduate inclusion decisions.
3. Implement and test sitemap changes without changing robots or protected routes.
4. Correct breadcrumbs and bound the reviews query.
5. Run the complete URL, metadata, structured-data, internal-link, protected-route, mobile, and build test plan with Vercel environment variables.
6. Push the approved implementation to the Scholars repository, verify the Vercel deployment, and only then use GSC validation for the affected URLs.

## References

[1]: https://github.com/ImperioKDB/Scholars "Scholars source repository"
[2]: https://www.scholars.com.ng/ "Scholars production homepage"
[3]: https://www.scholars.com.ng/robots.txt "Scholars production robots file"
[4]: https://www.scholars.com.ng/sitemap.xml "Scholars production sitemap"
[5]: https://www.scholars.com.ng/opportunity/linux-foundation-lfx-mentorship-fa021582 "Linux Foundation LFX Mentorship public page"
[6]: https://www.scholars.com.ng/scholarships-in-nigeria "Scholarships in Nigeria public category"
[7]: https://www.scholars.com.ng/opportunities-for-students "Opportunities for students public category"
[8]: https://www.scholars.com.ng/reviews "Scholars reviews public page"
[9]: https://github.com/ImperioKDB/Updates "Updates repository containing the supplied GSC exports"
