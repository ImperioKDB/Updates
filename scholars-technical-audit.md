# Scholars — Technical Audit: Performance, Scalability & Production Readiness

Snapshot audited: Gitingest dump of `ImperioKDB/Scholars` (674 files, about 2.9 MB). Audit date: 24 Nov 2026. No code was modified and no patches are proposed here.

## 0. Scope, method and limits

**What I did:** extracted the snapshot, read the middleware, Supabase/Redis clients, matching engine, every cache and rate-limit path, the main API routes, the email/cron/Inngest code, the migration set (139 files, 83 indexes) and the client polling/telemetry code, then traced the registration, login, dashboard, matching, search, bookmark and reminder paths end to end.

**What I could not verify (needs runtime or dashboard access):** live deploy target, Cloudflare plan and limits, Supabase region/plan/pool size, the Data API "max rows" setting, the live RLS and index state, Upstash plan and quotas, actual bundle sizes, real traffic. Registered-user and catalog numbers below come from the repo's investor documents (216 users, 60+ listings), which are dated and unverified. Nothing here is a measured benchmark; where I give arithmetic it is labelled illustrative.

**Evidence labels.** Confirmed = visible in code. Probable = strongly implied, needs a runtime check. Potential = architectural risk that appears under load. Severity: Critical / High / Medium / Low.

## 1. Executive Technical Audit Report (Deliverable 1)

### Overall assessment

Scholars is a carefully built application for its current size. There is real defensive engineering: narrowed column projections, timeouts on every Supabase fetch, transient-auth handling in middleware, an outbox with claim/lease/dead-letter for email, fail-closed email gating, local fonts, error boundaries and `loading.tsx` files, a thorough index set, and an offline catalog cache plus action outbox for bad networks. I found no evidence of an exploitable security hole or an imminent data-integrity problem.

The risks are of a different kind. Most are **silent** (wrong answers rather than errors), **coupled** (optional infrastructure able to block core reads), or **load-multiplying** (small per-user behaviours that grow linearly with open tabs and page views). Several only bite once the catalog or user base grows by a few multiples, which the product plan (200 listings, 1,000 then 5,000 users) says is near.

### Top risks, in priority order

1. **Scheduler gap (F-02, Probable, High).** The only timer for the deadline/push job is a `vercel.json` cron. The repo is configured for Cloudflare Workers (`wrangler.jsonc`, OpenNext) and its GitHub workflow is manual-only. If production is on Workers, saved-deadline alerts may never run. Docs dated 12 Nov say production was on Vercel; the Workers config (compat date 2026-11-21) suggests a later move.
2. **Silent truncation of the match catalog (F-08, Probable, High).** `getMatches.ts` reads all scholarships and all rules with no pagination. Supabase's default Data API cap is 1,000 rows. At roughly 250 or more listings, rules past the cap are dropped without any error, so scholarships lose requirements and look more eligible than they are. This is the core differentiator, so it is the most important correctness risk.
3. **Matching hot path does avoidable work (F-06, F-07, F-09, F-13).** For any user who has saved or tracked one scholarship, the per-user cache is bypassed and the entire rules table is re-read on every dashboard load, even when the catalog is cached. The dashboard then ships every match, with full requirement text, to the phone.
4. **Telemetry is the busiest traffic (F-14).** Each page view fires up to six separate POSTs (one page view plus five web-vitals), each doing an auth call, one or two Redis calls and a DB write. This burns Redis quota, competes with the app on slow networks, and inflates the `events` table.
5. **Optional infrastructure can block core reads (F-18, F-19).** The rate limiter fails closed. A Redis outage or exhausted free-tier quota returns 503 on browse, save and events. Limits are keyed by IP, and mobile carriers share IPs, so real users can be throttled together.
6. **Public pages probably are not cached (F-03, F-04).** `revalidate = 300` is set on several public pages, but the OpenNext config has no incremental cache, and SEO pages are `force-dynamic`.

### Scalability outlook

Current scale is comfortable. 5K to 10K registered users is reachable after the P0/P1 items below. 50K to 100K needs the matching and telemetry changes plus retention. 500K to 1M is achievable on the same stack only if matching is precomputed or pre-filtered in SQL, telemetry leaves Postgres, and notifications move to a queue. Registered users are not concurrent users; see Section 5 for the arithmetic.

### Reliability outlook

Good fault handling exists for Supabase Auth blips (retry, 503, `/connection-problem`) and for email providers (failover only on definitive rejection, which avoids duplicate sends). Weak points: 15-second default timeouts on user-facing server calls, the Redis fail-closed coupling, no visible scheduler for background work, and email batch loops that run inside one HTTP request.

### Production readiness verdict

Ready for the current user base. Not yet ready for 10x growth until P0 is done (about a week of low-risk work) and P1 is under way. No change recommended requires new paid infrastructure; two (R2 or KV for the cache, a Cloudflare cron or GitHub schedule) fit free tiers.

### What is already good (keep it)

