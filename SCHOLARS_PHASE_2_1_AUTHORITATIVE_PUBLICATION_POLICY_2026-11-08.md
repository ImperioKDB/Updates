# Scholars Phase 2.1 — Authoritative Publication Policy and Gates

**Status:** Proposed policy; founder/editorial approvals A-01 through A-12 are pending.
**Controlling evidence:** Phase 1.3.1 clarification addendum and its 17-record matrix.
**Scope:** Exact-cycle publication, actionable matching, student-facing status, routes, saves, reminders, public pages, and indexability.

## 1. Non-negotiable policy principles

1. **One exact cycle at a time.** An enduring opportunity (provider/programme) and a provider-announced cycle are different records. No annual recurrence, new intake, date, deadline, or “open” state is inferred from a prior year, a stored date, or a prediction.
2. **Seven dimensions stay independent.** Store and evaluate provider authenticity, audience eligibility, academic-level fit, application status, application-route status, evidence freshness, and publication disposition separately. The original A–E audit remains traceability, not an operational status field.
3. **Provider evidence and editorial judgment are different.** Automated extraction, URL reachability, a database `verified` boolean, or a match score cannot approve a record.
4. **Unknown is not eligible, open, closed, free, or fully funded.** For any material claim, unknown/conflicting/stale/unsupported fails closed for actionability. Preserve the factual state as unknown/conflicting; do not convert it to “closed” to make the UI simpler.
5. **A passed gate is not a successful application.** The app may state that a provider presents a cycle as open and points to a route. It must not claim that a student’s submission will succeed unless that was actually established—and Scholars must not submit applications to test it.
6. **All surfaces consume one decision.** Browse, matching, detail, related items, public APIs, saved-state writes, reminders, notification workers, public SEO pages, and sitemap generation must use the same policy output and policy version. A per-route copy of the lifecycle predicate is prohibited.

## 2. Separate fact states from the publication outcome

### 2.1 Seven editorial dimensions

The values below retain the Phase 1.3.1 seven-dimension model, with the mandatory Phase 2.1 scope/lifecycle correction and generic freshness vocabulary. They remain evidence-backed facts or human classifications; the publication function must not collapse them into one `verified` field.

| Dimension | States used in this design | Decision question |
|---|---|---|
| `provider_authenticity` | `confirmed`, `partially_confirmed`, `unresolved`, `not_established` | Is the exact provider/programme relationship supported? |
| `audience_eligibility` | `confirmed_nigerian`, `restricted_nigerian`, `unresolved_nigerian`, `non_nigerian_or_out_of_scope`, `mixed_or_not_applicable` | Does the intended beneficiary cohort fit the selected catalogue scope, and are material restrictions known? |
| `academic_level_fit` | `undergraduate_confirmed`, `undergraduate_restricted`, `mixed_levels`, `postgraduate_only`, `secondary_or_entry_stage`, `unresolved` | Does this exact route/cycle fit the undergraduate catalogue and applicant stage? |
| `application_status` | `open_publicly_presented`, `closed_or_historical`, `unresolved`, `conflicting` | What does authoritative evidence say about the exact cycle? |
| `application_route_status` | `provider_route_verified`, `provider_route_reachable_acceptance_unconfirmed`, `branch_or_restricted_route`, `conflicting_provider_instructions`, `closed_provider_route`, `generic_or_non_programme_route`, `source_unavailable_or_integrity_unresolved`, `paid_route_distinct`, `no_current_route_verified` | Is there a programme-specific, authentic, usable student next step, and what does the route prove about acceptance? |
| `evidence_freshness` | `fresh_provider_recheck`, `carried_forward`, `mixed_freshness`, `stale`, `not_checked` | When and how was each material claim last supported? |
| `publication_disposition` | `actionable_open_candidate`, `restricted_lead_not_actionable`, `manual_review_withhold`, `exclude_initial_nigerian_undergraduate_catalogue`, `historical_archive_only` | What may this product scope publish after review? |

