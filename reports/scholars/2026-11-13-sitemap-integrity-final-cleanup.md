# Scholars PR #32 — Final Cleanup Report

**Reporting repository:** ImperioKDB/Updates (public)
**Report path:** reports/scholars/2026-11-13-sitemap-integrity-final-cleanup.md
**Source repository:** ImperioKDB/Scholars
**PR:** #32 — https://github.com/ImperioKDB/Scholars/pull/32
**Branch:** fix/sitemap-public-data-integrity
**Final commit:** 8b6de63162d52d8d950af52acd608ec95e54578d
**Parent:** fd76865adf19aa8ea2926dc46de1a54b1de186ee
**Date:** 13 November 2026

---

## Summary of changes

This is the final cleanup of PR #32, which restores Scholars sitemap integrity. The core remediation (approved public catalogue views, no silent failure masking) was preserved. This cleanup:

1. **Made Resource Centre category sitemap inclusion data-driven** — only categories with at least one published article are included in the sitemap. Empty categories (e.g. `study-abroad-and-funding` with no articles) are excluded from sitemap URLs but their product routes remain accessible.

2. **Removed unrelated files from the PR**:
   - `reports/scholars/2026-11-13-resource-center-phase-2a-audit-and-plan.md` — unrelated security audit report. Not copied to the public Updates repository.
   - `tsconfig.tsbuildinfo` — TypeScript build artifact, removed and added to `.gitignore`.

3. **Added 6 category eligibility regression tests** covering local/DB article inclusion, empty category exclusion, category becoming eligible when an article is added, duplicate prevention, and ineligible article exclusion.

---

## File-by-file scope audit

