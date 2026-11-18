# Collective - Product Requirements Specification (PRS)

| Field | Value |
|---|---|
| Document ID | DOC-PRS |
| Version | 0.1 (remediated draft) |
| Phase / task | Phase 0 / P0.1 |
| Status | REMEDIATED DRAFT - pending founder approval. Not yet approved. |
| Last updated | 2026-11-18 |
| Supersedes | None (first version) |
| Authority | Product requirements. Architecture belongs to P0.2 and later; this document does not select technologies. |

## 0. How to read this document

**Status labels.** Every statement is one of:

- **[DECISION]** - confirmed by the founder. Changing it needs founder approval.
- **[ASSUMPTION]** - believed true, not yet validated. Listed in section 22 with an ID (ASM-nnn).
- **[RECOMMENDATION]** - the author's proposal. Not binding until approved.

Nothing in this document has been technically validated. No implementation, test or benchmark exists. Technology names appear only as **candidates**.

**Priority definitions.**

| Priority | Meaning |
|---|---|
| P0 | Essential for the initial working product (the MVP). |
| P1 | Important for a complete initial (public) release. |
| P2 | Valuable subsequent enhancement. |
| P3 | Future consideration. No design effort now beyond not blocking it. |

**Categories.** Functional, Non-functional, Security, Infrastructure, Commercial.

**ID scheme.** `FR` functional, `NFR` non-functional, `RBAC` roles and permissions, `AGT` agents, `PTM` project/task management, `MDL` models and providers, `COL` collaboration, `MEM` memory, `EXE` execution, `VER` verification, `SEC` security, `OBS` observability and cost, `SAAS` commercial, `AC` acceptance, `ASM` assumption, `OQ` open question, `RSK` risk, `EX` exclusion, `UC` use case, `CP` principle. IDs are permanent. A retired requirement keeps its ID and is marked withdrawn.

**Provisional targets.** Numeric targets marked *(prov.)* are placeholders chosen by the author to make the requirement testable. They must be confirmed or replaced by the founder.

## 1. Product overview

Collective is a public SaaS platform in which a user states an **objective** and Collective organises a **workforce** of specialised AI agents to achieve it. Agents are coordinated, run on any supported AI model provider, share permitted context, communicate through structured messages, and have their output independently verified before a completion report is returned.

The user manages outcomes. The user does not manually relay prompts and context between separate AI chats.

Core loop: **Objective -> Plan -> Delegated tasks -> Collaboration -> Verification -> Completion report.**

## 2. Problem statement

Users who rely on AI today typically face these problems:

1. **The user is the integration layer.** Useful work needs several steps and specialties, so the user copies context between chats, tools and models.
2. **Context is fragmented.** Each conversation starts from a partial picture. Project knowledge is not shared or persistent across them.
3. **Single-model dependence.** Quality, price, speed and availability differ by model and change over time. Users cannot easily use the right model for each step.
4. **No independent check.** The model that produced a result usually also judges it. Errors pass unnoticed.
5. **Autonomy is all-or-nothing.** Tools are either manual or run with broad, hard-to-bound authority.
6. **Cost is opaque.** Multi-step AI work can consume spend without clear limits or attribution.

## 3. Product vision and positioning

**Tagline [DECISION]:** "One objective. An entire AI workforce."

**Vision.** Any legitimate objective, in any domain, can be handed to Collective and delivered as a verified outcome, with the human controlling goals, permissions and budgets rather than prompts.

**Positioning.**

- Not a chatbot: the unit of work is an objective, not a message.
- Not a single-domain coding agent: software engineering is one use case among several.
- Not a model vendor: Collective is provider-neutral and never ties a role to one model.
- Differentiators: model-independent roles; managed and bring-your-own-key access; independent verification; permission-bounded autonomy; persistent project memory; cost controls.

## 4. Target users and use cases

### 4.1 User segments

| Segment | Description | Release focus |
|---|---|---|
| Solo builder / founder | Delegates research, planning, writing, engineering tasks | MVP |
| Researcher / analyst | Multi-source research and structured reports | MVP |
| Small business operator | Business operations workflows with bounded permissions | P1 |
| Personal productivity user | Planning, organising, drafting | P1 |
| Team / organisation | Shared workspaces, governance, enterprise needs | P2 and later |

### 4.2 Use cases

| ID | Domain | Example objective | Needs beyond model calls | Target |
|---|---|---|---|---|
| UC-01 | Research | "Produce a sourced brief comparing X and Y for decision Z." | Web retrieval (MCP candidate) | MVP reference candidate |
| UC-02 | Business operations | "Draft an onboarding process and supporting templates." | Document artifacts | P1 |
| UC-03 | Software engineering | "Add feature F to this repository and open a pull request." | Code sandbox, repository access, tests | P1/P2 |
| UC-04 | Personal productivity | "Plan my month around these commitments." | Calendar/data connectors | P2 |
| UC-05 | Strategy | "Evaluate three market-entry options with risks." | Research, critique | MVP-compatible |
| UC-06 | Local workflows | "Reorganise the files in this folder." | Local runner | P2 |

**[RECOMMENDATION]** OQ-001 remains open because UC-01's sourced brief requires retrieval and source attribution, while UC-05 can be demonstrated using supplied or otherwise available information. Option B is more feasible under the initial ₦0 constraint, but no scenario is approved yet.

## 5. Core product principles

| ID | Principle | Consequence |
|---|---|---|
| CP-1 | Outcomes over conversations | Primary UI and data model centre on objectives, tasks and deliverables. |
| CP-2 | Model independence | Roles are defined by capability needs, never by a named model. |
| CP-3 | Autonomy within permissions | Agents act without per-step prompting but only inside explicit, enforceable policy. |
| CP-4 | Independent verification | Production and verification are separated, preferably across different models. |
| CP-5 | Transparency | Every agent action, message, cost and decision is inspectable. |
| CP-6 | Bounded by default | Every run has enforced limits on cost, steps and time. |
| CP-7 | Provider neutrality | No hard dependency on a single provider, protocol or vendor feature. |
| CP-8 | Simplicity first | The smallest design that satisfies the requirement; no speculative infrastructure. |