- Email is decoupled from user requests: app mail is manual-only (`lib/email/send.ts:38`), auth mail goes through Supabase, and Brevo-to-Resend failover happens only on definitive rejection (`send.ts:53-56`).
- Push campaigns paginate correctly with `.range` (`lib/push/campaigns.ts`). The matching code should follow that pattern.
- Narrow profile projection (`lib/supabase/currentUser.ts:49-55`), `server-only` service client, zod validation, escaped LIKE patterns, HSTS and security headers.
- Local fonts with `display: swap`, lazy-loaded web-vitals, client-side avatar downscaling (`lib/images.ts`).

## 2. Application Architecture Map (Deliverable 3)

```
Student browser / installed PWA (often low-end Android, unstable data)
   |  HTML + RSC, fetch /api/*, supabase-js directly for signup/login/OTP
   v
Cloudflare edge --> Worker (OpenNext build of Next.js 15.5)
   |                  middleware (auth gate) -> RSC pages / route handlers
   |                    |-- Supabase Auth   /auth/v1/user   (middleware + page + each API call)
   |                    |-- Supabase PostgREST  (RLS, anon key + user cookie; service role for jobs)
   |                    |-- Upstash Redis REST  (rate limit, catalog cache, per-user match cache)
   |                    |-- Brevo -> Resend failover (admin-triggered only)
   |                    '-- HIBP password-range API (signup)
   '-- static assets (.open-next/assets)

Supabase Auth --SMTP (set in Supabase dashboard, not in repo)--> email provider
GitHub Actions: manual dispatch only --> /api/cron/*   (Vercel cron exists only if hosted on Vercel)
Inngest: route registered, functions are no-ops (email automation paused)
```

### Traced execution paths (counted from code, latency not measured)

- **Registration/login:** browser calls `supabase.auth.signUp` / `signInWithPassword` / `verifyOtp` directly. Signup first awaits `/api/auth/password-check` (plain `fetch`, no timeout) and posts a confirmation event to `/api/auth/confirmation-email-event`. Auth mail leaves via Supabase's SMTP, not app code.
- **Any protected navigation:** middleware `getUser()` (retried once on transient error, 8 s timeout each) -> RSC `getCurrentUserAndProfile()` calls `getUser()` again plus a `profiles` select. `React.cache` only dedupes within one render, so the auth server is called at least twice per navigation.
- **Dashboard:** about 8 to 11 network calls, about 7 sequential: auth, profile, retained-ID queries (2), Redis match-cache GET, Redis catalog GET, then on a miss or an engaged user a scholarships query and an unfiltered rules query, then `cycle_events`, then a Redis SET (not awaited). In parallel: saved list (joined) and a trending RPC.
- **Matching:** pure in-memory TypeScript (`lib/matching/engine.ts`), cost O(scholarships x rules) per request. No DB writes. Cheap CPU; the expensive part is fetching and serializing the inputs and outputs.
- **Search/browse:** `/api/scholarships` -> rate limit (Redis) -> `getUser` -> retained-ID queries -> one filtered, offset-paginated query using `ILIKE %q%`.
- **Bookmark:** `/api/scholarships/save` POST -> rate limit -> `getUser` -> insert -> analytics event. Achievement triggers run in the database.
- **Reminders:** email reminders are disabled by design. Only opt-in web push via `/api/cron/deadline-check`, whose scheduler is the open question in F-02.

## 3. Performance Findings Register (Deliverable 2)

Line references are from the snapshot. Where I read a file without line numbers I cite the function instead.