**Required Phase 2.1 correction:** catalogue scope is not an application lifecycle state. Retire the scope-coded `not_currently_actionable_due_scope` value from `application_status`. Represent scope through `audience_eligibility`, `academic_level_fit`, the selected catalogue-scope key, and `publication_disposition`/output category. Thus an authentic NDDC postgraduate call may have its own genuinely open source status while being `excluded` from the initial Nigerian-undergraduate catalogue; the supplied NDDC evidence here records status as `unresolved` because live acceptance was not established. JG Afrika may be publicly presented as open while excluded from this catalogue because Nigerian eligibility is unresolved. Neither case should have its cycle status rewritten to match catalogue visibility.

Freshness uses the five generic states above. Phase-specific recheck labels, source-check scope, production snapshot time, publication date, and exact timestamps belong in separate provenance fields; they are not additional freshness enum values. A fresh reconciliation does not refresh a claim that was not reopened.

A fresh source check refreshes only claims actually reopened. The production snapshot timestamp, source publication date, source-check date, audience assessment date, application-status assessment date, and editorial-decision timestamp remain distinct.

### 2.2 Required output category for every cycle/scope evaluation

`decision_category` is a derived policy output, not a substitute for the seven input dimensions:

| Output | Meaning | Default surface capability |
|---|---|---|
| `actionable` | All exact-cycle, source, route, scope, freshness, and human-approval gates pass now. A known restricted cohort may still be actionable for a student who satisfies every confirmed restriction. | Public listing and actionable match candidate; apply CTA; actionable save; reminders only with user consent and an allowed cycle-bound trigger; indexability only if separately permitted. |
| `upcoming` | Exact future cycle and future opening are provider-confirmed, but it is not open now. | Optional public future listing; no actionable matching, apply-now CTA, actionable save, or open-cycle reminder. A separately approved watchlist may be offered. |
| `restricted_non_actionable` | Opportunity is a potentially relevant restricted lead, but at least one actionability gate is unresolved or policy does not permit an active listing. | Editor-only by default pending A-02. If A-02 is approved, warning-only lead treatment; no match, active CTA, actionable save, reminder, or sitemap by default. |
| `manual_review` | A material claim is missing, stale, conflicting, unsupported, or unsafe to resolve automatically. | Withhold from student-facing actionable surfaces; no CTA, match, actionable save, reminders, or indexability. Preserve a review task and evidence trail. |
| `historical` | The exact cycle is evidenced as ended/closed, or its announced application window is conclusively past under the approved archive rule. | Optional dated archive only if A-06 approves; no match, apply CTA, active save, or reminder. Never imply recurrence. |
| `excluded` | The opportunity is outside the requested catalogue scope, is a distinct fee-paying product where a scholarship is requested, or fails a non-remediable scope gate. | Not listed/matched/indexed in this scope. Preserve source and personal history; a future separate scope may re-evaluate it. |

Priority rule: material conflict/staleness routes to `manual_review`; a confirmed out-of-scope academic/audience route is `excluded` for this scope; a documented closed exact cycle is `historical`; an unresolved restricted lead is `restricted_non_actionable`; otherwise evaluate `upcoming` or `actionable`. A known, precisely expressed restriction alone does **not** force `restricted_non_actionable`: an eligible student may match an otherwise fully approved cycle if the machine-supported constraint is confirmed and satisfied.

### 2.3 Capability envelope

The authoritative function returns one envelope for the exact cycle and catalogue scope:

```ts
export type PublicationDecisionCategory =
  | "actionable"
  | "upcoming"
  | "restricted_non_actionable"
  | "manual_review"
  | "historical"
  | "excluded";

export type PublicationDecision = {
  category: PublicationDecisionCategory;
  policyVersion: string;
  catalogueScope: string;
  cycleId: string | null;
  evaluatedAt: string;
  inputsRevision: string;
  reasonCodes: string[]; // allowlisted codes; no private excerpts or applicant data
  capabilities: {
    publicListing: boolean;
    actionableMatchCandidate: boolean;
    applyCta: boolean;
    saveAsActionable: boolean;
    saveAsUpcomingWatch: boolean;
    sendReminder: boolean;
    indexable: boolean;
  };
  nextReviewAt: string | null;
};
```

