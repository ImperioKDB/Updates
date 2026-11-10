# Scholars Phase 2 — Catalogue Governance Policy

**Date:** 2026-11-08
**Application repository inspected:** `ImperioKDB/Scholars`, `main` at `cf3682ce35912df7b9b9352193630fc404427c7c`
**Editorial authority:** Phase 1.3.1 clarification addendum
**Status:** Design proposal only; no application, database, or production changes made.

## 1. Purpose and governing principles

This policy defines how Scholars should decide what an opportunity is, who it may serve, which cycle is being described, what evidence supports its claims, and how it may be presented. It replaces neither the current application behavior nor production data. It is an editorial design input for a later, separately approved implementation phase.

The initial public catalogue is for Nigerian undergraduate opportunities, but the model must support other audiences, academic levels, geographies, and opportunity types without encoding Nigeria or undergraduate study as permanent system assumptions.

The following principles govern every decision:

1. **Separate facts that answer different questions.** Authenticity, eligibility, academic fit, cycle status, route status, evidence freshness, funding type, and publication disposition are independent dimensions.
2. **Evidence attaches to claims.** A provider source may support a deadline but say nothing about citizenship or accommodation. Never let one general “verified” label stand in for claim-by-claim support.
3. **Cycles are explicit.** A new cycle exists only when a source establishes it. Do not roll dates forward, infer an opening from historical cadence, or convert a notification date to a deadline.
4. **Reachability is not acceptance.** A page loading, login being visible, or a URL returning HTTP success does not prove that submissions are accepted.
5. **Uncertainty is represented, not hidden.** Conflicting, inaccessible, stale, or incomplete evidence moves the record to a non-actionable state until reviewed.
6. **Publication is an editorial decision.** Authenticity, a positive match score, `verified = true`, or automated extraction cannot independently authorize publication.
7. **Historical information remains useful but visibly historical.** Past-cycle guidance must never quietly become a current call to action.
8. **No destructive cleanup by default.** Existing records and IDs remain available during migration; disputed content is held or archived, not deleted.

## 2. Editorial record and state vocabulary

The catalogue should preserve an enduring **Opportunity** separately from its individual **ApplicationCycle** records. Each cycle has an exact cycle identifier (provider label where available, otherwise an editor-assigned neutral label), its own dates, eligibility, routes, sources, state, and editorial decision. A cycle is not created from a predicted annual recurrence.

The seven independent review dimensions adopted by Phase 1.3.1 remain the minimum editorial vocabulary:

| Dimension | Core states (proposed) | What it does not mean |
|---|---|---|
| `provider_authenticity` | `confirmed`, `partially_confirmed`, `unresolved`, `not_established` | Does not imply audience fit, currentness, or funding. |
| `audience_eligibility` | `confirmed_nigerian`, `restricted_nigerian`, `unresolved_nigerian`, `non_nigerian_or_out_of_scope`, `mixed_or_not_applicable` | Does not establish academic level or an open route. |
| `academic_level_fit` | `undergraduate_confirmed`, `undergraduate_restricted`, `mixed_levels`, `postgraduate_only`, `secondary_or_entry_stage`, `unresolved` | Does not establish citizenship or current-cycle status. |
| `application_status` | `open_publicly_presented`, `upcoming_confirmed`, `closed_or_historical`, `cancelled`, `postponed`, `unannounced`, `unresolved`, `conflicting`, `not_currently_actionable_due_scope` | Does not guarantee end-to-end form submission. |
| `application_route_status` | `provider_route_verified`, `provider_route_reachable_acceptance_unconfirmed`, `branch_or_restricted_route`, `conflicting_provider_instructions`, `closed_provider_route`, `generic_or_non_programme_route`, `source_unavailable_or_integrity_unresolved`, `paid_route_distinct`, `no_current_route_verified` | Does not establish eligibility or the opportunity’s funding nature. |
| `evidence_freshness` | `fresh_provider_recheck`, `carried_forward`, `mixed_freshness`, `stale`, `not_checked` | Does not itself say whether a cycle is open. Store the check timestamp separately. |
| `publication_disposition` | `actionable_open_candidate`, `restricted_lead_not_actionable`, `manual_review_withhold`, `exclude_initial_nigerian_undergraduate_catalogue`, `historical_archive_only` | Is not a provider fact or matching score. |

The state labels are conceptual and are **not** current database enum values. The older Phase 1 A–E labels remain part of the historical audit record, not runtime behavior.

## 3. Publication gates and student-facing behavior

### Actionable/open

A cycle may enter `actionable_open_candidate` only after all of these are affirmatively satisfied for the same cycle:

