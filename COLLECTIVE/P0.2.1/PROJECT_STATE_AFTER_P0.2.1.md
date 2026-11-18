# Collective - Project State

| Field | Value |
|---|---|
| Document ID | DOC-STATE |
| Last updated | 2026-11-19 |
| Updated by | Manus AI (P0.2.1 recovery and feasibility investigation) |
| Rule | Update at the end of every task. Never mark work complete unless it was completed and verified. |

## 1. Current position

- **Current phase:** Phase 0 - Foundation
- **Current task:** P0.2.1 — Combined-stack zero-cost feasibility investigation
- **P0.1 status:** **FORMALLY APPROVED BY THE FOUNDER ON 2026-11-18**, according to the P0.2.1 recovery brief. The four P0.1 documents remain historical governance records.
- **P0.2 status:** **FORMALLY AUTHORISED AND COMMENCED** on 2026-11-18. No architecture or technology decision has been approved.
- **P0.2.1 status:** **INVESTIGATION COMPLETE; AWAITING FOUNDER REVIEW.** Overall verdict: no complete production-compliant zero-cost stack was verified.

## 2. Completed work

| Item | Status | Note |
|---|---|---|
| `CLAUDE.md` budget constraints corrected | Remediated; P0.1 approved 2026-11-18 | Permanent engineering instructions |
| `docs/PROJECT_BRIEF.md` budget and MVP status corrected | Remediated; P0.1 approved 2026-11-18 | Concise overview |
| `docs/PROJECT_STATE.md` reconnaissance, decisions and handoff corrected | Remediated; P0.1 approved 2026-11-18 | Continuity and document index |
| `docs/PRODUCT_REQUIREMENTS.md` scope and semantics corrected | Remediated; P0.1 approved 2026-11-18 | 142 requirements: P0 56, P1 61, P2 19, P3 6 |
| Structural checks on the PRS | Performed before remediation; to re-run after edits | Unique IDs, valid priority/category values, five fields per requirement row, valid references |

**Not performed in P0.1:** technical validation of architecture assumptions; application tests; benchmarks; prototypes; free-tier feasibility validation. The recovered `main` branch was clean at the approved P0.1 commit and contained only the four P0.1 documents; no application implementation or partial P0.2.1 work was identified. The previous execution was reported to have encountered a Manus usage limit while running the investigation; no partial report or script was present in the canonical repository. The P0.2.1 research was documentary only: no provider accounts, credentials, deployments, payment methods, API calls, database projects or migrations were created.

## 3. Decisions

### 3.1 Confirmed [DECISION] (from founder instructions)

1. Collective is a public SaaS platform with room for future enterprise deployment.
2. Modular, provider-neutral architecture.
3. Agent roles are model-independent.
4. Managed model access and BYOK.
5. Native and external agents.
6. Hybrid cloud and local execution.
7. Persistent project memory with permission-aware access.
8. Independent verification; permission-controlled autonomy.
9. Initial development is cloud-based; the founder uses an Android device and has no local computer.
10. Initial deployment on low-cost infrastructure.
11. Initial development and the initial MVP have a founder-confirmed ₦0 monthly budget for platform infrastructure and managed AI/API spend; paid services are excluded unless this decision changes.
12. Phase 0 includes no application feature implementation.

### 3.2 Awaiting validation (candidates, not final)

| Area | Candidate | Validate in |
|---|---|---|
| Frontend | Next.js, TypeScript | P0.2 |
| Backend | Python, FastAPI, Pydantic | P0.2 |
| Orchestration | LangGraph | P0.2 |
| Database and auth | Supabase PostgreSQL and Auth | P0.2 |
| Queue | PostgreSQL-backed queue or Supabase Queues | P0.2 |
| Tool protocol | MCP | P0.2 |
| External agent protocol | A2A | Before P2 |
| Hosting | Vercel; low-cost Python hosting | P0.2 |
| Execution | Isolated workers or sandboxes; authenticated local runner | P0.2 (cloud), later (local) |

No ADR exists yet. ADR creation begins in P0.2.

### 3.3 P0.2.1 findings [RECOMMENDATION — NOT AN ARCHITECTURE DECISION]

1. No complete production-compliant zero-cost stack is verified.
2. Supabase Free plus a lightweight Cloudflare component is the strongest prototype hypothesis, subject to a second qualifying provider and hands-on validation.
3. Render Free and Vercel Hobby should not be treated as commercial production options under the reviewed current terms.
4. No provider, database, hosting platform or architecture is approved.

### 3.4 Proposed in P0.1, carried forward as unresolved [RECOMMENDATION]

See section 5.

## 4. Known blockers and outstanding work

| ID | Item | Blocks |
|---|---|---|
| B-1 | **Initial reconnaissance record corrected.** The founder's Colab publishing report confirmed the repository identity and initial empty state. This session inspected the published `main` branch and found the four P0.1 documents; no application implementation was identified. The initial pre-publication state was not independently observed. | Resolved for P0.1 review; no implementation work begins before approval |
| B-2 | OQ-002: model-access sequencing under the ₦0 constraint remains unresolved. P0.2.1 did not verify two qualifying free managed providers. | Founder decision before any credential design or implementation |
| B-3 | P0.2.1 found no complete production-compliant zero-cost stack. Supabase Free plus Cloudflare primitives is only a conditional prototype hypothesis; MDL-002 remains unresolved. | Founder decision if the MVP proof or funding model must change |
| B-4 | OQ-005 remains unresolved. Cloudflare Workflows has the strongest documented recovery model, but true $0 entitlement for the required arrangement was not verified; Supabase Free and Render Free have material continuity limits. | P0.2.2 only after founder approval |
| B-5 | OQ-001 and OQ-008: reference scenario; meaning of "full autonomy" | P0.2 tool and security scope |
| B-6 | Founder review of the P0.2.1 report, unresolved provider/Nigeria evidence, and any decision to revise the MVP proof or budget. | Founder approval before P0.2.2 |

