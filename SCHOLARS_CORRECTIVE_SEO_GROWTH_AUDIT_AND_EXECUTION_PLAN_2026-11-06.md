# SCHOLARS — CORRECTIVE SEO GROWTH AUDIT AND EXECUTION PLAN

**Date:** 6 November 2026  
**Mode:** Strictly read-only for the Scholars application and production systems. The only permitted write is publishing this report to `ImperioKDB/Updates`.  
**Application commit audited:** `67070cbbf93c31327c1bf311af631ad24a01a1a3`  
**Application repository:** `https://github.com/ImperioKDB/Scholars`  
**Website:** `https://www.scholars.com.ng`

## 1. Executive Summary

**The previous audit contained one incorrect homepage-link finding and one counting error; after correction, Scholars’ technical SEO foundation is sound, while the strongest remaining growth opportunity is turning verified inventory into clearer public decision support and measurable organic activation.** The exact remediation commit, current `main`, and live homepage HTML all link “Browse all active scholarships” to `/scholarships-in-nigeria`, not protected `/discover`. The live XML sitemap contains 93 unique canonical URLs: 44 scholarship pages, 42 opportunity pages, and seven static URLs; the earlier 92 count omitted the root URL during parsing. Public slug pages have server-rendered metadata, canonicals, breadcrumbs, status messaging, verification dates, and JSON-LD. The main content gap is not missing application data in the database: scholarship and opportunity rows already store application URLs and instructions, but the scholarship public template does not select or display those fields, while eligibility rules are stored separately for matching and are not publicly explained. Fresh Search Console, GA4, backlink, and Core Web Vitals data remain unavailable, so traffic, rankings, CTR, authority, and organic conversion cannot be claimed. The next four weeks should therefore validate measurement, expose accurate database-backed detail-page value, strengthen contextual links and only justified hubs, then test credible authority assets and the organic-to-activation funnel.

## 2. Scope and Methodology

This corrective audit reused the earlier public-site, repository, deployment, database, and competitor evidence and rechecked only the disputed or incomplete areas. The work included:

- exact source inspection of `app/page.tsx` at commit `67070cbbf93c31327c1bf311af631ad24a01a1a3` and on current `main`;
- live HTML inspection of the homepage, public hubs, detail pages, `robots.txt`, and `sitemap.xml`;
- XML parsing of every current sitemap `<loc>` element, with duplicate, host, and route checks;
- read-only inspection of the connected Supabase schema for `scholarships`, `opportunities`, `scholarship_rules`, and `profiles`;
- inspection of the current public detail templates, sitemap implementation, robots implementation, and relevant Git history;
- review of the earlier Updates reports that recorded the 93-URL inventory and remediation behavior;
- qualitative public competitor research across ScholarshipAir, Scholastica, Opportunity Finder, Opportunities for Africans, the Federal Ministry of Education portal, and Opportunity Desk;
- inspection of the available Vercel deployment record for the audited commit.

No application source, database record, schema, policy, deployment, domain, analytics configuration, Search Console setting, or production content was modified. Search Console and GA4 were not available through an authorized data connection in this session. No keyword volume, ranking, backlink, traffic, conversion, or Core Web Vitals number was invented.

Evidence labels used below:

- **VERIFIED** — directly confirmed from a cited source, live URL, source file, or read-only database schema query.
- **INFERENCE** — a supported interpretation of verified evidence.
- **UNVERIFIED** — relevant but not independently confirmed in this audit.
- **SPECULATIVE** — a hypothesis that requires testing.

## 3. Corrections to the Previous Audit

### 3.1 Homepage CTA correction

**VERIFIED:** The previous report incorrectly stated that the homepage’s main “Browse all active scholarships” link pointed to protected `/discover`. The exact merge commit contains:

```tsx
<Link href="/scholarships-in-nigeria" ...>
  Browse all active scholarships ...
</Link>
```

The same code is present on current `main`, which points to the audited commit. The live homepage HTML renders the destination as `/scholarships-in-nigeria`. The live homepage also contains public links to `/scholarships-in-nigeria` and `/opportunities-for-students`; no homepage link to `/discover` was found in the inspected HTML.

**Correction:** Remove the earlier claim, remove it from the priority recommendations, and do not change a link that already works correctly.

### 3.2 Sitemap count correction

**VERIFIED:** The previous report’s count of 92 unique URLs resulted from a counting mistake. The earlier parser used a regular expression that required a non-empty path after the domain, so it omitted `https://www.scholars.com.ng/`. XML parsing of the current sitemap returns 93 unique URLs.

The current source’s `STATIC_PATHS` array contains seven routes, including `/` [7]. The earlier post-merge production verification also recorded 93 URLs, 44 scholarships, 42 opportunities, and seven static URLs [8]. The two reports are consistent once the root URL is counted.

## 4. Homepage Link Verification

| Check | Result | Evidence |
|---|---|---|
| Exact remediation commit | **VERIFIED** | `67070cbb.../app/page.tsx`, lines 159–161, links to `/scholarships-in-nigeria` [1]. |
| Current `main` branch | **VERIFIED** | Current `main` is `67070cbb...`; the same link is present in `app/page.tsx` [2]. |
| Live rendered CTA | **VERIFIED** | Live homepage HTML renders “Browse all active scholarships” → `/scholarships-in-nigeria` [3]. |
| Public opportunities link | **VERIFIED** | Live homepage renders “Opportunities for students” → `/opportunities-for-students` [3]. |
| Prominent homepage `/discover` link | **VERIFIED absent in inspected HTML** | No `/discover` href was found among homepage links matching scholarship, opportunity, or discover intent [3]. |
| Protected `/discover` route | **VERIFIED** | `/discover` is in the application’s protected prefix list and is disallowed in robots [4] [5]. |

**Correct finding:** The homepage public linking is working as intended. The remaining internal-linking work is contextual depth: related active alternatives, category/state/discipline hubs where justified, links from closed pages to current alternatives, and ensuring every sitemap URL is reachable from a public HTML link rather than only from the sitemap.

