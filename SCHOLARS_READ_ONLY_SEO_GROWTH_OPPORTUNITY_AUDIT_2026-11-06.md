# Scholars — Read-Only SEO Growth Opportunity Audit

**Audit date:** 6 November 2026  
**Mode:** Read-only investigation; no source code, database, deployment, Search Console, analytics, or production settings were changed.

## Executive Summary

**Scholars has completed the core technical cleanup, but its next organic-growth constraint is public acquisition depth rather than crawlability.** The live site exposes 92 unique sitemap URLs: 44 verified scholarship pages, 42 verified opportunity pages, and six static pages, matching the connected database inventory; 24 scholarships and 27 opportunities are active. Public slug detail pages render server-side titles, descriptions, canonicals, breadcrumbs, verification dates, and JSON-LD, while protected dashboard routes remain outside the indexable surface. The clearest missed opportunity is internal: the homepage sends “Browse all active scholarships” to authenticated `/discover`, while the crawlable hub is `/scholarships-in-nigeria`, so Google and visitors are not being led directly from the homepage to the public collection. Current pages are concise and conversion-gated; an active scholarship detail page explains the award and fit but does not expose the provider application route, requirements checklist, or related alternatives. Fresh Search Console, GA4, backlink, and Core Web Vitals data were unavailable, so no current traffic, CTR, ranking, conversion, authority, or performance claim is made. Competitor research shows broad editorial directories and application portals, leaving Scholars a defensible position in verified Nigeria-first structured data, explainable eligibility matching, deadline provenance, and application follow-through.

## Organic Traffic Trend

A current six-month traffic trend cannot be established because the authorized Search Console and analytics data sources were unavailable. The only numeric baseline supplied for context covers approximately 9 October–3 November 2026: 1,863 impressions, 48 clicks, 2.58% CTR, and average position 7.42 globally; Nigeria accounted for 384 impressions, six clicks, 1.56% CTR, and 24 landing pages. Those figures are historical and must not be treated as current performance.

The earlier baseline identified several promising near-winners: Sande Poetry Prize had 87 impressions and zero clicks at average position 5.77; ICON Scholarship had 49 impressions, one click, and average position 10.37; Stories from Nigeria Competition had 39 impressions, one click, and average position 5.74; Linux Foundation LFX Mentorship had 38 impressions and zero clicks at average position 7.32; Amir Fund Medical Scholarship had 31 impressions and three clicks at average position 5.94; and the homepage had 26 impressions and zero clicks at average position 6.69. These pages should be rechecked in a fresh export before any title or content decision is made.

The live inventory has changed since that baseline. The sitemap now contains 44 scholarship URLs and 42 opportunity URLs, including new 2026–2027 listings and public historical pages [2]. The connected database reports 44 verified scholarships, 42 verified opportunities, 24 currently active scholarships, and 27 currently active opportunities. This is evidence of a larger indexable surface, not evidence that Google has indexed or ranked it.

**Required measurement next:** export the latest complete seven-day period, the preceding seven-day period, the latest 28-day period, and a pre-remediation comparison from Search Console for `sc-domain:scholars.com.ng`. Segment by query, page, country, device, and search appearance. In analytics, connect organic landing page to registration start, completed registration, onboarding completion, match view, save, application start, and provider click. Without those joins, organic acquisition and product activation cannot be evaluated together.

## Top Organic Countries

Nigeria is the intended primary market, but current country shares and device splits were not available. The historical snapshot reported Nigeria separately but did not provide a complete current country table or device breakdown. Do not infer that Nigeria is the largest market from the product positioning alone.

The live copy is strongly Nigeria-oriented. The primary public hub is titled “Undergraduate scholarships in Nigeria” and explicitly includes Nigerian deadlines, providers, disciplines, and verified listings [4]. The opportunity hub broadens the audience to Nigeria and beyond and includes fellowships, internships, competitions, mentorship, and training [4]. This gives Scholars a credible local acquisition base while retaining international opportunity coverage.

The country analysis should be completed from Search Console with three page-level cuts: scholarship pages for Nigerian state, institution, and discipline intent; opportunity pages for Nigeria-specific competitions, internships, fellowships, and training; and static hubs for generic discovery. The top three Nigerian landing pages, their page type, top query, clicks, impressions, CTR, average position, and device split are currently **data not provided**.