## 6. Functional requirements (user-facing capabilities)

| ID | Requirement | Pri | Cat | Acceptance criterion |
|---|---|---|---|---|
| FR-001 | A user can submit a free-text objective to create a run in a project. | P0 | Functional | Submission creates a persisted run in state `queued` and returns its ID in a single request. |
| FR-002 | The system generates a task plan from the objective and shows it to the user. | P0 | Functional | For a submitted objective, the plan (tasks, roles, dependencies) is visible in the UI before or during execution. |
| FR-003 | The user can watch run progress: task states, active agent, and message timeline. | P0 | Functional | Task state changes appear in the UI within 10 s *(prov.)* of occurring, by push or refresh. |
| FR-004 | The user can cancel a run. | P0 | Functional | After cancel, no new model call starts for that run; in-flight calls complete or abort; run state becomes `cancelled` within 30 s *(prov.)*. |
| FR-005 | A run continues to execute when the user closes the browser. | P0 | Functional | Closing the client mid-run, then reopening, shows the run progressed or completed. |
| FR-006 | The user can read the completion report and the deliverables in the UI. | P0 | Functional | The report defined in VER-007 and every deliverable are viewable; text deliverables are downloadable as Markdown. |
| FR-007 | The user can choose autonomy mode per run: fully autonomous within policy, or approval required before plan execution. | P1 | Functional | In approval mode, no task starts until the user approves the plan. |
| FR-008 | The user can pause and resume a run. | P1 | Functional | Paused run starts no new work; resume continues from the last completed task. |
| FR-009 | The system can ask the user clarifying questions before planning when the objective is ambiguous. | P1 | Functional | Max 3 questions *(prov.)*; the run proceeds on answers or stated assumptions. |
| FR-010 | The user can attach files or reference material to an objective. | P1 | Functional | Supported file types and size limits are documented; attached content is available to permitted agents. |
| FR-011 | The user can start a follow-up objective in the same project that reuses project memory. | P1 | Functional | A second run can reference outcomes of the first without re-pasting them (see MEM-002). |
| FR-012 | The user can provide instructions to a run in progress. | P2 | Functional | Instruction is delivered to the Director and recorded in the trace. |
| FR-013 | The user receives notification on completion or when blocked. | P2 | Functional | Notification sent via at least one channel within 60 s *(prov.)* of state change. |
| FR-014 | Objective templates for common workflows. | P2 | Functional | At least 5 templates *(prov.)* selectable at submission. |

## 7. Non-functional requirements

| ID | Requirement | Pri | Cat | Acceptance criterion |
|---|---|---|---|---|
| NFR-001 | **Durability.** Accepted runs survive backend or worker restart and resume from the last durable checkpoint without re-running completed tasks. | P0 | Non-functional | Test: terminate the worker mid-run. The run resumes and completes; the trace shows no duplicate committed outputs and no invalid state transition. Delivery may be repeated; completion is made idempotent. |
| NFR-002 | **Cloud-only developability.** Build, test and deploy are possible with no local computer, through GitHub and cloud CI/CD. | P0 | Infrastructure | A change committed from a mobile device triggers automated checks and a preview or staging deployment with no local step. |
| NFR-003 | **Cost ceiling for infrastructure.** Fixed monthly infrastructure cost is documented and kept within the founder-confirmed initial ceiling of ₦0. | P0 | Infrastructure | Cost table exists and initial platform infrastructure cost is ₦0; any later change requires an explicit founder decision. |
| NFR-004 | **Reproducible environments.** Dependencies pinned; the same commit yields the same build. | P1 | Infrastructure | Rebuild of a tagged commit produces identical dependency versions (lock files committed). |
| NFR-005 | **API latency (non-model endpoints).** | P1 | Non-functional | p95 under 500 ms *(prov.)* at 20 concurrent users *(prov.)* in a load test. |
| NFR-006 | **Concurrency.** The platform runs multiple runs concurrently. | P1 | Non-functional | At least 5 concurrent runs *(prov.)* complete without cross-run interference in a test. |
| NFR-007 | **Testability.** Model and tool calls can be replaced by recorded or scripted fixtures so orchestration logic is testable without live providers. | P1 | Non-functional | Core orchestration test suite runs in CI with zero live provider calls. |
| NFR-008 | **Responsive web UI.** Core flows are usable on a 360 px wide viewport. | P1 | Non-functional | Objective submission, run view and report view pass a manual check at 360 px. |
| NFR-009 | **Browser support.** Latest two stable versions of Chrome, Safari, Firefox, Edge; Chrome on Android. | P1 | Non-functional | Manual smoke test on listed browsers before public release. |
| NFR-010 | **API contract documentation.** All public API endpoints have a machine-readable contract. | P1 | Non-functional | Contract generated from code and published for every endpoint. |
| NFR-011 | **Availability.** | P2 | Non-functional | Monthly availability of 99.5 % *(prov.)* measured after public launch. |
| NFR-012 | **Localisation.** UI strings externalised for translation. | P3 | Non-functional | Not applicable until scheduled. |

## 8. User roles and permissions

### 8.1 Roles

- **Owner** - full control of a workspace, billing, members, keys.
- **Admin** - manages members, projects, policies; no billing ownership change.
- **Member** - creates and runs projects within granted policy.
- **Viewer** - read-only.
- **Platform operator** - Collective staff; manages the service, not user data by default.

### 8.2 Autonomy levels

| Level | Meaning |
|---|---|
| A0 | Suggest only; no actions executed. |
| A1 | Agents act; irreversible or external-effect actions need user approval. |
| A2 | Agents act autonomously within policy, including external-effect actions that the policy allows. |