## 5. Sitemap Inventory Reconciliation

### 5.1 Current production inventory

**VERIFIED:** `https://www.scholars.com.ng/sitemap.xml` returned HTTP 200 with `application/xml`. XML parsing found 93 `<loc>` elements, 93 unique URLs, and zero duplicates. All URLs use the canonical `https://www.scholars.com.ng/` host.

| Route group | Earlier post-merge verification | Current XML parse | Difference | Reconciliation |
|---|---:|---:|---:|---|
| Root `/` | 1 | 1 | 0 | Present; omitted only by the earlier regex count. |
| Other static routes | 6 | 6 | 0 | `/about`, `/reviews`, two collection hubs, and two legal pages. |
| Static total | 7 | 7 | 0 | Exact match. |
| Scholarship detail routes | 44 | 44 | 0 | Exact match to verified scholarship inventory. |
| Opportunity detail routes | 42 | 42 | 0 | Exact match to verified opportunity inventory. |
| **Total** | **93** | **93** | **0** | **Discrepancy resolved as a counting-method error.** |

The seven static URLs are:

1. `https://www.scholars.com.ng/`
2. `https://www.scholars.com.ng/about`
3. `https://www.scholars.com.ng/reviews`
4. `https://www.scholars.com.ng/scholarships-in-nigeria`
5. `https://www.scholars.com.ng/opportunities-for-students`
6. `https://www.scholars.com.ng/legal/privacy`
7. `https://www.scholars.com.ng/legal/terms`

### 5.2 Source implementation and database cross-check

**VERIFIED:** `app/sitemap.ts` defines the seven static routes and reads verified, slugged scholarship and opportunity rows through `lib/sitemap-data.ts` in 500-row batches [6] [7]. The connected Supabase project reports 44 verified scholarships and 42 verified opportunities. It reports 24 currently active scholarships and 27 currently active opportunities. The sitemap intentionally includes verified historical rows while active collection feeds apply deadline filters.

**VERIFIED:** The earlier post-merge report recorded the same 93/44/42/7 inventory and explained that closed historical records and postgraduate rows remain eligible for the sitemap [8]. The current XML parse confirms there is no current static-route removal, temporary mismatch, or route-policy change.

**Remaining validation gap:** The sitemap was checked for canonical host, uniqueness, route composition, and XML validity. A full 93-URL final-status crawl was not repeated in this corrective pass. The earlier report recorded a valid production route check, while sampled current detail pages returned 200. A future automated check should keep testing every sitemap URL for 200/expected redirect behavior.

## 6. Current Technical SEO Assessment

### Public and protected route boundaries

**VERIFIED:** Public SEO pages use singular slug routes: `/scholarship/[slug]` and `/opportunity/[slug]`. Authenticated plural routes such as `/scholarships/[id]`, `/opportunities/[id]`, `/discover`, dashboards, settings, and applications are protected by middleware [4]. Robots disallows those authenticated or internal surfaces while allowing public root content [5]. This is an appropriate separation between public acquisition and private matching/application data.

### Canonical host and legacy URLs

**VERIFIED:** Requests to apex and HTTP variants redirect to `https://www.scholars.com.ng`. Sampled legacy `/s/[id]` URLs on the canonical host redirect once with 308 to their canonical scholarship slug and then return 200. This is a healthy one-hop consolidation pattern, not a redirect loop.

### Metadata, breadcrumbs, and structured data

**VERIFIED:** Public collection pages have title, description, self-canonical, page-one index/follow handling, later-page `noindex,follow`, and CollectionPage/ItemList JSON-LD. Detail pages have unique title/description, self-canonical, breadcrumbs, status messaging, and WebPage/BreadcrumbList JSON-LD [9] [10]. The homepage had no JSON-LD in the inspected HTML. That absence is not a proven ranking defect; any future WebSite/Organization markup should describe visible content accurately and be validated against Google’s guidance [14].

### Pagination and sitemap behavior

**VERIFIED:** Collection pages use bounded, deterministic pagination with crawlable HTML Previous/Next links. Later pages are noindex/follow to avoid thin permanent search surfaces. The sitemap is dynamic and uses verified, non-null-slug rows in batches [6] [7]. These are completed remediation items, not fresh recommendations.

### Main remaining architecture opportunities

**INFERENCE:** The technical architecture is no longer the dominant constraint at the current 93-URL scale. The higher-value work is to make public pages more useful and connected: expose accurate application context already stored in the database, add related alternatives, and only then create a small number of non-empty hubs.

## 7. Search Console and Analytics Data Availability

### Available evidence

The supplied historical baseline covers approximately 9 October–3 November 2026: 1,863 impressions, 48 clicks, 2.58% CTR, and average position 7.42 globally; Nigeria had 384 impressions, six clicks, 1.56% CTR, and 24 landing pages. These are historical context only. Earlier page examples included Sande Poetry Prize, ICON Scholarship, Stories from Nigeria Competition, Linux Foundation LFX Mentorship, Amir Fund Medical Scholarship, and the homepage.

### Unavailable evidence

**UNVERIFIED / NOT AVAILABLE:** No current Search Console property data for `sc-domain:scholars.com.ng` was accessible. Therefore the latest complete seven-day period, preceding seven-day period, latest 28-day period, pre-remediation comparison, query/page/country/device breakdowns, search appearance, indexing coverage, and current CTR/position are unavailable.

**UNVERIFIED / NOT AVAILABLE:** No GA4 or other authorized analytics export was accessible. Organic landing-page sessions, new organic visitors, registration starts, completed registrations, onboarding completion, first match, saves, application activity, provider clicks, and organic cost of acquisition cannot be reported as current measurements.

**UNVERIFIED / NOT AVAILABLE:** No backlink export or Core Web Vitals/CrUX export was accessible.

## 8. Existing Page Quality Assessment

