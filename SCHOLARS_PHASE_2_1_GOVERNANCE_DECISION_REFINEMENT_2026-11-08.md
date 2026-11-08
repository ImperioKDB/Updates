# Scholars Phase 2.1 — Governance Decision Refinement

**Date:** 2026-11-08
**Application revision inspected:** `ImperioKDB/Scholars` `main` at `cf3682ce35912df7b9b9352193630fc404427c7c`
**Authority:** Phase 1.3.1 clarification addendum controls the 17-record classifications.
**Phase 2 reference commit:** `ImperioKDB/Updates` `187209aa0bca66ef8eb373657fc7534912e02887`.
**Status:** Design recommendations only. Every A-01–A-12 decision below remains **pending explicit founder/editorial approval**. No approval is implied by this document.

This register resolves the choices into an implementation-ready recommendation set while preserving the authority boundary: facts and prior editorial classifications are inputs; policy choices below are recommendations, not approvals or permission to change production.

## 1. Approval summary

The following are recommendations, not approved policy. Every strategy-dependent row is explicitly `FOUNDER_DECISION_REQUIRED` until the founder records an approval or deferral.

| ID | Student-facing consequence | Engineering consequence | Recommended default | Approval |
|---|---|---|---|---|
| A-01 | Nigerian undergraduates see a clearly scoped catalogue; postgraduate/international records are not silently mixed in. | Scope becomes an explicit versioned policy/filter and future scopes need separate gates. | Keep v1 Nigerian undergraduate; separate later scopes. | `FOUNDER_DECISION_REQUIRED` — pending |
| A-02 | Uncertain/restricted leads do not look like endorsed open offers. | Requires separate editor-only and public projection states; no ordinary browse/match/SEO inclusion. | Editor-only until a labelled lead surface is approved. | `FOUNDER_DECISION_REQUIRED` — pending |
| A-03 | Students see “provider presents as open” only when exact-cycle evidence and a supported route exist; no false submission guarantee. | One central evaluator consumes route provenance, acceptance evidence, cycle facts, freshness, and human approval. | Exact-cycle provider-open evidence plus programme-specific route; never test-submit. | `FOUNDER_DECISION_REQUIRED` — pending |
| A-04 | Stale listings stop acting current but are not falsely called closed. | Add configurable freshness policy, `next_review_at`, review queue, and cache/reminder invalidation. | Risk-tiered intervals; stale means non-actionable and review. | `FOUNDER_DECISION_REQUIRED` — pending |
| A-05 | High-impact/conflicting facts receive independent scrutiny. | Add reviewer/approver roles, no-self-approval checks, and atomic audit events. | One reviewer routine; independent second approval for high-risk decisions. | `FOUNDER_DECISION_REQUIRED` — pending |
| A-06 | Search results distinguish archives from current offers and suppress unresolved pages. | Central indexability output controls metadata, canonical pages, sitemap, and revalidation. | Noindex unresolved/manual/restricted by default; selected historical archives only. | `FOUNDER_DECISION_REQUIRED` — pending |
| A-07 | A student can distinguish a scholarship from a fee-paying programme or training offer. | Add controlled nature, fee, funding, and route dimensions while preserving legacy enums. | Separate taxonomy dimensions; no paid-programme-as-scholarship label. | `FOUNDER_DECISION_REQUIRED` — pending |
| A-08 | Students are not told an award covers costs that have not been confirmed. | Model benefit components and evidence state; gate “fully funded” copy by current-cycle claims. | Component-level coverage; unknown never means full. | `FOUNDER_DECISION_REQUIRED` — pending |
| A-09 | Existing verified listings retain their behavior until a deliberate transition. | Keep legacy and new gates in shadow; prohibit semantic reuse of `verified`. | Preserve current meaning until every consumer is migrated and tested. | `FOUNDER_DECISION_REQUIRED` — pending |
| A-10 | Past saves/applications remain attached to what the student actually did, not a guessed year. | Add nullable cycle references and stable ID mapping; leave legacy cycle unresolved. | Preserve IDs/history; map only with exact evidence. | `FOUNDER_DECISION_REQUIRED` — pending |
| A-11 | Scholarship and other programme types retain their appropriate filters and labels. | Add a constrained shared identity/cycle layer rather than merging existing tables. | Keep both legacy catalogues; defer full convergence. | `FOUNDER_DECISION_REQUIRED` — pending |
| A-12 | Students can see when a specific source was checked and what that check does—and does not—mean. | Store check/published/snapshot/decision timestamps independently; use an allowlisted public serializer. | Claim-specific attribution; retire universal “verified” implication. | `FOUNDER_DECISION_REQUIRED` — pending |


## 2. A-01–A-12 decision cards

### A-01 — Public catalogue scope beyond Nigerian undergraduates