`actionableMatchCandidate` means only that the cycle may enter the existing profile-specific matching pipeline. It does not itself say a student is eligible. The matching engine still evaluates known supported constraints; unknown hard requirements must not be counted as a positive match. Unsupported material rules block actionable matching pending explicit resolution.

## 2.4 Stable reason-code contract

Return one or more stable, machine-readable reason codes. Codes explain which gate determined the result; they are not user-visible prose and must never embed private excerpts, names, credentials, or reviewer commentary. Keep student-safe explanation strings in a separate allowlisted localization layer.

| Reason code | Meaning |
|---|---|
| `NO_EXACT_PROVIDER_CYCLE` | No authoritative exact cycle identity exists. |
| `PROVIDER_AUTHENTICITY_UNRESOLVED` | Provider/programme relationship is not adequately established. |
| `CATALOGUE_SCOPE_EXCLUDED` | Confirmed audience or academic level is outside this catalogue scope. |
| `MATERIAL_ELIGIBILITY_UNKNOWN` | A material eligibility rule is missing, unsupported, or unverified. |
| `CYCLE_NOT_YET_OPEN` | Exact future cycle is confirmed but opening has not been reached. |
| `CURRENT_STATUS_UNRESOLVED` | Current provider acceptance/open state is not evidenced. |
| `CURRENT_STATUS_CONFLICTING` | Material current-cycle sources disagree. |
| `PUBLISHED_DEADLINE_PASSED_UNCONFIRMED` | Published deadline elapsed without adequate closure/extension recheck. |
| `EXACT_CYCLE_CONFIRMED_CLOSED` | Provider evidence closes the exact cycle. |
| `ROUTE_PROVENANCE_UNRESOLVED` | The route is not provider-owned or provider-linked for this cycle. |
| `ROUTE_NOT_PROGRAMME_SPECIFIC` | Only a generic portal/page is known. |
| `ROUTE_ACCESS_CHALLENGED` | Login, 401/403, CAPTCHA, timeout, or similar prevents current route verification. |
| `ROUTE_ACCEPTANCE_UNCONFIRMED` | Route identity/reachability is known but acceptance evidence is not. |
| `ROUTE_INSTRUCTIONS_CONFLICTING` | Official route/destination/instructions materially conflict. |
| `MATERIAL_EVIDENCE_STALE` | One or more material claims expired under the approved freshness policy. |
| `FUNDING_OR_FEE_CLAIM_UNRESOLVED` | A material benefit, coverage, or fee claim is unknown or conflicting. |
| `HUMAN_APPROVAL_REQUIRED` | Required reviewer/approver disposition is missing, expired, or invalidated. |
| `REVIEW_INPUTS_CHANGED` | Evidence/input revision changed after review; approval must be repeated. |
| `RESTRICTED_LEAD_ONLY` | A-02-controlled lead treatment; never implies active application. |
| `HISTORICAL_CYCLE_ONLY` | Exact cycle is historical and has no active capabilities. |
| `EVIDENCE_REMOVED_REASSESS` | Required support was removed; dependent claims and decision need review. |

The reason-code set is versioned with the evaluator. Multiple codes may be returned; category precedence remains deterministic and is not left to each consuming surface.

## 3. Single authoritative function and data-access boundary

### 3.1 Proposed function contract

Implement exactly one server-only policy function, `evaluateCyclePublicationDecision(snapshot, scope, asOf, policyVersion)`, in a shared catalogue policy module. It must be pure/deterministic: no hidden database calls, time reads, network calls, email/push side effects, user-supplied overrides, or route-specific flags. The caller supplies one consistent, versioned snapshot of the exact cycle’s decision inputs and the as-of time.

A trusted server data loader obtains the snapshot in one database-consistent operation (prefer a tightly scoped internal RPC/read transaction over several unrelated PostgREST requests). Public clients never call the evaluator with arbitrary claims or dates. The loader and evaluator are server-only; only an allowlisted capability envelope and safe catalogue projection are returned to browsers.

All existing runtime consumers and jobs call one shared facade that invokes this evaluator. A different runtime must call the shared service or a stable package that contains this function; it must not reimplement the logic. The evaluator owns the final booleans for listing, matching-candidate inclusion, CTA, actionable save, reminder, and indexability. Route components may not recompute those gates locally.

