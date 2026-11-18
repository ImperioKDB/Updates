# Collective - Project Brief

| Field | Value |
|---|---|
| Document ID | DOC-BRIEF |
| Version | 0.1 (remediated draft, pending founder approval) |
| Last updated | 2026-11-18 |
| Detail lives in | `docs/PRODUCT_REQUIREMENTS.md` (requirements), `docs/PROJECT_STATE.md` (status) |

## 1. What Collective is

Collective is a public SaaS platform: a **universal autonomous multi-model AI workforce**.

Tagline: **"One objective. An entire AI workforce."**

A user states an objective. Collective plans it, assigns tasks to specialised AI agents, lets them collaborate through structured messages, verifies the result independently and returns a completion report. The user manages outcomes, not separate AI conversations.

## 2. The problem it solves

- Users act as the integration layer, copying context between AI chats and tools.
- Context is fragmented and not shared across conversations.
- Work is tied to one model although models differ in quality, cost, speed and availability.
- The producing model usually checks its own work.
- Autonomy is either absent or unbounded.
- Multi-step AI spend is opaque.

## 3. Positioning

- Not a chatbot (the unit of work is an objective).
- Not only a coding agent (software engineering is one use case among research, business operations and personal productivity).
- Not a model vendor (provider-neutral; roles are model-independent).

## 4. Confirmed product decisions [DECISION]

1. Public SaaS, with room for future enterprise deployment.
2. Modular, provider-neutral architecture.
3. Agent roles (Researcher, Engineer, Critic, Strategist and others) are model-independent.
4. Managed model access and BYOK are both supported.
5. Native Collective agents and external agents are both supported.
6. Hybrid cloud and local execution.
7. Persistent projects, shared context and permission-aware memory.
8. Independent verification and quality control.
9. Autonomy within user-defined permissions and safety boundaries.
10. Development is cloud-based (the founder works from an Android device); deployment starts on a founder-confirmed ₦0 monthly budget. Paid services are not assumed during initial development or the initial MVP.

## 5. Architectural direction under consideration [ASSUMPTION - unvalidated]

These are candidates. Evaluation happens in P0.2. Do not treat them as final. P0.2 must evaluate the combined feasibility of the free infrastructure and model-access stack: persistent background execution, database access, authentication, quotas, resumability and provider access. Individual free-tier availability is not proof that the complete architecture can operate at ₦0. User-paid BYOK, temporary promotional credits and paid services are separate categories, not equivalent to permanently free managed access.

| Area | Candidate |
|---|---|
| Frontend | Next.js, TypeScript |
| Backend | Python, FastAPI, Pydantic |
| Orchestration | LangGraph |
| Database and auth | Supabase PostgreSQL, Supabase Auth |
| Queue | PostgreSQL-backed queue or Supabase Queues |
| Model access | Provider-neutral model gateway with provider adapters |
| Tools | MCP |
| External agents | A2A |
| Cloud execution | Isolated workers or sandboxes |
| Local execution | Authenticated local runner |
| Hosting | Vercel (frontend), low-cost Python hosting (backend) |

## 6. Core systems and capabilities

1. **Objective and project management** - objectives, runs, tasks, dependencies, state.
2. **Agent workforce** - model-independent roles, Director/Planner, specialists, Critic/Verifier.
3. **Model gateway** - provider adapters, model registry, role-to-model assignment, managed access and BYOK.
4. **Collaboration layer** - structured messages, hand-offs, shared permitted context, conflict resolution.
5. **Memory and knowledge** - task context, project memory, permission-aware scopes.
6. **Execution** - cloud workers and sandboxes; later a local runner.
7. **Verification** - independent checking, revision loops, completion reports.
8. **Governance and security** - permissions, budgets, audit log, tenant isolation.
9. **Observability and cost** - traces, usage, budgets.
10. **SaaS layer** - accounts, plans, billing, administration.

## 7. MVP objective

Prove that **one objective produces a verified outcome through coordinating agents on at least two AI providers, with no manual transfer of prompts or context by the user.**

Recommended smallest implementation (see PRS section 19): one reference scenario selected through OQ-001; roles Director, at least two specialists and Critic; sequential execution; durable state; no code execution; no external side effects; invite-only access; hard run budget; BYOK excluded from the proposed MVP; and a measured comparison against a single-model baseline. A critical unresolved dependency is MDL-002: P0.2 must establish whether two genuinely free AI providers can support the proof. No free managed-access solution has been validated. If two suitable free providers cannot be established, the founder must decide whether to revise the MVP proof; paid access must not be introduced silently.

The MVP is all retained P0 requirements. Two formerly P0 requirements are now P1 after remediation because they are not essential to the minimum proof and would otherwise imply budget or extensibility commitments: MDL-003 and MDL-007. MDL-002 remains P0 and is a critical unresolved feasibility dependency, not evidence that free access exists. Excluded features are listed in PRS section 20.

## 8. Long-term product direction

- Full BYOK and managed model access with policy-based, then adaptive, model routing.
- Code-execution sandboxes, then an authenticated local runner for hybrid execution.
- External agents through an interoperability protocol, treated as untrusted by default.
- Persistent project memory with richer retrieval.
- Team workspaces, approval gates, billing and plans.
- Enterprise readiness (SSO, dedicated deployment, compliance) as a later option; the design must not preclude it.

## 9. Current status

Phase 0, task P0.1. See `docs/PROJECT_STATE.md`. Nothing is implemented. No technical claim has been validated. P0.1 has been remediated and awaits founder approval; the next task after explicit approval is P0.2, which is not yet approved or started.