**Options.** Keep one Nigerian-undergraduate catalogue; create separately scoped catalogues (postgraduate, international, entry-stage, or other); or build one broad catalogue with visible audience filters.

**Recommendation.** Keep the initial public scope limited to Nigerian undergraduate applicants. A later postgraduate or international surface should be a separately named scope with its own eligibility rules, routes, and SEO treatment—not a relaxation of the undergraduate predicate.

**Consequence.** JG Afrika remains excluded from this scope because Nigerian citizenship and university-location eligibility are unresolved; the NDDC 2026/27 master’s call remains excluded because it is postgraduate-only. Neither disposition says that the underlying opportunity is illegitimate or closed.

**Approval:** Pending founder approval.

### A-02 — Whether restricted leads appear publicly

**Options.** Keep all restricted/uncertain leads editor-only; show a separate student-visible “restricted / not confirmed actionable” area; or show them in the ordinary browse feed with warnings.

**Recommendation.** Do not expose restricted leads in the ordinary browse, match, reminder, or sitemap paths. Keep them in the editor queue until a separately approved public lead surface exists. If approved later, that surface must distinguish known restrictions from unknown eligibility, disclose material uncertainty above the route, and provide no apply-now CTA, actionable match, actionable save, or deadline reminder.

**Consequence.** This is more conservative than a prominent lead catalogue and may reduce discovery, but avoids accidental endorsement while route or lifecycle facts remain unresolved. The Phase 1.3.1 B classification is not public/actionable approval.

**Approval:** Pending founder approval. Until then, editor-only is the default.

### A-03 — Meaning of “actionable/open” and route usability

**Options.** Treat an official open notice plus a linked route as sufficient; require an additional explicit form-acceptance signal; or require a successful test submission.

**Recommendation.** Do not require or perform a test submission. Require (1) an exact provider-announced cycle, (2) a current official statement presenting that cycle as open or an equivalent provider acceptance signal, (3) a programme-specific route with documented provenance, (4) no unresolved material route conflict, and (5) current route-specific evidence. Record the result as “provider presents this cycle as open; submission was not tested.” HTTP 200, a login screen, an unexpired form, or a third-party label alone does not meet the bar. A login-protected route may qualify only when the official current-cycle instructions identify that exact route and direct applicants to use it.

**Consequence.** The policy can support an honest application path without impersonating a student, bypassing CAPTCHA, or claiming end-to-end submission success. Inaccessible or conflicting routes fail closed to manual review unless a provider-authenticated alternative route resolves the issue.

**Approval:** Pending founder/editorial approval. See the route matrix and central policy contract.

### A-04 — Freshness intervals and stale-state response

**Options.** One universal expiry date; risk-tiered intervals; or manual rechecks only.

**Recommendation.** Adopt configurable risk-tiered maximum ages (provider identity 365 days; cycle-specific eligibility and benefit claims 90 days; current-open claim 7 days, tightened to 24 hours within 72 hours of the deadline; route provenance 30 days, route acceptance/open signal 7 days, tightened to 24 hours within 72 hours of deadline). A new cycle invalidates cycle-specific claims unless revalidated. These are proposed defaults, not approved service levels.

**Consequence.** Expiration makes the decision non-actionable and schedules review; it does not rewrite a source claim to “closed.” An elapsed deadline without authoritative closure is not evidence that the provider marked the programme closed; it blocks action and routes the record to review.

**Approval:** Pending editorial approval, including staffing/SLA.

### A-05 — Required reviewer roles

**Options.** Any admin can approve; one trained reviewer per record; independent dual review for selected claim types; or founder-only approval for all publication.

**Recommendation.** One trained editor may approve routine records after all evidence is complete. A second independent reviewer must approve material conflicts, audience/scope exceptions, eligibility interpretations with high student impact, fee/coverage claims, exceptions to freshness, and any reactivation after a closed/conflicting/stale state. The author of a change cannot be its sole approver. Automation may recommend but never approve.

**Consequence.** This provides separation of duties for high-impact decisions without forcing two-person review for every routine refresh; it adds reviewer workload. Exact role names and escalation path remain to be agreed.

**Approval:** Pending founder approval.

### A-06 — Indexing historical and unresolved pages

**Options.** Index all archives; noindex all non-actionable content; or index only selected, useful, editorially approved historical pages.

**Recommendation.** Index only pages whose public-visibility decision and archive policy explicitly permit indexing. `manual_review`, unresolved, excluded, and restricted-non-actionable records are noindex and excluded from sitemap by default. A historical page may be indexable only as a dated, cycle-specific archive with a visible closed/historical label and no active CTA. Never redirect a closed cycle automatically to a new cycle or imply recurrence.