The public pages are accurate and restrained, which is preferable to inventing award or eligibility facts. The homepage clearly explains the product’s differentiator: eligibility-matched rather than keyword-matched discovery [3]. The two public collection pages provide indexable summaries and listings [9] [10]. Detail pages show provider, title, deadline/status, level or type, discipline/location where available, overview, and last-checked or official-application context.

The principal quality issue is uneven depth between stored data and visible page content. The public opportunity template can display `application_url` and `how_to_apply`. The public scholarship template currently selects and displays title, provider, description, amount, deadline, status, level, discipline, and `last_verified_at`, but its public query does not select `application_url` or `how_to_apply` even though both fields exist in the database [11] [12] [13]. This is a verified presentation gap, not a missing database-field problem.

The current pages also lack a public “why this matches” explanation because matching depends on a visitor’s private profile. The public page should not expose private profile information or a private score. It can still explain which eligibility dimensions are checked, show confirmed rules in plain language, identify unknown conditions, and invite profile creation for personalized evaluation.

## 9. Detail-Page Content Gap Analysis

### 9.1 Database and public-template field matrix

| Information element | Exists in database? | Displayed publicly? | Gap | Recommended action |
|---|---|---|---|---|
| Opportunity title | **VERIFIED: yes** | **VERIFIED: yes** | None | Keep unique title and canonical slug. |
| Provider identity | **VERIFIED: yes** | **VERIFIED: yes** | None on sampled pages | Keep provider adjacent to title. |
| Overview/description | **VERIFIED: yes** | **VERIFIED: yes** | Depth varies by record | Use editorial minimum standard; do not pad thin records. |
| Official source URL | **VERIFIED: stored in `application_url`** | Scholarship: **not displayed by current public template**; opportunity: **displayed** | Scholarship source/application link is hidden | Select and display the official link with status-aware label. |
| Application URL | **VERIFIED: yes on both base tables** | Scholarship: **not displayed**; opportunity: **displayed** | Scholarship template omits it | Expose it when present; label historical links accurately on closed pages. |
| Application instructions | **VERIFIED: `how_to_apply` exists on both tables** | Scholarship: **not displayed**; opportunity: **displayed** | Scholarship instructions are stored but hidden | Render a concise, source-backed application section. |
| Eligibility notes | Opportunity: **VERIFIED: `eligibility_notes` exists**; scholarship rules are stored separately | Not fully public on sampled templates | Rules are used for matching but not explained | Display confirmed public criteria and “verify manually” conditions. |
| Structured scholarship rules | **VERIFIED: `scholarship_rules` has field/operator/value/gating** | Private matching behavior is not shown | Visitors cannot understand the rule dimensions | Show a safe summary such as level, discipline, institution/state or document conditions when confirmed. |
| Country restrictions | Not a dedicated base-table column; may be in text/rules/research notes | Not consistently structured publicly | Hard to compare and filter | Do not add a landing-page filter until provenance and field coverage are reliable. |
| Academic level | **VERIFIED: scholarship `level`; opportunity `type`, with level sometimes in text** | **VERIFIED: yes where available** | Opportunity level is less normalized | Normalize only after data-quality review. |
| Discipline | **VERIFIED: yes on both tables** | **VERIFIED: yes where populated** | Empty values reduce usefulness | Use “not specified by provider” rather than infer. |
| Award/benefit coverage | Scholarship `amount`; opportunity `compensation` | **VERIFIED: yes where populated** | Tuition/stipend/living/travel distinctions are not consistently structured | Add coverage labels only when supported by source notes. |
| Required documents | Not a dedicated base-table column; often present in `how_to_apply` or `research_notes` | Not shown as a structured checklist | Application readiness is weaker than stored research | Extract only verified requirements into a checklist presentation. |
| Deadline | **VERIFIED: yes on both tables** | **VERIFIED: yes** | Timezone/opening context often absent | Store/display timezone or explicitly state that provider timezone must be confirmed. |
| Open/closed status | Derived from deadline and cycle fields; `verified` is separate | **VERIFIED: yes** | Status semantics should be documented | Keep closed historical pages and add clear status definitions. |
| Last verification date | Scholarship `last_verified_at`; opportunity has `updated_at` but no equivalent dedicated field in inspected columns | Scholarship: **displayed**; opportunity: not equivalent | Verification freshness is uneven | Establish a source-check date for both types without fabricating one. |
| Related opportunities | No dedicated relationship field observed | **VERIFIED: not shown on sampled pages** | Users have no next-best path | Add conservative related links based on shared structured fields. |
| Private profile/match score | **VERIFIED: stored in private profile/matching flow, not public page** | **Correctly not displayed** | None; privacy boundary is appropriate | Explain the matching process without exposing private student data. |

### 9.2 Product distinction and conversion balance

Scholars should not become another article archive. The public detail page should answer basic factual questions without registration, then give a reason to create a profile: “These are the confirmed rules; your profile can check them against your course, level, GPA, state, institution, and documents.” The public page should not reveal a private eligibility score or profile attributes.

A good balance is:

1. **Discovery:** indexable title, provider, type, amount/benefit, deadline, status, location, level, discipline, and source-backed overview.
2. **Trust:** last-checked date, official link, source/provenance note, unknown-condition warning, and closed-cycle explanation.
3. **Conversion:** one clear CTA to build a profile or track the opportunity.
4. **Matching:** after profile creation, show explainable rule matches and missing information.
5. **Retention:** allow saves, reminders, application milestones, and follow-up without turning the public page into a private dashboard.

## 10. Keyword and Search Intent Opportunities

Reliable search volumes and current Search Console queries are unavailable. The observations below are therefore intent hypotheses supported by the live inventory, observed public SERPs, historical page examples, and competitor page structures. They are not volume claims.