| ID | Finding | Sev | Conf | File / module | Impact | Recommendation |
|---|---|---|---|---|---|---|
| F-01 | Deploy target ambiguous: Vercel remnants beside a Cloudflare Workers build | Med | Confirmed | `vercel.json`; `wrangler.jsonc`; `middleware.ts:62-64,218` (VERCEL_ENV); `notification-worker.yml` targets a vercel.app host | Vercel-only branches are dead on Workers; ops and docs disagree | Confirm the live target; remove or port dead branches |
| F-02 | No visible scheduler for the deadline/push job on Workers | High | Probable | `vercel.json` crons; `wrangler.jsonc` has no `triggers.crons`; `digest-cron.yml` is `workflow_dispatch` only | Saved-deadline push alerts may never run | Add a GitHub `schedule:` trigger or Cloudflare cron; alert on a missed run |
| F-03 | OpenNext incremental cache not configured, so ISR `revalidate` is likely a no-op | High | Probable | `open-next.config.ts` (defaults only); `wrangler.jsonc` has no KV/R2; `app/page.tsx:21`, `s/[id]`, `o/[id]`, `scholarships-in-nigeria` | Public pages render and query Supabase per request | Configure an R2/KV cache, or cache at the edge with Cache-Control; check `x-nextjs-cache` / `cf-cache-status` |
| F-04 | SEO pages and sitemap are `force-dynamic`; share routes set cookies in middleware | Med | Confirmed | `app/scholarship/[slug]/page.tsx:20`; `app/opportunity/[slug]/page.tsx:109`; `app/sitemap.ts:9`; `middleware.ts:95-119` | Crawlers and shared links hit the DB; `Set-Cookie` responses are not CDN-cacheable by default | Cache public HTML with s-maxage plus stale-while-revalidate; move attribution cookie off the cached response |
| F-05 | No Smart Placement; Worker may sit far from Supabase/Upstash | Med | Potential | `wrangler.jsonc` | Edge-to-DB round trips multiply across about 7 sequential calls | Test `placement.mode: smart`; co-locate Upstash with the Supabase region |
| F-06 | Full `scholarship_rules` table re-read on every dashboard/match call for any user with a saved or tracked item, even when the catalog is cached | High | Confirmed | `lib/matching/getMatches.ts:100-124,132` | Largest avoidable read on the hottest path | Serve rules from the catalog cache; fetch only the retained scholarships |
| F-07 | Retained-ID queries run before the cache check, and a non-empty set bypasses the per-user match cache | High | Confirmed | `getMatches.ts:67,75`; `lib/scholarship-visibility.ts:11-30` | The cache only helps users with zero saves, i.e. the least engaged | Apply retention in memory over the cached catalog; run lookups in parallel |
| F-08 | Unpaginated catalog and rules reads exposed to the Data API row cap (default 1,000); same pattern in digest | High | Probable | `getMatches.ts:109-124`; `lib/email/digest.ts:60,77` | Rules beyond the cap silently ignored, so wrong eligibility; digest dedupe history truncated, risking repeat announcements | Paginate with `.range` or one RPC; add a count guard and alert |
| F-09 | `cycle_events` queried per user with `.in(all ids)` although the data is user-independent | Med | Confirmed (code), Potential (limit) | `getMatches.ts:34-55,175` | Extra round trip; URL grows with catalog, may fail past a few hundred ids and silently drop cycle data (fail-open) | Fold cycle predictions into the shared catalog cache |
| F-10 | Retained IDs embedded in `id.in.(...)` URLs | Med | Potential | `scholarship-visibility.ts:39`; `getMatches.ts:121`; `api/scholarships/route.ts:69` | Heavy savers can exceed URL limits | Move the visibility predicate into a SQL view/RPC |
| F-11 | Cache writes are `void` (not awaited) | Med | Probable | `getMatches.ts:136,177` | On Workers an un-awaited promise can be cancelled when the response ends; cache fills intermittently | Use `waitUntil` / `after()` |
| F-12 | Per-user cache stores fully expanded matches (requirements plus two filtered copies); catalog cached as one blob | Med | Probable | `lib/matching/types.ts:73-85`; `matchCache.ts` | Redis memory and bandwidth scale with users x catalog; one-blob catalog may approach Upstash request-size limits near about 1K listings, and the failure is swallowed | Cache the catalog only, or compact tuples; compute is cheap |
| F-13 | Dashboard sends every match, with requirement text, to the client | High | Confirmed (code), Probable (size) | `app/dashboard/page.tsx:73-83`; `DashboardClient.tsx` | HTML/RSC payload grows linearly with catalog; parse and hydrate cost on low-end Android | Send a list projection; load requirement detail on the detail page |
| F-14 | Telemetry fan-out: page_viewed plus 5 web-vitals as separate POSTs, each with auth, Redis, DB write | High | Confirmed | `Monitoring.tsx` (effects); `lib/analytics.ts:38-50`; `api/events/route.ts:55-81` | Busiest endpoint is analytics; at least 12 Redis calls per signed-in page view (2 limiter keys x 6); anonymous vitals sent only to get a 401 | Batch with `sendBeacon`, sample vitals, skip vitals for anonymous, one auth check per batch |
| F-15 | Notification polling every 60 s, not paused when the tab is hidden; endpoint unthrottled | Med | Confirmed | `NotificationBell.tsx:59`; mounted in `Sidebar.tsx`; `api/notifications/route.ts` | Baseline load grows with open tabs, plus mobile data and battery cost | Pause when hidden, back off, refresh on focus |
| F-16 | Presence ping also fires on every focus/visibility event; legacy `/api/heartbeat` appears unused | Low | Confirmed | `lib/presence.ts:7`; `api/heartbeat/route.ts` | Extra writes to `profiles` | Add a minimum interval; delete the legacy route |
| F-17 | Chatty sequential SSR with repeated `getUser()` | Med | Confirmed pattern, magnitude unmeasured | `middleware.ts:166-175`; `currentUser.ts:37-55`; every API route | One or more extra auth round trips per navigation | Parallelize independent calls; consider JWT-claims verification in middleware after a client upgrade |
| F-18 | Rate limiter fails closed on any Redis error | Med | Confirmed | `lib/ratelimit.ts:83-112` | Redis outage or free-tier exhaustion returns 503 on browse, save, events | Fail open for reads; fail closed only for abuse-prone writes; in-memory fallback |
| F-19 | Buckets keyed by IP first, extra user key checked sequentially | Med | Probable | `ratelimit.ts:100-107`; `api/events/route.ts:58-61` | Shared mobile-carrier IPs cause false 429s (events cap is 60/min per IP, about 10 page views) | Key by user id once authenticated; measure the 429 rate |
| F-20 | Authenticated routes with no rate limit | Med | Confirmed | `api/scholarships/match`, `api/profile`, `api/profile/waec`, `api/notifications`, `api/applications/[id]` (+checkin, click), `api/scholarships/[id]`, `api/opportunities`, `api/scholarships/report`, `api/onboarding/prompts`, `api/achievements/announce`, MFA routes | Match endpoint can force a full recompute; throwaway accounts can load the DB | Add per-user limits, strictest on `match` and `profile` |
| F-21 | Index name collision: `idx_profiles_last_seen` is created on `last_seen` (0015) then `IF NOT EXISTS` skips the `last_seen_at` index (0021); duplicate migration numbers 0021, 0102, 0103 | Low-Med | Confirmed (code), verify in DB | `0015_add_last_seen_to_profiles.sql:10`; `0021_add_presence_and_verified_on.sql:21-22` | Presence/admin queries on `last_seen_at` are unindexed; ordering ambiguity | Check `pg_indexes`; create under a unique name; use unique migration numbers |
| F-22 | No retention or archival for `events`, `visitor_daily_metrics`, `monitoring_error_events`, notification tables | Med | Confirmed absence in repo | `supabase/migrations/*` (no pg_cron, purge, partitioning) | Unbounded growth, size, backup time | Scheduled purge or rollup with documented retention |
| F-23 | RLS policies use bare `auth.uid()` (117 hits) and `is_admin(auth.uid())` (58), none wrapped in `(select ...)` | Low | Probable | `supabase/migrations/*` (includes superseded policies) | Per-row re-evaluation on scans | Wrap in `(select auth.uid())`; verify against live `pg_policies` |
| F-24 | Search uses leading-wildcard `ILIKE` with no trigram index | Low | Confirmed | `api/scholarships/route.ts:75-78` | Sequential scan; trivial at hundreds of rows | Add `pg_trgm` only if the table passes about 10K rows or latency shows it |
| F-25 | Offset pagination ordered by `deadline` only | Med | Confirmed | `api/scholarships/route.ts:71` | Rows with equal or null deadlines can repeat or vanish between pages | Order by `deadline, id`; keyset later |
| F-26 | Email lookup scans `auth.admin.listUsers` page by page; hard stop at 100 pages | High at 10K | Confirmed | `lib/email/authRecipients.ts:14-29`; also `admin/users/page.tsx:60`, `admin/broadcast/route.ts:68`, `reengagement/route.ts:65`, `profileNudges.ts:186` | Users beyond 10,000 silently get no email; O(N) calls per 300-recipient batch | `service_role`-only SECURITY DEFINER RPC returning email by id list |
| F-27 | Digest/broadcast loops run inside one request, about 4 to 6 subrequests per recipient; `maxDuration` is a Vercel directive | High if Workers limits apply | Probable | `lib/email/digest.ts:95-185`; `api/admin/digest/route.ts`; cron and inngest routes | A 300-recipient batch may exceed the per-invocation subrequest limit on Workers (50 free, 1,000 paid) | Process in chunks of about 50 using the existing outbox claims |
| F-28 | All automated email disabled; no deadline email reminders | Info | Confirmed | `send.ts:38`; `cron/notification-worker/route.ts`; `inngest/functions.ts` | Reminder reach limited to opt-in push | Re-enable only after queue and delivery observability exist |
| F-29 | CSP allows `'unsafe-inline'` scripts (documented as deliberate) | Low | Confirmed | `next.config.js` | Weaker XSS backstop | Accept; nonces would force dynamic rendering and undo caching |
| F-30 | Admin MFA is an opt-in env flag and enforced only in the `/api/admin` middleware branch | Med | Confirmed | `middleware.ts:40-42,193-215` | Admin compromise impact | Set `REQUIRE_ADMIN_MFA=true`; confirm `/admin` pages are covered |
| F-31 | Signup awaits the password-check call with no client or server timeout; plaintext password is sent to the app to hash | Med | Confirmed | `app/(auth)/signup/page.tsx:57`; `api/auth/password-check/route.ts` | Signup can stall on poor networks; extra plaintext exposure | Hash client-side and send the 5-char prefix; `AbortSignal.timeout(2-3s)` both sides |
| F-32 | Server Supabase timeout is 15 s; middleware can retry (8 s x 2) | Med | Confirmed | `lib/fetch.ts:87`; `middleware.ts:148,166-171` | Worst-case page waits 16 s or more before any fallback | 4 to 6 s budgets for SSR calls with partial render |
| F-33 | Root layout mounts five client components on every route; `NetworkStatus` imports the Supabase browser client | Med | Confirmed (import), size unmeasured | `app/layout.tsx:74-82`; `NetworkStatus.tsx:1-6` | Extra JS on the public landing page | Lazy-load after idle; measure with a bundle analyzer |
| F-34 | 89 of 172 TSX files are client components; onboarding is one 38 KB client page | Med | Probable | `app/onboarding/page.tsx` | Heavy hydration at the highest-abandonment step | Split steps with dynamic imports after measuring |
| F-35 | Plain `<img>` without dimensions or `next/image` | Low | Confirmed | `Sidebar.tsx:123`, `TestimonialsRotator.tsx`, `about/page.tsx:92` | Possible layout shift; avatars are already downscaled | Add width/height and `loading="lazy"` |