The PR diff (vs `main` at `de9b406`) contains 136 files. The majority came from merging `origin/main` (PR #29: Resource Centre public frontend) into the fix branch. Only the files below are sitemap-relevant changes authored for this PR.

### Files required for sitemap integrity

| File | Action | Required for sitemap? | Notes |
|------|--------|----------------------|-------|
| `app/sitemap.ts` | Changed | **Yes** | Core fix: public views, no silent catch, data-driven category eligibility, no misleading lastModified |
| `lib/sitemap-data.ts` | Changed | **Yes** | Core fix: PublicCatalogTable type, deterministic `id` ordering, `eligibleLocalCategorySlugs()`, filtered `readAllResourceCategoryRows()` |
| `lib/sitemap-data.test.ts` | Changed | **Yes** | 19 unit tests including 6 category eligibility tests |
| `app/sitemap.test.ts` | Changed | **Yes** | 18 route-level tests including 4 category eligibility tests |
| `.gitignore` | Changed | **Yes** | Added `tsconfig.tsbuildinfo` to prevent build artifact commits |
| `lib/supabase/config.ts` | Added | **Yes** | Defines `hasPublicSupabaseConfig()`, imported by `lib/sitemap-data.ts` for local-fallback gating. Also used by `lib/resource-center.ts` (which has its own local copy). |

### Files from origin/main merge (NOT sitemap-specific, kept as legitimate user changes)

These files came from `origin/main` (PR #29: Resource Centre public frontend) when it was merged into the fix branch. They are **not** required for sitemap integrity but are legitimate user changes preserved per instructions:

| File | Action | Required for sitemap? | Notes |
|------|--------|----------------------|-------|
| `lib/resource-center.ts` | Added | No | Resource Centre data access layer. Not imported by sitemap files. Has its own local `hasPublicSupabaseConfig()` copy. |
| `lib/resource-content.ts` | Added | No | Local Resource Centre content (6 categories, 5 articles). Sitemap imports `LOCAL_RESOURCE_ARTICLES`/`LOCAL_RESOURCE_CATEGORIES` directly from here. |
| `app/resources/page.tsx` | Changed | No | Resource Centre homepage UI. Not a sitemap dependency. |
| `app/resources/[slug]/page.tsx` | Changed | No | Resource Centre article page UI. Not a sitemap dependency. |
| `app/resources/category/[slug]/page.tsx` | Changed | No | Resource Centre category page UI. Not a sitemap dependency. |
| `components/resource-center-search.tsx` | Added | No | Client-side search component for Resource Centre. Not a sitemap dependency. |
| `next-env.d.ts` | Added | **Yes** | Standard Next.js type declaration file. Referenced in `tsconfig.json` `include` array. Required for TypeScript compilation. |

### Removed from PR

| File | Action | Reason |
|------|--------|--------|
| `reports/scholars/2026-11-13-resource-center-phase-2a-audit-and-plan.md` | Removed | Unrelated security audit report. Updates repo is public; not copied there. |
| `tsconfig.tsbuildinfo` | Removed | TypeScript build artifact. Added to `.gitignore`. |

### next-env.d.ts assessment

`next-env.d.ts` does not exist on `main` (`de9b406`). It is new in the PR branch. It IS referenced in `tsconfig.json` (`"include": ["next-env.d.ts", "**/*.ts", ...]`). It is a standard Next.js file required for TypeScript compilation with Next.js types. **Retain it.**

### lib/supabase/config.ts assessment

`lib/supabase/config.ts` defines `hasPublicSupabaseConfig()`. It is imported and used by:
- `lib/sitemap-data.ts` (lines 2, 53, 95) — for local fallback of resource articles/categories when Supabase config is absent
- `lib/resource-center.ts` has its own local copy of the same function (line 217) — minor duplication but not a problem

**Keep it.** It is justified, used, and tested indirectly through sitemap tests.

### Resource Centre page/search changes assessment

The Resource Centre page and search changes (`app/resources/page.tsx`, `app/resources/[slug]/page.tsx`, `app/resources/category/[slug]/page.tsx`, `components/resource-center-search.tsx`, `lib/resource-center.ts`) came from the `origin/main` merge. They are **not** necessary for the category eligibility implementation. The sitemap's `readAllResourceCategoryRows()` and `readAllResourceRows()` functions operate independently using `createPublicClient()` and `LOCAL_RESOURCE_*` constants. These files are preserved as legitimate user changes from origin/main per instructions ("Preserve user changes and do not force-push").

---

## Category eligibility behavior

A category URL appears in the sitemap only when at least one published, publicly accessible article belongs to that category. Eligibility is determined from:

- Local articles (`lib/resource-content.ts`) — their `categories` arrays via `eligibleLocalCategorySlugs()`
- Database-backed articles (`resource_public_article_categories` view) — which already filters to published articles and active categories

Categories become eligible automatically when their first published article is assigned. No hardcoded category list. Empty categories (e.g. `study-abroad-and-funding` with no articles) are excluded from sitemap URLs but their product routes remain accessible.

---

## Tests executed and actual results

| Check | Result |
|-------|--------|
| `npx vitest run` | **PASS** — 27 files, 183 tests passed |
| `npx tsc --noEmit` | **PASS** — clean (no type errors) |
| `npx next build` | **PASS** — compiles successfully (`sitemap.xml` is dynamic/server-rendered) |

**Build caveat:** `next build` reports `@supabase/ssr: URL and API key required` prerender errors on `/login`, `/signup`, `/onboarding`, `/legal/privacy`, `/legal/terms`, `/`, `/reset-password`, `/resources`. These are pre-existing environment limitations (no `NEXT_PUBLIC_SUPABASE_URL`/`SUPABASE_URL` set in this sandbox), unrelated to the sitemap change.

### Sitemap-specific tests (37 total)

Unit tests (`lib/sitemap-data.test.ts`): public catalogue retrieval across batches, empty catalogues, missing slugs, both query failures, no raw-table access, deterministic ordering, local fallback, DB merge dedup, category eligibility (6 tests).

Route-level tests (`app/sitemap.test.ts`): `/resources` in sitemap, category eligibility, local articles without Supabase, DB merge dedup, failure resilience, approved views only, query failures reject, empty catalogues valid, closed/postgraduate discoverable, pagination >500 records, no misleading `lastModified`, canonical host consistency, no duplicate URLs.

---

## CI and Vercel preview status

| Check | Status |
|-------|--------|
| GitHub Actions build | **pass** (run #518) |
| Vercel deployment | **pass** |
| Vercel Preview Comments | **pass** |

---

## Remaining risks or unresolved issues

- Production sitemap has **not** been fetched, parsed, or verified (no deploy/verification authorization)
- `NEXT_PUBLIC_SUPABASE_URL` not set in this sandbox, preventing full prerender verification
- ESLint is not configured in the Scholars repo
- PR #32 is open, mergeable, but **not merged or deployed**

---

## Production verification

**Explicit statement: Production verification has not yet occurred.** This PR has not been merged or deployed to production. The correct success criterion is completeness relative to eligible public records at verification time (do not hardcode the previous count of 93).

---

## Security

No raw-table access, no service-role credentials, no RLS bypass, no new grants. The Updates repository is public; no sensitive security findings from the Phase 2A audit are published here.
