# Scholars PR #32 — Commit and PR Links

**Repository:** ImperioKDB/Scholars
**Branch:** `fix/sitemap-public-data-integrity`
**Base:** `main`

## Pull Request

- **URL:** https://github.com/ImperioKDB/Scholars/pull/32
- **Title:** fix(seo): restore sitemap integrity, Resource Centre coverage, and correct lastModified
- **State:** Open (mergeable, not merged, not deployed)

## Commit

- **URL:** https://github.com/ImperioKDB/Scholars/commit/fd76865adf19aa8ea2926dc46de1a54b1de186ee
- **SHA:** fd76865adf19aa8ea2926dc46de1a54b1de186ee
- **Message:** merge: integrate origin/main Resource Centre content into sitemap fix branch

## Description

PR #32 restores Scholars sitemap integrity by:

1. Switching the sitemap data source from raw `scholarships`/`opportunities` tables to the approved public catalogue views `scholarships_public_preview_v1` and `opportunities_public_preview_v1`.
2. Removing the silent-failure `.catch()` that converted catalogue query failures into incomplete HTTP 200 sitemap responses.
3. Restoring Resource Centre sitemap coverage (`/resources`, `/resources/category/{slug}`, `/resources/{slug}`) with local-content fallback and database merge deduplication.
4. Omitting `lastModified` for scholarship/opportunity entries (verification timestamps are not content-modification timestamps).
5. Using a single deterministic `order("id")` with correct 500-row batch pagination.

No raw-table access, no service-role credentials, no RLS bypass, and no new grants are introduced.

## Validation

- `npx vitest run`: 26 files, 160 tests passed
- `npx tsc --noEmit`: clean
- `npx next build`: compiles successfully

Production is NOT considered fixed until the PR is merged, deployed, and verified against `https://www.scholars.com.ng/sitemap.xml`.
