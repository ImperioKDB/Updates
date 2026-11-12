# Scholars Resource Centre — Baseline Audit

**Repository:** ImperioKDB/Scholars
**Working directory:** `/workspaces/Scholars`
**Branch:** `feature/resource-center-public-frontend`
**HEAD commit:** `c2fc789` — "fix: resource-center test file reading and sitemap local content inclusion"
**Audit date:** Thu Nov 12 2026
**Scope:** Read-only inspection. No application source files, tests, configuration, or deployment settings were modified. One new audit report was created.

---

## 1. Repository state and inspected commit

| Item | Value |
|---|---|
| Working directory | `/workspaces/Scholars` |
| Repository | ImperioKDB/Scholars |
| Branch | `feature/resource-center-public-frontend` |
| HEAD | `c2fc789` fix: resource-center test file reading and sitemap local content inclusion |
| git status | Clean tracked tree; untracked audit/report files present (see below) |
| Ignored artifacts | `.codegraph/`, `.env.local`, `.next/`, `.vercel/`, `node_modules/`, `private-backups/` |

### Untracked user work preserved (not touched)

`.agents/`, `CODEGRAPH_FRESH_SESSION_VERIFICATION_2026-11-12.md`, `CODEGRAPH_INSTALLATION_REPORT.md`, `OPENCODE_CAPABILITY_TEST.md`, `OPENCODE_STAGE_1_DEFECT_SELECTION.md`, `OPENCODE_STAGE_2_COMBOBOX_IMPLEMENTATION_REPORT.md`, `PR31_*` reports, `PR_30_REVIEW_EVIDENCE.md`, `PR_31_REVIEW_EVIDENCE.md`, `RESOURCE_CENTER_*` reports, `SCHOLARS_AUDIT_REPORT.md`, `SCHOLARS_OPENCODE_SKILLS_RUNTIME_VERIFICATION_2026-11-12.md`, `SRC UPDATES.md`, `next-env.d.ts`, `scholars-phase-2-1-8-blocker-report.md`, `skills-lock.json`.

No branches switched, no files reset/stashed/cleaned/overwritten, no commits or pushes made.

---

## 2. Skill runtime verification evidence

OpenCode's native `skill` tool was invoked for each of the seven installed skills. Instructions were loaded into context for each invocation (base directory confirmed as `.agents/skills/<name>/`).

| Skill | Discovered | Native invocation successful | Relevant guidance | Issues |
|---|---|---|---|---|
| `emil-design-eng` | Yes | Yes | Design engineering philosophy; animation decision framework; press feedback (`scale(0.97)` on `:active`); avoid `ease-in`, `scale(0)` entries, `transition: all`; respect `prefers-reduced-motion`; origin-aware popovers; CSS transitions over keyframes for dynamic UI | None |
| `frontend-design` | Yes | Yes | Distinctive visual identity over templated defaults; deliberate typography; one or two typefaces; intentional type scale; line lengths < 80 chars; non-user-triggered motion sparingly; copy as design content | None |
| `mobile-native` | Yes | Yes | Viewport meta (`viewport-fit=cover`, `interactive-widget=resizes-content`); `-webkit-tap-highlight-color: transparent`; `100dvh`/`100svh`; 16px input font size; `touch-action: manipulation`; `overscroll-behavior`; `env(safe-area-inset-*)`; `user-select: none` on controls only; per-scheme `theme-color` | None |
| `seo` | Yes | Yes | One primary intent per page; title ~50-60 chars; meta description ~120-160 chars; one H1; `Article`/`BreadcrumbList` JSON-LD; crawlability/indexability; internal linking with descriptive anchors | None |
| `vercel-react-best-practices` | Yes | Yes | 70 rules across 8 categories: eliminate waterfalls, bundle size, server performance, client data fetching, re-render, rendering, JS performance, advanced patterns | None |
| `webapp-testing` | Yes | Yes | Playwright reconnaissance-then-action pattern; `wait_for_load_state('networkidle')`; `with_server.py` helper scripts; `sync_playwright()`; headless Chromium | None |
| `web-design-guidelines` | No | No | N/A — not installed | Skill not present in `.agents/skills/` or `skills-lock.json`; `skill` tool reports "Unable to load skill web-design-guidelines" |