**[RECOMMENDATION]** The MVP supports only side-effect-free actions (model calls, reading, drafting), so A2 is safe there. A1 gating is required before any external-effect tool ships.

| ID | Requirement | Pri | Cat | Acceptance criterion |
|---|---|---|---|---|
| RBAC-001 | Only authenticated users can access the product; unauthenticated requests are denied. | P0 | Security | Automated test: every non-public endpoint returns an authorisation failure without a valid session. |
| RBAC-002 | Every project, run and artifact belongs to a workspace; all access is workspace-scoped, even when a workspace has one user. | P0 | Functional | Data model review confirms no project-level entity lacks a workspace reference. |
| RBAC-003 | A run-level policy defines: allowed tools, maximum cost, maximum steps, maximum wall-clock time. | P0 | Security | Run creation fails without a policy or default; test shows each limit is enforced. |
| RBAC-004 | Roles Owner, Admin, Member, Viewer with a documented permission matrix. | P1 | Security | Matrix published; tests verify each role cannot exceed its permissions. |
| RBAC-005 | Per-agent policies: tool access, data scopes, side-effect classes. | P1 | Security | An agent without a tool in its policy cannot invoke it (negative test). |
| RBAC-006 | Approval gates (A1) for actions classified irreversible or external. | P1 | Security | Test: gated action stays pending until approved; denial cancels it and is logged. |
| RBAC-007 | Operator console: suspend accounts, view usage, without default access to user content. | P1 | Security | Operator can suspend a user; content access requires a logged, explicit action. |
| RBAC-008 | Invite members to a workspace. | P2 | Functional | Invitee gains only the assigned role. |

## 9. Agent workforce requirements

| ID | Requirement | Pri | Cat | Acceptance criterion |
|---|---|---|---|---|
| AGT-001 | A **role** is defined by purpose, instructions, allowed tools, output contract and required model capabilities. A role contains no hard-coded provider or model. | P0 | Functional | Automated check fails if any role definition names a provider or model identifier. |
| AGT-002 | MVP role set: Director/Planner, at least two specialist roles, and Critic/Verifier. | P0 | Functional | The reference scenario executes using at least four distinct role instances. |
| AGT-003 | The Director decomposes an objective into tasks with dependencies, assigned roles and acceptance criteria per task. | P0 | Functional | Plan output validates against the plan schema; dependencies form an acyclic graph. |
| AGT-004 | Agent outputs conform to a declared schema; invalid output triggers a bounded retry, then task failure. | P0 | Functional | Test with malformed output: exactly the configured retry count occurs, then `failed`. |
| AGT-005 | Each agent invocation records agent ID, role, provider, model and prompt version. | P0 | Non-functional | Every trace entry contains these four fields. |
| AGT-006 | Every agent loop and run has enforced termination limits (iterations, steps, time, cost). | P0 | Security | Test: a deliberately non-terminating loop is stopped at the limit and the run reports why. |
| AGT-007 | Extended role library (for example Engineer, Strategist, Operator, Data Analyst). | P1 | Functional | Each added role has a definition passing AGT-001 and an evaluation example. |
| AGT-008 | Users can define custom roles. | P2 | Functional | Custom role validates against AGT-001 and respects workspace policy. |
| AGT-009 | The Director can propose new roles or specialists during a run. | P2 | Functional | Proposed role requires policy check before use. |
| AGT-010 | External agents can be registered and used as workforce members; treated as untrusted by default. | P2 | Functional | An external agent receives only data its policy permits; its outputs go through verification. |

## 10. Project and task management requirements

| ID | Requirement | Pri | Cat | Acceptance criterion |
|---|---|---|---|---|
| PTM-001 | A **project** is a persistent container for objectives, runs, artifacts and memory. | P0 | Functional | Project survives sessions; runs and artifacts are retrievable by project ID. |
| PTM-002 | Tasks follow a defined state machine: `pending`, `ready`, `running`, `blocked`, `in_review`, `done`, `failed`, `cancelled`. Transitions are timestamped and recorded. | P0 | Functional | Illegal transitions are rejected in tests; each transition appears in the trace. |
| PTM-003 | A task starts only when all its dependencies are `done`. | P0 | Functional | Test: a dependent task never starts before its prerequisite completes. |
| PTM-004 | Failed tasks follow a retry policy and then escalate to the Director. | P0 | Functional | After max retries, the Director receives an escalation message and re-plans or fails the run. |
| PTM-005 | Independent tasks may execute in parallel. | P1 | Functional | Two independent tasks overlap in time in a test run. |
| PTM-006 | The Director may revise the plan during a run; plan versions are retained. | P1 | Functional | A blocker triggers a new plan version; the previous version remains viewable. |
| PTM-007 | A project may hold multiple objectives and runs. | P1 | Functional | A project lists all runs with status and cost. |
| PTM-008 | Projects can be archived and deleted (see SEC-009 for data deletion). | P1 | Functional | Archived projects are read-only; deleted projects are unrecoverable by users. |
| PTM-009 | Scheduled or recurring runs. | P3 | Functional | Not applicable until scheduled. |

**[RECOMMENDATION]** MVP runs tasks sequentially (PTM-005 deferred) to reduce concurrency complexity. See ASM-012.

## 11. Multi-model and provider requirements

