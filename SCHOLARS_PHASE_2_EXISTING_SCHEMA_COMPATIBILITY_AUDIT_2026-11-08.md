# Scholars Phase 2 — Existing Schema Compatibility Audit

**Inspection date:** 2026-11-08
**Application revision:** `ImperioKDB/Scholars` `main` at `cf3682ce35912df7b9b9352193630fc404427c7c`
**Live project:** Supabase `scholarship-platform` (`cmdglabohpttgfofcmqc`, `eu-west-1`), metadata-only inspection
**Status:** Read-only; no data or schema changes made.

## 1. Scope, evidence, and limits

This audit inspected the checked-in Scholars source and migrations, and queried Supabase metadata (table/column/key/RLS inventory, public views, and relevant policies). It did not select scholarship or student rows, inspect private research-note values, mutate database state, read provider pages, test credentials, or invoke production routes. The live metadata inventory reported **95 `public.scholarships` rows, 42 `public.opportunities` rows, 242 `public.scholarship_rules` rows, and 10 `public.cycle_events` rows** at inspection. These are inventory counts, not a claim that each row’s content is currently accurate.

The application checkout corresponds to the commit recorded by the Phase 1.1 audit. The reporting-repository handoff bundled in `Updates` refers to `2f90abf` although the reviewed commit is `c06e1b0`; this mismatch is documentation hygiene, not application evidence.

The checked-in migration chain has duplicate numeric prefixes and does not, by itself, prove which migrations were applied in production. Live table metadata confirms that `public.opportunities` exists in production despite no base `CREATE TABLE opportunities` migration being found in this checkout. Any future migration plan must reconcile against Supabase migration history and deployed DDL before applying changes. This audit did not inspect the migration ledger.

## 2. Current catalogue and related entities

### Scholarships

`public.scholarships` is initially defined in `supabase/migrations/0001_init.sql`; later migrations add important fields. Live metadata confirms: `id`, `title`, `provider_name`, `description`, `amount`, `deadline`, `application_url`, `level` (enum `undergrad`, `postgrad`, `both`), `discipline`, `verified`, `created_by`, `created_at`, `updated_at`, `research_notes`, `how_to_apply`, competitiveness fields, `opens_at`, `last_cycle_closed_at`, `last_verified_at`, and `slug`.

The fields are overloaded for a multi-cycle evidence catalogue:

- `verified` is a single boolean used as a broad visibility/publication gate, not claim-level factual support.
- `last_verified_at` has no first-class source/capture or claim target; code stamps it when an admin sets `verified=true` and clears it on `false` (see `app/api/admin/scholarships/route.ts` and `app/api/admin/scholarships/[id]/route.ts`). Public detail copy can describe it as a team check, which risks implying more than the actual source check.
- `deadline`, `opens_at`, and `last_cycle_closed_at` are single listing fields, not multiple independently evidenced cycle records. `opens_at` affects some push-campaign filtering but not all catalogue query paths. Date edits alter visible lifecycle behavior.
- `application_url` and `how_to_apply` express one primary route/fallback, not multiple route types, conflicting instructions, provider-vs-third-party route ownership, or acceptance state.
- `research_notes` is a free-text private provenance field; the migration comment and code convention explicitly say it must not be selected into public API results. Free text is not sufficient for structured, queryable claims or audit/reporting.
- `level` and `discipline` are coarse listing attributes; richer criteria live in rules and/or text.

`scholarship_rules` (242 live rows) stores `field`, `operator`, JSONB `value`, and `gating`. `gating=true` is a hard cutoff; `false` is a soft preference. This is a usable compatibility layer for matching, but the table’s generic `text` field and JSON value do not provide strong typed semantics, source linkage, scope/effective cycle, uncertainty, or validation for each requirement.

### Opportunities

`public.opportunities` is separate from scholarships. Live metadata reports 42 rows and confirms an enum `type` including `fellowship`, `internship`, `competition`, `mentorship`, and `training`, as well as `deadline`, `opens_at`, `application_url`, `how_to_apply`, `eligibility_notes`, `verified`, and private `research_notes`. This catalogue has different display and matching behavior; do not merge it into a scholarship taxonomy by assuming the two models are interchangeable. No checked-in base-table creation migration was located in this repository revision; the live object is real, but its authoritative DDL source must be identified.

### Cycle events

`public.cycle_events` is defined in `supabase/migrations/0020_add_cycle_events.sql` and live metadata reports 10 rows. It holds `scholarship_id`, `kind` (`opened`, `closed`, `deadline_set`), `event_date`, optional `source_url`, `note`, `captured_by`, and `captured_at`. It is useful history, but it is not a cycle entity: dates remain tied to a scholarship, no event distinguishes notifications/disbursements/cancellation/postponement, and the current admin PATCH route’s event writes are best-effort. Date mutation may alter lifecycle behavior even if event logging fails.