## 4. Performance Optimization Roadmap (Deliverable 4)

Ordering principle: high gain, low regression risk first; one change per hot path at a time; every change behind a flag or a cache-key bump so it can be undone without a redeploy.

### P0 — Immediate production risks (about one week, low risk)

**P0-1. Confirm the deploy target and restore a scheduler (F-01, F-02)**
- What: confirm which platform serves `www.scholars.com.ng`. If Workers: add a `schedule:` trigger to the existing GitHub workflow that calls `/api/cron/deadline-check` (free; the secret and workflow already exist), or add a Cloudflare Cron Trigger. Point `notification-worker.yml` at the real host. Remove the `vercel.json` cron and the `VERCEL_ENV` branches once confirmed.
- Why: otherwise saved-deadline push alerts silently never run.
- Files: `.github/workflows/digest-cron.yml`, `notification-worker.yml`, `wrangler.jsonc`, `vercel.json`, `middleware.ts`.
- Dependencies: `CRON_SECRET`. First confirm `runDailyPushCampaign` is safe to run twice in a day (I did not verify its idempotency).
- Regression risk: duplicate pushes if it is not idempotent. GitHub scheduled runs are best effort and can lag, which is acceptable for a daily job.
- Test: manual dispatch against staging, compare send counts. Rollback: delete the schedule line.