## Page Type Analysis

The current public page mix is concentrated in individual opportunity detail pages: 44 scholarship URLs and 42 opportunity URLs in the sitemap, plus six static pages [2]. That is a strong inventory base, but it is not yet a complete search architecture. The site has only two principal collection hubs—`/scholarships-in-nigeria` and `/opportunities-for-students`—and no public, crawlable collection pages for state, level, discipline, funding type, or opportunity type.

The most important page-type issue is the homepage-to-collection path. The live homepage contains a “Browse all active scholarships” link that points to `/discover`, while `/discover` is an authenticated product route and is disallowed in `robots.txt` [1] [3]. The public, crawlable scholarship collection is `/scholarships-in-nigeria`. This is not a sitemap failure; it is an internal linking and conversion-path mismatch. A first-time visitor and a crawler should be led from the homepage to the public hub before being asked to create a profile.

The homepage itself has strong product positioning: “eligibility-matched, not keyword-matched,” a clear Nigerian audience, verification language, and a direct free-profile CTA [1]. It contains no JSON-LD in the inspected HTML, while both collection pages and detail pages emit JSON-LD. That is not a critical defect because structured data is not a ranking guarantee, but Organization/WebSite/Breadcrumb markup could make the public entity and navigation clearer if it accurately reflects visible content [12].

## Branded vs Non-Branded Search Terms

**Branded versus non-branded traffic cannot be calculated because current Search Console query data was unavailable.** The supplied historical report did not include a branded/non-branded split.

The observed public SERP landscape shows non-branded intent around “scholarships for Nigerian undergraduates,” “fully funded scholarships for Nigerians,” “internships for Nigerian students,” “fellowships for Nigerians,” and “essay competitions for Nigerian students.” Search results surfaced ScholarshipAir, the Federal Ministry of Education portal, Scholastica, Opportunities for Africans, Opportunity Desk, and other publishers for these themes. These are observed SERP appearances only; they do not establish rank, volume, impressions, or click share.

Scholars’ current public titles are relevant but narrow. “Undergraduate Scholarships in Nigeria” is a defensible head term, and “Student Fellowships, Internships and Opportunities” covers a broad opportunity family [4]. The next growth question is whether those hubs receive non-branded impressions and whether individual pages capture provider-plus-programme intent. Use non-branded clicks and registrations as the primary SEO KPI once data is available; do not use total organic clicks if branded demand dominates.

## Keyword Portfolio

Search volume is unavailable. The following opportunities are based on observed query wording in public SERPs, the historical Search Console snapshot supplied in the brief, and the current public inventory. Competition levels are qualitative and reflect the number and strength of visible competing page types, not a paid keyword-tool score.