### 3.2 Source-of-truth and access caveat

Use `lib/catalogue/publication-policy.ts` (proposed path) as the single decision implementation and a private, versioned input snapshot as its data contract. A public projection should be a serializer over the decision envelope, not a second policy engine. Do not grant browser roles access to evidence captures or the internal reason detail merely to run the evaluator.

This architecture is **not safe to ship** until the production ACL findings in the Readiness Assessment are separately reviewed and the public/private data boundary is proven. RLS policy presence is not a substitute for narrow table privileges; PostgreSQL `TRUNCATE` is not row-filtered by RLS. This document does not authorize a permission change or a destructive permission test.

### 3.3 Deterministic gate order

1. Resolve a valid, stable catalogue item and exact provider-announced `cycle_id`; no cycle means no actionable decision.
2. Confirm exact opportunity identity and provider authenticity from current or still-valid evidence.
3. Apply the requested immutable catalogue-scope policy revision (v1 = Nigerian undergraduate). Determine whether the exact audience/level is in scope, restricted, unresolved, or excluded.
4. Validate cycle lifecycle and date semantics. Future confirmed opening → `upcoming`; explicit closure → `historical`; stale/unknown/contradictory current status → `manual_review`. A past date with no current status is non-actionable and sent to review; it is not silently converted to provider-confirmed closure.
5. Resolve route provenance, route type, current-cycle link, accessibility state, provider open/acceptance signal, and all material instruction conflicts. Route reachability alone cannot pass this gate.
6. Confirm all material audience, academic, deadline, route, and funding claims are supported by evidence within their approved freshness interval. Any material unknown, conflict, or stale claim blocks actionability.
7. Require the required human editorial disposition for the same scope and cycle, current policy version, no self-approval, and no unresolved review hold.
8. Compute the category and capability envelope. Apply `publicListing`, `actionableMatchCandidate`, `applyCta`, `saveAsActionable`, `sendReminder`, and `indexable` only from this result.
9. Calculate `nextReviewAt` as the earliest of evidence expiry, route/status check due, expected opening/deadline recheck, and policy-defined review date.

## 4. Conjunctive actionable gate

A cycle is `actionable` only if every condition below is true at evaluation time:

- The exact provider and opportunity are `confirmed`, with a source-backed identity relationship.
- The cycle is a real provider-announced instance, not an extrapolated year or predicted window.
- The selected catalogue scope is explicit. For v1, Nigerian audience and undergraduate stage are established; any branch/state/host-community/gender/course/year restriction is known and presented. For a profile match, the student satisfies all confirmed hard constraints.
- Provider evidence currently presents that exact cycle as open or gives an equivalent authoritative current acceptance signal. `application_status` is not `unresolved`, `conflicting`, closed, or merely inferred from a date.
- A programme-specific route is authenticated, linked to the exact cycle, safe to render, and supported by route-specific evidence; route instructions do not materially conflict.
- Route/acceptance evidence reaches the A-03 standard in the route matrix. A page’s HTTP status, login form, CAPTCHA, open-looking button, or third-party index label alone is insufficient.
- All material claims used to describe eligibility, dates, route, benefit, and fees are source-linked, not stale, and have acceptable freshness. Source freshness does not imply content publication recency.
- A human reviewer has approved the same cycle/scope after reviewing material supporting and contradicting sources. Automation scores are advisory only.
- The legacy listing is not otherwise excluded by the backward-compatibility gate during shadow migration.

Unknowns in non-material editorial copy may be disclosed without necessarily blocking actionability, but unknown **material eligibility, route, current status, fee, or benefit** facts fail closed. The editor must record materiality by claim; it cannot be downgraded solely to pass the gate.

## 5. Surface contract — one decision everywhere