| ID | Requirement | Pri | Cat | Acceptance criterion |
|---|---|---|---|---|
| MDL-001 | A provider-neutral internal contract covers messages, tool calls, structured output requests, streaming (if used) and usage reporting. | P0 | Infrastructure | The same role runs on two provider adapters with zero role-level code changes. |
| MDL-002 | At least two independent AI providers are integrated through adapters. | P0 | Infrastructure | A single run's trace shows calls to at least two providers. |
| MDL-003 | A model registry holds capability and price metadata (context limit, structured-output support, tool-use support, price, status) as data, not code. | P1 | Infrastructure | Adding a model entry requires no code change to roles or orchestration. |
| MDL-004 | Role-to-model assignment is configuration. | P0 | Functional | Changing a role's assigned model changes the model used in the next run with no deployment. |
| MDL-005 | Provider errors trigger bounded retry with backoff. | P0 | Non-functional | Simulated provider error: retry count and backoff observed; run fails cleanly if exhausted. |
| MDL-006 | Per-call usage capture: tokens, estimated cost, latency, model, provider. | P0 | Functional | 100 % of model calls in a test run have a usage record. |
| MDL-007 | Managed access: the platform may hold provider keys and meter usage per workspace, subject to an approved funding model. | P1 | Commercial | In a later managed-access release, invited users can run without supplying a key and usage is attributed per workspace. |
| MDL-008 | Bring your own key: users supply provider keys; keys are validated on save and never shown again. | P1 | Security | Key is stored encrypted; API never returns it; a run uses it when configured. |
| MDL-009 | Fallback to an alternate model when the assigned model is unavailable. | P1 | Non-functional | With provider A disabled in test, the task completes using the configured alternate. |
| MDL-010 | Policy-based role-to-model routing using capability, reliability, cost, speed and context limits. | P1 | Functional | Given a task requirement set, the router selects deterministically and logs its reasoning inputs. |
| MDL-011 | Provider rate-limit and quota handling. | P1 | Non-functional | Rate-limit responses cause throttling, not run failure, within retry limits. |
| MDL-012 | Adaptive routing based on measured outcomes. | P2 | Functional | Routing changes are justified by recorded quality, cost and latency data. |
| MDL-013 | Model deprecation tracking and alerts. | P2 | Non-functional | Registry status flag triggers an alert when a used model is marked deprecated. |
| MDL-014 | Self-hosted or local models via a standard endpoint. | P2 | Infrastructure | A local endpoint is usable through the same contract (MDL-001). |

**Note.** Managed access and BYOK remain confirmed long-term product capabilities. Their MVP sequencing is unresolved (OQ-002). The founder's initial ₦0 budget means managed access cannot be assumed to be free; BYOK may shift provider charges to the key owner but is also not inherently free.

## 12. Agent collaboration requirements

| ID | Requirement | Pri | Cat | Acceptance criterion |
|---|---|---|---|---|
| COL-001 | Agents communicate through a structured message envelope: ID, run, task, sender, recipient, type, schema-validated payload, references. Messages are persisted. | P0 | Functional | Every inter-agent exchange in a run exists as a stored message validating against the envelope schema. |
| COL-002 | Outputs of upstream tasks reach downstream agents automatically. | P0 | Functional | In the reference run, the user performs zero manual copy or paste operations between agents. |
| COL-003 | Agents see only context allowed to them by policy (MVP: task-scoped; P1: fine-grained). | P0 | Security | Test: an agent denied a context item cannot retrieve it through any message path. |
| COL-004 | Critic objections trigger a bounded revision loop (default 2 rounds *(prov.)*); unresolved objections go to the Director, then to the user. | P0 | Functional | Test with a seeded flawed deliverable: objection, revision, re-verification occur; unresolved case escalates. |
| COL-005 | The user can read the full message log of a run. | P0 | Functional | Log shows all messages in order with sender, recipient and type. |
| COL-006 | Agents can request clarification from the Director or the user. | P1 | Functional | Clarification request pauses the dependent task and resumes on answer. |
| COL-007 | Peer-to-peer conflict resolution between specialists (competing proposals). | P1 | Functional | Conflicting outputs are surfaced and resolved by a defined protocol, with outcome recorded. |
| COL-008 | Detection of repeated or circular message patterns. | P1 | Non-functional | Seeded ping-pong loop is detected and halted before AGT-006 limits. |
| COL-009 | Multi-agent debate or ensemble voting for high-stakes tasks. | P2 | Functional | Configurable per task; vote results recorded. |

## 13. Memory and knowledge requirements

| ID | Requirement | Pri | Cat | Acceptance criterion |
|---|---|---|---|---|
| MEM-001 | A task-scoped context store holds intermediate results and artifacts for a run. | P0 | Functional | Artifacts produced by a task are retrievable by authorised downstream tasks and by the user. |
| MEM-002 | Project memory persists facts, decisions and artifacts across runs in a project. | P1 | Functional | A later run in the same project can use an earlier run's verified outputs without re-input. |
| MEM-003 | Each memory entry records provenance: source agent, run, time, verification status. | P1 | Functional | Every entry exposes these fields in the UI or API. |
| MEM-004 | Memory scopes (workspace, project, run, role-private) enforced server-side. | P1 | Security | Cross-scope access tests all denied. |
| MEM-005 | Users can view, edit and delete memory entries. | P1 | Functional | Deleted entries are not retrievable by any agent afterward. |
| MEM-006 | Context-window management: when assembled context exceeds a model limit, content is compacted or selected by a defined rule and the action is recorded. | P1 | Functional | Oversized context test: no provider limit error; trace shows what was reduced. |
| MEM-007 | Retrieval by keyword and structure. | P1 | Functional | Query returns relevant entries in a fixed test corpus with documented precision. |
| MEM-008 | Semantic (embedding-based) retrieval. Requires an ADR justifying added complexity. | P2 | Infrastructure | Demonstrated retrieval gain over MEM-007 on a test corpus. |
| MEM-009 | User knowledge-base uploads available to projects. | P2 | Functional | Uploaded documents are indexed and retrievable within permissions. |
| MEM-010 | Cross-project, user-level memory. | P3 | Functional | Not applicable until scheduled. |

## 14. Cloud and local execution requirements