| Actual query or query family | Search intent | Current Scholars visibility | Recommended target | Evidence and confidence |
|---|---|---|---|---|
| scholarships for Nigerian undergraduates | Broad active scholarship discovery | `/scholarships-in-nigeria` targets this intent directly | Keep the hub as the canonical target; improve homepage linking and explanatory copy | SERP results show ScholarshipAir, the Federal Ministry portal, and Scholastica. High confidence in intent; volume unavailable. |
| fully funded scholarships for Nigerians | Funding-coverage discovery, usually study-abroad or major award intent | No dedicated public hub observed | A carefully maintained page only if enough verified listings and an explicit funding-coverage taxonomy exist | Multiple public SERPs show ScholarshipAir and editorial guides. Medium confidence; volume unavailable. |
| scholarships without IELTS for Nigerians | Constraint-led international scholarship discovery | No dedicated public page observed | Do not launch until Scholars can verify language-test rules per listing and explain exceptions | SERPs show highly editorial and mixed-quality pages. Medium confidence in intent; high risk of thin or misleading content. |
| postgraduate scholarships for Nigerians | Level-specific discovery | Postgraduate records are present in the sitemap, but no public postgraduate hub was observed | A single postgraduate hub with live verified listings and clear level rules | The remediation added postgraduate sitemap coverage. High confidence in product relevance; demand unavailable. |
| technology scholarships for Nigerian students | Discipline and career-direction discovery | Individual technology-related listings exist; no public technology hub observed | Technology scholarships and fellowships hub, only when enough verified inventory exists | Current opportunity inventory includes technology-related programmes. Medium confidence. |
| internships for Nigerian students | Student opportunity discovery | `/opportunities-for-students` includes internships but has no internship-specific hub | One controlled internship hub with duration, skills, mode, employer, and student stage fields | SERPs surface Opportunities for Africans, Prosple, and IAESTE. High confidence in intent; volume unavailable. |
| fellowships for Nigerians | Fellowship discovery and eligibility research | Fellowship listings are mixed into the opportunity hub | Fellowship hub with applicant stage, geography, funding, and duration filters | SERPs surface Opportunity Desk and Opportunities for Africans. Medium-high confidence. |
| essay competitions for Nigerian students | Time-sensitive competition discovery | Individual competition pages exist; no competition hub observed | Competition hub with age/level, submission format, prize, deadline, and official source | SERPs surface ScholarshipAir and provider pages. High confidence in intent; volume unavailable. |
| state scholarship or bursary + Nigerian state | Local eligibility and bursary intent | Individual state listings exist, but no state landing-page system observed | State-specific hubs only where there is enough recurring, verified supply | Scholars has Oyo and Lagos-related records. High business value; demand unavailable. |
| provider + programme + year | Navigational/application intent | Individual slug pages target this well | Strengthen detail pages with official source, requirements, status, and related alternatives | Historical baseline included named pages such as Sande, ICON, and LFX. High confidence. |

The highest-value portfolio is not a large set of near-identical landing pages. It is a small number of controlled hubs—undergraduate, postgraduate, internships, fellowships, competitions, technology, and selected states—whose pages show real inventory, unique eligibility context, and useful internal links. Empty or auto-generated hubs would create indexable repetition without improving user value.

## SEO Content Analysis

### Landing-page strategy

The public hubs are a good foundation but currently describe the inventory more than they help a student decide. The scholarship hub explains that Scholars verifies listings and compares them against a profile; the opportunity hub explains provider, deadline, location, and compensation [4]. Both should add a short “how to choose” layer: who the page is for, what the status labels mean, how last verification works, how to interpret partial versus full funding, and what the student should do next.

Recommended landing pages, subject to inventory thresholds:

1. **Undergraduate scholarships in Nigeria** — retain `/scholarships-in-nigeria`; primary intent is active Nigerian undergraduate scholarship discovery. Add secondary themes for state, discipline, award coverage, deadline, and official-source verification. Feature current records and link to postgraduate, technology, and relevant state hubs. Original value should be a plain-language comparison of award coverage and eligibility signals.
2. **Student internships in Nigeria** — proposed `/internships-for-students`; target internships for Nigerian students. Use fields for student/graduate stage, skills, duration, paid or stipend status, remote/on-site mode, location, and provider. Link to active internship details and application-readiness guidance.
3. **Fellowships and competitions for Nigerian students** — proposed `/fellowships-competitions-for-students`; use only if the two types can be clearly filtered without creating a vague archive. Separate funding, age/level, geography, submission format, and deadline. Link to related opportunity pages and guides.
4. **Postgraduate scholarships for Nigerians** — proposed `/postgraduate-scholarships-for-nigerians`; include degree level, destination, discipline, funding coverage, language-test conditions, and application stage. Do not claim “fully funded” unless each included record supports that label.
5. **State bursaries and scholarships** — proposed `/scholarships-by-state`; this should be a navigational hub to state pages, not a thin page itself. Launch individual state pages only where recurring verified inventory and clear indigene/residency rules exist.
6. **Technology scholarships and fellowships** — proposed `/technology-scholarships-fellowships`; include discipline and skills, study level, programme format, and whether the benefit is tuition, stipend, training, or mentorship.

“Scholarships without IELTS” should be deferred until the database stores verified language requirements and the editorial process can distinguish “IELTS not required,” “alternative proof accepted,” and “requirement varies by institution.” This query has clear user intent but high misinformation risk.

### Detail-page quality

The public detail templates are honest and technically accessible. An active scholarship page such as the M. Kukoyi Foundation listing shows the provider, award, deadline, level, discipline, last-checked date, an overview, and a profile-based eligibility CTA [5]. A closed Oyo page clearly states that the cycle is closed and retained for historical reference [6]. These are strengths and should not be replaced with automatic noindexing.