**P0-2. Guard the row cap (F-08)**
- What: check the Data API "Max rows" setting and the real counts (SQL in Section 7). Paginate the catalog and rules reads with `.range` loops ordered by id (or one RPC returning JSON), the same pattern `lib/push/campaigns.ts` already uses. Log or alert when any page returns exactly the cap. Apply the same fix to the digest reads (`profiles`, `announcement_log`).
- Files: `lib/matching/getMatches.ts`, `lib/email/digest.ts`.
- Regression risk: low. Same data, more requests, paid once per 60 s because the result is cached.
- Test: golden comparison of ranked output for about 20 real profile fixtures before and after (must be identical), plus a synthetic 1,200-rule catalog proving nothing is dropped. Rollback: revert the file and bump the cache key.

**P0-3. Baseline measurements (all findings).** Workers observability is already enabled in `wrangler.jsonc`. Record p50/p95/p99 per route, subrequests per invocation, Supabase API and Auth reports, Upstash usage, and a throttled-Android Lighthouse run. No code change; every later claim depends on it.

### P1 — High-impact performance and reliability

**P1-1. Matching path v2 (F-06, F-07, F-09, F-11, F-12, F-13)**
- What: (a) put cycle predictions inside the shared catalog payload; (b) when the catalog is warm, never re-query rules, because the cached rules already include closed listings and the retained scholarships come from the cached catalog; (c) run the retained-ID lookup, match-cache read and catalog read in parallel; (d) drop the per-user full-match cache or shrink it to compact tuples (id, score, tier), since evaluation is cheap CPU and the cache costs a large Redis round trip; (e) write caches with `waitUntil`/`after()`; (f) send the dashboard a list projection (id, title, provider, amount, deadline, tier, score) and let the detail page keep full requirements.
- Files: `getMatches.ts`, `matchCache.ts`, `scholarship-visibility.ts`, `app/dashboard/page.tsx`, `DashboardClient.tsx`, `lib/matching/types.ts`.
- Dependencies: P0-2 first. Regression risk: ranking drift and a changed props contract.
- Test: golden rankings, type check of the dashboard props, before/after dashboard timing under the load test. Rollback: `MATCH_PATH_V2` flag plus a cache-key bump (v3).

**P1-2. Telemetry diet (F-14, F-15, F-16)**
- What: queue events in memory and flush as one `sendBeacon` POST when the page is hidden or about every 10 s; sample web-vitals (start near 20 percent); send no vitals when signed out; one auth check per batch; poll notifications only while visible, with back-off when empty; add a minimum interval to the presence ping; delete the unused `/api/heartbeat`.
- Files: `Monitoring.tsx`, `lib/analytics.ts`, `api/events/route.ts`, `NotificationBell.tsx`, `lib/presence.ts`.
- Regression risk: admin funnel and vitals counts change. Record the sample rate in event meta so reports can rescale. The DB event whitelist stays unchanged.
- Test: staging events arrive, funnel within tolerance. Rollback: flag.