| ID | Requirement | Pri | Cat | Acceptance criterion |
|---|---|---|---|---|
| EXE-001 | Runs execute in backend workers independent of any client session. | P0 | Infrastructure | See FR-005. |
| EXE-002 | Work is dispatched through a durable queue with at-least-once delivery; task execution is idempotent. | P0 | Infrastructure | Test: duplicate delivery of a task message is tolerated, does not create duplicate committed outputs or double usage accounting, and cannot cause invalid state transitions. Exactly-once execution is not promised. |
| EXE-003 | **MVP performs no code execution and no external side effects.** | P0 | Security | Review of MVP tool list confirms none can execute code or change external state. |
| EXE-004 | Any code-execution capability runs in an isolated sandbox: no access to platform secrets, restricted network egress, CPU, memory and time limits, destroyed after use. | P1 | Security | Sandbox test suite: secret access, unrestricted egress and resource exhaustion attempts all fail. |
| EXE-005 | Per-workspace concurrency limits. | P1 | Infrastructure | Limit enforced; excess runs queue. |
| EXE-006 | Run artifacts larger than text records are stored in object storage with size limits and metadata. | P1 | Infrastructure | Upload over limit rejected; stored artifact is retrievable by authorised users only. |
| EXE-007 | **Local runner:** authenticated, device-bound, outbound-only connection, user-approved capability scopes, revocable. | P2 | Security | Revoking a runner stops task dispatch within 60 s *(prov.)*; out-of-scope requests are rejected. |
| EXE-008 | Task placement policy chooses cloud or local based on declared task needs. | P2 | Functional | A task needing local resources is never placed in the cloud and vice versa. |

**Note.** Hybrid cloud/local remains a confirmed direction [DECISION]. EXE-007 is P2 because the founder has no local development machine and the MVP proof does not need local access. This is a sequencing recommendation, not a withdrawal.

## 15. Verification and quality assurance requirements

| ID | Requirement | Pri | Cat | Acceptance criterion |
|---|---|---|---|---|
| VER-001 | Every task carries acceptance criteria created at planning time. | P0 | Functional | Plan validation rejects tasks without criteria. |
| VER-002 | **Independent verification:** the Verifier is a distinct agent instance that receives the deliverable and criteria, not the producer's private reasoning. | P0 | Functional | Verifier input contains no producer-internal reasoning (checked in trace). |
| VER-003 | **Model diversity:** when at least two models are available, the verifier uses a different model from the producer, preferably from a different provider. | P0 | Functional | In the reference run, at least one deliverable is verified by a different provider than its producer. |
| VER-004 | Verdict schema: pass, partial, fail; per-criterion evidence; severity. | P0 | Functional | Verdicts validate against the schema; fail verdicts name the failed criteria. |
| VER-005 | Failed verification triggers the bounded revision loop (COL-004). | P0 | Functional | See COL-004. |
| VER-006 | Final check of the overall result against the original objective, not only task criteria. | P0 | Functional | Report includes an objective-level verdict with justification. |
| VER-007 | **Completion report** contains: objective, outcome (achieved, partially, not achieved), task summary, deliverables, verification results including failures and unresolved issues, providers and models used, cost, duration, known limitations. | P0 | Functional | A report for the reference run contains every listed field. |
| VER-008 | Deterministic checks where possible (schema, links exist, tests pass) in addition to model-based review. | P1 | Functional | At least one deterministic check type runs in the reference scenario. |
| VER-009 | Factual claims in research deliverables are linked to sources or flagged unsupported. | P1 | Functional | Sampled claims: each has a source link or an explicit unsupported flag. |
| VER-010 | **Verifier calibration:** a labelled set of known-good and known-flawed outputs measures verifier false-pass and false-fail rates. No accuracy claim is made without this measurement. | P1 | Non-functional | Calibration report exists with sample size and rates. |
| VER-011 | User can accept or reject deliverables; feedback is stored. | P1 | Functional | Rejection starts a revision run with feedback attached. |

## 16. Security and governance requirements

| ID | Requirement | Pri | Cat | Acceptance criterion |
|---|---|---|---|---|
| SEC-001 | Authentication through a managed identity service; sessions expire. | P0 | Security | Expired session is rejected; credentials are never stored by Collective in plain text. |
| SEC-002 | Tenant isolation enforced at the data layer, not only in application code. | P0 | Security | Automated cross-tenant read and write attempts are all denied. |
| SEC-003 | Provider keys (platform and user) are encrypted at rest, never logged, never sent to the client. | P0 | Security | Log and API response scans show no key material. |
| SEC-004 | Content from tools, files and the web is untrusted data and cannot alter permissions, policy or system instructions. | P0 | Security | Design review confirms separation; see SEC-005 for tests. |
| SEC-005 | A prompt-injection test set exists; results are recorded per release. | P1 | Security | Test set of at least 25 cases *(prov.)* with pass/fail record. |
| SEC-006 | Least-privilege tool access: an agent can invoke only tools in its policy. | P0 | Security | Negative test: unlisted tool call is rejected and logged. |
| SEC-007 | Append-only audit record of agent actions, tool calls, permission decisions and approvals. | P0 | Security | Records cannot be modified by application roles; run replay of actions possible from the log. |
| SEC-008 | Rate limiting and abuse controls on public endpoints. | P1 | Security | Load test: excess requests throttled. |
| SEC-009 | Data deletion and export: account deletion removes user content within 30 days *(prov.)*; users can export their data. | P1 | Security | Deletion test confirms removal from primary storage; export contains all user projects. |
| SEC-010 | Data-handling disclosure: users are told which providers process their data; user data is not used for training by Collective. Provider terms are reviewed. | P1 | Security | Published disclosure; provider terms review recorded. |
| SEC-011 | Dependency pinning and automated vulnerability alerts. | P1 | Security | Alerts enabled on the repository; no unresolved critical advisories at release. |
| SEC-012 | Acceptable-use policy and enforcement path for non-legitimate workflows. | P1 | Security | Policy published; operator can suspend (RBAC-007). |
| SEC-013 | Multi-factor authentication. | P2 | Security | Optional MFA enrolment works. |
| SEC-014 | Enterprise compliance programmes (for example SOC 2). | P3 | Security | Not applicable until scheduled. |

**Legal note.** Data-protection obligations depend on user locations (for example Nigeria and other jurisdictions). Legal review is required before public launch. This document is not legal advice. See OQ-007.