| Query/theme | Intent | Existing Scholars coverage | Demand evidence | Main risk | Business value |
|---|---|---|---|---|---|
| scholarships for Nigerian undergraduates | Broad active discovery | Existing `/scholarships-in-nigeria` hub | SERPs consistently surface Nigerian scholarship portals and directories | Broad competition | High |
| postgraduate scholarships for Nigerians | Level-specific funding discovery | Postgraduate records exist in sitemap; no dedicated hub | Remediation confirmed postgraduate inventory | Thin page if inventory is small | High if inventory stays current |
| fully funded scholarships for Nigerians | Coverage/benefit intent | No dedicated verified hub | SERPs show repeated editorial demand wording | Mislabeling partial awards | High, but only with structured coverage data |
| scholarships without IELTS | Constraint-led international intent | No dedicated page | Public SERPs show many editorial pages | Requirement varies by institution; high misinformation risk | Medium; defer until fields are reliable |
| internships for Nigerian students | Opportunity discovery | Mixed in opportunity hub | SERPs surface internship directories and Africa opportunity sites | Mixed student/graduate/job intent | High |
| fellowships for Nigerians | Fellowship discovery | Mixed in opportunity hub | SERPs surface broad fellowship publishers | Audience and career-stage ambiguity | Medium-high |
| essay competitions for Nigerian students | Deadline-driven competition intent | Individual opportunity pages | SERPs surface competition pages and provider pages | Secondary/tertiary age groups may differ | High for timely acquisition |
| technology scholarships and fellowships | Discipline/career intent | Individual technology listings | Current opportunity inventory includes technology programmes | Overlapping scholarship/fellowship taxonomy | Medium-high |
| scholarships by Nigerian state | Local eligibility intent | Individual state records | Oyo/Lagos/Osun-related inventory and Nigerian relevance | Thin state pages and changing cycles | High where recurring supply exists |
| provider + programme + year | Navigational/application intent | Strong slug detail-page foundation | Historical GSC examples included named programme pages | Thin detail pages if source/application facts are hidden | High and measurable |

The immediate opportunity is not to create every page above. It is to improve existing detail pages first, then launch only the hubs that have enough verified records, unique eligibility context, and a maintenance owner.

## 11. Landing-Page Strategy

| Candidate page | Existing intent satisfaction | Inventory | Cannibalisation/thin risk | Recommendation |
|---|---|---|---|---|
| Undergraduate scholarships in Nigeria | Existing `/scholarships-in-nigeria` already satisfies the core intent | Strong: 44 verified scholarships, 24 currently active | Low if retained as canonical hub | **Keep and improve; do not create a duplicate.** |
| Postgraduate scholarships for Nigerians | Not satisfied by a dedicated public hub | Postgraduate records confirmed in sitemap, exact active subset not separately measured | Medium | **P1 candidate** after checking enough live records and adding clear level/funding fields. |
| Fully funded scholarships for Nigerians | No dedicated hub | Inventory contains varying benefits, not a consistently structured coverage field | High risk of inaccurate labels | **P2 experiment only after coverage classification and enough verified records.** |
| Scholarships without IELTS | No dedicated hub | Requirements are not consistently structured | High misinformation and thin-content risk | **Defer.** Publish only when language requirements can be verified record by record. |
| Internships for Nigerian students | Opportunity hub covers internships but not as a focused landing page | Verified opportunity inventory includes internships | Medium | **P1 candidate** with type, student stage, skills, duration, mode, and location fields. |
| Fellowships for Nigerians | Opportunity hub covers fellowships | Verified fellowship inventory exists | Medium | **P2 candidate**; consider a combined fellowship/competition hub only if filters prevent overlap. |
| Essay competitions for Nigerian students | Individual pages exist; no hub | Multiple competition records are present | Medium | **P1 candidate** if the hub can show submission format, level, prize, deadline, and official source. |
| Technology scholarships and fellowships | Individual technology opportunities exist | Current listings include tech programmes | Medium | **P2 candidate** after taxonomy review; avoid duplicating the same listing across shallow pages. |
| Scholarships by Nigerian state | No controlled public state hub observed | Some state-specific records exist | High if many states have no inventory | **P2 navigational hub**, with individual state pages only where recurring verified supply exists. |

## 12. Internal Linking Strategy

The homepage linking finding is corrected: public links to both collection hubs already exist [3]. The next internal-linking improvements should be contextual and evidence-led:

- **Collection to detail:** retain descriptive listing anchors and add visible status/discipline/level context so each card communicates why the listing belongs on the page [9] [10].
- **Detail to collection:** retain breadcrumbs to the correct public hub. This is already implemented on sampled pages [11] [12].
- **Detail to related detail:** add two or three related active opportunities based on shared type, level, discipline, geography, or funding coverage. Do not recommend “related” links based only on title similarity.
- **Closed detail to active alternatives:** keep the historical page indexable when useful, but provide a current alternative block with an explicit “similar, not equivalent” label.
- **Homepage to hubs:** retain the verified links to `/scholarships-in-nigeria` and `/opportunities-for-students`; add a short public navigation block only for real hubs, not keyword lists.
- **Hub to guides:** once original guides exist, link them to relevant listings and from listings back to the guide. Examples include Nigerian application documents, state bursary eligibility, and how to compare tuition-only versus living-support awards.
- **Sitemap versus HTML links:** compare sitemap URLs with crawled internal links and identify any listing discoverable only through XML. Google states that important pages should be reachable through crawlable HTML links [15].

## 13. Competitor Comparison

The following is a qualitative comparison of public pages inspected on 6 November 2026. No competitor traffic, ranking, backlink, or conversion figures are claimed.

