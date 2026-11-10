# Scholars Phase 2 — Migration and Rollout Plan

**Date:** 2026-11-08
**Scope:** Proposed additive migration strategy; no SQL, code, or production change executed.
**Application revision audited:** `cf3682ce35912df7b9b9352193630fc404427c7c`.

## 1. Baseline and non-negotiable safeguards

The read-only Supabase metadata inventory for `scholarship-platform` reported 95 `public.scholarships`, 42 `public.opportunities`, 242 `public.scholarship_rules`, and 10 `public.cycle_events`. Phase 1.3.1 reconciles 17 named scholarship records; they are the first manual-review cohort, not the entire legacy catalogue. Do not select or copy student profile, application, or private research-note rows merely to design the migration.

No table, row, bucket, slug, UUID, source record, or personal tracking data is to be deleted. Do not alter the semantics of current fields during the additive phases. Never fabricate cycles or dates from annual recurrence. Keep the 17 audit outcomes and evidence dates exactly as reviewed; recheck only if a future authorized implementation is proposed.

Before DDL is considered, compare the actual deployed migration ledger, schema, grants, RLS policies, functions, and views to `ImperioKDB/Scholars/supabase/migrations`. The checkout contains duplicate numeric migration prefixes and lacks a base `CREATE TABLE public.opportunities` migration even though that table exists live. Do not blindly apply repository migrations or renumber history.

## 2. Proposed stages

### Stage 0 — Freeze baseline and design sign-off

**Changes:** none. Capture metadata and source commit references; record counts, object definitions, policies/grants, scheduled jobs, public routes, matching behavior, notification behavior, and current deployment revision in a reviewed baseline. Confirm the migration ledger through an approved read-only inspection. Approve naming, lifecycle state vocabulary, scope policy, freshness intervals, role matrix, and public behavior.

**Gate:** founder/editorial and engineering sign-off on the five Phase 2 documents, unresolved questions, and explicit security model. No production operation during this stage.

### Stage 1 — Additive schema foundation (future authorized phase)

**Proposed tables/entities:** `providers`, `opportunities`/stable opportunity identity only if the current `scholarships`/`opportunities` split can be mapped safely, `application_cycles`, `evidence_sources`, immutable `source_captures`, `evidence_claims`, `claim_evidence`, `eligibility_constraints`, `application_routes`, `funding_components`, `editorial_decisions`, and append-only `editorial_events`.

Avoid creating duplicate abstractions before a detailed ERD maps the current scholarship and opportunity identities. It may be safer to retain `scholarships` and `opportunities` as legacy/catalogue projections and add cycle/evidence entities keyed to their stable IDs first, then revisit unification after cross-catalogue requirements are approved.

All new tables should be additive, foreign-keyed, idempotently deployable with stable keys, and protected by RLS from first creation. Public clients should receive only an allowlisted projection of published opportunity/cycle/route fields. Editor-only evidence, snapshots, internal notes, sensitive excerpts, and reviewer data must never be reachable through a public query. Service-role access is restricted to worker endpoints; service secrets never enter the client.

**Gate:** static SQL review, RLS/grant matrix, migration dry run against a sanitized clone/snapshot, policy tests for anon/authenticated/admin/service roles, and rollback test before production DDL. DDL is not in scope here.

### Stage 2 — Backfill and explicit legacy mapping

Create a migration registry that maps each existing scholarship/opportunity UUID to its proposed enduring opportunity identity, and an optional exact cycle only when an editor can support the association from provider evidence. Preserve existing UUIDs where feasible, or use a reversible mapping table. Keep legacy records visible to their current consumers.

- Do not infer a current cycle from `deadline`, `opens_at`, `last_cycle_closed_at`, a future-looking stored date, or a typical annual pattern.
- Do not convert `last_verified_at` to “official source checked” unless an actual source URL, checked time, and claim scope are documented. Otherwise mark `not_checked` or carry the dated value as an unverified legacy observation with origin.
- Do not convert `verified=true` to `provider_authenticity=confirmed`; map it to a legacy publication/visibility observation pending review.
- Preserve existing `application_url`, `how_to_apply`, `level`, `discipline`, rules and private research notes in place until explicit claim-level mapping is approved.
- Migrate `cycle_events` only when event kind/date/source interpretation is clear; retain original rows and do not invent a cycle for the event.
- Do not turn `scholarship_discovery_candidate_claims` into published claims merely because candidate claim status is `confirmed`; require an explicit promotion/review event.

The Phase 1.3.1 17-record set requires manual disposition before an active-cycle mapping: ASUU, Bode Amao, Decagon, Ejiro, Florence, JG Afrika, KPMG, Lagos State, Light and Bells, PAU, Midwestern, MTN, NDDC, NNPC–Renaissance, NNPC/Seplat, Project 100, PTDF. Other legacy rows need a triage process; they are not automatically safe because they were previously verified.

### Stage 3 — Admin/editor workflow

Implement private editorial screens and API operations for provider, source capture, claim/evidence, cycle, route, constraints, funding and decision history. Require human approval for public disposition and material change. Candidate extraction and automated eligibility/quality tools remain advisory; proposals are reviewable and versioned. Every decision/event write must be atomic, with actor, time, before/after state, reason, and source references.

Add validation to prevent:

- a cycle deadline earlier than opening without explicit exception;
- a paid route from being rendered as a scholarship route;
- an unsupported or stale evidence state from passing publication;
- a confirmed claim with no linked qualifying source;
- a rule whose value cannot be mapped to a supported matcher field;
- deletion or mutation of historical source capture/decision events.