**Consequence.** This may reduce short-term index coverage but prevents stale or conflicting records being interpreted as current offers.

**Approval:** Pending founder/SEO approval.

### A-07 — Opportunity taxonomy and display language

**Options.** Keep a single scholarship/opportunity label; add a few text labels; or separate opportunity nature, funding, fee model, and route.

**Recommendation.** Use controlled, separate dimensions: opportunity nature (scholarship, bursary, grant, fellowship, competition, internship, mentorship, paid training, fee-paying programme, other); funding components; applicant fee; provider programme route; exact cycle. A paid programme is not a scholarship merely because it is adjacent to a scholarship provider.

**Consequence.** Decagon Foundation scholarship and Decagon Institute direct-pay Honours Programme remain separate identities and routes. The latter’s stated ₦275,000 annual programme fee plus university/school fees must not be presented as scholarship coverage.

**Approval:** Pending founder approval.

### A-08 — Funding coverage policy

**Options.** Use one “fully funded” flag; show a narrative summary; or model each benefit component and evidence state.

**Recommendation.** Model tuition, accommodation, living stipend, books/materials, transport, examination fees, and other stated components separately. `unknown` is an explicit value. Do not use “fully funded” unless current-cycle evidence confirms all material components included in that claim. If a material component or relationship is unresolved, withhold the funding claim and, where the uncertainty changes what the student is applying for, keep the cycle non-actionable pending review.

**Consequence.** Descriptive coverage is more precise but needs more editorial work. The Decagon Foundation/Institute funding and fee relationship remains unresolved; the evidence does not support a “fully funded” claim.

**Approval:** Pending founder/editorial approval.

### A-09 — Legacy `verified` compatibility period

**Options.** Replace the boolean immediately; use it as the new authenticity state; or preserve it as a legacy gate while a distinct cycle decision is shadowed and migrated.

**Recommendation.** Keep `verified` unchanged and preserve its current compatibility meaning until every consumer is migrated. Do not reinterpret `verified=true` as current, authentic, open, or actionable. Use explicit mapping and shadow comparisons before a future deprecation proposal.

**Consequence.** Two systems coexist temporarily, with risk of drift; compatibility tests and a documented sunset condition are required. No existing row is mass-updated by this design.

**Approval:** Pending founder/engineering approval.

### A-10 — Existing saves and application history

**Options.** Assign all existing history to the first newly created cycle; create a synthetic “legacy” cycle; leave cycle unset; or migrate only where exact evidence establishes the cycle.

**Recommendation.** Preserve stable listing IDs and personal history. Add nullable cycle references for new writes; keep historical rows unassigned (`legacy_cycle_unknown`) unless a source-backed exact-cycle mapping exists. Do not use a synthetic provider cycle as if it were real.

**Consequence.** Older tracking remains visible but cannot be attributed to a year-specific cycle. New saves and applications can bind to exact cycles after cutover; no deletion or destructive remapping.

**Approval:** Pending founder/product approval.

### A-11 — Scholarship/opportunity catalogue convergence

**Options.** Merge both tables; keep them completely separate; or retain the existing tables while a shared identity/cycle/evidence layer maps to them.

**Recommendation.** Use the third option for v1. Preserve current `scholarships`, `opportunities`, rule, save, and application contracts. Add a constrained one-to-one catalogue identity mapping (exactly one legacy source per mapping row) and let new cycles/evidence refer to that stable identity. Do not force fellowship, paid training, or mentorship into scholarship rules or scoring.

**Consequence.** Adds a mapping layer and migration work but protects existing queries and student histories. Full unification is deferred until usage and type semantics are proven.

**Approval:** Pending founder/engineering approval.

### A-12 — Public source timestamps and attribution

**Options.** Show a generic “verified” stamp; show provider source/check dates; or omit dates from student pages.

**Recommendation.** Show a compact, claim-specific “Provider source checked [date]” attribution when it helps a student judge currency, link to the official source, and identify whether the date is source publication, source check, or production snapshot. Where acceptance was not tested, say so. Do not use `last_verified_at` as a universal proof of current application acceptance.

**Consequence.** More transparent and less misleading; slightly more UI text and precise backend fields are needed.

**Approval:** Pending founder/editorial approval.

## 3. Phase 1.3.1 cases to preserve as policy fixtures

These are evidence-led policy outcomes, not production edits or new provider checks.