The main content weakness is decision depth. The inspected active scholarship page does not expose a required-documents checklist, application steps, official application URL, source citation, related alternatives, or a clear “what is still unknown” panel. The scholarship route’s current implementation selects title, provider, description, amount, deadline, status, level, discipline, and verification date, but not the opportunity-style `application_url` and `how_to_apply` fields [7]. The opportunity detail template is stronger because it can show duration, application instructions, and an official application link [7].

Recommended sustainable standard for every public detail page:

- verified title, provider, type, level, discipline, location, and applicant geography;
- open, upcoming, rolling, or closed status with a dated last check;
- deadline and timezone where known;
- award coverage stated as tuition, stipend, living support, travel, materials, or partial support;
- eligibility rules separated into confirmed requirements and items the student must verify;
- required documents and application steps when supplied by the official source;
- official provider URL and a short source/provenance label;
- related active alternatives with genuinely similar level, discipline, or geography;
- one explainable CTA that connects the page to matching or tracking without hiding the public facts.

This standard should use the database’s actual fields. It must not invent award amounts, eligibility, deadlines, or provider terms.

### Internal linking

The current detail pages contain descriptive HTML links and breadcrumbs, which is good crawlable structure [5] [6] [9]. Google recommends crawlable anchor links, descriptive anchor text, and ensuring important pages are reachable from other pages [9]. The collection pages link to their listings, and detail pages link back to their collection hubs.

The missing layer is contextual depth. The homepage should link to `/scholarships-in-nigeria` and `/opportunities-for-students` with descriptive anchors instead of sending the main browse action to `/discover`. Collection pages should link to the most relevant public category hubs once those exist. Detail pages should link to two or three genuinely similar active alternatives, the relevant level/discipline/state hub, and the official provider page. Closed pages should link to current alternatives rather than only retaining the historical notice.

Concrete examples:

- Homepage → `/scholarships-in-nigeria`: “Browse verified undergraduate scholarships in Nigeria.”
- Homepage → `/opportunities-for-students`: “Explore verified fellowships, internships, competitions, and training.”
- M. Kukoyi page → technology/health or undergraduate hub, plus comparable active undergraduate awards.
- Oyo closed page → current Nigerian undergraduate bursaries or state-scholarship alternatives, with the closed status preserved.
- LFX Mentorship page → technology fellowships and open-source opportunities, while retaining the official LFX link [6].

## Site Architecture

**The architecture is technically crawlable but commercially under-linked.** The public route split is sensible: `/scholarship/[slug]` and `/opportunity/[slug]` are public, while authenticated plural routes such as `/scholarships/[id]`, `/opportunities/[id]`, `/discover`, and dashboard routes are protected. The risk is that the public homepage still points the user’s primary browse action into the protected route instead of the public SEO hubs.

**Click depth:** The sitemap and collection pages expose direct links to detail pages, and the public detail pages provide breadcrumbs back to the hubs [2] [4] [5]. A complete crawl-depth export was not provided, so average click depth and the deepest important page are data not provided. A crawl should confirm that every sitemap URL has at least one HTML link from a public page, not only sitemap inclusion.

**Orphan pages:** No orphan-page inventory was available. The current sitemap contains all verified slugs, but sitemap presence does not prove internal discoverability. Compare sitemap URLs against extracted internal links and flag any listing reachable only through the XML sitemap.

**Hierarchy and URL structure:** The canonical public hierarchy is understandable: static hub → singular typed slug → detail page. Legacy `/s/[id]` share URLs now redirect once to canonical scholarship slugs on the `www` host for the sampled historical IDs, which is a healthy consolidation pattern. Apex and HTTP requests redirect to `www` HTTPS. Keep internal links on the canonical slug routes.

**Internal link equity:** The homepage-to-`/discover` link is the clearest leak. It sends equity and users toward a route disallowed by robots and protected by authentication, while the public scholarship hub is not the destination of the main browse CTA [1] [3]. Fix this before creating many new hubs.