| Consumer | Permitted behavior from decision envelope | Explicit prohibition |
|---|---|---|
| Browse/catalogue APIs | Return only a safe projection where `publicListing=true`; show exact cycle label/state and applicable restriction. | Do not duplicate `verified`, deadline, or `opens_at` predicates in a route to override the evaluator. |
| Profile matching (`lib/matching/getMatches.ts`, `lib/matching/engine.ts`) | Candidate set includes only `actionableMatchCandidate=true`; then run existing supported profile constraints. | A predicted cycle, `verified=true`, soft score, or missing profile data cannot turn a cycle actionable. |
| Public detail routes (`app/scholarship/[slug]/page.tsx`, `app/opportunity/[slug]/page.tsx`) | Show only the authorized safe page state; render an apply CTA only when `applyCta=true`. | Do not expose `research_notes`, evidence excerpts, internal reason text, private snapshots, or an old application URL as current. |
| Related/similar results | Filter through the same public-listing and candidate capabilities before similarity/ranking. | No weaker predicate than browse or detail. |
| Save writes | New “save as actionable” requires `saveAsActionable=true` at write time. Optional future watchlist is separate and requires its own approved capability. Preserve existing saved rows. | Do not delete a saved item or relabel a historic save as an application to a new cycle. |
| Reminder selection/dispatch | Worker re-evaluates immediately before enqueue and before send; require `sendReminder=true`, exact `cycle_id`, valid user preference/consent, and idempotent cycle-bound key. | No reminders from listing-level deadline alone, old saved state, or future prediction. |
| Public SEO and sitemap | Include only `publicListing=true && indexable=true`; revalidate pages/canonical/sitemap when decision or cycle changes. | Noindex manual-review, unresolved, excluded, or unapproved restricted/historical records. Do not redirect a closed cycle to a guessed new one. |
| Admin/editor APIs | Show complete private evidence, reason codes, approvals, and audit history only to authorized editorial roles. All writes append an atomic event. | A public-facing code path cannot elevate its own decision. |

Relevant existing paths include `app/api/scholarships/route.ts`, `app/api/opportunities/route.ts`, scholarship/opportunity detail APIs/pages, `app/api/cron/deadline-check/route.ts`, `lib/push/campaigns.ts`, `lib/sitemap-data.ts`, `app/sitemap.ts`, and `app/robots.ts`. The complete route-by-route migration map is in the Technical Specification.

## 6. End-to-end editorial workflow

1. **Discover:** create a private candidate only. Record first-seen URL, reason for intake, source type, and suspected opportunity identity. No public row or `verified=true` write.
2. **Deduplicate and scope:** determine whether it is a new provider, enduring opportunity, exact route variant, cycle, or duplicate; set catalogue scope(s) for review. A similarly named paid programme or institutional branch is not merged by name.
3. **Capture safely:** open official/authoritative sources and exact linked routes using approved safe-fetch controls. Record check time, final URL/redirect chain, source publication date if stated, access limits, response/content hash, and only necessary excerpt. Never submit a form or bypass access control.
4. **Extract atomic claims:** create separate claims for authenticity, audience, academic level, current cycle/open state, dates, route provenance/acceptance, fees, funding components, and eligibility. Link every claim to one or more captures with `supports`, `contradicts`, `limits`, or `context_only`. Preserve contradictions; do not overwrite an older claim.
5. **Normalize cycle:** create a cycle only when an authoritative source identifies it. Store date precision/time zone as stated and date semantic (`opens`, `deadline`, `notification`, `award`, `closure`, `postponement`). Never shift a previous-year date or treat a notification date as a deadline.
6. **Automated quality checks:** validate URL/redirect safety, cycle consistency, claim-source links, freshness, controlled vocabularies, duplicate candidates, field conflicts, required reviewer. Record machine findings separately; no automatic publication.
7. **Human review:** an editor reviews primary and contradicting evidence, marks materiality, confirms the seven dimensions, and either approves, restricts, holds, excludes, or archives the exact cycle and scope. Apply the A-05 independent approver rule when approved.
8. **Atomic decision/event write:** version the decision and append its event in the same transaction. Store actor, reviewer/approver, timestamp, policy version, input revision, previous decision reference, reason codes, evidence IDs, and next-review deadline. No deletion of losing evidence.
9. **Evaluate and publish:** call the central function for the approved cycle and scope; return only the safe projection. Public prose identifies the exact cycle, restriction, current status, route, and check date without claiming that submission was tested.
10. **Operate and revalidate:** queue reviews before `nextReviewAt`; re-fetch the official source/route safely; detect changes; refresh only claims actually checked; re-evaluate and invalidate caches. Staleness moves the decision out of actionable status, not automatically into “closed.”
11. **Handle events:** explicit extension, cancellation, postponement, reopening, route change, fee change, or eligibility change creates a new capture/claim and append-only event, then reviewer approval and fresh evaluation. Recalculate reminders idempotently; preserve the earlier claim and decision.
12. **Create a new cycle:** only after provider evidence; keep the older cycle immutable/historical; copy no dates/requirements/route/benefit without revalidation.