### Stage 4 — Shadow reads and compatibility adapters

Build read adapters that compute the proposed disposition and visibility without changing current outputs. Compare old versus new decisions for all 95 scholarships and 42 opportunities by public listing, match, detail, sitemap, saved item, and reminder. Emit private diff reports with counts and record identifiers. Do not inspect student-specific data to verify catalog state.

For matching, map approved cycle constraints to existing typed fields/rules where lossless. Keep unknown provider-specific conditions editorially visible, and do not let unsupported criteria become soft preferences by omission. Ensure match result names do not imply provider acceptance.

For public routes, separate active-cycle CTAs from historical details. New cycles need stable URLs/redirect rules; current stable slugs should not be broken. Do not expose unapproved internal states or source excerpts. Review canonical, Open Graph, sitemap, robots, cache/ISR behavior, and public projection allowlists.

For reminders, migrate from listing-level date logic to a deduplicated `(profile_id, cycle_id, channel, reminder_kind/date)` key. Stop dispatch for closed, cancelled, postponed, unresolved, stale, restricted, or route-unusable cycles. Test closure/extension state changes against already queued notifications. Do not send any live message until separately authorized.

**Gate:** all shadow differences classified; no unexpected catalogue visibility or matching regressions; no stale/closed/unresolved reminder candidate; migration rollback tested; client/server typechecks and database integration tests pass.

### Stage 5 — Controlled rollout

Use feature flags/allowlisted cohort to read new data for a small reviewed set. Keep legacy read path available. Initially enable the new editorial workflow but retain existing public API behavior until sign-off. Then move public listing/detail, matching, sitemap, saves and reminders in separate monitored increments. Each increment has an owner, success metrics, audit log, and rollback trigger. Do not do a single large cutover.

**Rollback:** disable new reads/writes via flag and return to legacy adapters. Because initial changes are additive, do not drop new tables/data during rollback. Reconcile any new editorial events before re-enabling. Preserve already-recorded saved/application histories. If any public copy or reminders were wrong, disable the surface/job immediately, stop future notifications, and prepare a truthful correction through normal editorial approval.

### Stage 6 — Deprecation (separate approval only)

Only after all consumers are mapped, every record has a reviewed legacy projection, and rollback windows expire may the team propose deprecating old lifecycle fields, `verified`, or free-text fallbacks. That requires a separate impact assessment and explicit founder approval. This document does not authorize removal, column rename, data deletion, or contract change.

## 3. Compatibility and validation matrix

| Area | Additive design | Migration risk | Required validation |
|---|---|---|---|
| Catalogue identity | Preserve UUIDs; mapping registry first | Duplicating or merging scholarship/opportunity identities | Collision report; no losing IDs; dual-read consistency. |
| Cycles/dates | New cycle table; legacy fields remain untouched | Mistaking old/future date for announced cycle; timezone loss | Human evidence mapping, source/precision, compare date-derived display. |
| Evidence | Immutable captures and linked claims | Public leakage of private notes/excerpts; false freshness | RLS/grants tests, public projection allowlist, freshness transition tests. |
| Eligibility | Typed constraints mapped to existing rule engine | Unsupported rule becomes match pass; missing profile data over-scored | Shadow matcher comparison; unit/property tests for unknowns and hard gates. |
| Route | Multiple routes and distinct acceptance status | External route lost/unsafe redirect; false open state | URL validation and route rendering tests; zero auto-submission. |
| Editorial state | Separate reviewed disposition | Existing `verified` still leaks as actionable | Public/API test matrix confirms all gates; atomic audit events. |
| Saves/applications | Link legacy records to stable identity plus cycle later | Personal history orphaned or mapped to wrong cycle | FK/backfill checks, user-owned data integrity, no unrelated row read. |
| Reminders | Cycle-based eligibility and dedupe | Duplicate, stale, already-closed reminder dispatch | Dry-run recipient counts, controlled fake clock, closure/extension tests; no live send in migration. |
| Public SEO | Cycle-aware public pages and sitemap rules | De-indexing useful history or indexing wrong cycle | Snapshot tests for canonical/noindex/sitemap and routes; crawler fetch check separately. |
| RLS/API | New tables private by default; explicit safe view | New tables default exposed or service role overused | Grants/RLS negative tests for anon and ordinary authenticated users. |

## 4. Data triage and acceptance criteria

For each record, the audit packet should specify exact legacy UUID, proposed enduring opportunity and cycle IDs, source captures, claims/constraints, route, funding category, current seven dimensions, decision owner, and outstanding questions. Evidence may be carried forward only with an explicit `carried_forward` label and original date. No absent value is reconstructed from URL shape or historical notes alone.

Before any cohort is enabled, require:

- zero unreviewed differences that could alter student eligibility, current status, date, funding, route, reminders, or public claims;
- all material claims with evidence links and review timestamps;
- every public-actionable cycle approved by a human and passing policy gates;
- tests for boundary dates, conflicting sources, route failure, stale evidence, change/extension, and cancelled cycle;
- successful verification that unauthenticated/public users cannot retrieve editor-only evidence or student-private data;
- verified rollback to the legacy behavior without loss of cycle/evidence history.

## 5. No action taken

This plan is design-only. No DDL, migration, table, row, policy, function, trigger, application code, deployment, provider contact, application submission, or notification send was performed. It proposes no destructive operation.