| Competitor | Audience | Content structure and coverage | Eligibility/application information | Search architecture | Distinctive value | Gap Scholars can address |
|---|---|---|---|---|---|---|
| ScholarshipAir [16] | Nigerian students and international scholarship seekers | Broad taxonomies by level, country, course, sponsor, gender, funding status; dated feeds and detail pages | Detail pages commonly show benefits, requirements, selection, deadline, and external application | Deep category taxonomy and program/year titles | Breadth, freshness cues, email/WhatsApp/Telegram distribution | More reliable structured comparison, source verification, explainable matching, and application workflow. |
| Scholastica [17] | Nigerian scholarship and bursary applicants | Sponsor-specific scheme pages, scholarships/bursaries/grants, FAQs and support | Strong eligibility, requirements, document, steps, anti-fraud and contact guidance | Sponsor/application pages and featured schemes | Detailed application management and trust messaging | Combine broad cross-provider discovery with public structured matching and alternatives. |
| Opportunity Finder [18] | Nigerian and global opportunity browsers | Mixed editorial archive for scholarships, jobs, grants, fellowships, training, competitions | Individual articles explain benefits, eligibility, steps, deadline, official link | Broad topic/geography/level archives | Breadth and program/year editorial titles | Replace prose-only browsing with normalized fields, verified status, and student task tracking. |
| Opportunities for Africans [19] | African students, graduates, innovators, and professionals | Country and topical archives with dated opportunity articles | Detail pages often include criteria, benefits, process, and official link | Country/category/programme titles and related posts | Pan-African breadth and country segmentation | Nigeria-first local context, state/institution routes, and profile-based fit. |
| Federal Ministry Scholarship Portal [20] | Nigerian scholarship applicants | Official government funnel, account workflow, process FAQs | Strong institutional trust and application workflow; public inventory was empty during inspection | Official portal and gated application routes | Government identity and formal application process | Provide discovery breadth and public decision support before requiring account creation. |
| Opportunity Desk [21] | Global opportunity seekers, including Africans | Regional/category archives, deadline pages, dated detail posts, email alerts | Detail pages show award, eligibility, application, official source | Broad categories, archives, approaching deadlines | Distribution, deadline browsing, submission funnel | Nigeria-specific eligibility, verified provenance, explainable matching, and application readiness. |

**Central answer:** Scholars can own the combination rather than one isolated feature. Competitors show broad editorial discovery or formal application management. Scholars can provide a verified, Nigeria-first structured opportunity layer where each listing makes eligibility dimensions explicit, explains what is known versus unverified, and lets a student move from public facts to a private profile-based match and application follow-through.

## 14. Backlink and Authority Strategy

**UNVERIFIED:** No backlink export was available. Current referring-domain quality, anchor-text mix, link velocity, target-page distribution, and country relevance are unknown. No conclusion about spam or active link building is justified.

The ethical authority strategy should be asset-led, not mass outreach-led:

1. Publish a periodically updated, cited Nigerian scholarship and bursary methodology page explaining verification, status labels, and source handling.
2. Create original state-bursary or institution-funding explainers only when they contain verified, maintained information rather than rewritten lists.
3. Produce a structured annual or quarterly Nigerian student opportunity dataset with clear definitions, dates, and limitations.
4. Offer universities, student associations, campus technology communities, and credible education organisations a useful public resource they can reference naturally.
5. Build application-readiness checklists for NIN, admission evidence, transcripts, references, and personal statements where the guidance is general and accurately sourced.

Do not buy backlinks, create mass guest posts, or ask providers to link solely to manipulate rankings. Authority work should support discovery, trust, and qualified registration.

## 15. AI Search Visibility

This section is a strategic assessment, not a claim of current AI-search traffic.

**VERIFIED:** Public detail pages contain clear titles, provider names, deadlines, descriptions, status notices, and JSON-LD; collection pages contain CollectionPage/ItemList markup [9] [10] [11] [12]. Google’s guidance says structured data can help it understand page content, but markup must describe visible information and does not guarantee a search feature [14].

**INFERENCE:** Scholars is more likely to be cited by answer engines when a page has one unambiguous opportunity identity, source-backed facts, explicit eligibility constraints, date/status context, and an official link. Prose that hides the application URL or leaves the source/date relationship unclear reduces answer reliability.

Priorities for AI-search readiness:

- use stable canonical slug URLs and descriptive headings;
- expose source-backed facts in visible HTML, not only private matching logic;
- separate “provider states” from “Scholars interpretation” and “student must verify”;
- show dates and closed status clearly;
- use structured fields consistently across similar listings;
- link to official providers and related public pages with descriptive anchors;
- maintain a transparent last-checked process;
- avoid adding unsupported schema types or facts that are not visible on the page.

## 16. Top 15 Prioritised Recommendations

Scores: impact and confidence use 1–5, where 5 is highest. Effort uses 1–5, where 5 is most difficult. “Time to signal” means the earliest realistic time to observe a measurement change, not a guaranteed ranking outcome.