### Discovery/evidence staging

A substantial workflow exists, but it is a **candidate intake and publication trust path**, not yet a catalogue-wide claim/evidence model:

- `discovery_sources`, `scholarship_discovery_candidates`: `0042_add_scholarship_discovery_candidates.sql`.
- Publication linkage: `0044_add_discovery_publication_tracking.sql`.
- Duplicate tracking, URL verification, quality scoring, eligibility review, and pilot controls: `0045`–`0049` migration files.
- Verification attempts: `0061_harden_scholarship_verification_agent.sql`.
- Fetch snapshots and candidate claims: `0062_add_safe_fetch_and_structured_claims.sql`.
- Freshness and review events/workflow queue: `0064_complete_discovery_trust_path.sql`.
- Claim review policies: `0065_add_claim_review_policies.sql`.
- Current-freshness publication gate: `0066_require_current_freshness_for_publication.sql`.

Candidate claims carry proposed field/value, source URL, evidence excerpt/confidence/extraction method, review status and reviewer. These are valuable ingredients but remain candidate-scoped; a published scholarship does not gain a durable, cycle-scoped claim→evidence ledger. Automated candidate extraction/eligibility verdict must not be presented as human editorial approval.

## 3. Current status/lifecycle behavior in code

| Concern | Actual implementation observed | Compatibility risk |
|---|---|---|
| Scholarship browse | `app/api/scholarships/route.ts`: authenticated; filters `verified=true`, `level` undergrad/both, deadline null/today-or-later, and `last_cycle_closed_at` null/future. Saved/applied IDs are retained by `lib/scholarship-visibility.ts`. | A closed/past item may remain available through personal tracking; a future `opens_at` is not a browse gate. |
| Matching | `lib/matching/getMatches.ts`, `lib/matching/engine.ts`: same verified/level/date gates; rules drive score/tier. Supported profiles include discipline, GPA, nationality, gender, need, age from DOB, state/LGA, year, institution type, JAMB, WAEC, disability. Some categorical failures are gating; missing/unsupported criteria can be omitted from scoring. | “Eligible” score tier is an advisory computation, not provider-confirmed eligibility. Matching is tied to the current scholarship row, not an exact cycle. |
| Detail and similar listings | Authenticated detail uses matching visibility; related scholarship queries use weaker predicates and do not consistently apply `last_cycle_closed_at`/level filters. | Similar-item surfaces may include records excluded from primary browse. Must normalize predicates before changing publication semantics. |
| Opportunity browse/detail | Verified, not-past-deadline query; `opens_at` does not gate; no scored eligibility result. | Behavior differs from scholarships; do not assume one shared visibility helper covers both. |
| Public routes | `app/scholarship/[slug]/page.tsx`, `/opportunity/[slug]/page.tsx`, sitemap and `lib/sitemap-data.ts` query verified rows. Closed records can remain reachable/indexable as public pages; pages label dates but do not establish provider acceptance. | Public exposure is not equivalent to actionable catalogue eligibility. Preserve useful history while preventing a current CTA or reminders. |
| Reminders | `app/api/cron/deadline-check/route.ts`, `lib/push/campaigns.ts`, notification worker. Push deadline reminders target verified scholarships with exact date 7 days away and saved by profiles with active push; selection does not consistently include `opens_at` or `last_cycle_closed_at`. The worker route currently reports automatic email disabled. | Cycle-based eligibility is missing; closed/status-conflicted routes can be reminder candidates based on date alone. Any future change needs tests and safe stop/rollback. |
| Cycle prediction | `lib/cycles.ts` uses `cycle_events`, distinct from `opens_at`. | Observed event history and predicted dates must not be confused; prediction must never instantiate a cycle or permit actionability. |
| Applications/saves | `public.applications` and saved tables relate by scholarship/opportunity IDs; they do not bind to a cycle ID. | Personal tracking cannot distinguish an application to one cycle from a later cycle if records are reused. Preserve legacy links during migration. |

`app/robots.ts`, `app/sitemap.ts`, public page routes, canonical/metadata utilities and route-specific query logic all affect indexability. Search engine indexing itself was not verified. A public page that is crawlable does not prove external scholarship facts.

## 4. Admin, discovery, security, and audit trail

Scholarship CRUD is through `app/api/admin/scholarships/route.ts` and `app/api/admin/scholarships/[id]/route.ts`; rule CRUD is under `app/api/admin/scholarships/[id]/rules/`. Admin guards are in `lib/admin/guard.ts`, with middleware in `middleware.ts`; `profiles.is_admin` and optional MFA configuration gate admin routes. Admins can set `verified` directly. `last_verified_at` is stamped/cleared with that boolean. This conflates editorial approval and source-check timestamp.