**P1-3. Rate limiting redesign (F-18, F-19, F-20)**
- What: fail open for read routes, fail closed for auth-adjacent, admin, email-triggering and write routes; key by user id once authenticated and keep a generous per-IP ceiling; run the limiter calls in parallel; add per-user limits to the unthrottled routes (strictest on `match` and `profile`); optional in-memory per-isolate token bucket as the degraded fallback.
- Files: `lib/ratelimit.ts` (+ `ratelimit.test.ts`) and the routes in F-20.
- Regression risk: a short abuse window on reads while Redis is down, which is the intended trade. Test: extend the unit tests, simulate Redis down. Rollback: revert one file.

**P1-4. Cache public pages at the edge (F-03, F-04, F-05)**
- Option A (preferred, near-zero cost): `Cache-Control: public, s-maxage=300, stale-while-revalidate=3600` on anonymous public HTML plus a Cloudflare cache rule for an explicit path allowlist; keep personalised routes `private, no-store`; move the attribution cookie in `middleware.ts:95-119` to a small client call so cached HTML carries no `Set-Cookie`. Option B: configure the OpenNext incremental cache with R2 or KV so the existing `revalidate` settings work. Also trial `placement.mode: smart` and co-locate Upstash with the Supabase region.
- Risk: caching a personalised page and leaking one user's data. Mitigate with an allowlist (never wildcards over `/dashboard`, `/api`, `/settings`), and test with two accounts. Rollback: delete the cache rule.

**P1-5. Signup and SSR timeouts (F-31, F-32).** Hash the password client-side and send only the 5-character prefix; add `AbortSignal.timeout` of 2 to 3 s on both the client call and the HIBP call; give SSR Supabase calls a 4 to 6 s budget and render partially (the dashboard already tolerates saved/trending failing).

### P2 — Important optimizations

- **P2-1. Email recipient RPC and chunked sending (F-26, F-27).** A SECURITY DEFINER function `get_auth_emails(ids uuid[])` executable only by `service_role`; process at most about 50 recipients per invocation, reusing the existing `claimNotificationDelivery` outbox. Do this before 5,000 users or before re-enabling any automation. Re-enable deadline emails only with provider delivery-event tracking and a daily cap under the provider quota.
- **P2-2. Retention and index fix (F-21, F-22).** Suggested starting retention: raw `events` 90 days then a daily rollup; `monitoring_error_events` 30 days; read notifications 90 days; `visitor_daily_metrics` 13 months. Use `pg_cron` (available on Supabase) and `CREATE INDEX CONCURRENTLY` under a unique name. Check the admin analytics RPC windows before deleting anything, and take a backup first.
- **P2-3.** Wrap RLS calls in `(select auth.uid())` after confirming against live `pg_policies` (F-23); add the `id` tiebreaker to pagination (F-25); add trigram search only if measurements justify it (F-24).
- **P2-4.** Bundle and hydration diet after measurement: lazy-load `NetworkStatus`, split onboarding steps, add image dimensions (F-33 to F-35).
- **P2-5.** Middleware auth cost (F-17) behind a flag, and `REQUIRE_ADMIN_MFA=true` (F-30).

### P3 — Long-term, only if measurements demand it

- Precomputed or SQL pre-filtered matches (incremental recompute on profile or catalog change) for 100K+ users.
- Queue-based notification fan-out (Cloudflare Queues or Supabase queues) on top of the existing outbox.
- Move analytics events out of the OLTP database (partitioning, rollups or an external store).
- Read replica for admin and analytics reads, only if the primary shows contention.
- Nonce-based CSP only if the app becomes fully dynamic anyway.

### Caching strategy (what, where, how long, invalidation)

| Data | Where | TTL | Invalidation |
|---|---|---|---|
| Public landing, listing, SEO and share pages | Cloudflare edge | 5 min plus 1 h stale-while-revalidate | Short TTL; optional URL purge on admin publish |
| Shared catalog plus rules plus cycle predictions | Redis, one key | 60 to 120 s | Explicit delete on admin scholarship or rule write; `SET NX` lock so only one request rebuilds (stampede guard) |
| Reference data (courses, institutions, LGAs) | Already static TS modules | Build time | Deploy |
| Per-user matches | Not shared; recompute from the catalog, or a compact per-user key if kept | 10 min | Delete on profile or WAEC write (already done) |
| Profiles, matches, notifications, dashboard, auth, admin | Never CDN-cached | `private, no-store` | n/a |

## 5. Scalability Assessment (Deliverable 5)

**Registered is not concurrent.** The assumptions below are placeholders to replace with measured DAU and peak-concurrency ratios: DAU is 10 to 20 percent of registered; peak concurrent is 5 to 10 percent of DAU. A signed-in open tab currently generates about 0.02 background requests per second (60 s notification poll plus 5 min presence ping), each costing at least two backend calls (auth plus database), before any navigation or telemetry (up to six POSTs per page view). Postgres never sees one connection per registered user; the pressure is request rate through the Data API pool and the Auth server.