Six of seven skills are installed and loadable natively. `web-design-guidelines` is referenced in the project skill inventory but is **not installed** — its directory is absent from `.agents/skills/` and it is absent from `skills-lock.json`.

### Overlapping instructions and precedence

- **Mobile viewport/touch/safe areas:** `mobile-native` takes precedence (platform-layer authority; `emil-design-eng` touches touch targets only as a secondary concern).
- **Animation/motion and press feedback:** `emil-design-eng` takes precedence (deep animation decision framework; `mobile-native` defers motion to `animate` skill and focuses on platform layer).
- **Visual hierarchy/typography/layout distinctiveness:** `frontend-design` takes precedence.
- **SEO/metadata/structured data:** `seo` takes precedence.
- **React/Next.js performance and data fetching:** `vercel-react-best-practices` takes precedence.
- **Testing strategy:** `webapp-testing` takes precedence.

---

## 3. Resource Centre architecture summary

### Public routes
- `app/resources/page.tsx` — Resource Center home (server component). Reads via `getResourceHomeWithRepositoryContent()`; falls back to local content. Renders masthead frame, breadcrumbs, hero, category chips, search, featured/latest articles, `OpportunityBridge`, `ResourceAdSlot`.
- `app/resources/[slug]/page.tsx` — Article detail (server component). `generateMetadata` reads article via `getResourceArticleWithRepositoryContent()`; canonical URL via `getResourceCanonicalUrl()`. Renders `ResourcePageFrame`, `ReadingProgress` (client), `SeoJsonLd`, article header with breadcrumbs/meta/share, `ResourceArticleBody`, table of contents, author bio, category chips, related articles, CTA section.
- `app/resources/category/[slug]/page.tsx` — Category listing (server component). Metadata from `getResourceCategoryWithRepositoryContent()`. Renders featured + remaining articles, bridge, ad slot, back link.

### Shared components
- `components/resource-center.tsx` — `ResourceMasthead`, `ResourcePageFrame`, `ResourceAdSlot`, `ResourceImage`, `ResourceCard`, `ResourceEmptyState`, `ResourceErrorState`, `OpportunityBridge`.
- `components/resource-center-interactions.tsx` (`"use client"`) — `ResourceMobileNav`, `ReadingProgress`, `ArticleTableOfContents`, `ShareArticle`, `useHeadingIds`, `slugify`.
- `components/resource-center-search.tsx` (`"use client"`) — client-side fuzzy substring search over articles with `aria-live="polite"` results.
- `components/ResourceArticleBody.tsx` — markdown-ish block parser (headings/lists/quotes/paragraphs) with inline link/emphasis rendering; `extractArticleHeadings`, `safeHref`, `slugify`.

### Data layer
- `lib/resource-center.ts` — public projection reads (`resource_public_articles`, `resource_public_categories`, `resource_public_article_categories`), `ResourceDataError`, canonical URL normalization, image path allowlist (`resource-center/featured/` prefix), repository-content merge (`LOCAL_*` primary over published), `getResourceImageUrl` via Supabase Storage public URL.
- `lib/resource-content.ts` — six local categories and five local articles as markdown, plus derived card lists.
- `lib/sitemap-data.ts` — sitemap rows for resources + categories, merging local repository rows with public projection rows.

### Admin route
- `app/admin/resources/page.tsx` — read-only editorial overview (server component). `requireAdmin()` gate; reads `resource_articles` via server Supabase client; status/type/updated table. No write path.

### Tests
- `lib/resource-center.test.ts` (9), `components/ResourceArticleBody.test.tsx` (4), `components/resource-center.test.ts` (2), `app/resources/page.test.ts` (1) — all pass; 16 Resource Centre tests of 132 total.