**Crawl budget and indexation logic:** At 92 sitemap URLs, crawl budget is not the immediate concern. The sitemap is dynamic and includes verified scholarship and opportunity rows, including closed records that retain useful historical pages [2] [7]. Later pagination pages use `noindex,follow`, which is a defensible consolidation choice when the first collection page is the preferred landing page. Do not use robots.txt as a canonicalization substitute; Google identifies robots blocking as a crawl restriction, not a canonical signal [10].

**Navigation and breadcrumbs:** Breadcrumbs are present on public detail pages and point to descriptive collection hubs [5] [6]. The public navigation is thin: the homepage has strong CTA copy but limited crawlable category navigation. Add a small, human-readable set of public collection links, not a large keyword menu.

## Backlink Analysis

**The backlink profile cannot be assessed from the available evidence.** No authorized Ahrefs, Semrush, Majestic, Search Console links report, or backlink export was available. Therefore the last six months’ link-building activity, referring-domain quality, anchor-text mix, link velocity, country relevance, and authority distribution are all **data not provided**.

**Domain Quality:** Data not provided. No conclusion about spam, quality, or harmful links is justified.

**Anchor Text Analysis:** Data not provided. It is not possible to classify branded versus non-branded anchors or infer whether links are PR-driven or SEO-team-driven.

**Distribution of Backlinks:** Data not provided. A proper review should separate homepage links from links to scholarship hubs, opportunity hubs, and individual feature pages.

**Verdict:** Do not purchase links or start broad outreach based on this audit. First export referring domains, linked pages, anchor text, follow/nofollow status, first-seen dates, and country/topic relevance. The most defensible future authority assets are original Nigerian scholarship data, transparent verification methodology, state-bursary explainers, and student application-readiness resources that universities and providers can cite.

## Technical SEO

| Finding | Evidence | SEO/business meaning | Action |
|---|---|---|---|
| Canonical host is consistent | Apex and HTTP requests redirect to `https://www.scholars.com.ng`; sampled `/s/[id]` routes redirect once to canonical slugs | Strong consolidation of old and new URL forms | Keep canonical internal links on `www` HTTPS slug URLs and monitor legacy share routes. |
| Public sitemap is healthy | `sitemap.xml` returned 200, valid URL inventory, 92 unique URLs, 44 scholarships, 42 opportunities, six static pages [2] | Search engines have a coherent discovery feed; this is not the main growth bottleneck | Maintain verification and slug uniqueness tests; monitor sitemap count against eligible database records. |
| Robots boundary is deliberate | Public root is allowed; `/discover`, auth, dashboard, plural protected routes, and API paths are disallowed [3] | Prevents authenticated surfaces from becoming search landing pages | Retain protection, but remove the homepage dependency on `/discover` for public browsing. |
| Collection metadata is strong | Collection pages have self-canonicals, title/description, page-one index/follow, later-page noindex/follow, and CollectionPage/ItemList JSON-LD [4] [7] | The main hubs are technically eligible for discovery | Validate rendered markup after future changes; do not repeat the remediation as new work. |
| Detail metadata is accurate but sparse | Detail pages have unique title/description/canonical, breadcrumbs, status, and verification date [5] [6] | Good baseline for provider/programme intent, but limited search differentiation | Add only database-backed requirements, sources, application steps, and related alternatives. |
| Homepage structured data is absent in inspected HTML | Homepage had zero JSON-LD scripts in the live inspection; detail and collection pages had one | Not a blocking SEO issue, but entity/navigation clarity could improve | Add WebSite/Organization markup only if it accurately represents visible site content; validate it. |
| Main homepage browse link is misrouted | “Browse all active scholarships” points to `/discover` [1]; `/discover` is protected/disallowed [3] | Weakens discovery, internal linking, and first-session conversion | Point the public browse CTA to `/scholarships-in-nigeria`; keep authenticated discovery as a secondary signed-in action. |
| Legacy redirect errors are resolved for sampled IDs | Three historical `/s/[id]` URLs on `www` returned one 308 to canonical scholarship slugs and then 200 | Previously reported redirect errors are now expected redirects for these records | Recheck all legacy IDs in Search Console; distinguish expected one-hop redirects from chains or broken records. |