| Stage | Illustrative peak concurrent | Illustrative idle background load | Likely bottleneck | Required changes |
|---|---|---|---|---|
| Now (about 216 per repo docs; refresh from DB) | tens | under 1 req/s | Not load. Correctness (F-08) and scheduler (F-02) | P0 |
| 10K | 50 to 200 | 1 to 4 req/s | `listUsers` 10,000 hard cap (F-26); Upstash free quota burned by telemetry (F-14, F-18); row cap if catalog is 250+ listings | P0, P1-1 to P1-3 |
| 50K | 250 to 1,000 | 5 to 20 req/s | Per-navigation auth calls and the sequential chain; dashboard payload; `events` growth; PostgREST pool size (plan dependent) | P1-4, P1-5, P2-1, P2-2, paid Workers plan |
| 100K | 500 to 2,000 | 10 to 40 req/s | `events` table in the tens of millions of rows per year; Workers CPU and subrequest limits; edge cache hit ratio | Retention mandatory, compute add-on if measured, P2-4 |
| 500K | 2,500 to 10,000 | 50 to 200 req/s | Per-request matching and serialization at high concurrency; notification fan-out; analytics on the OLTP database | P3 precomputed matches, queue fan-out, analytics off Postgres |
| 1M | 5,000 to 20,000 | 100 to 400 req/s | Write path (events, presence), auth validation volume, large batch operations | Full capacity review, partitioning, read replica, cost model |

Matching math: cost per evaluation is proportional to scholarships times rules and is pure in-memory work, so CPU is probably not the first limit (measure with a micro-benchmark). The first limits are the volume of data fetched and serialized per request, and the cache design (F-12): at about 2 KB per match, a user's cached payload is roughly 120 KB at 60 listings and about 2 MB at 1,000, held per user for 10 minutes. That per-match size is my estimate from the type shape, not a measurement.

## 6. UX and Mobile Performance Report (Deliverable 6)

Targets below are proposals to validate, not measurements.