| Rank | Priority | Problem/opportunity | Evidence | Impact | Confidence | Effort | Expected time to signal | Dependencies | Success measurement |
|---:|---|---|---|---:|---:|---:|---|---|---|
| 1 | P0 | Establish current organic and activation baseline | Search Console/GA4 unavailable; historical baseline only [22] | 5 | 5 | 2 | 1–2 weeks after export/instrument check | Authorized exports and event map | Fresh clicks/impressions/CTR/position plus organic registration and onboarding funnel. |
| 2 | P1 | Scholarship template hides stored application URL and instructions | `scholarships.application_url` and `how_to_apply` exist; public template omits them [11] [13] | 5 | 5 | 2 | 2–6 weeks after release | Product/editorial approval; field quality check | Provider-link clicks, detail engagement, application starts, and manual content QA. |
| 3 | P1 | Make stored eligibility rules understandable publicly without exposing private profiles | `scholarship_rules` stores field/operator/value/gating; public page only gives generic CTA [13] [23] | 5 | 5 | 3 | 2–8 weeks | Rule-to-copy mapping and privacy review | More qualified signup starts; lower “what does this mean?” feedback; match-view rate. |
| 4 | P1 | Add source provenance and consistent freshness display for both page types | Scholarship has `last_verified_at`; opportunity columns have `updated_at` but no equivalent dedicated check field [13] | 5 | 4 | 3 | 2–8 weeks | Editorial source policy | Detail-page trust interactions, lower stale-link reports, source-click rate. |
| 5 | P1 | Improve detail-page application readiness | Current templates show concise facts; required documents are often in `how_to_apply`/notes, not structured [11] [12] [13] | 5 | 5 | 3 | 4–10 weeks | Editorial minimum standard | Checklist views, provider clicks, application starts, and content completeness score. |
| 6 | P1 | Add related active alternatives and closed-page alternatives | Sampled detail pages have breadcrumbs but no related-opportunity block [11] [12] | 4 | 4 | 3 | 3–8 weeks | Comparable-field taxonomy and closed-status rules | Related-link CTR, sessions per organic landing visit, return visits. |
| 7 | P1 | Reconcile sitemap URLs with public HTML internal links | Sitemap is healthy at 93 URLs, but a full orphan comparison was not provided [6] [7] | 4 | 4 | 3 | 1–3 weeks | Crawl/export or bounded internal-link script | Zero important sitemap URLs without a public HTML path. |
| 8 | P1 | Create one internship landing page if inventory passes threshold | Internship intent exists; current coverage is mixed in opportunity hub | 4 | 4 | 3 | 4–12 weeks | Count/type/field quality review | Non-branded impressions/clicks and organic signup quality for internship intent. |
| 9 | P1 | Create one essay-competition landing page if inventory passes threshold | Multiple competition listings and observed SERP intent | 4 | 4 | 3 | 4–12 weeks | Deadline, level, submission, prize fields | Impressions/clicks by competition queries and provider-link clicks. |
| 10 | P2 | Create postgraduate hub only after live inventory review | Postgraduate records are in the sitemap; no dedicated public hub [2] [6] | 4 | 4 | 3 | 6–14 weeks | Active inventory and level-specific copy | Postgraduate query/page performance and qualified registration starts. |
| 11 | P2 | Build a state scholarship navigation hub, not thin pages for every state | State-specific records exist, but supply is uneven | 4 | 4 | 4 | 8–16 weeks | Recurring verified supply and state taxonomy | State query impressions/clicks, page completeness, stale-page rate. |
| 12 | P2 | Create an evidence-led verification/methodology resource | Competitors use trust and anti-fraud messaging; Scholars has verification positioning [3] [16] [17] | 4 | 4 | 3 | 6–16 weeks | Editorial policy and source examples | External citations, assisted organic registrations, trust feedback. |
| 13 | P2 | Build low-bandwidth/shareable application-readiness resources | Competitor distribution is strong; Scholars’ product value is workflow-oriented [16] [21] | 3 | 3 | 3 | 8–20 weeks | Content owner and consented distribution plan | Shares, returning organic users, checklist use, activation rate. |
| 14 | P3 | Test credible campus/university/technology-community authority partnerships | Backlink profile is unmeasured; no outreach or link quality is verified | 3 | 3 | 4 | 12–24 weeks | Asset quality, partner fit, consented outreach | Relevant referring domains and referral activation, not link count alone. |
| 15 | P3 | Test AI-search-ready structured answer blocks on a small page cohort | Public pages have JSON-LD but no AI referral measurement [14] | 3 | 3 | 3 | 8–16 weeks | Baseline pages and source-backed content | Citation/referral observations where measurable, plus organic CTR and assisted conversions. |

The ranking intentionally puts measurement and verified presentation gaps ahead of speculative new pages or authority campaigns. If the inventory thresholds for ranks 8–11 are not met, do not create those pages merely to reach a round number; use the capacity for detail quality and source verification instead.

## 17. Four-Week Execution Roadmap

### Week 1 — Measurement and validation

**Tasks:** Obtain Search Console exports for the latest complete seven-day period, preceding seven-day period, latest 28-day period, and pre-remediation comparison if available. Segment by query, page, country, device, search appearance, and index status. Reconcile current redirect/legacy URLs and compare all sitemap URLs to public HTML links. Audit analytics event names and landing-page attribution for organic registration, onboarding, match, save, application, and provider-click events.

**Deliverables:** Baseline workbook; query/page opportunity list; redirect and sitemap reconciliation log; event availability matrix; list of pages ranking 4–20 and pages with impressions but poor CTR.

**Dependencies:** Authorized Search Console/analytics access and a read-only crawl or export.

**Responsible role:** Founder/product owner with technical SEO support.

**Success indicators:** Every requested KPI has a source or is explicitly marked unavailable; top pages and queries can be named without relying on the old baseline.

**Risks:** Search Console date ranges may be incomplete; GA4 events may not join cleanly to organic landing pages; average position may be misread as a universal rank.

### Week 2 — Existing page quality

**Tasks:** Sample active scholarships, closed scholarships, opportunities, and pages from historically promising queries. Compare database fields with public HTML. Prioritize official source URLs, application instructions, requirements, award coverage, deadline provenance, status, and last-checked information. Establish a minimum public detail-page standard and a “known/unknown/must verify” editorial pattern.

**Deliverables:** Detail-page completeness matrix; prioritized page refresh list; approved content standard; source-verification checklist; measurement events for provider-link and checklist interactions.

**Dependencies:** Week 1 page/query list; database field audit; editorial owner.

**Responsible role:** Founder/editorial verifier, with product/engineering review only after approval.

**Success indicators:** Every priority page has a documented evidence gap and a safe public recommendation; no invented award or eligibility claim is introduced.

**Risks:** Provider pages may change; source notes may be stale; adding too much prose may reduce scannability.

### Week 3 — Search architecture and internal linking

**Tasks:** Evaluate collection pages, public link depth, orphan candidates, pagination, breadcrumbs, related alternatives, and closed-page pathways. Decide whether internship, essay competition, postgraduate, technology, or state hubs meet inventory and uniqueness thresholds. Design contextual links based on actual structured fields rather than keyword repetition.

**Deliverables:** Public architecture map; internal-link recommendations with URL examples; approved or rejected hub list; related-opportunity rule; noindex/canonical review for pagination.

**Dependencies:** Week 1 crawl inventory and Week 2 field standard.

**Responsible role:** Technical SEO/product owner.

