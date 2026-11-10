# Scholars Phase 2 — Decision Register

**Date:** 2026-11-08
**Authority:** Phase 1.3.1 is the controlling editorial input where earlier reports differ.
**Application revision inspected:** `cf3682ce35912df7b9b9352193630fc404427c7c`
**Status:** Design register; no implementation approved or performed.

## 1. Evidence-backed design decisions

| ID | Decision | Basis | State |
|---|---|---|---|
| D-01 | Keep provider authenticity, audience eligibility, academic level, application status, route status, evidence freshness, and publication disposition independent. | Phase 1.3.1 clarification addendum; current single `verified` field is insufficient. | Supported; use as design baseline. |
| D-02 | Model an enduring opportunity separately from each exact application cycle. Never infer a new cycle by shifting prior dates. | Phase 1.3.1 audit; `scholarships` currently has listing-level `deadline`, `opens_at`, and `last_cycle_closed_at`. | Supported. |
| D-03 | Store evidence sources/captures and individual claims with evidence relationships. One source may support a deadline while leaving nationality or funding unknown. | Phase 1.3.1 date model; current `research_notes` is private free text; discovery claims are candidate-scoped. | Supported. |
| D-04 | Treat route provenance, reachability, and acceptance as separate facts. | NDDC portal access anomaly and JG Afrika form not submitted; live route or login is not acceptance evidence. | Supported. |
| D-05 | Make public actionability a separate human-approved editorial disposition; automated extraction, quality score, and eligibility verdict are advisory. | Current discovery workflow and publication function create catalog records with `verified=false`; separate verification is needed. | Supported. |
| D-06 | Use additive migration, stable IDs, shadow reads, and staged cutover; do not redefine `verified` or existing date fields in place. | 95 live scholarship rows and consumer behavior in routes/matching/reminders/SEO; lifecycle fields affect multiple surfaces. | Supported. |
| D-07 | Only an approved, confirmed, exact active cycle may drive actionable matching, application CTA, or reminders. | Current reminders can use listing deadline and do not consistently apply `opens_at`/`last_cycle_closed_at`; new model must close this gap. | Supported. |
| D-08 | Keep scholarships and other opportunities distinct during initial migration; normalize their taxonomy only after mapping both contracts. | Live production has 95 scholarships and 42 opportunity rows with distinct enums, queries, saves, and user-facing behavior. | Supported. |
| D-09 | Preserve private evidence and notes; do not publish `research_notes`, snapshots, evidence excerpts, or applicant data through public views/API. | Existing comments, RLS, and public-query conventions; live metadata shows editor-only discovery access. | Supported. |
| D-10 | Keep historical cycle data; date-based inactionability is not proof of provider-confirmed closure. | Phase 1.3.1 date/freshness distinctions and history requirements. | Supported. |

## 2. Decisions requiring founder/editorial approval

| ID | Decision | Options / trade-off | Why approval is needed |
|---|---|---|---|
| A-01 | Public catalogue scope beyond initial Nigerian undergraduates | Keep initial-only; create separate international/postgraduate/other catalogue; make a broader unified catalogue with audience filters. | Product positioning and eligibility risk. JG Afrika and NDDC demonstrate materially different scope. |
| A-02 | Whether restricted leads appear publicly | Editor-only hold vs student-visible non-actionable lead with warnings. | Student risk, perceived endorsement, SEO/reputation trade-off. |
| A-03 | Meaning of “actionable/open” and route usability | Require explicit official open statement and provider-controlled application route; allow carefully reviewed third-party route; separate acceptance proof levels. | Public claim threshold has business/legal/reputation consequences. |
| A-04 | Freshness intervals and stale-state response | Time windows by claim risk, cycle stage, and route; stale might auto-withhold but must not auto-close. | Requires editorial capacity and acceptable false-positive/false-negative balance. |
| A-05 | Required reviewer roles | One admin reviewer; independent approver for material funding/eligibility/date claims; founder-only exceptions. | Separation of duties and operating model. |
| A-06 | Indexing historical/unresolved pages | Keep indexable archive with clear cycle canonical; noindex unresolved; retain historical pages only where value justifies it. | SEO and student-facing permanence. |
| A-07 | Opportunity taxonomy and display language | Distinguish scholarship, bursary, grant, fellowship, competition, internship, paid training, fee-paying programme, partial/full scholarship. | Naming affects student expectations and content taxonomy. |
| A-08 | Funding coverage policy | Require explicit component-level confirmation; define whether awards with unknown coverage remain listed and how “fully funded” may be used. | High consequence for student financial decisions. |
| A-09 | Legacy `verified` compatibility period | Keep it as a gate; map its historic meaning without equivalence; decide when to replace after dual-read. | Changes affect 95 scholarship rows and public surfaces. |
| A-10 | Treatment of existing saved/application history after cycle model | Map old tracking to an “unspecified legacy cycle” vs backfill only when provider evidence establishes cycle. | User history should not be misrepresented; requires product choices. |
| A-11 | Existing scholarship/opportunity catalogue convergence | Keep two tables with shared cycle/evidence architecture or unify into a polymorphic opportunity model. | Opportunity semantics, rule/matching behavior, and UI differ. |
| A-12 | Public display of source timestamps and attribution | Show last source check, source link/role, “not confirmed accepting” notices, or a simpler reviewed-on indicator. | Avoid overclaiming while maintaining usable student copy. |

## 3. Unresolved technical questions