| Journey step | Observation | Recommendation |
|---|---|---|
| 1. Landing | Server rendered; local fonts with swap (good). Five client components mount in the root layout; install prompt and cookie banner compete for attention | Lazy-load non-critical components after idle; confirm caching works (F-03, F-33) |
| 2. Registration | Awaits a password-check call with no timeout; fails open on error | Client-side prefix hashing and a 2 to 3 s timeout (F-31) |
| 3. Email verification | Code entry alternative exists, which suits Android where switching to the mail app can lose the PWA session. Delivery is not measured beyond Supabase accepting the request | Keep the OTP path; add delivery-event tracking (per the repo's own 12 Nov email audit); clear resend cooldown copy |
| 4. Onboarding | One 38 KB client page; step saves are fire-and-forget (fast) and resumable via `onboarding_step` (good), but failures are silent until the final submit | Split steps with dynamic imports; show a retry indicator using the existing outbox |
| 5. Academic profile | Saved through the unthrottled `/api/profile` | Add a per-user limit (F-20) |
| 6. First matching | Hot path described in F-06 to F-13 | P1-1 |
| 7. Dashboard | Skeleton exists (good), but the payload carries every match with requirement text | List projection; show top matches first with "show more" (F-13) |
| 8. Discovery | Debounce, abort, 20 per page and an offline first-page cache (all good); tie-ordering can repeat rows | `deadline, id` ordering (F-25) |
| 9. Scholarship detail | Dynamic with three parallel queries (good) | Cache the public parts; keep personal match separate |
| 10. Saving | Offline outbox exists | Verify the optimistic path in airplane mode |
| 11. Returning | `/` redirects signed-in PWA users to the dashboard (good). Cookie-domain migration logic is intricate | Treat `middleware.ts` cookie code as frozen except behind a flag |
| 12. Deadline reminders | Email paused; only opt-in push, whose scheduler is unconfirmed | Fix F-02; ask for push permission right after the first save; surface upcoming deadlines on the dashboard |

**Low-end Android and unstable connections, in order of payoff**
1. Cut background traffic (telemetry batching, visible-only polling). It also saves prepaid data.
2. Shrink the dashboard payload and hydration (list projection, lazy-load community, onboarding and network components).
3. Bound waits: 4 to 6 s timeouts with a cached last-known view, extending the existing offline catalog cache to the top dashboard matches.
4. Confirm the network overlay in `NetworkStatus` never blocks input during sync (its minimum hold times are 0.9 to 2.6 s).
5. Proposed budgets to validate: LCP under 2.5 s and INP under 200 ms on a 2 to 3 GB RAM device at Slow 4G; set a JS budget after the first bundle analysis.

## 7. Runtime Validation Checklist (Deliverable 7)

**Dashboards and metrics**
- Cloudflare Workers: CPU time p50/p95/p99, subrequests per invocation, wall time, error rate, per route; cache status headers (`cf-cache-status`, `x-nextjs-cache`, `age`) on public pages.
- Supabase: Data API latency and error report, database connections, Auth requests per minute, slow queries.
- Upstash: commands per day, bandwidth, largest request size, p99 latency, quota remaining.
- Real users: p75 LCP, INP and CLS by day from the `web_vital` events already stored.
- Settings to read: Data API "Max rows", Supabase region and plan, Upstash plan and region, Workers plan, whether Smart Placement is on.

**SQL (run read-only on production, or on a copy)**

```sql
-- 1. Catalog size against the Data API row cap
select (select count(*) from scholarships where verified and level in ('undergrad','both')) as listings,
       (select count(*) from scholarship_rules) as rules;
-- 2. Index collision (F-21)
select indexname, indexdef from pg_indexes
 where schemaname='public' and tablename='profiles' and indexdef ilike '%last_seen%';
-- 3. Largest tables
select relname, pg_size_pretty(pg_total_relation_size(relid)) as size, n_live_tup
 from pg_stat_user_tables order by pg_total_relation_size(relid) desc limit 15;
-- 4. Event volume by type, last 7 days
select event, count(*) from events where created_at > now() - interval '7 days' group by 1 order by 2 desc;
-- 5. Heaviest statements
select left(query,120) q, calls, round(mean_exec_time::numeric,1) mean_ms,
       round(total_exec_time::numeric) total_ms
 from pg_stat_statements order by total_exec_time desc limit 20;
-- 6. RLS policies not wrapped in (select auth.uid())
select tablename, policyname from pg_policies
 where qual ilike '%auth.uid()%' and qual not ilike '%select auth.uid()%';
-- 7. Tables read mostly by sequential scan
select relname, seq_scan, idx_scan from pg_stat_user_tables
 where seq_scan > coalesce(idx_scan,0) order by seq_scan desc limit 15;
-- 8. Auth users against the 10,000 listUsers cap
select count(*) from auth.users;
-- 9. Real-user web vitals, p75
select meta->>'name' as metric,
       percentile_cont(0.75) within group (order by (meta->>'value')::numeric) as p75
 from events where event='web_vital' and created_at > now() - interval '7 days' group by 1;
-- 10. Signup growth by week
select date_trunc('week', created_at) wk, count(*) from profiles group by 1 order by 1;
```

Also run `explain (analyze, buffers)` on the browse query and the dashboard's retained-ID queries once catalog size is known.

**Load-testing strategy (k6 or similar, free)**
- Environment: a separate Supabase project, Upstash database and staging Worker. Seed 10K profiles and 300 to 1,000 listings with realistic rules. Create accounts through the service role and inject sessions, so signup tests do not hit Auth email limits. Never test against production with real email.
- S1 public: landing, listing and SEO pages; measure edge cache hit ratio.
- S2 signed-in session: dashboard, three debounced searches, detail, save, then 5 minutes of idle polling.
- S3 onboarding burst: profile upserts at campaign-launch rates.
- S4 spike: 10x traffic in 60 s on one shared scholarship link.
- S5 soak: one hour of background mix (polls, presence, events) at the target concurrent count; watch Redis commands, DB connections and Auth request rate.
- Pass criteria: set from the baseline (for example dashboard p95 and an error rate under 1 percent), plus zero 503s from the limiter with Redis healthy.
- Mobile: Lighthouse and DevTools throttling (Slow 4G, 4x CPU) and at least one real low-end Android device.

## 8. Regression Prevention Plan (Deliverable 8)

1. **Golden tests for matching.** Freeze a catalog snapshot and about 20 profile fixtures; assert identical tier, score and order before and after every change (extends `lib/matching/engine.test.ts`). Add RLS checks under `supabase/tests`.
2. **Flags first.** Every P1 change ships dark behind an env flag, then admins only, then 10 percent, then all. A cache-key prefix bump is the universal kill switch.
3. **Cloudflare gradual deployments and `wrangler rollback`.** Deploy at the lowest-traffic hour once traffic data exists. One change per hot path per release, with a 24 h bake.
4. **Database changes are additive.** Create a new index `CONCURRENTLY` or a new function first, switch code second, drop old objects last. Use unique migration numbers. Rehearse on staging and keep rollback SQL in the pull request.
5. **Cache safety tests.** CI assertions that personalised routes return `private, no-store`; a two-account test proving no shared keys or cached HTML; an explicit edge-cache path allowlist.
6. **Freeze the cookie and PWA session code.** Any change to `middleware.ts` auth (F-17) needs the `cookie-domain`, `pwa-session` and `return-destination` tests green plus a manual installed-PWA test on Android.
7. **Contract tests.** Keep `/api/scholarships/match` and the dashboard props backward compatible; add fields before removing any.
8. **Observability gates.** Define SLOs (error rate, p95 per route, Redis quota) and rollback triggers before each rollout.
9. **CI.** Keep `tsc` and `vitest`; add a bundle-size budget once measured.
10. **Suggested order.** P0, then measure, then P1-1 behind a flag, P1-2, P1-3, P1-4, P1-5, then P2.

### Questions only your team can answer

- Which platform actually serves production today, and what is the Workers plan?
- What are the Supabase region, plan, and Data API Max rows setting, and where is the Upstash database?
- Is `runDailyPushCampaign` idempotent on repeated runs, and does Web Push actually deliver from the Workers runtime?
- What are the current registered-user, DAU and listing counts (the repo documents show 216 and 60+)?