## 17. Monitoring, observability and cost management

| ID | Requirement | Pri | Cat | Acceptance criterion |
|---|---|---|---|---|
| OBS-001 | Per-run trace: every model call, tool call and message with timestamps, latency, tokens, cost. | P0 | Non-functional | For the reference run, the trace reconstructs the full sequence of events. |
| OBS-002 | Hard run budget: when the estimated spend reaches the cap, the run halts gracefully and reports status. | P0 | Functional | Test with a low cap: spend exceeds the cap by no more than one in-flight model call. |
| OBS-003 | Run cost and duration shown to the user in the report. | P0 | Functional | Report fields match the sum of per-call usage records. |
| OBS-004 | Workspace usage view by period, role, model and provider. | P1 | Functional | Totals reconcile with per-call records. |
| OBS-005 | Budget threshold alerts at 80 % *(prov.)* of run or period caps. | P1 | Functional | Alert emitted when threshold crossed in test. |
| OBS-006 | Pre-run cost estimate range. | P1 | Functional | Actual cost falls within the estimate in at least 70 % *(prov.)* of evaluation runs. |
| OBS-007 | Structured application logs and error tracking with run IDs. | P1 | Non-functional | A failure is traceable from error report to run ID. |
| OBS-008 | Provider health and latency metrics. | P1 | Non-functional | Dashboard or query shows per-provider error rate and latency. |
| OBS-009 | Run replay from trace for debugging. | P2 | Non-functional | A recorded run can be replayed with fixtures (see NFR-007). |
| OBS-010 | Product analytics (funnel, retention). | P2 | Commercial | Events captured without storing user content. |

## 18. SaaS and commercial requirements

| ID | Requirement | Pri | Cat | Acceptance criterion |
|---|---|---|---|---|
| SAAS-001 | MVP access is invite-only (allowlist). | P0 | Commercial | Non-invited email cannot create an account. |
| SAAS-002 | Public sign-up. | P1 | Commercial | Any eligible user can register, subject to SEC-008. |
| SAAS-003 | Plans with usage entitlements (for example free tier, paid tier, usage credits). | P1 | Commercial | Entitlements enforced at run creation. |
| SAAS-004 | Billing through a payment provider that supports the founder's jurisdiction and target user markets. Provider choice is unresolved. | P1 | Commercial | Successful test payment and entitlement change end to end. |
| SAAS-005 | Usage ledger attributing cost to workspace, run, role and model. | P1 | Commercial | Ledger reconciles with provider usage records. |
| SAAS-006 | Pricing for managed access covers provider cost plus overhead. | P1 | Commercial | Margin report per plan shows non-negative margin on the evaluation workload. |
| SAAS-007 | Terms of service and privacy policy published before public sign-up. | P1 | Commercial | Documents live and linked at registration. |
| SAAS-008 | Landing page and waitlist. | P1 | Commercial | Waitlist sign-ups stored. |
| SAAS-009 | Enterprise readiness (SSO, dedicated deployment, data-processing agreements). Design must not preclude it. | P3 | Commercial | Not applicable until scheduled. |
| SAAS-010 | Marketplace for roles, templates or external agents. | P3 | Commercial | Not applicable until scheduled. |

## 19. MVP scope

### 19.1 MVP objective

Prove the central proposition: **one objective, handed to Collective, produces a verified outcome through coordinating agents on more than one AI provider, with no manual transfer of prompts or context by the user.**

**Critical unresolved feasibility dependency [ASSUMPTION]:** MDL-002 requires at least two independent AI providers. The initial budget is ₦0, BYOK is excluded from the proposed MVP, and no genuinely free managed-access solution has been validated. P0.2 must establish whether two genuinely free providers can support the proposed MVP. If it cannot establish this, the founder must decide whether to revise the MVP proof; paid access must not be introduced silently.

### 19.2 Assessment of the proposed proof

| Proof step | Maps to | Assessment |
|---|---|---|
| 1. User submits one objective | FR-001 | Sound. |
| 2. Director decomposes into tasks | AGT-003, PTM-002..004 | Sound. Needs plan schema validation. |
| 3. At least two specialists collaborate | AGT-002, COL-001..004 | Needs sharpening: a linear pipeline is not collaboration. Require at least one exchange beyond hand-off (critique, revision or clarification). |
| 4. At least two AI providers used | MDL-001..004 | Sound. Meaningful only if the providers play different roles. |
| 5. Structured messages and shared permitted context | COL-001, COL-003, MEM-001 | Sound. |
| 6. Independent Critic/Verifier | VER-001..006 | Sound. Independence defined in VER-002 and VER-003. |
| 7. Completion report | VER-007 | Sound. |
| 8. No manual transfer | COL-002 | Sound. Measurable by observation. |

**Gaps in the proposed proof (added by this specification):**

1. **Cost and termination controls** (OBS-002, AGT-006, FR-004). Without them an MVP run can spend without limit.
2. **Durability** (NFR-001, EXE-002). Agent runs are long; restarts are expected on low-cost hosting (ASM-002).
3. **Tenant isolation basics** (SEC-002). Even invite-only, user data must not mix.
4. **Evidence of value.** The eight steps prove the mechanism works, not that it is better than one model in one prompt. See MVP-EVAL.

### 19.3 Smallest implementation that proves the proposition **[RECOMMENDATION]**

- One reference scenario, selected through OQ-001. **Option A:** sourced research, which requires retrieval and source attribution. **Option B:** planning/synthesis using supplied or otherwise available information, without promising live sourced research.
- Roles: Director, at least two specialists, and Critic. Specialists use different providers where access is available; Critic uses a provider different from the deliverable's producer where available.
- Sequential task execution; one worker; durable state; no code execution; no external side effects (EXE-003).
- Retrieval is required only if Option A is approved; otherwise supplied or otherwise available information is sufficient for the proof.
- Invite-only; hard run budget; BYOK is excluded from the proposed MVP. No free managed-access solution has been validated, so P0.2 must establish whether two genuinely free providers can support the proof. No paid access is assumed or may be introduced silently.
- Minimal UI: objective form, plan view, run timeline and message log, report view.
- No billing, no BYOK, no local runner, no external agents, no semantic memory.