**Success indicators:** Every proposed hub has a distinct intent, enough inventory, unique copy, an owner, and a maintenance rule; rejected hubs are documented rather than quietly created.

**Risks:** Near-duplicate hubs could cannibalize one another; related-link automation could connect inaccurate or closed records.

### Week 4 — Authority and growth

**Tasks:** Identify credible university, student association, education, and technology-community partners. Select one or two original assets: verification methodology, state bursary guide, structured opportunity snapshot, or application-readiness checklist. Define an ethical partnership approach and establish the next measurement cycle.

**Deliverables:** Authority asset brief; partner-quality criteria; consented outreach plan for founder review; next-cycle KPI dashboard specification; post-implementation comparison plan.

**Dependencies:** Weeks 1–3 evidence and founder approval; no outreach should begin automatically.

**Responsible role:** Founder, with editorial and partnerships support.

**Success indicators:** Assets have a clear audience and citation value; measurement windows and comparison pages are fixed before publication; no guaranteed ranking or traffic claim is made.

**Risks:** Link activity may produce no immediate ranking signal; low-quality partnerships could damage trust; resource diversion could delay core detail-page quality.

## 18. Measurement and KPI Framework

### Search visibility

| KPI | Definition | Source | Required tracking/configuration | Frequency | Currently available? | Why it matters |
|---|---|---|---|---|---|---|
| Organic clicks | Search clicks to Scholars URLs | Search Console | Authorized property export | Weekly/28-day | No; historical aggregate only | Direct search traffic signal. |
| Impressions | Search result appearances | Search Console | Same property and date range | Weekly/28-day | No; historical aggregate only | Measures visibility, not visits. |
| CTR | Clicks divided by impressions | Search Console | Query/page segmentation | Weekly | No | Identifies title/snippet opportunity. |
| Average position | Search Console average position | Search Console | Query/page/country/device cuts | Weekly | No | Prioritizes near-winners; not a universal rank. |
| Branded/non-branded clicks | Clicks split by query classification | Search Console export plus documented classifier | Query export and rules | 28-day/monthly | No | Separates brand demand from discovery. |
| Priority-page indexing | Indexed/not indexed status for selected URLs | Search Console URL/page indexing data | Current sitemap and URL list | Weekly/monthly | No | Distinguishes availability from ranking. |
| Query performance | Clicks/impressions/CTR/position per query | Search Console | Query dimension | Weekly/28-day | No | Identifies real intent, not assumed demand. |
| Landing-page performance | Search metrics by URL | Search Console | Page dimension | Weekly/28-day | No | Finds high-impression pages and near-winners. |
| Country/device distribution | Search metrics by country and device | Search Console | Country/device dimensions | 28-day/monthly | No | Tests Nigeria fit and mobile priorities. |

### Acquisition

| KPI | Definition | Source | Required tracking/configuration | Frequency | Currently available? | Why it matters |
|---|---|---|---|---|---|---|
| Organic landing-page sessions | Sessions whose first page and source are organic | GA4 or equivalent | Source/medium and landing-page dimensions | Weekly/monthly | No | Connects Search Console clicks to sessions. |
| New organic visitors | New users from organic source | GA4 | User acquisition source | Monthly | No | Measures new audience acquisition. |
| Organic registration starts | Organic sessions triggering signup start | GA4/app event stream | Preserve landing source through signup | Weekly | Event instrumentation exists in project history, but current joined data unavailable | Measures acquisition intent. |
| Completed registrations | Organic users completing registration | GA4/Supabase event data | Stable user/event identity join | Weekly | Current joined data unavailable | Business outcome closer than clicks. |
| Organic acquisition cost | Spend divided by new organic acquired users, if applicable | Finance/marketing plus analytics | Cost allocation rules | Monthly | No | Prevents confusing free distribution with zero operating cost. |

### Activation and product engagement

| KPI | Definition | Source | Required tracking/configuration | Frequency | Currently available? | Why it matters |
|---|---|---|---|---|---|---|
| Onboarding completion | New user reaches completed onboarding state | App events/Supabase | Event and user join | Weekly | Instrumented historically; current result unavailable | First activation gate. |
| Profile completion | Profile reaches defined completeness threshold | Profiles/events | Threshold definition | Weekly | Partly available in schema via `profile_completeness` | Measures readiness for matching. |
| First eligibility match | User views first personalized match | App events | Match-view event | Weekly | Instrumented historically; current result unavailable | Core product value event. |
| Saved opportunity | User saves a scholarship/opportunity | App tables/events | Save event and source attribution | Weekly | Instrumented historically; current result unavailable | Indicates intent beyond browsing. |
| Application tracking activity | User starts/updates application status | Applications/events | Stable status event taxonomy | Weekly | Instrumented historically; current result unavailable | Measures follow-through. |
| Official provider-link clicks | User clicks provider/application URL | App event | Event on outbound CTA with listing ID | Weekly | Must be confirmed for scholarship template after presentation change | Connects page utility to application action. |

### Content performance

| KPI | Definition | Source | Required tracking/configuration | Frequency | Currently available? | Why it matters |
|---|---|---|---|---|---|---|
| Clicks/impressions by content type | Search metrics grouped into static, collection, scholarship, opportunity, guide | Search Console plus URL classifier | Stable route taxonomy | 28-day/monthly | No | Shows which page types acquire traffic. |
| Detail-page performance | Metrics per scholarship/opportunity detail page | Search Console/analytics | Page and listing ID mapping | Weekly/28-day | No | Finds refresh candidates. |
| Collection-page performance | Metrics for public hubs | Search Console/analytics | Landing-page reporting | Weekly/28-day | No | Tests architecture and hub demand. |
| Scholarship-category performance | Metrics by level, discipline, state, funding type | Data warehouse/URL/content taxonomy | Controlled fields and page mapping | Monthly | No | Guides catalog and hub decisions. |
| Opportunity-category performance | Metrics by internship, fellowship, competition, training, mentorship | Same | Controlled type mapping | Monthly | No | Tests non-scholarship growth. |
| Impressions with poor CTR | High-impression/low-click URLs or queries | Search Console | Threshold agreed after baseline | Weekly | No | Prioritizes snippets and intent fit. |
| Positions 4–20 | URLs/queries with average position in range | Search Console | Query/page export | Weekly | No | Finds realistic near-term opportunities. |