The repository’s current `main` commit is `67070cbbf93c31327c1bf311af631ad24a01a1a3`, and it contains the technical SEO remediation, dynamic sitemap, public slug templates, pagination helpers, and related tests [7]. The latest Vercel production deployment for this commit is `READY`, so the remediation is live [8]. Do not recommend reimplementing these completed items.

## Core Web Vitals and Page Experience

No Lighthouse, CrUX, Search Console Core Web Vitals, field data, or mobile lab export was available. The HTTP inspections returned successful HTML responses, but server response timing from a small number of requests is not a Core Web Vitals measurement and cannot establish LCP, INP, CLS, mobile usability, or page experience quality.

The site is clearly mobile-oriented in its copy and layout, and the public pages render meaningful HTML without requiring authentication. That is a positive implementation signal, not a measured performance result. Obtain Search Console Core Web Vitals data and a representative mobile Lighthouse run for the homepage, scholarship hub, opportunity hub, one active scholarship, one active opportunity, and one closed page before prioritizing performance work.

## Final Prioritization

1. **Problem:** The homepage’s main scholarship-browse CTA points to protected `/discover` instead of the crawlable public scholarship hub.  
   **Fix:** Link the public CTA to `/scholarships-in-nigeria` and reserve `/discover` for signed-in, personalized matching.

2. **Problem:** Public scholarship detail pages expose a concise summary but not enough application decision support to compete consistently for provider and eligibility intent.  
   **Fix:** Add database-backed official source, requirements, application steps, award-coverage explanation, “last verified” provenance, and relevant active alternatives without inventing missing facts.

3. **Problem:** Search acquisition is concentrated in two broad hubs and individual listings, with no controlled public taxonomy for recurring state, level, discipline, internship, fellowship, or competition demand.  
   **Fix:** Build a small set of non-empty canonical hubs from structured inventory, starting with internships, fellowships/competitions, postgraduate funding, technology opportunities, and selected Nigerian states.

4. **Problem:** Organic growth and registration quality cannot currently be diagnosed because fresh Search Console, analytics conversion joins, backlink, and Core Web Vitals data are unavailable.  
   **Fix:** Export the specified Search Console periods and configure the organic landing-page-to-activation funnel before judging CTR, rankings, content ROI, authority, or page experience.

## References

[1]: https://www.scholars.com.ng/ "Scholars live homepage"
[2]: https://www.scholars.com.ng/sitemap.xml "Scholars live XML sitemap"
[3]: https://www.scholars.com.ng/robots.txt "Scholars live robots.txt"
[4]: https://www.scholars.com.ng/scholarships-in-nigeria "Scholars undergraduate scholarships in Nigeria hub"
[5]: https://www.scholars.com.ng/scholarship/m-kukoyi-foundation-mkf-scholarship-2026-a06f2b07 "Scholars active scholarship detail example"
[6]: https://www.scholars.com.ng/scholarship/oyo-state-scholarship-bursary-award-2026-b5b07e70 "Scholars closed scholarship detail example"
[7]: https://github.com/ImperioKDB/Scholars/tree/67070cbbf93c31327c1bf311af631ad24a01a1a3 "Scholars repository audited main commit"
[8]: https://vercel.com/imperiokdbs-projects/scholars/Cp4SKRNQ8XdGpS7fJg96QdhyqJij "Scholars Vercel production deployment"
[9]: https://developers.google.com/search/docs/crawling-indexing/links-crawlable "Google Search Central link best practices"
[10]: https://developers.google.com/search/docs/crawling-indexing/consolidate-duplicate-urls "Google Search Central canonical URL guidance"
[11]: https://developers.google.com/search/docs/crawling-indexing/sitemaps/overview "Google Search Central sitemap overview"
[12]: https://developers.google.com/search/docs/appearance/structured-data/intro-structured-data "Google Search Central structured data introduction"
[13]: https://www.scholarshipair.com/ "ScholarshipAir public site"
[14]: https://candidate.scholastica.ng/ "Scholastica public site"
[15]: https://opportunityfinder.com.ng/ "Opportunity Finder public site"
[16]: https://www.opportunitiesforafricans.com/ "Opportunities for Africans public site"
[17]: https://scholarship.education.gov.ng/ "Federal Ministry of Education Scholarship Portal"
[18]: https://opportunitydesk.org/ "Opportunity Desk public site"