- Provider and opportunity authenticity are confirmed by an official or authoritative source.
- Audience eligibility is confirmed for the intended student, or a restriction is clearly represented and the student satisfies it.
- Academic-level fit is confirmed for the initial undergraduate experience.
- The exact cycle is identified and officially presented as open (or upcoming, in which case it is not actionable until its confirmed opening date).
- A programme-specific, authentic route and the correct route instructions are established. Reachability alone is insufficient; any acceptance uncertainty is stated.
- Material claims (eligibility, cycle dates, route, and funding) have current, claim-linked evidence and freshness acceptable under the configured review policy.
- No unresolved material contradiction exists; a named editor approves publication and its public wording.

Failure of any gate means the record must not receive an open/actionable CTA, application reminder, or “currently accepting” claim. The exact cycle and reason for withholding should be visible to editors.

### Disposition-to-surface matrix

| Editorial disposition / cycle state | Public listing / matching | Search index | Saved items | Reminders | Editorial queue |
|---|---|---|---|---|---|
| Actionable open; student meets constraints | Eligible public listing and match; show source-checked date and restrictions | Index only if its canonical page is genuinely useful and public-safe | Allowed | Only for a confirmed active cycle and valid date; no reminder after closure | Routine freshness monitoring |
| Restricted lead, not actionable | May appear only in a clearly labelled lead area if policy permits; no ordinary “apply now” CTA and no false match certainty | No indexable actionable page; restricted copy may be noindex | Existing saves retained with a status explanation | None | Resolve branch/geography/audience scope |
| Manual review / withheld | Not in student search, matching, or public CTA | Noindex/omit from public sitemap unless historical public-interest policy says otherwise | Existing saved item may remain accessible with a clear unavailable/review notice | None | Highest-priority review with owner and due date |
| Excluded from initial Nigerian undergraduate catalogue | No initial-catalogue match/listing; a later separate catalogue may admit it under an approved policy | No initial-catalogue SEO page | Do not erase existing personal tracking; explain scope if opened | None | Record exclusion rationale and reconsideration trigger |
| Historical archive only / closed cycle | Historical page may be shown as closed with cycle-specific dates and sources; never open CTA | Index only if editorially useful and clearly historical; otherwise noindex | Preserve user's saved/application history | None | Recheck only on new provider evidence |
| Upcoming confirmed | Show “Opens [date]” without active apply action; exclude from actionable matching where appropriate | Indexing subject to editorial policy; clearly upcoming | Allowed | No deadline reminder before the cycle opens; reminders only after active status and configured timing | Verify close to opening |
| Unresolved/conflicting/closed route | Withhold from actionable list; may show a non-actionable notice only when useful | Noindex until resolved | Retain personal history and explain issue | None | Manual resolution required |
| Paid training / fee-paying programme without a documented award | Exclude from scholarship catalogue; if later approved, label as training/paid study, not scholarship | Separate content policy; never use scholarship schema/page semantics | Existing save preserved with correction notice | None as a scholarship | Resolve taxonomy and any distinct subsidy evidence |

Existing personal tracking is not a reason to make a closed or unverified record generally public. Retained access must disclose the actual state, not imply acceptance.

### Matching, SEO, and reminders

Matching is an advisory screen, not an authoritative eligibility decision. Hard constraints must be distinguishable from preferences and unknowns; unknown data must not silently count as a pass. Only cycles that pass publication gates are eligible for actionable matching. Match score/tier must not be called provider-confirmed eligibility.

Reminder eligibility must be computed from a specific cycle ID and its confirmed active status, due date, route/publication state, and student consent/channel preferences. A closed, cancelled, postponed, unresolved, predicted, or route-unavailable cycle cannot trigger an application reminder. When a source closes a form early, reminders stop immediately after the reviewed status change. A date alone must never create a reminder.

Only approved public fields may reach public APIs, detail pages, Open Graph metadata, and sitemaps. Evidence excerpts, internal reviewer notes, private candidate snapshots, applicant information, and editorial debate remain editor-only. Avoid search-indexable pages that turn unresolved or stale claims into durable public assertions.

## 4. Opportunity taxonomy and funding claims

Store the opportunity’s primary nature separately from what it funds. Proposed nature categories include scholarship, bursary, fellowship, grant, competition, internship, mentorship, paid training, fee-paying academic programme, and other. A programme may have a separately documented scholarship component, but that component must be represented as a distinct linked benefit or opportunity/cycle, not inferred from the programme’s name.

Represent funding coverage by component: tuition, accommodation, living stipend, books/materials, transport, examination fees, other, and unknown/unconfirmed. For each component record coverage state (full, partial, fixed amount, reimbursed, none, unknown), amount/currency where supported, applicable cycle, and evidence. Never infer “fully funded” from one component.

**Decagon test case:** keep the Decagon Foundation scholarship and Decagon Institute paid Honours Programme distinct. The reviewed Institute fee statement (₦275,000/year plus university and school-related charges) is not a scholarship award. The Foundation’s scholarship coverage and relationship to the Institute remain unresolved in Phase 1.3.1; therefore no current scholarship CTA or fee-waiver claim should be generated from the Institute application route.