### 19.4 MVP evaluation requirement

| ID | Requirement | Pri | Cat | Acceptance criterion |
|---|---|---|---|---|
| MVP-EVAL-001 | Run the reference scenario on at least 10 distinct objectives *(prov.)* and record completion, cost, duration and verifier outcomes. | P0 | Functional | Results table exists; no figures are fabricated; failures are included. |
| MVP-EVAL-002 | Compare each deliverable against a single-model single-prompt baseline using a blind human rating on a fixed rubric. | P0 | Functional | Rubric and ratings stored; summary states whether Collective was rated better, equal or worse. This is a manual activity, not a feature. |
| MVP-EVAL-003 | MVP success threshold: at least 8 of 10 runs *(prov.)* complete without human intervention, within budget. | P0 | Functional | Threshold met or the shortfall is documented. |

### 19.5 MVP requirement summary

MVP = all **retained P0** requirements in this document. After remediation there are 56 P0 requirements, 61 P1, 19 P2 and 6 P3 requirements. MDL-003 and MDL-007 were moved to P1 because they are not essential to the minimum proof and MDL-007 would otherwise imply funded managed access inconsistent with the initial ₦0 constraint. Nothing else is MVP unless the founder promotes it.

## 20. Explicitly excluded features

| ID | Excluded from MVP | Reason | Earliest target |
|---|---|---|---|
| EX-001 | Code execution and sandboxes | Security cost; not needed for the proof | P1 |
| EX-002 | Local runner and local execution | No local test environment; not needed for the proof | P2 |
| EX-003 | External agents (A2A) | Needs stable protocol and trust model | P2 |
| EX-004 | BYOK as a required MVP capability | Access sequencing remains unresolved; user-paid BYOK is not equivalent to free managed access (OQ-002) | P1 |
| EX-005 | Billing and plans | Invite-only MVP | P1 |
| EX-006 | Actions with external side effects (sending messages, payments, deployments) | Requires A1 approval gates | P1 |
| EX-007 | Team collaboration and role matrix beyond Owner | Single-user workspaces suffice | P1 |
| EX-008 | Semantic memory and knowledge-base uploads | Adds infrastructure | P2 |
| EX-009 | User-defined roles and dynamic role creation | Needs governance | P2 |
| EX-010 | Parallel task execution | Complexity | P1 |
| EX-011 | Native mobile apps | Responsive web first | P3 |
| EX-012 | Enterprise SSO, on-premises or dedicated deployment | Future enterprise | P3 |
| EX-013 | Marketplace | Future | P3 |
| EX-014 | Voice interfaces, model fine-tuning, training own models | Out of product scope | Not planned |

## 21. Acceptance criteria (system level)

None of these has been validated. No implementation exists.

| ID | Criterion | Validates | Status |
|---|---|---|---|
| AC-001 | A user submits one objective and receives a completion report with no manual relay of prompts or context. | FR-001, COL-002, VER-007 | Not validated |
| AC-002 | The trace of the reference run shows at least two providers and at least four distinct agent instances. | MDL-002, AGT-002 | Not validated |
| AC-003 | At least one deliverable is verified by a different provider than its producer, and a seeded flawed deliverable triggers a revision loop. | VER-003, COL-004 | Not validated |
| AC-004 | A run with a low budget cap halts within the tolerance in OBS-002. | OBS-002 | Not validated |
| AC-005 | Terminating the worker mid-run does not lose the run, create duplicate committed outputs, or cause invalid state transitions. | NFR-001, EXE-002 | Not validated |
| AC-006 | Cross-tenant access attempts are denied in automated tests. | SEC-002 | Not validated |
| AC-007 | No provider or model identifier appears in any role definition. | AGT-001 | Not validated |
| AC-008 | A mobile-initiated commit passes automated checks and deploys to a preview without a local step. | NFR-002 | Not validated |
| AC-009 | MVP-EVAL-001..003 completed with honest, recorded results. | MVP-EVAL | Not validated |

## 22. Assumptions and unresolved questions

### 22.1 Assumptions (all unvalidated)

P0.2 feasibility must be evaluated at the combined-stack level, not service by service. The evaluation must cover persistent background execution, database access, authentication, quotas, resumability and provider access together. A free individual service, temporary credit or user-paid BYOK path is not evidence that the complete MVP architecture can operate within the founder's ₦0 budget.

| ID | Assumption | Impact if false | Validate in |
|---|---|---|---|
| ASM-001 | Next.js on Vercel supports the needed run-progress updates (streaming or polling) within free or low-cost limits. | UI delivery and hosting choice change. | P0.2 |
| ASM-002 | A low-cost Python host can run FastAPI plus background workers continuously; idle sleeping or request time limits do not break long runs. | Durable execution design and cost change. | P0.2 |
| ASM-003 | LangGraph (as an open-source library, not a paid platform) provides checkpointed, resumable execution compatible with the chosen database and provider neutrality. | Orchestration choice reopened. | P0.2 |
| ASM-004 | Supabase Postgres can serve as database, auth and queue at MVP scale within the cost ceiling, including connection modes needed by the orchestration library. | Data and queue choices change. | P0.2 |
| ASM-005 | MCP is mature enough for tool integration, including authentication and a Python client. | Tool layer needs a custom abstraction. | P0.2 |
| ASM-006 | A2A is mature enough for external-agent interoperability by the time it is scheduled (P2). | External-agent plan changes. | Before P2 |
| ASM-007 | At least two commercial providers' APIs are accessible and billable from the founder's location and the hosting region at acceptable cost. | Provider shortlist and MVP cost change. | P0.2 |
| ASM-008 | Provider differences in tool calling and structured output can be abstracted without losing needed features. | MDL-001 contract narrows. | P0.2 |
| ASM-009 | A cross-provider verifier reduces correlated errors compared with same-model verification. | VER-003 value in doubt. | Measured via VER-010 |
| ASM-010 | A GitHub-and-cloud-CI workflow driven from a mobile device is sufficient for all development and operations. | NFR-002 needs rework. | P0.2 |
| ASM-011 | The cost of one reference run is low enough to evaluate at least 10 runs within a budget. | MVP evaluation scope shrinks. | First reference runs |
| ASM-012 | Sequential execution gives acceptable latency for the reference scenario. | PTM-005 moves into MVP. | MVP |

