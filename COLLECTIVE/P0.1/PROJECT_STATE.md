# Collective - Project State

| Field | Value |
|---|---|
| Document ID | DOC-STATE |
| Last updated | 2026-11-18 |
| Updated by | Claude (P0.1 remediation session) |
| Rule | Update at the end of every task. Never mark work complete unless it was completed and verified. |

## 1. Current position

- **Current phase:** Phase 0 - Foundation
- **Current task:** P0.1 - Repository Reconnaissance and Product Requirements
- **P0.1 status:** **REMEDIATED, AWAITING FOUNDER APPROVAL.** The four documents were corrected for the founder's ₦0 budget decision, reconnaissance record, MVP scenario ambiguity, P0 scope, and task-durability semantics. Founder approval remains pending.

## 2. Completed work

| Item | Status | Note |
|---|---|---|
| `CLAUDE.md` budget constraints corrected | Remediated, awaiting approval | Permanent engineering instructions |
| `docs/PROJECT_BRIEF.md` budget and MVP status corrected | Remediated, awaiting approval | Concise overview |
| `docs/PROJECT_STATE.md` reconnaissance, decisions and handoff corrected | Remediated, awaiting approval | Continuity and document index |
| `docs/PRODUCT_REQUIREMENTS.md` scope and semantics corrected | Remediated, awaiting approval | 142 requirements: P0 56, P1 61, P2 19, P3 6 |
| Structural checks on the PRS | Performed before remediation; to re-run after edits | Unique IDs, valid priority/category values, five fields per requirement row, valid references |

**Not performed:** technical validation of any architecture assumption; application tests; benchmarks; prototypes; free-tier feasibility validation. The published `main` branch was inspected after the four documents had been published and contained the four P0.1 documents; no application implementation was identified. The initial pre-publication reconnaissance was not independently performed.

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

### 3.3 Proposed in P0.1, awaiting founder approval [RECOMMENDATION]

See section 5.

## 4. Known blockers and outstanding work

| ID | Item | Blocks |
|---|---|---|
| B-1 | **Initial reconnaissance record corrected.** The founder's Colab publishing report confirmed the repository identity and initial empty state. This session inspected the published `main` branch and found the four P0.1 documents; no application implementation was identified. The initial pre-publication state was not independently observed. | Resolved for P0.1 review; no implementation work begins before approval |
| B-2 | OQ-002: model-access sequencing under the ₦0 constraint remains unresolved | P0.2 credential design |
| B-3 | ₦0 feasibility of the combined infrastructure and model-access stack remains technically unvalidated, including whether two genuinely free AI providers can support the MVP | P0.2 combined-stack feasibility evaluation; founder decision if the MVP proof must change |
| B-4 | OQ-005: durable long-running execution on low-cost hosting | P0.2 |
| B-5 | OQ-001 and OQ-008: reference scenario; meaning of "full autonomy" | P0.2 tool and security scope |
| B-6 | Founder review of the remediated PRS, including the retained P0 set (56 of 142) and recommendation on OQ-001/OQ-002/OQ-008 | P0.1 approval |

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

P0.2 has not started. No application code, architecture decision record, deployment configuration or technical validation was created.

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

**Next task after founder approval: P0.2 — Architecture evaluation and decision records. Not yet approved or started.**

Do not begin P0.2 until the founder explicitly approves P0.1.

## 8. Document index (interim, authoritative)

| ID | Path | Purpose | Status |
|---|---|---|---|
| DOC-CLAUDE | `CLAUDE.md` | Permanent engineering instructions for Claude sessions | Remediated draft v0.1, pending approval |
| DOC-BRIEF | `docs/PROJECT_BRIEF.md` | Concise project overview | Remediated draft v0.1, pending approval |
| DOC-STATE | `docs/PROJECT_STATE.md` | Continuity: phase, task, decisions, blockers, index | Remediated draft v0.1, pending approval |
| DOC-PRS | `docs/PRODUCT_REQUIREMENTS.md` | Product requirements specification | Remediated draft v0.1, pending approval |

No other project documents exist as of 2026-11-18, as far as this session could determine. This session inspected the published `main` branch and found the four P0.1 documents; no application implementation was identified. It did not independently observe the pre-publication repository state described by the founder's Colab report.

## 9. Change log

| Date | Task | Change |
|---|---|---|
| 2026-11-18 | P0.1 | Initial drafts of the four documents. |
| 2026-11-18 | P0.1 remediation | Incorporated founder decisions and consistency corrections; awaiting approval. |
| 2026-11-18 | P0.1 targeted corrections | Added the MDL-002 two-provider feasibility gate, corrected reconnaissance wording, clarified P0.2 authorization, and defined combined-stack ₦0 feasibility evaluation; awaiting approval. |