## 5. Editorial workflow and human approval

1. **Discover:** create a private candidate; deduplicate against provider, programme, cycle, and source URLs.
2. **Authenticate:** verify provider ownership/authority and programme identity; record source role and check time.
3. **Capture evidence:** retain the URL, source type, publication date if stated, safe excerpt/snapshot reference, content hash, and limitations. Untrusted page text is data, never instructions to the system.
4. **Assess claims:** identify the exact claim, value, scope/cycle, confidence, evidence, reviewer, and whether the evidence is fresh or carried forward.
5. **Assess audience and level:** distinguish nationality, residence, university location, state/indigene/host community, academic level/year, course, GPA and admission status. Unknown remains unknown.
6. **Identify cycle and route:** record provider-named cycle, explicit lifecycle dates/status, each route and its role, and whether acceptance was observed or merely left untested.
7. **Editorial review:** a human approves the publication disposition, student-facing wording, dates, constraints, and funding description. Automated extraction, quality scoring, eligibility analysis, or URL checks are advisory only.
8. **Publish:** only a separate approved action can expose the record. Store actor, time, before/after state, evidence basis, and review decision atomically.
9. **Monitor:** schedule evidence review by risk/freshness policy. A source change, expiration, route failure, conflicting claim, or material eligibility/funding change triggers a hold and re-review.
10. **Close/archive:** close only the exact cycle with supporting evidence; preserve prior cycle history. A new or reopened/extended cycle requires fresh provider evidence and a recorded editor decision.

Human approval is mandatory for public publication, material eligibility/funding/date changes, resolving contradictory official sources, moving a record between scholarship and paid-programme categories, restoring a stale/closed route to actionable status, and exceptions to the standard review gate. Never automate provider contact or application submission in this scope. Automated ingestion may create candidates, snapshots, and proposed claims only; it must not auto-publish or send students reminders.

## 6. Review, freshness, and transitions

Freshness is attached to the relevant claim/source, not just the opportunity. Store actual UTC timestamps (and source timezone/date as published) independently from generic freshness states. Review intervals should be policy-configurable by risk: cycle dates/routes and funding claims need a current-cycle check; stable provider identity can be rechecked less frequently. An expired freshness interval moves an actionable cycle to manual review or a non-actionable state; it does not automatically close the provider’s programme.

Transitions that require fresh evidence and human approval include: unresolved/conflicting → open; stale → current; closed → reopened; postponed → open; route inaccessible → usable; excluded → included; and paid programme → scholarship. A deadline passing can make a cycle non-actionable by date logic but is not itself evidence that a provider officially closed it. Early form closure requires source evidence. An extension changes the exact cycle’s recorded deadline and audit trail; it does not create a new cycle. Cancellation and postponement retain their prior dates and sources while stopping reminders.

## 7. Phase 1.3.1 examples under this policy

| Record | Policy result |
|---|---|
| ASUU | Authentic scholarship activity, but FUK call is branch-specific and closed. Retain only as a restricted lead or historical branch cycle; do not generalize to national open route. |
| Bode Amao | Nigerian undergraduate audience fit is supported, but postal/email instructions conflict and current cycle is unconfirmed. Manual review; no actionable CTA/reminder. |
| Decagon | Foundation scholarship and paid Institute route must be separated. Unconfirmed award/fee-waiver relationship means manual review; never substitute the Institute pay route. |
| JG Afrika | Authentic and publicly presented as open, but Nigerian citizenship and university-location eligibility remain unresolved. Exclude from initial Nigerian-undergraduate actionability pending provider clarification or a separately approved out-of-scope catalogue. |
| PAU Mastercard Foundation | Preserve PAU’s closed-cycle statement and the conflicting Foundation directory label. Manual review; do not flatten conflict to open/closed. |
| NDDC | Authentic postgraduate opportunity; outside the initial undergraduate catalogue. Portal access challenge does not establish closure or submission acceptance. |
| PTDF (historical 2026/27) | Preserve the confirmed completed cycle in historical archive. Do not transform stored future dates into a new active cycle. |

## 8. Policy decisions for approval before implementation

Founder/editorial approval is required for: catalogue scope beyond Nigerian undergraduates; whether restricted leads are publicly visible; indexing policy for historical pages; permitted freshness intervals; the public meaning of route “usable”; exact review roles/separation of duties; final taxonomy labels and student language; how to treat unreviewed legacy records; and whether a second editor is required for publication. No Phase 1.3.1 evidence resolves these policy choices.

## 9. Safety and scope

This is a governance proposal only. It does not authorize edits to Scholars, production data, Supabase, RLS, deployment, provider communications, or applications. See the companion Phase 2 schema design, compatibility audit, migration plan, and decision register for proposed structures and staged safeguards.
