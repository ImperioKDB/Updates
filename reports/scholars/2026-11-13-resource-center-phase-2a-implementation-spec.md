# Scholars Resource Centre — Phase 2A Implementation Specification

**Source repository:** ImperioKDB/Scholars  
**Verified branch:** main (origin/main = 137f2fa28a4f1a5b1fb6eaa55e3c6c3677bb4210)  
**Report date:** 2026-11-13  
**Prepared for:** ImperioKDB/Updates  
**Destination file:** reports/scholars/2026-11-13-resource-center-phase-2a-implementation-spec.md  
**Mode:** Planning only. No implementation performed. Read-only access to Scholars.

---

## Purpose

This specification defines the smallest safe implementation sequence for Phase 2A product alignment and editorial foundation refinements. All items preserve public reading without login. No changes are implemented yet — this is a specification for owner review and approval.

---

## Item 1: Correct duplicate SEO title suffixes

### Problem (VERIFIED)
Root layout `app/layout.tsx` line 40 sets `template: "%s | Scholars"`. Resource pages additionally append `| Scholars`:
- `app/resources/page.tsx` line 11: `title: "Resource Center for students | Scholars"`
- `app/resources/[slug]/page.tsx` line 19: `` title: \`${article.title} | Scholars\` ``
- `app/resources/category/[slug]/page.tsx` line 15: `` title: \`${result.category.name} resources | Scholars\` ``

Rendered titles are doubled: `Resource Center for students | Scholars | Scholars`.

### Files likely to change
- `app/resources/page.tsx` — remove ` | Scholars` from `title`
- `app/resources/[slug]/page.tsx` — remove ` | Scholars` from `title` in `generateMetadata`
- `app/resources/category/[slug]/page.tsx` — remove ` | Scholars` from `title` in `generateMetadata`

### Expected behavior
- Homepage `<title>`: `Resource Center for students | Scholars`
- Article `<title>`: `{article.title} | Scholars`
- Category `<title>`: `{category.name} resources | Scholars`
- Each title contains the brand suffix exactly once.

### Potential regressions
- Open Graph `title` fields on article/category pages also include `| Scholars` (lines 19 and 15 respectively) — these should be reviewed for consistency but are not doubled because OG title doesn't go through the Next.js template. Changing page `title` without changing OG `title` could create inconsistency between `<title>` and `og:title`.
- Any tests asserting on rendered title strings may need updating.

### Required automated tests
- Unit test asserting homepage `metadata.title` does not contain `| Scholars | Scholars`
- Unit test asserting article `generateMetadata` title does not contain doubled suffix
- Unit test asserting category `generateMetadata` title does not contain doubled suffix
- Existing `app/resources/page.test.ts` (source-contract test) should continue to pass

### Manual verification
- View page source on `/resources`, `/resources/[slug]`, `/resources/category/[slug]` and confirm `<title>` contains `| Scholars` exactly once
- Confirm `npm test` passes and `npx tsc --noEmit` exits 0

---

## Item 2: Hide categories with no published articles from homepage navigation

### Problem (VERIFIED)
`app/resources/page.tsx` line 26: `visibleCategories = categories.length > 0 ? categories : LOCAL_RESOURCE_CATEGORIES` — renders all categories regardless of article count. `lib/sitemap-data.ts` `readAllResourceCategoryRows()` returns all categories including empty ones. If a database-backed category with zero articles is added, it renders an empty `ResourceEmptyState` page and a sitemap route.

### Files likely to change
- `app/resources/page.tsx` — filter `visibleCategories` to categories with `articleCount > 0`
- `lib/resource-center.ts` — `getResourceCategory()` already returns `totalCount`; `getResourceHome()` returns categories without article counts. Need to add article count to home categories or filter in the page component.

### Expected behavior
- Homepage category chips only include categories with ≥1 published article
- "X active subjects" count reflects only populated categories
- Empty categories do not render navigation chips

### Potential regressions
- If all categories are empty, the "Browse by subject" section should gracefully hide (handle `visibleCategories.length === 0`)
- Category count display text (singular/plural) must work with filtered list

### Required automated tests
- Unit test asserting `visibleCategories` excludes categories with zero articles
- Unit test asserting "X active subjects" count matches filtered list length
- Unit test asserting section is hidden when no categories have articles

### Manual verification
- Confirm homepage renders only populated category chips
- Confirm no empty category navigation links exist

---

## Item 3: Exclude empty categories from sitemap generation

### Problem (VERIFIED)
`app/sitemap.ts` lines 71-75 emits category routes for all distinct slugs with no article-count guard. Empty categories become indexable empty pages.

### Files likely to change
- `app/sitemap.ts` — filter `resourceCategoryRoutes` to categories with ≥1 article
- `lib/sitemap-data.ts` — `readAllResourceCategoryRows()` needs article count info, or filtering happens in `app/sitemap.ts` after fetching category-article mappings

### Expected behavior
- Sitemap only includes `/resources/category/<slug>` for categories with ≥1 published article
- Empty categories are not in `sitemap.xml`

### Potential regressions
- `readAllResourceCategoryRows()` currently queries `resource_public_article_categories` for slugs only. To filter by article count, either:
  - (a) Add a `GROUP BY slug HAVING COUNT(*) > 0` equivalent in the query, or
  - (b) Fetch article counts per category and filter in `app/sitemap.ts`
- Option (a) requires a more complex Supabase query; option (b) is simpler but fetches more data.

### Required automated tests
- Unit test asserting sitemap category routes exclude slugs with zero articles
- Unit test asserting all sitemap category routes correspond to populated categories

### Manual verification
- Fetch `/sitemap.xml` and confirm no empty category URLs appear

---

## Item 4: Improve Resource Centre search to include article body and category

### Problem (VERIFIED)
`components/resource-center-search.tsx` line 12: search matches only `` `${article.title} ${article.excerpt ?? ""} ${article.article_type}` ``. Article body (`content_markdown`) and category name/description are not searchable.

### Files likely to change
- `components/resource-center-search.tsx` — extend match string to include article body and category context
- `lib/resource-center.ts` — `ResourceArticleCard` type may need `categoryNames` or similar field, or the page passes full articles with categories to the search component
- `app/resources/page.tsx` — may need to pass category context alongside articles to `ResourceSearch`

### Expected behavior
- Search matches article body text (e.g., "transcript", "recommender", "Federal Scholarship Board")
- Search matches category name/description
- Existing title/excerpt/article_type matching preserved
- Result cap of 6 maintained
- Accessible label and `aria-live="polite"` preserved

### Potential regressions
- Client-side search over article body means body text is bundled to the client (already the case for excerpts; body increases payload slightly)
- `ResourceArticleCard` type doesn't include `content_markdown` — need to either extend the type or pass body text separately
- Search relevance ranking is still simple substring match (no change to ranking algorithm)

### Required automated tests
- Unit test asserting search finds body-only terms
- Unit test asserting search finds category name terms
- Unit test asserting existing title/excerpt/article_type matching still works
- Unit test asserting search is case-insensitive
- Unit test asserting 6-result cap

### Manual verification
- Type a term that appears only in article body and confirm the article appears in results
- Type a category name and confirm articles in that category appear
- Confirm no-results message still shows for non-matching queries

---

## Item 5: Correct homepage positioning to represent all six content pillars

### Problem (VERIFIED)
`app/resources/page.tsx` line 50: hero sub-headline reads "Clear, practical articles about scholarships, applications, deadlines and the decisions that help students in Nigeria move with confidence." — narrowly framed around scholarships/applications/deadlines, under-representing Learn (academic development), Build (skills/career), Thrive (university/student life), and Understand (educational systems).

All six current articles are application-related (Prepare pillar). No content exists for Build or Thrive; only thin coverage of Discover, Learn, Understand.

### Files likely to change
- `app/resources/page.tsx` — hero sub-headline and possibly hero heading to reference all six pillars
- `app/resources/page.tsx` — category chips section may need pillar grouping (optional, lower priority)

### Expected behavior
- Homepage copy references academic development, skills/career, student life, and educational systems in addition to scholarships/applications/deadlines
- Scholarship/application focus remains prominent (don't dilute the core value proposition)
- No new dependencies introduced

### Potential regressions
- Longer hero copy may affect layout on mobile; verify wrapping and line lengths
- Any SEO tests checking meta description length may need updating (description is unchanged; only visible hero copy changes)

### Required automated tests
- Source-contract test asserting hero copy contains references beyond scholarships/deadlines (optional — source-contract tests check file content, not semantics)

### Manual verification
- Review homepage hero copy for six-pillar alignment
- Confirm copy remains clear and not overly broad

---

## Item 6: Resolve Supabase configuration dependency without breaking protected routes

### Problem (PARTIALLY VERIFIED)
`getResourceImageUrl()` (`lib/resource-center.ts:131-136`) calls `createClient()` without a `hasPublicSupabaseConfig()` guard. `createClient()` (`lib/supabase/server.ts:21`) directly reads `process.env.NEXT_PUBLIC_SUPABASE_URL!` and `!ANON_KEY` and throws if either is absent.

The homepage data path IS guarded (`getResourceHomeWithRepositoryContent()` checks `hasPublicSupabaseConfig()` before calling `getResourceHome()` → `createClient()`). But `getResourceImageUrl()` is unguarded and would throw for database-backed articles with non-null `featured_image_path` when env vars are absent.

### Files likely to change
- `lib/resource-center.ts` — add `hasPublicSupabaseConfig()` guard to `getResourceImageUrl()` before calling `createClient()`
- `lib/supabase/server.ts` — optional: add `hasPublicSupabaseConfig()` guard inside `createClient()` itself (defense in depth)

### Expected behavior
- `getResourceImageUrl()` returns `null` gracefully when Supabase config is absent (instead of throwing)
- Homepage and article pages continue to render without Supabase configured (using local repository content)
- Protected routes (`/dashboard`, `/admin`, etc.) are NOT affected — they legitimately require Supabase auth

### Potential regressions
- None expected for public routes — graceful degradation is already the documented pattern (`getResourceHomeWithRepositoryContent()` comment: "The repository-backed launch experience remains available when the optional public projection is unavailable")
- Image URLs would not be generated when Supabase is absent (fallback placeholder renders instead — already the behavior when `getResourceImageUrl` returns null)

### Required automated tests
- Unit test asserting `getResourceImageUrl()` returns `null` when `hasPublicSupabaseConfig()` is false (mock env vars)
- Unit test asserting `getResourceImageUrl()` returns a URL when config is present and path is approved
- Existing `lib/resource-center.test.ts` tests for `isApprovedResourceImagePath` and `getResourceCanonicalUrl` continue to pass

### Manual verification
- Confirm `/resources` renders without Supabase env vars (local content path)
- Confirm article pages render without Supabase env vars (local content path)
- Confirm protected routes still require Supabase/auth (no regression in auth behavior)

---

## Cross-cutting constraint: Preserve public reading without login

All items above must maintain:
- `/resources`, `/resources/[slug]`, `/resources/category/[slug]` remain outside `middleware.ts` `PROTECTED_PREFIXES` and `config.matcher`
- No authentication gate added to any public Resource Centre route
- No signup/login required to read articles

---

## Implementation sequence (recommended order)

1. **Item 1 (duplicate titles)** — lowest risk, pure metadata fix
2. **Item 6 (Supabase dependency)** — prevents build-time failures; defense in depth
3. **Item 2 (empty categories in nav)** — UI fix, depends on category count data
4. **Item 3 (empty categories in sitemap)** — SEO fix, depends on category count data
5. **Item 4 (search scope)** — component change, may require type changes
6. **Item 5 (homepage positioning)** — copy change, lowest technical risk but requires editorial judgment

Items 2 and 3 are related (both need category article counts) and can be implemented together. Item 6 should be done early to prevent build failures.

---

## Definition of done for Phase 2A

- [ ] `npx vitest run` passes (all existing tests + new tests)
- [ ] `npx tsc --noEmit` exits 0
- [ ] `<title>` on all three Resource Centre routes contains `| Scholars` exactly once
- [ ] Homepage navigation excludes categories with zero articles
- [ ] `/sitemap.xml` excludes categories with zero articles
- [ ] Search matches article body and category text
- [ ] Homepage hero copy references all six pillars
- [ ] `/resources` renders without Supabase env vars (local content fallback)
- [ ] Public reading requires no authentication (unchanged)
- [ ] No changes to `middleware.ts` protected prefixes or matcher

---

## Unresolved issues (outside Phase 2A scope)

| Issue | Why out of scope |
|-------|-----------------|
| CMS editorial publishing workflow | Requires Track C security remediation first (BLOCKED) |
| `profiles.is_admin` remediation | Already remediated on main (migrations 0023, 0029) — verified NOT REPRODUCED |
| `security_invoker = true` on public views | CMS security concern, not Phase 2A product refinement |
| `FORCE ROW LEVEL SECURITY` on base tables | CMS security concern |
| Production row counts / env verification | Requires production access (read-only constraint) |
