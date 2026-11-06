# Scholars PR #27 CI/Vercel Corrective Engineering Report

**Date:** 2026-11-06  
**Repository:** https://github.com/ImperioKDB/Scholars  
**Pull request:** [#27 — feat: implement approved technical SEO remediation](https://github.com/ImperioKDB/Scholars/pull/27)  
**Branch:** `seo/remediation-2026-11`  
**Corrective commit:** `7d12350b15f74ec739db6c573abb26d96574c9b4` — `fix: make sitemap build-safe in CI`  
**Production merge/deployment:** Not performed.

## A. Executive summary

PR #27 initially had two independent blockers. GitHub Actions failed during `next build` while prerendering `/sitemap.xml`, because the workflow supplied unreachable placeholder Supabase values and the sitemap correctly failed closed when its public-data queries failed. Separately, the initial Vercel deployment was blocked before build with an account-configuration collaboration error.

The corrective implementation selected request-time sitemap generation rather than adding credentials to CI. The sitemap route is now explicitly dynamic, so the build does not query Supabase during prerendering. Its existing batched reads, verified-record filtering, canonical URL construction, postgraduate inclusion, lifecycle behavior, and fail-closed error handling remain intact. The batched reader was moved into a focused helper with mocked tests covering pagination and failure behavior.

The corrective branch now has a successful GitHub Actions run and a READY Vercel preview deployment. The original Vercel account-configuration block did not recur for the corrective commit. No production data, production configuration, merge, or production deployment was changed.

**Final recommendation:** **READY FOR INDEPENDENT REVIEW — all required checks pass.**

The Vercel preview URL is protected by Vercel SSO, so anonymous command-line fetching of its sitemap was not possible. This is recorded as a validation limitation, not as a failed deployment.

## B. Root-cause analysis

### GitHub Actions failure — confirmed

The failed workflow was run `42258570371`, failed job `128032189342`, on commit `828df42e4756652810edbf206d5691905c082c41`.

The workflow `.github/workflows/ci.yml` supplied:

```text
NEXT_PUBLIC_SUPABASE_URL: https://placeholder.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY: placeholder-anon-key
```

The Next.js version is `14.2.35`. In this project, `app/sitemap.ts` exported `revalidate = 3600` without opting out of static generation. Next therefore executed the metadata route during `next build` while collecting and prerendering routes.

The failed log showed requests such as:

```text
FetchNetworkError: Network request to https://placeholder.supabase.co/rest/v1/opportunities?...&offset=0&limit=500 failed
Caused by: TypeError: fetch failed
Error occurred prerendering page "/sitemap.xml"
Error: Unable to build sitemap from public opportunities
Export encountered errors on following paths:
/sitemap.xml/route: /sitemap.xml
```

The scholarship query failed in the same run. This was not caused by a query returning incomplete data; the configured host itself was unreachable. The existing error path correctly threw rather than publishing a partial sitemap.

### Vercel failure — initial cause confirmed; corrective result verified

The initial deployment for commit `828df42` was:

- Deployment ID: `dpl_AxBtFBJHBmKDRtWyBCRm3WnkkHCJ`
- State: `BLOCKED`
- Error link: `https://vercel.com/docs/deployments/troubleshoot-project-collaboration#account-configuration`

The GitHub check displayed “GitHub couldn’t verify…” and the deployment metadata identified an account-configuration collaboration block. There were no build events for that deployment, confirming that the initial failure happened before application compilation. This was separate from the GitHub Actions sitemap failure.

For corrective commit `7d12350`, Vercel created deployment `dpl_Fw1AUPcDNJrQ63PrbUVy63XoA9YV`. Its build completed successfully in 53 seconds, the route table identified `/sitemap.xml` as dynamic, and the final deployment state is `READY`. The PR’s Vercel deployment check is green. Therefore, the account-level block did not prevent the corrected preview deployment.

The preview hostname is protected by Vercel SSO. An anonymous request to `/sitemap.xml` returned HTTP 302 to `vercel.com/sso-api` with `x-robots-tag: noindex`; the preview content itself was not exposed. No protection bypass or permission change was attempted.

## C. Architecture decision

### Option A considered — request-time sitemap generation

This option makes the App Router metadata route dynamic with `export const dynamic = "force-dynamic"`. Supabase is queried only when `/sitemap.xml` is requested. If Supabase is unavailable at request time, the existing error path throws and the route returns an error instead of silently returning an incomplete sitemap.

### Option B considered — valid Supabase configuration in CI

This option would add repository or environment-level public Supabase URL and anon/publishable key values to GitHub Actions. The values must be valid, must never be a service-role key, and must not appear in logs. The available GitHub integration did not permit inspection of secret values, and inventing or hardcoding credentials would be unsafe.

### Selected solution

Option A was selected because it removes the build-time dependency on live public data without adding credentials to CI, preserves the fail-closed behavior, and matches the route’s intended dynamic data source. Vercel’s successful build confirmed that Next.js 14.2.35 and the connected Vercel project support the resulting dynamic route.

This choice does not weaken sitemap correctness. The route still reads verified public rows in 500-record batches, includes records with non-null slugs, preserves canonical `www` URLs and closed-content policy, and fails if either public source cannot be queried.

## D. Implementation details

### Files changed

- `app/sitemap.ts` — replaced the build-time `revalidate` route configuration with `dynamic = "force-dynamic"` and imported the data reader from the testable helper.
- `lib/sitemap-data.ts` — contains the existing 500-row batched Supabase reader, verified/non-null-slug filters, deterministic ordering, and fail-closed error handling.
- `lib/sitemap-data.test.ts` — adds mocked tests for 501-record pagination, both scholarship and opportunity sources, postgraduate/closed slugs, verified filtering query construction, duplicate-free results, and surfaced Supabase failures.

### Preserved behavior

The correction did not change sitemap URL policy, canonical host construction, protected-route exclusions, closed-page lifecycle handling, postgraduate inclusion, or database schema. It did not add credentials, change robots rules, mutate production records, or alter authentication boundaries.

## E. Testing evidence

| Check | Result | Evidence |
|---|---|---|
| Dependency installation | Passed | `npm install` completed on the corrective branch. npm reported existing dependency audit warnings; no dependency changes were made. |
| Focused sitemap tests | Passed | `lib/sitemap-data.test.ts`: 3 tests passed. |
| Existing test suite | Passed | 17 test files and 69 tests passed. |
| TypeScript | Passed | `npx tsc --noEmit` completed successfully. |
| Production build with CI placeholder values | Passed | `NEXT_PUBLIC_SUPABASE_URL=https://placeholder.supabase.co`, placeholder anon key, and canonical app URL; `next build` completed successfully. |
| Build route behavior | Passed | Local build classified `/sitemap.xml` as `ƒ` dynamic/server-rendered rather than static. |
| Runtime fail-closed behavior | Passed | Local request with unreachable placeholder Supabase returned HTTP 500; no incomplete XML was returned. |
| GitHub Actions | Passed | Run [42260529177](https://github.com/ImperioKDB/Scholars/actions/runs/42260529177) completed successfully for `7d12350`. |
| Vercel preview deployment | Passed | Deployment `dpl_Fw1AUPcDNJrQ63PrbUVy63XoA9YV` is READY. Preview: https://scholars-52h41te2u-imperiokdbs-projects.vercel.app |
| Vercel PR check | Passed | PR #27 reports all 3 checks successful: Vercel, Vercel Preview Comments, and `ci/build`. |
| Preview sitemap anonymous XML fetch | Not verified | Vercel SSO protection returned HTTP 302 before application content. No bypass was attempted. |
| Production deployment | Not performed | Required by task restrictions. |
| PR merge | Not performed | Required by task restrictions. |

## F. Outstanding actions

No code or CI action remains for the two reported blockers. The project owner may independently review PR #27 and, if desired, open the Vercel preview through an authenticated Vercel session to inspect `/sitemap.xml` directly. The preview’s SSO protection should remain unchanged unless the owner intentionally changes project preview-access settings.

Production merge, production deployment, and any post-deployment sitemap/GSC validation remain separate approval-gated actions. No production database, Supabase schema, or Vercel permission changes were made.

## G. Final recommendation

**READY FOR INDEPENDENT REVIEW — all required checks pass.**

The corrective commit is pushed to the existing PR branch, GitHub Actions is green, the Vercel preview deployment is READY, and the Vercel PR check is green. Do not merge or deploy to production until the owner completes independent review and gives explicit approval.