Full question list: `docs/PRODUCT_REQUIREMENTS.md`, section 22.

## 5. Remediation completed

- Incorporated the founder's binding ₦0 monthly budget for platform infrastructure and managed AI/API spend. Paid services remain excluded unless the decision changes; BYOK is documented as potentially user-paid, not inherently free.
- Corrected the reconnaissance record, distinguishing the founder's Colab report from this session's independent inspection and identifying what remains unverified.
- Documented the UC-01 sourced-research versus supplied-information MVP conflict, retained OQ-001, and recommended the more feasible supplied-information option without treating it as approved.
- Reviewed all 58 former P0 requirements. Retained 56 that are essential to the minimum proof or to safe, durable operation; moved MDL-003 and MDL-007 to P1 with rationale.
- Reconciled at-least-once delivery and idempotency language; no exactly-once execution guarantee is made.
- Added quota-safe execution expectations: pause, report, preserve progress and resume where possible.
- Identified MDL-002 (at least two independent AI providers) as a critical unresolved MVP feasibility dependency. BYOK is excluded from the proposed MVP, no free managed-access solution has been validated, and P0.2 must establish whether two genuinely free providers can support the proof without silently introducing paid access.
- Required P0.2 to evaluate the complete free stack together: persistent background execution, database access, authentication, quotas, resumability and provider access. Individual free tiers are not evidence that the combined architecture works at ₦0.

P0.2.1 documentary investigation is complete. No application code, architecture decision record, deployment configuration, provider account, migration or production infrastructure was created. P0.2.1 must remain in review until the founder approves or rejects its findings.

## 6. Items requiring founder approval

1. The remediated MVP definition and sharpened proof (PRS section 19), including MVP-EVAL-001..003 and their provisional thresholds.
2. Model-access sequencing under OQ-002 (genuinely free managed access, user-paid BYOK, or another approved route). Managed access and BYOK remain confirmed long-term product capabilities; no MVP sequencing is approved.
3. Sequencing the local runner to P2 (EXE-007, EX-002). Hybrid execution stays a confirmed direction.
4. The exclusion list (PRS section 20).
5. All provisional numeric targets marked *(prov.)*.
6. The reference scenario (OQ-001): sourced research with retrieval, or planning/synthesis using supplied information.
7. Using `docs/PROJECT_STATE.md` as the interim central document index (section 8). The master instructions require a central index; P0.1 specified four documents only. Approve this arrangement or approve a dedicated index file in P0.2.
8. Names and file locations of the four documents.

## 7. Next task

**Next task:** Founder review of P0.2.1 and explicit decision on whether to revise the MVP proof, change the ₦0 constraint, or authorise a bounded hands-on validation. Do not start P0.2.2 or implement the application until the founder explicitly approves the next step.

## 8. Document index (interim, authoritative)

| ID | Path | Purpose | Status |
|---|---|---|---|
| DOC-CLAUDE | `CLAUDE.md` | Permanent engineering instructions for Claude sessions | Remediated draft v0.1; P0.1 approved 2026-11-18 |
| DOC-BRIEF | `docs/PROJECT_BRIEF.md` | Concise project overview | Remediated draft v0.1; P0.1 approved 2026-11-18 |
| DOC-STATE | `docs/PROJECT_STATE.md` | Continuity: phase, task, decisions, blockers, index | Remediated draft v0.1; P0.1 approved 2026-11-18 |
| DOC-PRS | `docs/PRODUCT_REQUIREMENTS.md` | Product requirements specification | Remediated draft v0.1; P0.1 approved 2026-11-18 |
| DOC-P0.2.1-FEASIBILITY | `docs/architecture/P0.2.1_ZERO_COST_STACK_FEASIBILITY.md` | Combined-stack zero-cost feasibility investigation | Completed; awaiting founder review |

No other project documents existed in the recovered canonical repository before this task. P0.2.1 added the feasibility report listed above. This session inspected the published `main` branch and found the four P0.1 documents; no application implementation was identified. It did not independently observe the pre-publication repository state described by the founder's Colab report.

## 9. Change log

| Date | Task | Change |
|---|---|---|
| 2026-11-18 | P0.1 | Initial drafts of the four documents. |
| 2026-11-18 | P0.1 remediation | Incorporated founder decisions and consistency corrections; awaiting approval. |
| 2026-11-18 | P0.1 targeted corrections | Added the MDL-002 two-provider feasibility gate, corrected reconnaissance wording, clarified P0.2 authorization, and defined combined-stack ₦0 feasibility evaluation; awaiting approval. |
| 2026-11-18 | Founder approval / P0.2 commencement | Per the recovery brief, P0.1 was formally approved and P0.2 was authorised and commenced. A previous execution encountered a Manus usage limit. |
| 2026-11-19 | P0.2.1 recovery | Recovered clean canonical state at `2c16eee`; no partial P0.2.1 work found. Completed documentary comparison of nine candidates and recorded the no-complete-stack-at-₦0 verdict. |
