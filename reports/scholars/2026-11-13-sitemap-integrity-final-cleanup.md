# Scholars PR #32 — Final Cleanup Report

**Reporting repository:** ImperioKDB/Updates (public)
**Report path:** reports/scholars/2026-11-13-sitemap-integrity-final-cleanup.md
**Source repository:** ImperioKDB/Scholars
**PR:** #32 — https://github.com/ImperioKDB/Scholars/pull/32
**Branch:** fix/sitemap-public-data-integrity
**Final commit:** 8b6de63162d52d8d950af52acd608ec95e54578d
**Date:** 13 November 2026

---

## Summary of changes

This is the final cleanup of PR #32, which restores Scholars sitemap integrity. The core remediation (approved public catalogue views, no silent failure masking) was preserved. This cleanup:

1. **Made Resource Centre category sitemap inclusion data-driven** — only categories with at least one published article are included in the sitemap. Empty categories (e.g. `study-abroad-and-funding` with no articles) are excluded from sitemap URLs but their product routes remain accessible.

2. **Removed unrelated files from the PR**:
   - `reports/scholars/2026-11-13-resource-center-phase-2a-audit-and-plan.md` — unrelated security audit report. Not copied to the public Updates repository.
   - `tsconfig.tsbuildinfo` — TypeScript build artifact, removed and added to `.gitignore`.

3. **Added 6 category eligibility regression tests** covering local/DB article inclusion, empty category exclusion, category becoming eligible when an article is added, duplicate prevention, and ineligible article exclusion.

## Category eligibility behavior

A category URL appears in the sitemap only when at least one published, publicly accessible article belongs to that category. Eligibility is determined from:
- Local articles (`lib/resource-content.ts`) — their `categories` arrays
- Database-backed articles (`resource_public_article_categories` view) — which already filters to published articles and active categories

Categories become eligible automatically when their first published article is assigned. No hardcoded category list.

## Files added, changed, removed

| File | Action |
|------|--------|
| `app/sitemap.ts` | Changed — data-driven category eligibility, no misleading lastModified |
| `lib/sitemap-data.ts` | Changed — eligibleLocalCategorySlugs(), filtered readAllResourceCategoryRows() |
| `lib/sitemap-data.test.ts` | Changed — 19 unit tests including 6 category eligibility tests |
| `app/sitemap.test.ts` | Changed — 18 route-level tests including 4 category eligibility tests |
| `.gitignore` | Changed — added tsconfig.tsbuildinfo |
| `reports/scholars/2026-11-13-resource-center-phase-2a-audit-and-plan.md` | Removed — unrelated security audit report |
| `tsconfig.tsbuildinfo` | Removed — build artifact |

## Tests executed and actual results

| Check | Result |
|-------|--------|
| `npx vitest run` | **PASS** — 26 files, 166 tests passed |
| `npx tsc --noEmit` | **PASS** — clean (no type errors) |
| `npx next build` | **PASS** — compiles successfully |

## CI and Vercel preview status

Vercel preview deployment and GitHub Actions checks were reported as passing in the prior review cycle. This cleanup does not change the core remediation; all tests and build pass locally.

## Remaining risks or unresolved issues

- Production sitemap has **not** been fetched, parsed, or verified (no deploy/verification authorization)
- `NEXT_PUBLIC_SUPABASE_URL` not set in this sandbox, preventing full prerender verification
- ESLint is not configured in the Scholars repo
- PR #32 is open, mergeable, but **not merged or deployed**

## Production verification

**Explicit statement: Production verification has not yet occurred.** This PR has not been merged or deployed to production. The correct success criterion is completeness relative to eligible public records at verification time (do not hardcode the previous count of 93).

## Security

No raw-table access, no service-role credentials, no RLS bypass, no new grants. The Updates repository is public; no sensitive security findings from the Phase 2A audit are published here.