## 7. Lifecycle transition rules

| Event or evidence | Fact treatment | Decision treatment |
|---|---|---|
| Provider confirms exact future cycle and opening date | Record cycle, opening-date claim, source, precision/timezone. | `upcoming`; no actionable match/CTA/reminder. Re-evaluate at opening only after fresh open-status and route evidence. |
| Official source presents exact cycle open and all gates pass | Record `open_publicly_presented`; route acceptance evidence separately. | `actionable` after human approval and freshness pass. |
| Stored opening/deadline passes, no source recheck/closure | Keep last claim and its age; do not state provider closed. | Non-actionable `manual_review` (or approved warning-only lead treatment); stop CTA, actionable match, and reminders. |
| Provider or form explicitly closes exact cycle | Record closure claim with source and time; do not overwrite original dates. | `historical`; stop active surfaces. |
| Provider sources materially disagree | Preserve both claims and captures; set `conflicting`. | `manual_review`, no CTA/match/save/reminder/indexing. |
| Source becomes 403/login/CAPTCHA/integrity anomaly | Record access outcome, not open/closed status. | Reuse only still-fresh prior claims if A-04 permits; no active CTA without corroborating route evidence; otherwise `manual_review`. |
| Provider publishes extension/reopening | New claim, source capture, cycle event, and human approval; keep previous deadline/state. | Re-evaluate; only then update CTA/reminder schedule. |
| Freshness interval expires | Retain original fact and source trail; mark the claim stale for current use. | Remove actionable capabilities and open a review item; do not auto-close. |
| Opportunity is outside this catalogue (e.g. postgraduate-only) | Preserve authentic source/cycle facts. | `excluded` for this scope; another approved scope may evaluate separately. |

## 8. Policy-test invariants

Every implementation must prove these properties with deterministic tests:

- `applyCta`, `actionableMatchCandidate`, `saveAsActionable`, and `sendReminder` can never be true unless `category=actionable`.
- No `actionable` output with unconfirmed authenticity, material audience/level unknown, cycle/status conflict, unacceptable route, material stale evidence, missing human approval, or wrong policy scope.
- `upcoming`, `historical`, `manual_review`, `restricted_non_actionable`, and `excluded` never permit apply-now, active match, or current-cycle reminder.
- Profile eligibility is evaluated after—not instead of—the catalogue publication gate.
- A route returning HTTP 200, a login page, a CAPTCHA, or an unlinked aggregator label cannot alone produce `actionable`.
- Date comparison uses source-native semantics/time zone; notification dates never become deadlines.
- Every evaluator response is reproducible from its `inputsRevision`, `policyVersion`, `scope`, and `evaluatedAt`.
- A policy change invalidates decision caches and triggers regression/shadow comparison before it can widen student access.

## 9. Related documents

- [Governance decision refinement](SCHOLARS_PHASE_2_1_GOVERNANCE_DECISION_REFINEMENT_2026-11-08.md)
- [Application-route acceptance matrix and freshness standard](SCHOLARS_PHASE_2_1_ROUTE_ACCEPTANCE_AND_EVIDENCE_FRESHNESS_POLICY_2026-11-08.md)
- [Evidence retention and security policy](SCHOLARS_PHASE_2_1_EVIDENCE_RETENTION_AND_SECURITY_POLICY_2026-11-08.md)
- [Technical specification](SCHOLARS_PHASE_2_1_TECHNICAL_SPECIFICATION_AND_FINAL_ERD_2026-11-08.md)
- [Readiness assessment](SCHOLARS_PHASE_2_1_IMPLEMENTATION_READINESS_ASSESSMENT_2026-11-08.md)