### 22.2 Open questions

| ID | Question | Why it matters | Decision required | Blocks P0.2? | Provisional direction |
|---|---|---|---|---|---|
| OQ-001 | Which domain and information mode is the MVP reference scenario? | Determines retrieval, attribution, tool and evaluation scope. | Choose A: sourced research requiring retrieval, or B: planning/synthesis using supplied or otherwise available information. | Partly (tool and sandbox scope) | B is recommended for ₦0 feasibility, not approved. |
| OQ-002 | Can two genuinely free AI providers support the proposed MVP under ₦0, and what model-access decision follows if they cannot? | Drives credential storage, security, disclosure and MVP-proof feasibility. | P0.2 must evaluate genuinely free provider access; if infeasible, founder decides whether to revise the MVP proof. Paid access must not be introduced silently. | Yes (provider and credential architecture) | BYOK is excluded from the proposed MVP; no free managed-access solution has been validated. |
| OQ-003 | Which two genuinely free providers, if any, can support the MVP? | Adapter work, quotas, regional access and budget feasibility. | Select only after P0.2 establishes that two providers are genuinely free and suitable; otherwise escalate to the founder's MVP-proof decision. | No | Decide in P0.2; do not assume paid access. |
| OQ-004 | What is the monthly infrastructure and model-spend ceiling? | NFR-003 and hosting choices depend on it. | **Resolved by founder:** initial platform infrastructure budget ₦0 and initial managed AI/API budget ₦0. | Yes (hosting ADR) | P0.2 must evaluate the complete infrastructure and model-access stack together; individual free tiers do not prove the architecture works at ₦0. |
| OQ-005 | How is durable long-running execution achieved on low-cost hosting? | NFR-001 and ASM-002. | Architecture decision. | Yes | Evaluate in P0.2. |
| OQ-006 | Which payment provider works for the founder's jurisdiction and users? | SAAS-004. | Select and validate. | No (P1) | Research before P1. |
| OQ-007 | Legal posture: data protection, terms, data residency. | SEC-009, SEC-010, SAAS-007. | Obtain legal review. | No (required before public launch) | None. |
| OQ-008 | What does "full autonomy" permit? Which external-effect actions may ever run without approval? | Defines policy engine and approval gates. | Founder decision. | Partly (security architecture) | Proposed conservative defaults only: read-only external research; drafting/internal artifacts; no messages, purchases, deployments, account changes or irreversible actions without explicit approval; clear permissions and audit logs. |
| OQ-009 | Is "Collective" available as a product name, domain and trademark? | Brand risk before launch. | Search and legal check. | No | Check before public launch. |
| OQ-010 | Does the repository already contain work or conventions? | Prevents overwriting existing work. | **Resolved for the published state:** founder's Colab report described the initial empty repository; this session independently verified the published `main` state contains only the four P0.1 documents. The pre-publication state was not independently observed. | No | No application implementation found. |

### 22.3 Risks

Likelihood and impact are the author's judgement (L, M, H), not measured values.

| ID | Risk | Likelihood | Impact | Mitigating requirements |
|---|---|---|---|---|
| RSK-001 | Runaway spend from loops or large contexts | M | H | OBS-002, AGT-006, FR-004 |
| RSK-002 | Verifier gives false passes; users trust wrong results | H | H | VER-002, VER-003, VER-010, VER-009 |
| RSK-003 | Prompt injection via tool or file content | M | H | SEC-004, SEC-005, SEC-006 |
| RSK-004 | Provider outage, rate limits or API changes | H | M | MDL-005, MDL-009, MDL-011 |
| RSK-005 | Low-cost hosting cannot sustain long-running work | M | H | NFR-001, EXE-002, ASM-002 |
| RSK-006 | Scope creep from "universal" positioning | H | H | MVP scope (section 19), EX list, CP-8 |
| RSK-007 | Protocol immaturity (MCP, A2A) | M | M | ASM-005, ASM-006; adapter boundaries |
| RSK-008 | Single-founder capacity with mobile-only tooling | H | M | NFR-002, CP-8 |
| RSK-009 | Multi-agent output not better than single-model baseline | M | H | MVP-EVAL-002 |
| RSK-010 | Cross-tenant data leakage | L | H | SEC-002, AC-006 |
| RSK-011 | Regulatory and payment constraints delay public launch | M | M | OQ-006, OQ-007 |
| RSK-012 | Sandbox escape once code execution ships | L | H | EXE-004, EX-001 |

## 23. Change log

| Version | Date | Change |
|---|---|---|
| 0.1 | 2026-11-18 | First draft produced in P0.1. Not reviewed or approved. |
| 0.1-remediated | 2026-11-18 | Incorporated founder's ₦0 decision, corrected reconnaissance record, kept OQ-001/OQ-002/OQ-008 open, reviewed P0 scope (56 retained; MDL-003 and MDL-007 moved to P1), and reconciled at-least-once/idempotency semantics. Pending founder approval. |
| 0.1-targeted-corrections | 2026-11-18 | Identified MDL-002 as a critical two-provider feasibility dependency, excluded BYOK from the proposed MVP, required combined-stack ₦0 feasibility analysis, and clarified the founder approval gate for P0.2. Pending founder approval. |
