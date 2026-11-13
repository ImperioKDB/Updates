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

### Important: PR file count (12 net changes)

GitHub's PR comparison (base `main` = commit `edb3b84`, head `fix/sitemap-public-data-integrity` = commit `8b6de63`) reports **12 changed files**. This is the authoritative net PR diff.

A local `git diff main fix/sitemap-public-data-integrity` against the local clone's `main` (commit `de9b406`) shows 136 files because the local `main` does **not** contain PR #29 (Resource Centre public frontend, commit `137f2fa`), whereas GitHub's base `main` (`origin/main` = `edb3b84`) **does** contain it. The branch merged `origin/main` into itself (merge commit `fd76865`), so those Resource Centre files are already in GitHub's base and do not appear in the net diff.

### The 12 files in the current net PR diff

| File | Action | Required for sitemap? | Notes |
|------|--------|----------------------|-------|
| `app/sitemap.ts` | Changed | **Yes** | Core fix: public views, no silent catch, data-driven category eligibility, no misleading lastModified |
| `lib/sitemap-data.ts` | Changed | **Yes** | Core fix: PublicCatalogTable type, deterministic `id` ordering, `eligibleLocalCategorySlugs()`, filtered `readAllResourceCategoryRows()` |
| `lib/sitemap-data.test.ts` | Changed | **Yes** | 19 unit tests including 6 category eligibility tests |
| `app/sitemap.test.ts` | Changed | **Yes** | 18 route-level tests including 4 category eligibility tests |
| `.gitignore` | Changed | **Yes** | Added `tsconfig.tsbuildinfo` to prevent build artifact commits |
| `lib/supabase/config.ts` | Added | **Yes** | Defines `hasPublicSupabaseConfig()`, imported by `lib/sitemap-data.ts` for local-fallback gating |
| `app/resources/page.tsx` | Changed | No | Resource Centre homepage UI from PR #29 merge context; page/component wiring for Resource Centre |
| `app/resources/[slug]/page.tsx` | Changed | No | Resource Centre article page UI from PR #29 merge context |
| `app/resources/category/[slug]/page.tsx` | Changed | No | Resource Centre category page UI from PR #29 merge context |
| `components/resource-center-search.tsx` | Changed | No | Client-side search component from PR #29 merge context |
| `lib/resource-center.ts` | Changed | No | Resource Centre data access layer; 1-line addition (`hasPublicSupabaseConfig()` guard in `getResourceImageUrl`) |
| `next-env.d.ts` | Added | **Yes** | Standard Next.js type declaration file, referenced in `tsconfig.json` `include` array |

### Files in merge history (historical context, NOT net PR changes)

The following files appear in the branch's commit history because PR #29 (Resource Centre public frontend) was merged into the fix branch (merge commit `fd76865`). They are present in GitHub's base branch (`origin/main` = `edb3b84`) and therefore do **not** appear in the net 12-file PR diff. They are listed here for historical context only.

- `lib/resource-content.ts` — Local Resource Centre content (6 categories, 5 articles). Sitemap imports `LOCAL_RESOURCE_ARTICLES`/`LOCAL_RESOURCE_CATEGORIES` from here, but this file was added by PR #29, not by this PR.
- `components/resource-center.tsx` — Resource Centre UI components (from PR #29).
- `components/resource-center-interactions.tsx` — Resource Centre interaction components (from PR #29).
- `package-lock.json`, `package.json`, `skills-lock.json`, vitest config, `.agents/skills/*`, docs, migrations, and many other Resource Centre-related files (from PR #29).

### Removed from PR

| File | Action | Reason |
|------|--------|--------|
| `reports/scholars/2026-11-13-resource-center-phase-2a-audit-and-plan.md` | Removed | Unrelated security audit report. Updates repo is public; not copied there. |
| `tsconfig.tsbuildinfo` | Removed | TypeScript build artifact. Added to `.gitignore`. |

### next-env.d.ts assessment

`next-env.d.ts` does not exist on the PR's base branch commit `edb3b84`. It is new in the PR branch. It IS referenced in `tsconfig.json` (`"include": ["next-env.d.ts", "**/*.ts", ...]`). It is a standard Next.js file required for TypeScript compilation with Next.js types. **Retain it.**

### lib/supabase/config.ts assessment

`lib/supabase/config.ts` defines `hasPublicSupabaseConfig()`. It is imported and used by:
- `lib/sitemap-data.ts` (lines 2, 53, 95) — for local fallback of resource articles/categories when Supabase config is absent

**Keep it.** It is justified, used, and tested indirectly through sitemap tests.

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
| `npx next build` | **Compiles successfully** (TypeScript compilation succeeds, `sitemap.xml` is dynamic/server-rendered), but **prerendering fails on several routes** |

### Build caveat (important)

`npx next build` completes TypeScript compilation successfully, but **prerendering errors occur** on `/login`, `/signup`, `/onboarding`, `/legal/privacy`, `/legal/terms`, `/`, `/reset-password`, `/resources`:

```
Error: supabaseUrl is required.
```

These are **pre-existing environment limitations** — this sandbox does not have `NEXT_PUBLIC_SUPABASE_URL`/`SUPABASE_URL` set. They are unrelated to the sitemap change. The build did **not** complete a fully successful prerender; compilation succeeded but prerendering could not run without Supabase credentials.

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