| Case | Required recommendation/output | Why | Evidence reference |
|---|---|---|---|
| ASUU — FUK branch 2026 | Treat the FUK cycle as historical; keep the national ASUU cycle unresolved; no national CTA or reminder. | The FUK call was branch-specific, closed 2026-09-24 at noon, and does not establish a universal ASUU cycle. | Phase 1.3.1 addendum, matrix row 1; `01-asuu.md` |
| Bode Amao Foundation | Phase 1.3.1 disposition is `restricted_lead_not_actionable`; proposed output is `manual_review` while the exact cycle is unresolved and official email/post instructions conflict. No CTA. | Reachable form and a third-party deadline do not resolve current acceptance or submission channel. | Addendum, row 2; `02-bode-amao.md` |
| Decagon Foundation | Phase 1.3.1 disposition is `restricted_lead_not_actionable`; proposed output is `manual_review` until the exact cycle and material fee/coverage relationship are resolved. Do not call it fully funded. | Nigerian/entry-stage conditions and open presentation are evidenced, but exact cycle, fee waiver, and non-tuition coverage remain unresolved. | Addendum, row 3; `03-decagon.md` |
| Decagon Institute | Separate paid-programme identity; never merge it into the Foundation scholarship or a scholarship match. | The Institute route is direct-pay; stated fee is ₦275,000 annually plus tuition/school fees. | Addendum, row 3; `03-decagon.md` |
| JG Afrika 2027 | Exclude from the initial Nigerian-undergraduate scope, not “closed.” | Provider/cycle authenticity and open presentation do not establish Nigerian citizenship or Nigerian-university eligibility; notification date is not a deadline. | Addendum, row 6; `06-jg-afrika.md` |
| PAU / Mastercard Foundation | `manual_review`; suppress CTA; preserve `application_status=conflicting`. Do not infer a route-channel conflict from status labels alone. | PAU states 2026/27 is closed while the directory says “Admissions Open.” The supplied evidence does not establish conflicting submission channels. | Addendum, row 10; `10-pau-mastercard.md` |
| NDDC 2026/27 | Excluded from the undergraduate catalogue; retain application status as `unresolved`, not `closed`. | It is postgraduate-only; the deadline and login/403 anomalies do not prove submission acceptance or closure. | Addendum, row 13; `13-nddc.md` |
| PTDF 2026/27 | Historical cycle only; no future-cycle inference or unsupported stored 2027 dates. | The evidenced application window ended 2026-06-05; no future cycle was established. | Addendum, row 17; `17-ptdf.md` |
| Synthetic open Nigerian-undergraduate fixture | `actionable` only for the explicitly stipulated fictional exact cycle after all evidence, route, freshness, scope, and human-approval gates pass. | Exercises the positive path without changing any real Phase 1.3.1 record; reminder still requires user consent, and indexing remains subject to A-06. | Fictional test fixture; no provider facts asserted. |

The positive example is a fictional policy fixture. Every source, date, route, open signal, and approval in it is stipulated solely to exercise a valid positive path; it is not a real provider fact or a claim about any Phase 1.3.1 record.

### Reconciliation notes from the eight source cases and synthetic positive fixture

1. **NDDC:** Keep the seven-dimension fact `application_status=unresolved` from the controlling addendum. `excluded` is the undergraduate-scope publication outcome, not a lifecycle value. Retire the previously proposed scope-coded status value; keep NDDC cycle status and catalogue exclusion separate.
2. **PAU/Mastercard:** Preserve `application_status=conflicting`. Do not infer `application_route_status=conflicting_provider_instructions` merely from conflicting “open/closed” labels; route instructions and lifecycle claims are separate. The route classification needs its own evidence review.
3. **Decagon:** Foundation scholarship and direct-pay Institute programme are separate opportunity identities, even though the sources share a provider family.

## 4. Decisions and approval control

- Approval must be recorded by ID, exact wording, approving person/role, date, and policy version. A silence, later document edit, or implementation task is not approval.
- A policy change that increases public visibility, match eligibility, funding claim strength, or reminder eligibility requires explicit approval and a regression review.
- Until approval, use the safe defaults above. No Phase 2.1 document authorizes modifying application code, production data, schema, grants, RLS, provider routes, messaging, or SEO configuration.

## 5. Related documents

- [Authoritative publication policy and gates](SCHOLARS_PHASE_2_1_AUTHORITATIVE_PUBLICATION_POLICY_2026-11-08.md)
- [Application-route acceptance matrix and freshness standard](SCHOLARS_PHASE_2_1_ROUTE_ACCEPTANCE_AND_EVIDENCE_FRESHNESS_POLICY_2026-11-08.md)
- [Evidence retention and security policy](SCHOLARS_PHASE_2_1_EVIDENCE_RETENTION_AND_SECURITY_POLICY_2026-11-08.md)
- [Technical specification](SCHOLARS_PHASE_2_1_TECHNICAL_SPECIFICATION_AND_FINAL_ERD_2026-11-08.md)
- [Readiness assessment](SCHOLARS_PHASE_2_1_IMPLEMENTATION_READINESS_ASSESSMENT_2026-11-08.md)
