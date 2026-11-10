# Scholars Post-Merge Production Deployment Verification

**Audit date:** 2026-11-06  
**Repository:** https://github.com/ImperioKDB/Scholars  
**Pull request:** [#27 — feat: implement approved technical SEO remediation](https://github.com/ImperioKDB/Scholars/pull/27)  
**Expected merge commit:** `67070cbbf93c31327c1bf311af631ad24a01a1a3`  
**Final reviewed branch commit:** `b5c4252094d35366b6c40aa88a29a182ca4e5932`  
**Production domain:** https://www.scholars.com.ng  
**Production sitemap:** https://www.scholars.com.ng/sitemap.xml

## 1. Executive verdict

# PARTIALLY CONFIRMED

The merged SEO behavior is demonstrably present in the live production response: the production sitemap now contains 93 valid canonical URLs, including closed historical records and postgraduate scholarship pages, and its inventory matches the current verified public Supabase rows by count and route composition.

The exact Vercel Production deployment ID, deployment environment, and Git commit serving the canonical production domain could not be independently retrieved. The connected Vercel tool reported that authentication was still required after the authorization flow, so this report does not fabricate deployment provenance. The live HTTP evidence strongly supports that the merged behavior is serving production, but the Vercel deployment-to-domain assignment and exact production deployment commit remain unverified.

## 2. GitHub merge provenance

GitHub independently confirmed:

- PR #27 state: `MERGED`
- Final reviewed branch HEAD: `b5c4252094d35366b6c40aa88a29a182ca4e5932`
- Merge commit on `main`: `67070cbbf93c31327c1bf311af631ad24a01a1a3`
- `main` branch currently points to: `67070cbbf93c31327c1bf311af631ad24a01a1a3`
- Merge time: `2026-11-06T19:19:12Z`

The final pre-merge branch checks and post-merge GitHub Actions run passed. The post-merge CI run was [42278572377](https://github.com/ImperioKDB/Scholars/actions/runs/42278572377).

## 3. Vercel deployment provenance

### Required checks

The connected Vercel deployment tools were invoked to locate the `scholars` project and inspect its Production deployment. The tool initially exposed the project context and the prior preview deployment, but after the merge it returned:

> `MCP server vercel requires login. Run auth.login for this server.`

An authorization card was completed, but subsequent Vercel project/deployment calls continued to report that authentication was required. Because of that connector limitation, the following fields are **not independently verified**:

- Production deployment ID.
- Production deployment URL as returned by Vercel.
- Vercel deployment state and environment assignment.
- Git commit SHA attached to the Production deployment.
- Whether the expected merge commit is the deployment currently assigned to `www.scholars.com.ng`.
- Vercel Production build logs for the merge commit.

The final PR Vercel check was successful before merge, and the prior corrective preview deployment for commit `7d12350` was reported READY. Those facts are not treated as proof of the post-merge Production deployment assignment.

### Deployment conclusion

The exact Production deployment provenance is **not confirmed through Vercel**. No deployment, promotion, setting change, or authentication bypass was performed.

## 4. Live production sitemap validation

An unauthenticated request was made to:

`https://www.scholars.com.ng/sitemap.xml`

Observed response:

- HTTP status: `200`.
- Content type: `application/xml`.
- XML parsing: successful with Python’s XML parser.
- URL count: `93`.
- Duplicate URL count: `0`.
- Canonical-host mismatches: `0`.
- Empty or malformed URL count: `0`.
- Protected plural application route matches: `0`.
- Response began with a valid XML declaration and Sitemap `urlset` namespace.

The 93 URLs decompose as follows:

| Route group | Count |
|---|---:|
| Static public routes | 7 |
| Scholarship detail routes | 44 |
| Opportunity detail routes | 42 |
| Total | 93 |

Every extracted `<loc>` used the canonical `https://www.scholars.com.ng` host. No URL used protected plural `/scholarships/<uuid>` or `/opportunities/<uuid>` application paths.

## 5. Sitemap inventory and implementation checks

### Supabase comparison

Read-only SQL was run against the connected `scholarship-platform` Supabase project `cmdglabohpttgfofcmqc` with the same public eligibility shape used by the sitemap: `verified = true`, non-null `slug`, deterministic `updated_at` and `id` ordering, and a limit of 500.

The database returned:

- 44 verified scholarship rows with non-null slugs.
- 42 verified opportunity rows with non-null slugs.

Those counts exactly match the production sitemap’s 44 scholarship URLs and 42 opportunity URLs. This is consistent with complete retrieval for the current inventory and provides evidence that the sitemap is not currently truncated at the former 1,000-row boundary or at a smaller active-only subset.

### Postgraduate inclusion

The production sitemap includes identifiable postgraduate scholarship slugs, including:

- `nddc-local-post-graduate-master-s-degree-scholarship-2026-2027-107bccf4`
- `cbias-graduate-scholarship-d015e1ba`
- `earth-university-mastercard-foundation-scholarship-2027-82516cc2`

The Supabase comparison confirms the first two records have `level = postgrad`. This verifies that postgraduate-only records are not excluded by the merged sitemap query.

### Closed historical records

The production sitemap includes closed or historically useful records that were returned by the verified public-row query, including:

- MTN Foundation Science & Technology Scholarship: `mtn-foundation-science-technology-scholarship-aaaaaaaa`, with `last_cycle_closed_at = 2026-05-31`.
- UBA Foundation National Essay Competition: `uba-foundation-national-essay-competition-2026-900828dc`, with a passed deadline and `deadline_passed_at` set.
- National Youth Pension Literacy Essay Competition: `national-youth-pension-literacy-essay-competition-2026-c2cd644f`, with a passed deadline and `deadline_passed_at` set.

Their sitemap presence is consistent with the approved policy that verified detail pages with historical value remain public while active listing feeds continue to apply active deadline/cycle filters. This audit did not mutate records or independently submit page requests for every closed URL.

### Verified and valid slugs

The database comparison used `verified = true` and `slug is not null`, and the production sitemap’s 44 scholarship plus 42 opportunity detail URLs matched those current row counts. No unverified or null-slug record was observed in the production sitemap response.

### Pagination/truncation

The current production inventory is below 500 rows per source. The exact more-than-500 behavior cannot be proven from current production volume alone, but the live route’s 93-row output matches all 44 scholarship and 42 opportunity rows returned by the read-only comparison. The merged implementation’s source code and tests cover 500-row batching, including a 501-record fixture; this audit did not create production fixtures.

## 6. Canonical domain behavior

The four requested variants were tested with both no-follow and follow requests.

| Requested URL | Initial response | Initial redirect | Final response |
|---|---:|---|---:|
| `https://scholars.com.ng/` | 308 | `https://www.scholars.com.ng/` | 200 |
| `https://www.scholars.com.ng/` | 200 | None | 200 |
| `http://scholars.com.ng/` | 308 | `https://scholars.com.ng/` | 200 at `https://www.scholars.com.ng/` |
| `http://www.scholars.com.ng/` | 308 | `https://www.scholars.com.ng/` | 200 |

No redirect loop was observed. The HTTP apex variant uses two host/protocol normalization steps before reaching the canonical HTTPS `www` URL; the HTTPS apex variant uses one redirect. The canonical HTTPS `www` URL responds directly with HTTP 200.

## 7. Evidence and limitations

### Verified evidence

- GitHub PR #27 is merged.
- `main` points to merge commit `67070cbbf93c31327c1bf311af631ad24a01a1a3`.
- Production sitemap responds with HTTP 200 and XML content type.
- Production sitemap parses successfully.
- Production sitemap contains 93 unique canonical URLs.
- Production sitemap contains 44 scholarship and 42 opportunity detail URLs.
- Read-only Supabase queries return 44 verified scholarship rows and 42 verified opportunity rows with non-null slugs.
- Postgraduate and closed historical records are represented.
- Canonical domain redirects resolve without loops.

### Unverified or limited checks

- Vercel Production deployment ID, assigned commit SHA, and domain assignment could not be retrieved because the Vercel connector continued to require authentication after the authorization attempt.
- Vercel Production build logs were not available.
- The production sitemap was not independently tested for every detail URL’s final HTTP status in this read-only pass.
- A production-sized fixture exceeding 500 rows was not created, in accordance with the no-production-mutation restriction.

## 8. Conclusion

The merged SEO remediation is **behaviorally confirmed in production** by the live 93-URL sitemap and its exact match to the current verified, non-null-slug Supabase inventory. The live response demonstrates postgraduate inclusion, closed historical record inclusion, canonical host construction, valid XML, no duplicates, and no protected application routes.

The exact Vercel Production deployment provenance is **not confirmed** because the connected Vercel deployment API remained unavailable behind authentication. Accordingly, the overall verdict is **PARTIALLY CONFIRMED**, not fully CONFIRMED. The remaining verification needed is an authenticated Vercel inspection showing that the Production deployment assigned to `www.scholars.com.ng` has commit `67070cbbf93c31327c1bf311af631ad24a01a1a3` and is Ready.