| ID | Question | Required resolution before design freeze |
|---|---|---|
| T-01 | What exact Supabase migration ledger/order is deployed, and which migrations were applied manually? | Read-only migration history comparison and approved DDL/schema diff. Repository contains duplicate numeric prefixes; live `opportunities` exists without its base creation in this checkout. |
| T-02 | What are exact deployed table grants/column grants in addition to RLS? | Inspect grants by anon/authenticated/service_role and test public clients. RLS metadata alone is not a complete access proof. |
| T-03 | Is there a code-generated `Database` type and canonical schema-generation workflow outside this repository checkout? | Locate source-of-truth types and migration process before adding fields. No generated type file was found in the inspected tree. |
| T-04 | What is the authoritative definition and migration history for `public.opportunities`? | Identify deployed DDL and safely check it into a future migration baseline without destructive recreation. |
| T-05 | How should new cycles affect application tracking, saves, discussion IDs, notification dedupe, and link stability? | Map all foreign-key consumers and define stable legacy/cycle references. Current user history links to listing IDs. |
| T-06 | Which query surfaces must share one publication/visibility predicate? | Resolve differences among browse, matching, related items, saves, public pages, sitemap, and push campaigns; write an explicit route matrix. |
| T-07 | Can current discovery claims be promoted losslessly into a catalogue claim ledger? | Define promotion, history, reviewer identity, cycle scoping, claim supersession, and atomic audit events. |
| T-08 | How are matcher unknowns represented for non-profile criteria? | Decide whether unsupported/unknown constraint blocks, marks partial, or is editorial-only; avoid silent denominator omission for critical rules. |
| T-09 | Which jobs own freshness expiration and reminder suppression? | Decide scheduler/lease path and idempotency for closure, extension, cancellation, and reschedule. No code is authorized here. |
| T-10 | How are published public pages invalidated or revalidated when editorial status changes? | Confirm Next.js ISR/revalidation, CDN/cache, sitemap refresh, canonical/redirect handling. |
| T-11 | What candidate/item limits and review SLA are realistic? | Current discovery queue can ingest and process automatically but publication remains human-gated; plan to scale human review. |

## 4. Editorial questions raised by Phase 1.3.1

1. **ASUU:** one national opportunity with branch-specific cycle/route records, or separate branch listings? FUK’s expired call cannot be nationalized.
2. **Bode Amao:** which postal/email submission route is authoritative, and what exact cycle is current?
3. **Decagon:** what is the relationship between the Foundation’s scholarship and Institute’s fee-paying programme; what exact fees/benefits are covered; is a subsidy officially available?
4. **JG Afrika:** are Nigerian citizens eligible, what university location is allowed, is a full tertiary transcript mandatory, and what is the true application deadline vs notification date?
5. **PAU:** how should a cycle-specific university closure be reconciled with an undated external directory label?
6. **NDDC:** is there an approved public way to confirm submission acceptance without bypassing access controls? The postgraduate cycle remains outside initial undergraduate catalogue regardless.
7. **Future dates:** who may null/qualify legacy dates that have lifecycle effects, and how are those changes approved without presenting the resulting page as a different fact?
8. **All 17 and remaining records:** which records may be historical archives versus editor-only monitoring items, and what review schedule will keep facts current?

No contact, application submission, or access-control bypass is authorized to answer these questions.

## 5. Risks and trade-offs

| Risk | Impact | Proposed mitigation |
|---|---|---|
| Overloaded legacy `verified` maps directly to new “authentic/current/actionable.” | False open listings, ineligible matches, wrong reminders. | Preserve legacy meaning; require distinct cycle/editorial gates; shadow compare. |
| Bulk legacy backfill invents cycles from dates or prior annual cadence. | Wrong current cycle and student deadline. | Manual evidence mapping; unknown cycle remains unknown; no date shifting. |
| Eligibility constraints are too generic or become executable arbitrary logic. | Incorrect exclusion/inclusion and unsafe rules. | Constrained typed fields first; explicit supported matcher map; tests. |
| Evidence/private notes leak through public table access. | Confidentiality and reputational harm. | Private-by-default RLS/grants, allowlisted projection, negative authorization tests. |
| Reminder logic stays listing-level. | Unwanted notifications for closed/uncertain opportunities. | Cycle-bound reminder keys and explicit active gate; dry-run before enabling. |
| Two catalogues are unified too early. | Breaks type-specific route, UI, scoring and personal histories. | Preserve current tables; add shared evidence/cycle components first; defer convergence. |
| Automated freshness/eligibility is treated as human verification. | Unsupported public assertions. | Store machine assessments separately; require human disposition and audit event. |
| Migration history differs from checked-in files. | Reapplying DDL or schema drift. | Verify deployed migration ledger/DDL and run reviewed migration dry-run. |
| Very rich evidence model slows editors and creates stale data. | Editorial backlog and lower freshness. | Phase model, progressive required fields, risk-based review intervals and workload pilot. |

## 6. Explicitly deferred

- All application code, schema, migration, RLS, grant, trigger, RPC, production data, deployment, GitHub automation, and UI changes.
- Contact with scholarship providers and submission of applications.
- Re-verification of provider facts in real time for future writes.
- Automatic NLP/LLM publication or automatic conversion of predicted cycles.
- Rewriting, deleting, or bulk-correcting the 17 audited production records.
- Dropping/renaming `scholarships`, `opportunities`, `verified`, date, rule, save, or application structures.
- Changing email, push, WhatsApp, or other student messaging behavior.
- Making policy decisions reserved for founder/editorial approval.

## 7. Review cadence and next gate

The next task should review this register with founder/editorial stakeholders, resolve A-01 through A-12 or mark them explicitly deferred, and answer T-01 through T-04 before finalizing schema. Only then should a separately authorized technical specification and implementation plan be prepared. Any production write requires exact field/value/scope approval, evidence recheck, a read-only before snapshot, a rollback plan, and post-change validation.

No Scholars application code, Supabase schema/rows, RLS, deployment, or provider workflow was changed in producing this register.
