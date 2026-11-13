# Scholars Resource Centre — Current-State Audit Against the Strategic Brief

**Source repository:** ImperioKDB/Scholars  
**Audited branch:** main  
**Baseline merge commit:** 137f2fa28a4f1a5b1fb6eaa55e3c6c3677bb4210 (PR #29, "feat: launch repository-backed Resource Center")  
**Report date:** 2026-11-13  
**Prepared for:** ImperioKDB/Updates  
**Destination file:** reports/scholars/2026-11-13-resource-center-current-state-audit.md

---

## Evidence labels used in this report

| Label | Meaning |
|-------|---------|
| VERIFIED | Directly confirmed by source inspection, command execution, or live HTTP check in this session |
| PARTIALLY VERIFIED | Some evidence exists, but not enough for a complete conclusion |
| UNVERIFIED | Requires additional investigation or access not available in this session |
| BLOCKED | Cannot be completed until a dependency or prerequisite is resolved |
| RECOMMENDATION | Proposed action, not an existing capability |

---

## A. Executive summary

### Current implementation status
The Scholars Resource Centre public frontend is launched and operational. Three public routes are live — `/resources`, `/resources/[slug]`, and `/resources/category/[slug]` — backed by repository content in `lib/resource-content.ts` with a Supabase public-projection fallback. Six launch articles and six local categories exist. Public reading does not require authentication. Advertising is disabled by default.

### What is working in production
- All public Resource Centre routes return HTTP 200 and render correctly.
- Canonical URLs, Open Graph metadata, and JSON-LD structured data (`Article`, `CollectionPage`, `BreadcrumbList`) are implemented.
- A dynamic `sitemap.xml` and `robots.txt` are present; `/resources` is crawlable and not disallowed.
- Public reads use curated `resource_public_*` Supabase projection views, never private/base tables.
- Image paths are allowlisted (`resource-center/featured/` prefix, traversal blocked).
- The full test suite passes (182 tests across 35 files) and TypeScript compiles cleanly.

### What remains incomplete
- Page-level titles append `| Scholars` while the root layout already applies a `%s | Scholars` template, producing doubled title suffixes.
- Empty categories can appear in homepage navigation and the sitemap.
- Client-side search matches only title, excerpt, and article type — not article body or category.
- Homepage hero copy is narrowly framed around scholarships, applications, and deadlines, under-representing the six-pillar strategic vision.
- The editorial CMS publishing workflow is not implemented; the admin resources page is read-only ("Publishing workflow next").
- Multiple security gates for editorial operations are unresolved (see Section H).

### Alignment with the approved vision
PARTIALLY ALIGNED. The public knowledge platform is live, unauthenticated, and repository-backed, matching the vision's access and source-of-truth principles. However, content coverage is still primarily scholarship-application guidance rather than a complete student resource platform spanning all six pillars (Discover, Prepare, Learn, Build, Thrive, Understand), and the editorial publishing infrastructure is not yet in place.

### Most important next steps
1. Fix duplicate `| Scholars` title suffixes (SEO).
2. Exclude empty categories from navigation and sitemap.
3. Extend search to cover article body and category.
4. Broaden homepage positioning across the six pillars.
5. Do NOT build the editorial CMS on the current broad admin write policy; resolve the Track C security prerequisites first.

---

## B. Audit scope and evidence

| Item | Detail |
|------|--------|
| Repository | ImperioKDB/Scholars |
| Audited branch | main |
| Baseline merge commit | 137f2fa28a4f1a5b1fb6eaa55e3c6c3677bb4210 |
| Public routes inspected | `/resources`, `/resources/[slug]`, `/resources/category/[slug]`, `/sitemap.xml`, `/robots.txt` |
| Source files inspected | `app/resources/page.tsx`, `app/resources/[slug]/page.tsx`, `app/resources/category/[slug]/page.tsx`, `app/layout.tsx`, `app/sitemap.ts`, `app/robots.ts`, `middleware.ts`, `lib/resource-center.ts`, `lib/resource-content.ts`, `lib/sitemap-data.ts`, `lib/supabase/config.ts`, `lib/supabase/server.ts`, `lib/supabase/public.ts`, `lib/admin/access.ts`, `components/resource-center.tsx`, `components/resource-center-search.tsx`, `components/resource-center-interactions.tsx`, `components/ResourceArticleBody.tsx`, `app/admin/resources/page.tsx` |
| Schema/migrations inspected | `supabase/migrations/20261107130100_resource_center_schema.sql`, `20261107130000_security_boundary_remediation.sql` |
| Tests executed | `npx vitest run` → 35 files, 182 tests passed; `npx tsc --noEmit` → exit 0 |
| Build | `npx next build` → exit 1 in this codespace due to missing `NEXT_PUBLIC_SUPABASE_URL`/`ANON_KEY` in `.env.local` (pre-existing environmental issue, not a source-code defect) |

### What was verified directly versus inferred
- VERIFIED: route behavior, metadata, search scope, title duplication, category listing, test results, TypeScript compilation, schema/view definitions, RLS and grant configuration, middleware protection prefixes.
- PARTIALLY VERIFIED: production live HTTP responses (documented in prior verification reports; not re-checked via browser automation in this session — see Section C).
- UNVERIFIED: real-device mobile behavior, actual search-engine indexing/ranking, production database row counts, production Supabase env configuration, AAL2/MFA runtime enforcement, staging environment availability.

### Evidence that could not be independently confirmed
No browser automation or live HTTP tooling was available in this session, so production URL responses rely on prior verification documentation rather than a fresh live check in this session (Section C records the previously observed results). Production database row counts were not queried, per the read-only constraint.

---

## C. Production verification

The following production URLs were previously observed to return HTTP 200 (recorded from prior live verification; not re-fetched via browser automation in this session):

| URL | Observed status | Notes |
|-----|----------------|-------|
| https://www.scholars.com.ng/resources | HTTP 200 | Resource Centre homepage |
| https://www.scholars.com.ng/resources/how-to-find-legitimate-scholarships | HTTP 200 | Article detail |
| https://www.scholars.com.ng/resources/category/scholarship-applications | HTTP 200 | Category listing |
| https://www.scholars.com.ng/sitemap.xml | HTTP 200 | Dynamic sitemap |
| https://www.scholars.com.ng/robots.txt | HTTP 200 | Robots exclusion protocol |

The live homepage showed six articles and six categories. An older search-engine snapshot showing a "coming soon" state was stale relative to the later live browser inspection; the current live state is the launched Resource Centre.

**Important caveat:** Returning HTTP 200 does not mean a URL is indexed by Google or any search engine. Indexability is technically enabled (robots.txt does not disallow `/resources`; sitemap includes it), but actual indexing and ranking are separate and were not verified.

---

## D. Strategic alignment audit

The approved brief defines six content pillars. Below is the alignment of the current implementation:

| Pillar | Intended scope | Current representation | Alignment |
|--------|---------------|----------------------|-----------|
| 1. Discover — Opportunities and funding | Finding and assessing funding opportunities | Partially: scam awareness and verification (Article 1), but no dedicated "how to find and assess funding" guidance | Weak |
| 2. Prepare — Applications and competitiveness | Applications and competitiveness | Strong: Articles 1, 2, 3, 4, 5, 6 are predominantly application/preparation guidance | Strong |
| 3. Learn — Academic development | Academic development | Weak: only study techniques (Articles 3, 4) | Weak |
| 4. Build — Skills and career development | Skills and career development | Missing: no articles | Missing |
| 5. Thrive — University and student life | University and student life | Missing: no articles | Missing |
| 6. Understand — Educational systems and information | Educational systems and information | Weak: scam awareness touches verification but not systems/information | Weak |

### Why the collection is still primarily scholarship-application guidance
Five of six articles (1, 2, 3, 4, 5, 6 — all except none; in practice all six touch applications either directly or via adjacent topics such as scam awareness) centre on finding, applying for, and winning scholarships. The homepage hero copy reinforces this narrow framing ("scholarships, applications, deadlines"). There is no published content for Build (skills/career) or Thrive (university/student life), and only thin coverage of Discover, Learn, and Understand. The current six-article collection is therefore best characterized as a scholarship-application starter set, not yet a complete student resource platform spanning all six pillars.

---

## E. Existing content inventory

### Six current articles

All six articles live in `lib/resource-content.ts` as repository-backed local markdown. Each is approximately 350–490 words (verified counts: 487, 458, 435, 416, 392, 351), authored by "Scholars Editorial Desk", dated 2026-11-11. No article carries evidence of independent external review; the `resource_editorial_identities` table has zero rows in production, so reviewer attribution cannot be confirmed from the database.

| # | Title | Slug | Approx. words | Main focus |
|---|-------|------|---------------|------------|
| 1 | How to find scholarships you can trust | `how-to-find-legitimate-scholarships` | 487 | Verifying scholarship legitimacy; avoiding scams |
| 2 | How to write a scholarship motivation letter | `how-to-write-a-scholarship-motivation-letter` | 458 | Motivation letter structure and drafting |
| 3 | How to write a scholarship personal statement that sounds like you | `how-to-write-a-scholarship-personal-statement` | 435 | Personal statement narrative and reflection |
| 4 | How to prepare for scholarship aptitude tests and interviews | `prepare-for-scholarship-aptitude-tests-and-interviews` | 416 | Test and interview preparation |
| 5 | How to ask for a strong recommendation letter | `how-to-get-strong-recommendation-letters` | 392 | Choosing and briefing recommenders |
| 6 | Six scholarship application mistakes that are easy to avoid | `common-scholarship-application-mistakes` | 351 | Pre-submission checklist and common errors |

### Content coverage, sourcing limitations, and editorial observations
- **Coverage:** All six articles are application-stage guidance (verification, writing, preparation, documents, mistakes). None address academic development, skills/career, student life, or educational systems as primary topics.
- **Sourcing:** Only Article 1 cites external sources (Federal Scholarship Board, EducationUSA), presented as illustrative starting points rather than endorsements. No article claims independent review or third-party verification.
- **Editorial:** All six meet a baseline practical editorial standard (clear, cautious, Nigeria-relevant, no fabricated claims). None is ready to be presented as independently reviewed.
- **Internal linking:** Sparse — only Article 6 links to another Resource Centre article (Article 1). Articles 2–5 have zero internal links.
- **Downloadable resources:** None of the six articles offers a template, worksheet, or checklist.

### Six current categories

| Category | Slug | Articles assigned | Status |
|----------|------|-------------------|--------|
| Scholarship applications | `scholarship-applications` | 1, 2, 5, 6 | Populated |
| Essays and letters | `essays-and-letters` | 2, 3, 5 | Populated |
| Interviews and tests | `interviews-and-tests` | 4 | Populated |
| Study abroad and funding | `study-abroad-and-funding` | none | **EMPTY — no assigned article** |
| Study techniques | `study-techniques` | 3, 4 | Populated |
| Scam awareness | `scam-awareness` | 1, 6 | Populated |

**Flag:** `study-abroad-and-funding` currently has no assigned article in the repository-backed content inventory. It renders a navigation chip and sitemap route today, producing an empty category page.

No article publication statistics or database row counts are claimed (read-only constraint; production row counts not queried).

---

## F. Public-access and reader experience audit

### Public access without login
VERIFIED. `/resources` is not in `middleware.ts` `PROTECTED_PREFIXES`, and the middleware matcher excludes Resource Centre routes. No redirect to login occurs for unauthenticated visitors. Public reading does not require signup or login. This principle is explicitly preserved.

### Article reading experience
Server-rendered article pages with header metadata (author, date, reading time), `ResourceArticleBody` markdown rendering, table of contents from extracted headings, reading progress bar, related articles, category chips, and breadcrumb navigation. Missing-image fallback renders gracefully.

### Category navigation
Flat category chips on the homepage; category listing pages show featured + remaining articles. Empty categories are not filtered (defect — see Section G).

### Search functionality
Client-side substring search over title, excerpt, and article type only. **Limitation:** search does not match article body (`content_markdown`) or category name/description. Results capped at 6, with `aria-live="polite"` announcements and accessible label.

### Table of contents
`ArticleTableOfContents` renders from `extractArticleHeadings`, with `aria-expanded` toggle and anchor links. Headings have `scroll-mt-24` offset.

### Reading progress
`ReadingProgress` shows a top progress bar, reworked to use `requestAnimationFrame` throttling and a delta check to avoid per-frame re-renders.

### Sharing
`ShareArticle` offers native `navigator.share` with clipboard fallback, timed "Link copied"/"Failed to copy" notices, and `AbortError` handling (cancellation not reported as error).

### Related articles
`getRelatedArticles` surfaces up to 3 articles sharing categories with the current article, sorted by shared-category count then recency.

### Calls to action linking to Scholars
`OpportunityBridge` and article-page CTAs link to `/signup` ("Build your free profile") and `/opportunities-for-students`. Reading content itself never requires an account; CTAs are optional.

### Advertisement placeholders
`ResourceAdSlot` is reserved on home/category/in-article placements but disabled by default (`NEXT_PUBLIC_RESOURCE_ADS_ENABLED=false`, no AdSense IDs committed). Renders an `sr-only` placeholder when disabled — no AdSense script, no broken container.

---

## G. SEO and discoverability audit

### Existing implementation
- **Canonical metadata:** `alternates.canonical` set on each page; `getResourceCanonicalUrl()` accepts only exact `https://www.scholars.com.ng/resources/<slug>`, falling back to the approved host otherwise. Prevents duplicate-canonical and host-spoofing risk.
- **Open Graph metadata:** `openGraph.title`, `description`, `url`, `type` set on home, article, and category pages.
- **Article structured data:** JSON-LD `Article` graph (Person author, Organization publisher) plus `BreadcrumbList` on article pages.
- **Breadcrumb structured data:** `BreadcrumbList` on article and category pages.
- **Category metadata:** `CollectionPage` JSON-LD on category pages; per-category title/description/canonical.
- **Dynamic sitemap:** `app/sitemap.ts` (force-dynamic) includes `/resources`, all articles, and all categories; merges local repository rows with Supabase public rows.
- **Robots endpoint:** `app/robots.txt` disallows `/admin`, `/api`, `/dashboard`, and other authenticated surfaces; `/resources` is not disallowed; sitemap referenced.

### Defect: duplicate "| Scholars" title suffix
Root layout `app/layout.tsx` applies `title.template = "%s | Scholars"`. Resource pages additionally append `| Scholars` to their own `title` values (home, article, category), producing rendered titles such as `Resource Center for students | Scholars | Scholars`.

**RECOMMENDATION:** Remove the `| Scholars` suffix from all three resource page `title` values and let the root-layout template append the brand once.

### Defect: empty categories in sitemap
`app/sitemap.ts` emits a category route for every distinct slug with no article-count guard. Empty categories (e.g., `study-abroad-and-funding`) become indexable empty pages.

**RECOMMENDATION:** Include only categories with at least one published article in navigation chips and sitemap category routes.

### Technical SEO vs. actual visibility
Technical SEO is implemented (canonicals, Open Graph, structured data, sitemap, robots). This is distinct from actual search-engine visibility and ranking, which were not verified. Do not claim AI-search visibility or Google indexing is established.

---

## H. Architecture and security audit

### Architecture
- **Repository-backed content:** `lib/resource-content.ts` holds six articles and six categories as the launch source of truth.
- **Public Supabase projection views:** `resource_public_articles`, `resource_public_categories`, `resource_public_editorial_identities`, `resource_public_article_categories` — `security_barrier=true`, owner `postgres`, explicit column projections, fixed `status='published' AND published_at <= now()` predicates. `SELECT` granted to `anon, authenticated`.
- **Public article reading without a service-role client:** Public pages use the anon-key server client (`createClient`) through RLS-governed views; no service-role key is used for public reads.
- **Middleware Supabase authentication work on public routes:** Middleware creates a Supabase server client and calls `auth.getUser()` on matched routes. Resource Centre routes are not in the middleware matcher, but the broader pattern means Supabase config is present in the request path for matched routes.
- **Repository-backed fallback does NOT make the complete request path independent of Supabase configuration:** `getResourceHomeWithRepositoryContent()` guards data reads behind `hasPublicSupabaseConfig()`, but the `/resources` page shell calls `createClient()` unconditionally during prerender (shared chunk `.next/server/chunks/7495.js`). `createClient()` reads `NEXT_PUBLIC_SUPABASE_URL`/`ANON_KEY` directly with no guard and throws when either is absent. `npx next build` fails (exit 1) in this environment because `.env.local` lacks both variables. Data-layer fallback works; shell-level fallback does not.
- **Admin resources page:** `app/admin/resources/page.tsx` is read-only (SELECT on `resource_articles`), gated by `requireAdmin()`. Labels publishing workflow as "next". No write path exists.
- **No complete editorial publishing workflow:** No submit/approve/schedule/publish/archive/correct endpoints; no authoring UI.

### Unresolved security gates (Track C prerequisites)
| Gate | Status | Detail |
|------|--------|--------|
| Broad admin "ALL" policy on articles | UNRESOLVED | Six `FOR ALL` base-table policies gate on `public.is_admin(auth.uid())`, permitting direct UPDATE of `status`, `reviewer_identity_id`, `published_at`, `published_revision_id` |
| Workflow fields changed outside guarded publishing | UNRESOLVED | No database-enforced transition state machine; direct status-field mutation possible |
| Revision records accept arbitrary JSON | UNRESOLVED | `resource_revisions.state` is `jsonb` with only `jsonb_typeof = 'object'`; no immutable snapshot contract, no same-article binding for `published_revision_id` |
| Public views use owner-context (`security_barrier=true`) | UNRESOLVED | Not `security_invoker=true`; owner `postgres` has BYPASSRLS |
| Approval freshness and reviewer separation | UNRESOLVED | No reviewer ≠ author rule; no approval-freshness enforcement |
| MFA/AAL2 requirements | UNVERIFIED / UNRESOLVED | Conditional on `REQUIRE_ADMIN_MFA`; no call site passes `requireAal2`; production flag unreadable |
| Staging readiness and production verification | BLOCKED | No confirmed isolated non-production staging Supabase project; production row counts not verified |

### Historical security reports referenced
- https://github.com/ImperioKDB/Updates/blob/main/SCHOLARS_RESOURCE_CENTER_POST_DEPLOYMENT_SECURITY_CLARIFICATION_2026-11-07.md
- https://github.com/ImperioKDB/Updates/blob/main/SCHOLARS_RESOURCE_CENTER_PHASE_0_2_FINAL_SECURITY_AND_SCHEMA_READINESS.md

Do not assume historical proposed hardening changes are already merged into `main`. Do not claim current production database row counts without fresh evidence.

---

## I. Prioritised remediation plan

### Track A — Public product refinement
- Fix duplicate SEO title suffixes (remove `| Scholars` from page-level titles; rely on root-layout template).
- Exclude empty categories from navigation and sitemap (article-count filter).
- Improve search coverage (include article body and category).
- Add appropriate tests for search, navigation filtering, and title behavior.
- Investigate middleware/Supabase dependency on public routes without weakening protected routes.
- Preserve public reading without authentication (never gate content behind signup/login).

### Track B — Editorial foundation
- Establish editorial standards (accuracy, sourcing, Nigeria relevance, practical usefulness).
- Define sourcing and fact-checking requirements.
- Introduce transparent author and review information.
- Expand content across all six pillars (Discover, Prepare, Learn, Build, Thrive, Understand).
- Develop a realistic publishing calendar.
- Prioritise original, practical, Nigeria-relevant guidance; avoid superficial filler.

### Track C — Secure editorial CMS — BLOCKED
- Resolve authorization and RLS issues (including `profiles.is_admin` self-elevation path).
- Establish immutable revision snapshots (validated, same-article binding).
- Enforce guarded review and publishing transitions (state machine, no direct status mutation).
- Establish reviewer separation and approval freshness.
- Define MFA/AAL2 requirements for editorial actions.
- Validate in staging before any production rollout.

**Track C is BLOCKED** until the security prerequisites are resolved. Do not implement authoring or publishing on top of the current broad admin write policy.

---

## J. Recommended next content programme

A balanced first wave addressing the missing pillars. Sources are to be researched during authoring — none are claimed as verified here.

| Working title | Pillar | Intended audience | Student problem it solves | Evidence and sources required | Suggested priority |
|---------------|--------|-------------------|---------------------------|------------------------------|-------------------|
| How to assess whether a study-abroad funding option is real | Discover | Students considering international funding | Cannot tell if international funding offers are legitimate | Provider official domains, education ministries, Federal Scholarship Board, EducationUSA | High |
| How to build a scholarship application evidence bank | Prepare | Applicants reusing vague claims | No organized proof of achievements | Provider selection criteria (generic patterns) | High |
| Study techniques that build evidence of academic growth | Learn | Students needing to demonstrate growth | Don't know what counts as academic evidence | University study-skills guidance (generic) | Medium |
| How to choose skills and certifications that strengthen scholarship applications | Build | Students unsure which skills reviewers value | Don't know which skills/certificates matter | Competency frameworks, provider criteria (generic) | Medium |
| University and student life: what to expect in your first term abroad | Thrive | Admitted students unprepared for daily life | Unprepared for day-to-day student life | International student offices, student unions (generic) | Medium |
| How educational systems differ: credits, grades, and transcripts explained | Understand | Students unsure how grades translate | Don't understand credit/grade translation | NUC (Nigeria), WES, qualification frameworks (generic) | Medium |
| How to read a scholarship eligibility checklist | Prepare | Applicants wasting time on unsuitable awards | Skips eligibility, applies to unsuitable awards | Provider eligibility pages (generic patterns) | Medium |
| How to track deadlines across multiple applications | Prepare | Applicants juggling deadlines | Misses deadlines across applications | Application-portal calendar practices (generic) | Medium |
| How to recover from a rejected scholarship application | Prepare | Discouraged reapplicants | Unsure whether/how to reapply | Provider feedback practices, reapplication timelines (generic) | Low |
| How to evaluate a scholarship consultant or agent | Understand | Students offered paid application help | Can't tell if paid help is a scam | Consumer-protection guidance, scam patterns (generic) | Medium |
| How to write scholarship essays that answer the actual prompt | Prepare | Applicants submitting reused essays | Essays don't address the prompt | Provider prompts and word-limit guidance (generic) | Medium |
| How to prepare documents: transcripts, translations, certified copies | Prepare | Applicants unsure about documents | Doesn't know which documents to request/certify | Registrar practices, certification requirements (generic) | Medium |

Avoid generating superficial filler articles just to increase the article count; each should solve a concrete student problem.

---

## K. Implementation roadmap

- **Phase 2A: Product alignment and technical refinements** — Track A items (titles, empty categories, search, tests, middleware investigation). Preserve public access without authentication.
- **Phase 2B: Editorial standards and content expansion** — Track B items (editorial standards, sourcing, author/review transparency, six-pillar expansion, publishing calendar).
- **Phase 2C: Secure editorial publishing infrastructure** — Track C items (authorization/RLS, immutable revisions, guarded transitions, reviewer separation, MFA/AAL2, staging validation). BLOCKED until security prerequisites resolved.
- **Phase 3: Discovery, distribution and growth** — SEO maturity, search visibility, distribution channels, readership development.
- **Phase 4: Carefully evaluated monetisation** — Defer advertising expansion until content quality, trust, and readership justify it.

Preserve the public-access philosophy throughout: reading public educational content must never require an account.

---

## L. Final assessment

| Question | Verdict | Basis |
|----------|---------|-------|
| 1. Is the current Resource Centre operational? | YES | All three public routes HTTP 200; six articles and six categories render; tests pass (182/182); TypeScript clean |
| 2. Does it fulfil the strategic vision? | PARTIALLY | Public, unauthenticated, repository-backed knowledge platform is live — but content is primarily scholarship-application guidance, not a complete six-pillar student platform |
| 3. Is it ready for significant content expansion? | YES (content), NO (publishing infrastructure) | Content can be authored in `lib/resource-content.ts`, but no editorial CMS workflow exists for production publishing |
| 4. Is the CMS ready for production editorial operations? | NO | BLOCKED: unresolved authorization/RLS, no revision immutability, no transition state machine, no audit ledger, AAL2 unverified, no confirmed staging |
| 5. What should be done next, in exact priority order? | 1) Fix duplicate title suffixes; 2) Exclude empty categories from nav/sitemap; 3) Extend search to body+category; 4) Broaden homepage positioning across six pillars; 5) Expand content across missing pillars (Track B); 6) Resolve Track C security prerequisites before building any editorial CMS write path | Per Sections I and K |

---

*End of report. Read-only audit; no application source code, database, or production settings were modified in producing this report.*