Discovery admin endpoints include `app/api/admin/discovery/route.ts`, `/claims`, and `/operations`; API-backed human candidate/claim review exists. Worker routes under `app/api/integrations/github/scholarship-*` use `CRON_SECRET` and service-role operations. GitHub schedules run verification/quality/eligibility at intervals; discovery ingestion is manual dispatch only. Automated research is advisory and candidate-scoped. A separate database RPC in `0066_require_current_freshness_for_publication.sql` publishes only reviewed/ready/current candidates with approved claim conditions, creates the scholarship with `verified=false`, and leaves final admin verification as a separate step.

Audit/trail limitations observed by source inspection:

- Claim and review state persistence is not always atomic at API level: claim update may commit before the review-event insert.
- Candidate approval/rejection status paths do not appear to append a complete event in all transitions.
- The publication RPC checks presence/status of nationality and level claims but does not fully validate claim values against normalized candidate attributes/eligibility report.
- `lib/admin/fix-log.ts` labels commits by message heuristic; it is not the authoritative per-record audit log.
- `cycle_events` is public-readable under its policy; do not repurpose it for private editorial evidence.
- Preserve private `research_notes`, candidate snapshots, claim excerpts, reviewer identity, and applicant information behind editor/service boundaries.

Live metadata shows RLS enabled on `scholarships`, `scholarship_rules`, saved items, cycle events, and discovery tables. Current relevant policies include verified/admin/retained-owner select on scholarships; public cycle-event read with admin writes; owner-only saved/application data; and admin-only discovery source/candidate/claim/snapshot/review-event access. A metadata query found four `resource_public_*` views only; no public scholarship/opportunity projection view was present. Therefore public catalogue projection is assembled by application queries against base tables. Live table metadata does not by itself establish column grants or prove every route safe; those need a dedicated ACL/API test before implementation.

## 5. Tests and operational compatibility

Tests include `lib/matching/engine.test.ts`, `lib/matching/discipline.test.ts`, `lib/public-application.test.ts`, `lib/public-pagination.test.ts`, `lib/sitemap-data.test.ts`, `lib/discovery/adapters.test.ts`, and `lib/discovery/safeFetch.test.ts`. CI in `.github/workflows/ci.yml` performs typecheck, `npm test`, and build. No focused route tests were found for the precise public/admin lifecycle filters, saves against changed visibility, cron/reminder inclusion, discovery decision/event atomicity, publication RPC gate, or candidate-to-catalogue claim/rule compilation. Read-only audit did not run tests or build.

Migration history contains many duplicate numeric prefixes (`0021`, `0062`, and others) and late timestamp-named migrations. `last_verified_at` appears in duplicate `IF NOT EXISTS` migrations with differing historical semantics. Repository order cannot safely be treated as actual production migration order. Compare live migration ledger and DDL in an approved implementation phase before any migration.

## 6. Proposed compatibility position

1. Keep current `scholarships`, `opportunities`, rules, saves, applications, and notifications operating unchanged while new structures are added.
2. Add the opportunity/cycle/source/capture/claim/constraint/route/funding/decision model additively and keep stable IDs via explicit one-to-one legacy mapping or existing UUID preservation.
3. Treat old date fields as a compatibility projection of one explicitly mapped cycle only after human/source review. Never infer a cycle from their values alone.
4. Retain `verified` as a legacy safety/public gate until all consumers are migrated; do not redefine it in place as `provider_authenticity` or `publication_disposition`.
5. Preserve all personal saves/applications and notification histories with the same stable opportunity/listing ID. New events/reminders reference a cycle; old rows remain interpretable.
6. Shadow-read new publication/match decisions against existing behavior before cutover; compare affected IDs and explain every difference.
7. Maintain private evidence and editorial notes outside public projection. Add negative access tests before introducing an evidence API or view.

## 7. Specific implementation facts to verify before any write

- Actual deployed migration ledger/order and DDL for all catalogue/discovery objects, especially `public.opportunities`.
- Exact table/column privileges in addition to RLS policies; whether anonymous public-page clients can select only intended fields under production grants.
- Runtime semantics and callers of `last_verified_at`, notification worker, `flag_expired_opportunities`, and scheduled jobs.
- Exact public API and SEO pages that will need a cycle-aware read adapter.
- Current record-level cycle/evidence mapping; do not use user profile/app rows for this mapping.
- Rollback and rebuild procedure for public catalogue query, match cache, and reminder dedupe.

No schema change or production data inspection beyond schema metadata was performed for this audit.