Leading indicators are impressions, clicks, CTR, indexed priority pages, provider-link clicks, and match views. Business outcomes are completed registrations, onboarding completion, saves, application starts, and verified follow-through. Impressions are not visitors; clicks are not registrations; registrations are not activated users; indexed pages are not ranking success.

## 19. Risks, Dependencies, and Unknowns

- **Search Console access:** Current query/page/country/device evidence is unavailable. No ranking or CTR conclusion should be treated as current until the export exists.
- **Analytics joins:** The project roadmap records activation events, but this audit did not access current event data or prove that organic landing attribution joins through signup and onboarding.
- **Backlinks:** Referring domains, anchor text, target-page distribution, and authority are unknown. No link-building activity should be inferred.
- **Core Web Vitals:** No field or lab data was available. HTTP response success is not a Core Web Vitals result.
- **Inventory freshness:** Opportunity deadlines and provider terms change. Public pages need a repeatable source-check process.
- **Field completeness:** Application URLs and instructions exist in schema, but not every row is guaranteed to contain complete values. Report completeness before adding landing pages.
- **Matching privacy:** Public pages must not expose private student attributes or private match scores. Explain rule categories instead.
- **Cannibalisation:** Multiple pages for “fully funded,” “without IELTS,” “international,” and “postgraduate” can overlap. Each page needs distinct intent and a maintenance owner.
- **Authority experiments:** Partnerships and links cannot be guaranteed. Measure qualified referral activation and relevance, not raw domain counts.
- **AI-search claims:** No AI referral or citation data was available. AI visibility recommendations are hypotheses grounded in source clarity and structured content.
- **Scope boundary:** This report recommends future work but does not implement it. Founder review must occur before any application change.

## 20. Final Strategic Recommendations

1. **Measure before expanding.** Obtain the Search Console and analytics exports, join organic landing pages to activation, and establish a current baseline before judging the old near-winner pages.
2. **Make existing detail pages useful without making them private.** Expose stored application URLs, instructions, source provenance, confirmed rule summaries, status, and related alternatives while keeping profile-specific matching behind signup.
3. **Treat verification as the product moat.** A visible last-checked process, official source, unknown-condition warning, and closed-cycle policy can distinguish Scholars from broad editorial directories.
4. **Launch fewer, stronger hubs.** Keep the existing undergraduate hub, then add only the internship, essay-competition, postgraduate, technology, or state hubs that have enough verified inventory and unique decision support.
5. **Optimise for qualified activation, not vanity traffic.** Evaluate SEO by eligible-student discovery, completed profiles, first useful matches, saves, provider clicks, and application follow-through—not by page count or impressions alone.

## References

[1]: https://github.com/ImperioKDB/Scholars/blob/67070cbbf93c31327c1bf311af631ad24a01a1a3/app/page.tsx "Scholars homepage source at exact audited commit"
[2]: https://github.com/ImperioKDB/Scholars/blob/main/app/page.tsx "Scholars homepage source on current main"
[3]: https://www.scholars.com.ng/ "Scholars live homepage"
[4]: https://github.com/ImperioKDB/Scholars/blob/67070cbbf93c31327c1bf311af631ad24a01a3/middleware.ts "Scholars middleware route boundaries"
[5]: https://www.scholars.com.ng/robots.txt "Scholars live robots directives"
[6]: https://github.com/ImperioKDB/Scholars/blob/67070cbbf93c31327c1bf311af631ad24a01a3/lib/sitemap-data.ts "Scholars batched sitemap data reader"
[7]: https://github.com/ImperioKDB/Scholars/blob/67070cbbf93c31327c1bf311af631ad24a01a3/app/sitemap.ts "Scholars sitemap implementation"
[8]: https://github.com/ImperioKDB/Updates/blob/main/SCHOLARS_POST_MERGE_PRODUCTION_DEPLOYMENT_VERIFICATION_2026-11-06.md "Earlier post-merge production sitemap verification"
[9]: https://www.scholars.com.ng/scholarships-in-nigeria "Scholars public scholarship collection"
[10]: https://www.scholars.com.ng/opportunities-for-students "Scholars public opportunity collection"
[11]: https://www.scholars.com.ng/scholarship/m-kukoyi-foundation-mkf-scholarship-2026-a06f2b07 "Scholars active scholarship detail example"
[12]: https://www.scholars.com.ng/opportunity/linux-foundation-lfx-mentorship-fa021582 "Scholars opportunity detail example"
[13]: https://github.com/ImperioKDB/Scholars/blob/main/app/scholarship/%5Bslug%5D/page.tsx "Scholars scholarship public template"
[14]: https://developers.google.com/search/docs/appearance/structured-data/intro-structured-data "Google Search Central structured data guidance"
[15]: https://developers.google.com/search/docs/crawling-indexing/links-crawlable "Google Search Central crawlable links guidance"
[16]: https://www.scholarshipair.com/ "ScholarshipAir public site"
[17]: https://candidate.scholastica.ng/ "Scholastica public site"
[18]: https://opportunityfinder.com.ng/ "Opportunity Finder public site"
[19]: https://www.opportunitiesforafricans.com/ "Opportunities for Africans public site"
[20]: https://scholarship.education.gov.ng/ "Federal Ministry of Education Scholarship Portal"
[21]: https://opportunitydesk.org/ "Opportunity Desk public site"
[22]: https://www.scholars.com.ng/sitemap.xml "Scholars live sitemap"
[23]: https://github.com/ImperioKDB/Scholars/blob/main/supabase/migrations/0085_seed_verified_user_requested_scholarships_2026.sql "Scholars verified scholarship rules and application data examples"