### SEO infrastructure
- `app/sitemap.ts` (dynamic), `app/robots.ts`, `app/manifest.ts`, `components/SeoJsonLd.tsx` (`Breadcrumbs` + JSON-LD script), per-page `metadata`/`generateMetadata`.

---

## 4. Current strengths

- **Repository-safe, fail-closed data layer.** Public reads use curated `resource_public_*` projection views, never `resource_articles` or other private/base tables; canonical URLs are normalized to the approved host; image paths are allowlisted (`resource-center/featured/`, no `..`, `\`, `//`). Tests assert these contracts.
- **Repository content as launch source of truth.** Local articles/categories merge over public projection so the public MVP works without Supabase configured; sitemap includes local rows when Supabase is unavailable.
- **Existing test suite passes.** 132 tests across 25 files, including 16 Resource Centre tests covering canonical normalization, image path allowlist, pagination without duplicates, heading ID uniqueness/TOC matching, inline link safety, and eager/lazy image priority.
- **Accessibility foundations present.** `sr-only` search label, `aria-live="polite"` search results, `aria-expanded` on mobile menu and TOC toggle, `role="alert"` on error states, `:focus-visible` rings, `font-size: 16px` on inputs (prevents iOS zoom), `scroll-mt-24` on headings for sticky header offset, `aria-current="page"` on breadcrumbs.
- **Performance-conscious image handling.** `ResourceImage` uses `loading={priority ? "eager" : "lazy"}` and `fetchPriority={priority ? "high" : "auto"}`; featured image eager on cards; missing-image fallback with `aria-hidden="true"`.
- **Reduced-motion support.** `prefers-reduced-motion` disables button press transforms and page animations; `scroll-behavior: auto` under reduced motion.
- **SEO metadata present.** Page titles, descriptions, canonical alternates, OpenGraph, `CollectionPage`/`Article`/`BreadcrumbList` JSON-LD, sitemap includes `/resources` and category routes, `robots.ts` disallows `/admin` and authenticated surfaces.
- **Distinctive visual identity.** Navy/parchment/emerald palette, Fraunces display + Manrope body, emerald/amber/rose tokens darkened to meet WCAG AA (documented in tailwind config comments).

---

## 5. Confirmed defects

### D1 — Mobile nav button lacks `aria-controls` when menu closed / focus management not verified
**Severity:** Medium
**Evidence:** `components/resource-center-interactions.tsx` lines 19-21. The menu button has `aria-expanded={open}` and `aria-controls="resource-mobile-menu"` but the menu container only exists in DOM when `open` is true; when closed, `aria-controls` references a non-existent id. Escape closes menu, but no focus return to trigger button.
**Why it matters:** Screen reader users navigating the mobile menu trigger encounter a dangling `aria-controls` reference; closing the menu drops focus to body rather than returning to the button.
**Recommended correction:** Render the menu container always (hidden via `hidden`/CSS) so `aria-controls` resolves, and return focus to the menu button on close.
**Within approved frontend scope:** Yes.
**Relevant skill:** mobile-native (accessible menus and interactive controls).

### D2 — Search results list lacks `role="list"` and matching items lack `role="listitem"`
**Severity:** Medium
**Evidence:** `components/resource-center-search.tsx` lines 27-33. Matches are rendered as bare `<Link>`/`<a>` inside a `div[role="status"][aria-live="polite"]`; no list semantics.
**Why it matters:** Screen readers announce each match as a live-region string without list context; the status announcement plus links can be redundant/confusing.
**Recommended correction:** Wrap matches in `<ul role="list">` with `<li role="listitem">`; keep `aria-live` on the container or remove if list semantics suffice.
**Within approved frontend scope:** Yes.
**Relevant skill:** mobile-native / frontend-design.

### D3 — `ReadingProgress` scroll listener attaches to `window` and reads `document.documentElement` on every scroll
**Severity:** Low
**Evidence:** `components/resource-center-interactions.tsx` lines 37-46. `window.addEventListener("scroll", update, { passive: true })`; `update` runs `document.documentElement.scrollHeight - window.innerHeight` on every scroll and resize.
**Why it matters:** Per-frame main-thread work on every article scroll; passive listener helps but the callback still executes on the main thread. Minor.
**Recommended correction:** Throttle/rAF the update, or compute `max` once and refresh on resize only.
**Within approved frontend scope:** Yes.
**Relevant skill:** vercel-react-best-practices (`rerender-` / rendering performance).

### D4 — Admin page queries `resource_articles` directly (private table) while public routes use projections
**Severity:** Low (architectural observation, not a user defect)
**Evidence:** `app/admin/resources/page.tsx` line 9: `supabase.from("resource_articles").select(...)`.
**Why it matters:** Inconsistent with the public projection pattern; reads author/reviewer identity IDs that are editorial metadata. Currently read-only and admin-gated, so no data exposure beyond admin.
**Recommended correction:** Keep read-only; no change required in this phase (administrative overview, not CMS). Document for the future editorial workflow phase.
**Within approved frontend scope:** Out of scope for this phase (boundary rule 3 — no CMS/write operations).
**Relevant skill:** N/A (boundary observation).

### D5 — `ResourceAdSlot` renders an empty reserved ad block when ads disabled, contributing layout noise
**Severity:** Low
**Evidence:** `components/resource-center.tsx` lines 29-36. Always renders `<aside aria-label="Advertisement">` with either "Advertisement" text or `sr-only` "Advertisement space reserved".
**Why it matters:** When ads disabled (default per `.env.example` `NEXT_PUBLIC_RESOURCE_ADS_ENABLED=false`), an empty bordered block still occupies `my-8` space on home/category/in-article placements.
**Recommended correction:** Return null when ads are not enabled, or only render the placeholder when enabled.
**Within approved frontend scope:** Yes.
**Relevant skill:** vercel-react-best-practices (bundle/rendering).

---

## 6. Accessibility findings

### A1 (confirmed) — Missing `lang`/`dir` considerations for en-NG content
**Severity:** Low
**Evidence:** `app/layout.tsx` line 58 `<html lang="en">`; article dates formatted with `en-NG` locale (`lib/resource-center.tsx` line 48, `app/resources/[slug]/page.tsx` line 48).
**Why it matters:** Content is Nigerian-English but the page language is generic `en`; screen readers may use wrong pronunciation rules for dates/names.
**Recommended correction:** Consider `lang="en-NG"` if content is consistently Nigerian English; verify with screen reader.
**Within approved frontend scope:** Yes.

### A2 (confirmed) — `ShareArticle` clipboard fallback notice has no persistent status semantics beyond initial render
**Severity:** Low
**Evidence:** `components/resource-center-interactions.tsx` lines 67-77. `notice` state renders `<span role="status">` only when set; once set it remains (never cleared), and `navigator.share` errors silently set `notice=null` without announcement.
**Why it matters:** Inconsistent screen-reader feedback for share/copy outcomes.
**Recommended correction:** Use a timed live-region announcement or reset notice after a short delay.
**Within approved frontend scope:** Yes.
**Relevant skill:** mobile-native.

### A3 (confirmed) — Article headings use `scroll-mt-24` but no verification that offset matches masthead height on mobile
**Severity:** Low
**Evidence:** `components/ResourceArticleBody.tsx` lines 36-37; `ResourceMasthead` height is `py-4` plus border (approx 64px) but `scroll-mt-24` = 96px; on mobile the masthead is shorter so offset may over-compensate.
**Why it matters:** Heading targets may land with excessive offset after anchor/TOC navigation.
**Recommended correction:** Measure masthead height on mobile and align `scroll-mt` accordingly, or use `scroll-padding-top` on the scroll container.
**Within approved frontend scope:** Yes.
**Relevant skill:** mobile-native.

---

## 7. Mobile findings

### M1 (confirmed) — No viewport meta tag on Resource Center pages specifically
**Severity:** Medium
**Evidence:** Root layout (`app/layout.tsx`) has no `<meta name="viewport">`; `app/manifest.ts` and `app/robots.ts` exist but no viewport tag found in layout or resource pages.
**Why it matters:** Without `width=device-width, initial-scale=1, viewport-fit=cover`, mobile browsers use a default viewport (often 980px), causing scaled-down layout and `env(safe-area-inset-*)` values of `0px` (notch content stops at safe area). `100dvh`/`100svh` behave unpredictably without a proper viewport.
**Recommended correction:** Add `<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover, interactive-widget=resizes-content" />` via Next.js `viewport` export or in root layout.
**Within approved frontend scope:** Yes.
**Relevant skill:** mobile-native (Hard Rule: `env()` values are 0 without the meta tag).

### M2 (confirmed) — No per-scheme `theme-color` meta tags
**Severity:** Low
**Evidence:** No `theme-color` meta tags in layout or resource pages; manifest sets `theme_color: #0B1E3D` but HTML meta overrides for browser chrome.
**Why it matters:** Address bar/status bar color may not match the navy brand on mobile browsers.
**Recommended correction:** Add `<meta name="theme-color" media="(prefers-color-scheme: light)" content="#F7F5EF" />` and dark variant.
**Within approved frontend scope:** Yes.
**Relevant skill:** mobile-native.

### M3 (confirmed) — Touch target sizes on category chips and category links may be below 44x44
**Severity:** Low
**Evidence:** `app/resources/page.tsx` line 72 category chips `px-4 py-2.5 text-sm`; category page chips `px-3 py-1.5 text-xs`. Compact padding could yield <44px touch targets on small screens.
**Why it matters:** WCAG 2.2 / mobile-native guidance: touch targets should be at least 44x44 CSS px.
**Recommended correction:** Increase vertical padding or add `min-h-[44px] min-w-[44px]` to interactive chips/links.
**Within approved frontend scope:** Yes.
**Relevant skill:** mobile-native.

### M4 (confirmed) — `user-select: none` not applied to button-like controls; `button:active` scale exists globally via globals.css
**Severity:** Low
**Evidence:** `app/globals.css` lines 97-112 apply `:active` scale to all buttons globally. Resource buttons (`ShareArticle`, `ResourceCard`, chips) use Tailwind classes; long-press text selection not explicitly prevented.
**Why it matters:** Long-press on controls may select label text on iOS.
**Recommended correction:** Add `user-select: none` / `-webkit-touch-callout: none` to button-like controls (share button, chips).
**Within approved frontend scope:** Yes.
**Relevant skill:** mobile-native.

---

## 8. Performance findings

### P1 (confirmed) — `ReadingProgress` main-thread scroll listener (see D3)
**Severity:** Low
**Evidence:** `components/resource-center-interactions.tsx` lines 37-46.

### P2 (confirmed) — Client-side search re-runs filter on every keystroke over full article list (currently 5 local articles, small; scales with content)
**Severity:** Low
**Evidence:** `components/resource-center-search.tsx` lines 10-13: `useMemo` filter over `articles` array on every `normalized` change.
**Why it matters:** Fine at 5 articles; if the list grows to dozens/hundreds, per-keystroke filtering on the main thread could cause input lag.
**Recommended correction:** Debounce input or memoize with a search index; keep client-side since dataset is small and public.
**Within approved frontend scope:** Yes.
**Relevant skill:** vercel-react-best-practices (`client-`, `rerender-`).

### P3 (confirmed) — `ResourceAdSlot` always mounts an empty aside when ads disabled (see D5)
**Severity:** Low
**Evidence:** `components/resource-center.tsx` lines 29-36.

### P4 (observation) — Server components fetch data sequentially within `getResourceHome` (`Promise.all` used for articles + categories — good); `getResourceArticle` fetches article then categories then related (sequential waterfall)
**Severity:** Low
**Evidence:** `lib/resource-center.ts` lines 105-128: article fetch, then categories, then `getRelatedArticles` which paginates `resource_public_article_categories` then `readArticlesByIds`.
**Why it matters:** Sequential dependent fetches on article page add request latency; acceptable for MVP with small data.
**Recommended correction:** Consider parallelizing independent fetches where data allows.
**Within approved frontend scope:** Yes.
**Relevant skill:** vercel-react-best-practices (`async-parallel`, `server-parallel-fetching`).

---

## 9. SEO findings

### S1 (confirmed) — Canonical URL normalization is strict and correct
**Evidence:** `lib/resource-center.ts` lines 140-154; `getResourceCanonicalUrl` only accepts exact `https://www.scholars.com.ng/resources/<slug>`; falls back to approved host otherwise. Tests confirm (9 cases).
**Assessment:** Strength — no duplicate canonical risk.

### S2 (confirmed) — Structured data present on home, article, and category pages
**Evidence:** `app/resources/page.tsx` lines 30-37 (`CollectionPage`); `app/resources/[slug]/page.tsx` lines 41-46 (`Article` + `BreadcrumbList` graph); `app/resources/category/[slug]/page.tsx` lines 33-33 (`CollectionPage` + `BreadcrumbList`).
**Assessment:** Strength. `Article` schema uses `author` (Person) and `publisher` (Organization).

### S3 (confirmed) — Sitemap includes `/resources`, resource articles, and category routes
**Evidence:** `app/sitemap.ts` lines 13, 61-75; static paths include `/resources`.
**Assessment:** Strength.

### S4 (confirmed) — `robots.ts` does not disallow `/resources` (correctly crawlable)
**Evidence:** `app/robots.ts` lines 16-32 disallow list; `/resources` not present.
**Assessment:** Strength.

### S5 (observation) — Meta description on home page is generic; no per-category unique descriptions beyond category description fallback
**Severity:** Low
**Evidence:** `app/resources/page.tsx` line 12 fixed description; category page line 15 falls back to `Guides and updates in ${category.name}.`.
**Recommended correction:** Keep as-is; descriptions are present and unique enough. No action required.

---

## 10. Test coverage gaps

### T1 (confirmed gap) — No Playwright / end-to-end tests exist
**Evidence:** No `playwright.config.*`, no `*.spec.*` or e2e files found; `webapp-testing` skill installed but unused.
**Why it matters:** Interactions (mobile nav open/close, search typing + results, TOC anchor navigation, share copy) are untested at the browser level; regression risk for keyboard/screen-reader flows.
**Recommended correction:** Add Playwright coverage for Resource Center: home loads, search filters results, article TOC links navigate, mobile menu opens/closes with Escape.
**Within approved frontend scope:** Yes.
**Relevant skill:** webapp-testing.

### T2 (confirmed gap) — No tests for `ResourceSearch`, `ResourceMobileNav`, `ReadingProgress`, `ShareArticle`, `ArticleTableOfContents` client components
**Evidence:** Test files exist only for `ResourceArticleBody`, `resource-center` source-contract, `page` source-contract, and `lib/resource-center`.
**Why it matters:** Client interaction behavior (focus management, `aria-expanded`, live announcements) is unverified.
**Recommended correction:** Add vitest + @testing-library/react tests for these components.
**Within approved frontend scope:** Yes.
**Relevant skill:** webapp-testing.

### T3 (observation) — `page.test.ts` and `resource-center.test.ts` are source-grep tests (read file and assert string presence) rather than behavioral tests
**Evidence:** `app/resources/page.test.ts` reads `app/resources/page.tsx` and asserts absence of "View all"; `components/resource-center.test.ts` asserts source contains image-loading attributes.
**Why it matters:** They guard against regressions in the source contract but do not render behavior. Complementary, not sufficient alone.
**Recommended correction:** Continue adding behavioral tests; keep source-contract tests as guards.
**Within approved frontend scope:** Yes.

---

## 11. Security and architectural observations

### SEC1 — Admin page is read-only and correctly gated
**Evidence:** `app/admin/resources/page.tsx` lines 6-9: `requireAdmin()` then a `SELECT` on `resource_articles`. No write operations, no RLS changes, no credentials exposed to client.
**Assessment:** Compliant with boundary rules 1-6. The page remains an editorial overview, not a CMS (boundary rule 3 respected).

### SEC2 — Public data layer uses `resource_public_*` projections; no private tables queried
**Evidence:** `lib/resource-center.test.ts` line 88 asserts `resource_articles` not in mocked calls; `lib/supabase/public.ts` comment documents the public-client contract.
**Assessment:** Strength.

### SEC3 — Image path allowlist prevents path traversal
**Evidence:** `lib/resource-center.ts` lines 136-138 `isApprovedResourceImagePath`; tests lines 39-45.
**Assessment:** Strength.

### SEC4 — Canonical URL normalization prevents open-redirect/host-spoofing via stored canonical
**Evidence:** `lib/resource-center.ts` lines 140-154; tests lines 47-63.
**Assessment:** Strength.

### SEC5 — `NEXT_PUBLIC_RESOURCE_ADS_ENABLED` defaults false; AdSense IDs not committed
**Evidence:** `.env.example` lines 7-9; `components/resource-center.tsx` line 30 checks env.
**Assessment:** Compliant with boundary rule 6 (no production env var changes).

---

## 12. Prioritised implementation roadmap

### P0 — Critical user-facing or accessibility defects
1. **Add viewport meta tag** (`width=device-width, initial-scale=1, viewport-fit=cover, interactive-widget=resizes-content`) — fixes mobile layout scaling and safe-area insets (M1, A3-related).
2. **Fix mobile nav `aria-controls` + focus return on close** — D1.

### P1 — High-value frontend improvements
3. **Add per-scheme `theme-color` meta tags** — M2.
4. **Ensure touch targets >= 44x44 on category chips/links** — M3.
5. **Add `user-select: none`/`-webkit-touch-callout: none` to button-like controls** — M4.
6. **Add `role="list"`/`role="listitem"` to search results** — D2.
7. **Throttle `ReadingProgress` scroll listener** — D3/P1.
8. **Add Playwright E2E tests** for Resource Center interactions — T1.
9. **Add vitest + testing-library tests** for client components (`ResourceSearch`, `ResourceMobileNav`, `ReadingProgress`, `ShareArticle`, `ArticleTableOfContents`) — T2.

### P2 — Refinements and optimisation
10. **Render `ResourceAdSlot` as null when ads disabled** — D5/P3.
11. **Debounce client-side search filtering** — P2.
12. **Consider parallelizing independent article-page data fetches** — P4.
13. **Review `scroll-mt-24` offset vs masthead height on mobile** — A3.
14. **Set `lang="en-NG"` if appropriate for Nigerian-English content** — A1.
15. **Improve `ShareArticle` status announcement consistency** — A2.

### Deferred — Work requiring separate approval
16. **Editorial write path / CMS for admin Resource Center page** — blocked by boundary rule 3 (no CMS publishing/write operations) and rule 4 (no author/reviewer permission changes).
17. **Database migrations / RLS changes** — blocked by boundary rules 1-2.
18. **Authentication or permission changes** — blocked by boundary rule 4.

---

## Report location

**`/workspaces/Scholars/SCHOLARS_RESOURCE_CENTRE_BASELINE_AUDIT.md`**

This follows the existing repository convention of root-level audit/report documents (e.g., `FRONTEND_AUDIT_REPORT.md`, `SCHOLARS_AUDIT_REPORT.md`, `RESOURCE_CENTER_PRODUCTION_VERIFICATION_2026-11-12.md`).

---

## Limitations / unresolved questions

- `web-design-guidelines` skill is not installed; runtime loading could not be verified for it. Its guidance was not applied.
- Skill verification confirmed instruction loading via native `skill` invocations; no bundled scripts were executed merely to prove loading.
- Mobile findings (M1, M3, M4) were verified against code and the mobile-native skill rules, but real-device hardware verification was not performed (no device available in this environment).
- Tests were run and all 132 passed (including 16 Resource Centre tests); this observation is based on observed test output.
- No application source, test, config, or deployment file was modified, per the read-only audit constraint.

Stopping here per execution rules. Await explicit approval before implementing any recommendations.
