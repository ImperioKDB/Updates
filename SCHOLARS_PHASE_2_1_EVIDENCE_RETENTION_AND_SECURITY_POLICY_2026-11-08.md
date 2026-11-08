# Scholars Phase 2.1 — Evidence Retention and Security Policy

**Status:** Proposed policy; privacy/security retention periods and access roles require approval.
**Inspection basis:** Read-only Supabase metadata inspection of `scholarship-platform` (`cmdglabohpttgfofcmqc`, `eu-west-1`) on 2026-11-08, plus the checked-in `security_boundary_remediation` migration.
**Important:** No permission, RLS, schema, storage, or data changes were made. No applicant data or provider submissions were read or tested.

## 1. Purpose and security boundary

Evidence is needed to explain why a precise claim was accepted, contradicted, held, or later superseded. It is not a reason to copy entire provider websites or applicant records. Store the minimum evidence required to support the decision, keep it private by default, and return only an allowlisted public catalogue projection.

The Phase 2.1 model must distinguish:

- public opportunity/cycle facts that are approved for student display;
- source registry and capture metadata;
- minimal, source-linked claim excerpts and contradictory evidence;
- editorial review/approval and audit history;
- student profile, saved-item, notification, and application data.

These data classes must not share public API permissions merely because they are all in Supabase’s `public` schema. Prefer a non-API-exposed editorial schema for source/claim/capture/audit data, or an equivalent separately tested boundary. If a private schema is not feasible, use explicitly narrow grants, RLS, column allowlists, server-only APIs, and negative authorization tests. Do not rely on RLS alone.

## 2. Evidence minimization rules

### 2.1 Capture by default

For each checked source, retain only:

- canonical source URL and, where safe, requested URL, final URL, and redirect chain;
- source class/role and assessed authority (provider, linked form, institution, secondary, etc.);
- `checked_at` in UTC, publication date if explicitly stated or `unavailable`, and the exact claim types reviewed;
- safe-fetch outcome/access limitation and retrieval method;
- content hash (e.g., SHA-256) to identify the checked content version;
- minimal excerpt or quoted phrase strictly necessary to explain a material claim, with page/heading/section location and claim-evidence relation;
- reviewer/method, confidence as a support annotation (not an approval), and retention/deletion state.

Do not store a full HTML page, PDF, video, or form response by default. If a full snapshot is essential for a documented dispute, copyright review and security approval are required; keep it in a private, encrypted storage location with an expiry and access audit. Never place evidence files in a public Supabase Storage bucket.

### 2.2 Prohibited evidence content

Do not collect, store, or expose:

- student/applicant names, email addresses, phone numbers, dates of birth, home addresses, identity numbers, passport/NIN/JAMB numbers, school records, transcripts, grades, bank details, disability/health information, biometric data, or application answers;
- passwords, OAuth/session tokens, cookies, API keys, reset links, signed URLs, secret query parameters, or CAPTCHA content/solution;
- contents of an applicant’s authenticated portal, another student’s application, or private provider correspondence not authorized for review;
- student submissions or confirmation receipts created by testing an application.

If a public source unexpectedly includes applicant-level or otherwise sensitive data, stop capture, do not quote it, redact/remove it from the evidence store, record a minimal incident/tombstone if lawful, and notify the authorized security/privacy owner. Do not use a live application form as an evidence source beyond its public, non-submitted instructions/status.

### 2.3 Safe source retrieval

- Follow the repository’s existing safe-fetch/URL validation model; resolve and block private, loopback, link-local, and internal network destinations; validate redirect hosts and URL schemes; cap response size/time; do not run arbitrary page scripts or download executable content.
- Use normal public access only. Do not bypass 401/403, WAF, paywall, login, geoblock, or CAPTCHA protections. An access failure is a capture outcome, not evidence that an opportunity is open/closed.
- Strip tracking parameters from stored canonical references where they are not needed to identify the route; retain a sensitive original only in a private restricted field if truly necessary and approved.
- Do not send source URLs containing embedded credentials/tokens to logs, analytics, public APIs, or third-party LLM prompts.
- Keep automated extraction separate from human-reviewed claim state. Model output or confidence scores cannot be represented as a reviewer decision.

## 3. Proposed retention schedule (approval required)

These are proposed maxima, not existing production commitments. Apply shorter periods if required by a verified legal, contractual, or privacy need. A legal hold or active dispute may suspend scheduled deletion only under authorized review.

| Data class | Proposed retention | End-of-period action |
|---|---|---|
| Ephemeral raw fetch buffer | Do not persist by default; if temporarily buffered, delete within 24 hours after claim extraction/quality checks. | Secure delete; retain only approved minimal capture metadata and excerpt if needed. |
| Private full-page/full-file snapshot (exception only) | Maximum 90 days after the review decision unless an approved dispute/legal hold requires longer. | Delete object and storage versions; append a deletion event. Never make public. |
| Minimal source excerpt/capture metadata | 24 months after the exact cycle’s final disposition/closure; for an active cycle, review annually and retain only while evidentially necessary. | Delete/redact excerpt; retain source URL/hash/check metadata only if still lawful and useful. Reassess any claim that relied on deleted text. |
| Normalized opportunity/cycle claims and dates | Keep with the opportunity’s historical record; re-evaluate after 7 years from final disposition for archive necessity. | Retain only normalized, non-personal facts that remain useful and lawful; otherwise anonymize or delete with an event. |
| Human decision and change audit metadata | 7 years from the final decision, subject to approved legal/privacy policy. | Purge or anonymize actor-linked details when permissible; do not retain source-body content inside the audit log. |
| Security/access audit logs for private evidence | 24 months. | Delete according to log-retention controls; no sensitive excerpt or secret value in logs. |
| Applicant/personal data accidentally captured | Not an approved evidence category; remove immediately under incident handling. | Preserve only a minimal incident record if necessary and lawful; never convert applicant data into evidence. |

Deletion must cover database rows, object versions/backups under the provider’s retention controls, derived exports, caches, and search indexes where feasible. The operator must document which layers cannot be immediately purged and their expiry.

## 4. Deletion request and evidence-removal procedure

1. Authenticate the requester and establish their relationship to the source or data. Do not accept a public deletion instruction as authority to erase another person’s evidence without review.
2. Identify affected captures, excerpts, claims, decisions, exports, and storage objects; apply a legal-hold check before destruction.
3. Remove the full body/excerpt or personal material from active storage and any reachable cache/export. Do not silently leave it in an editor note or public route.
4. Append a minimal `evidence_removed` audit event (actor, request reference, time, scope, deletion reason code, legal-hold result), omitting deleted personal/source content.
5. Mark any dependent claim `evidence_removed`/`unsupported` and re-run the authoritative publication decision. If a material claim no longer has adequate support, actionability fails closed; do not preserve the old approval using a broken evidence reference.
6. Record backup/replica expiry behavior and complete deletion at the approved schedule. Escalate requests with a legal hold or competing preservation obligation to the approved privacy/security owner.

## 5. Access model

| Role | Allowed access | Prohibited access |
|---|---|---|
| Anonymous/student browser | Only public-safe opportunity/cycle projection and approved route/source links; own authenticated features through their permitted API. | Source captures, editor notes, claim excerpts, reviewer identity beyond approved attribution, applicant data, internal reason codes, unverified candidates. |
| Authenticated student | Same public projection plus own saves/applications/notification state under existing authorization. | Another student’s rows, any editorial evidence, write access to published facts. |
| Researcher/source reviewer | Candidate/source registry, capture metadata, minimal excerpts, claims in assigned scope. | Approving own work where independent approval is required; student application/profile data. |
| Editorial approver | Review evidence and decide a cycle/scope disposition; append a decision event. | Secret credentials, unneeded student PII, direct provider application submission. |
| Service worker | Narrow read/write operations necessary for queueing/revalidation; service key stays server-side. | Publicly exposing service credentials, unrestricted evidence export, self-approval. |
| Security/privacy auditor | Read-only access to ACL/config/access logs and incident metadata, scoped to review. | Editing catalogue facts or reading unrelated applicant data. |

Implement access with non-public schemas/roles and explicit table/column/function grants, plus RLS as a defense-in-depth row boundary. Define default privileges for each migration-owner role; test both `anon` and `authenticated` as actual JWT roles. Ensure a policy function or RPC is not executable by browser roles unless its output is explicitly public-safe. Use `SECURITY DEFINER` only if unavoidable, with an owner that cannot log in, pinned `search_path`, narrow SQL, and explicit execution grants; prefer a server-only, least-privilege invocation.

## 6. Read-only production security findings — high-priority blocker

A metadata-only check on 2026-11-08 found the following in the live Supabase project. These are database privilege facts, not proof that a particular PostgREST route was exercised or exploitable.

### 6.1 Existing direct table ACLs

`pg_class.relacl` and `has_table_privilege()` confirmed direct/effective `anon` and `authenticated` privileges for **SELECT, INSERT, UPDATE, DELETE, and TRUNCATE** on multiple tables, including:

- `public.scholarships`, `public.scholarship_rules`, `public.opportunities`, and `public.cycle_events`;
- personal/user data tables `public.applications`, `public.saved_scholarships`, `public.saved_opportunities`, and `public.notifications`;
- discovery/evidence tables `public.scholarship_discovery_candidates`, `public.scholarship_discovery_candidate_claims`, and `public.scholarship_discovery_fetch_snapshots`.

The explicit ACL text for representative tables was `{postgres=arwdDxtm/postgres,anon=arwdDxtm/postgres,authenticated=arwdDxtm/postgres,service_role=arwdDxtm/postgres}`. `arwdDxtm` includes INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, and MAINTAIN. Effective `has_table_privilege('anon', ...,'TRUNCATE')` and the corresponding authenticated check returned true for those tables.

RLS policies are separately present—for example, owner/admin policies on applications and saved items, admin-only discovery policies, verified-row reads on scholarships/opportunities, and public cycle-event reads. RLS does not make broad table grants least-privilege, and PostgreSQL `TRUNCATE` is not filtered by row-level policies. No destructive/API test was performed; the actual exposed request path was not established in this documentation task.

### 6.2 Default privileges and checked-in remediation scope

The live `pg_default_acl` metadata showed `supabase_admin`’s `public`-schema table defaults granting all listed table privileges to `anon` and `authenticated`, including `TRUNCATE`. A separate `postgres` default ACL grants table privileges to `postgres` and `service_role`, not browser roles. The active migration role for every future migration must therefore be verified before assuming which defaults apply.

Checked-in `supabase/migrations/20261107130000_security_boundary_remediation.sql` revokes browser-role defaults for functions, tables, and sequences **for role `postgres` only**. Its comments state that existing objects retain their current ACLs and will be remediated separately. It does not, in this checkout, remove the observed existing table ACLs or the observed `supabase_admin` defaults.

The inspected explicit per-column ACL catalog returned one row for `notifications.read_at` (`authenticated` has column-level UPDATE); this is not a general column allowlist and does not offset the broader table ACLs on the other reviewed objects.

### 6.3 Required handling

- Treat this as a **production least-privilege/security-readiness blocker** before adding private evidence tables, a public projection, or a publication-decision API.
- Do not infer that the existing RLS policy set fully neutralizes the SQL privileges. A security owner should separately determine actual PostgREST/RPC reachability and approved corrective scope.
- Do not repair permissions, alter defaults, change RLS, or run a TRUNCATE/unauthorized write probe as part of this documentation task. The current user instruction expressly reserves RLS/permission changes.
- Any future permission remediation requires its own explicit approval, reviewed migration, access-path analysis, before/after ACL inventory, anon/auth negative tests, and rollback plan.

## 7. Public API and storage acceptance tests

Before launch, run positive **and negative** tests in a non-production clone and an approved production read-only probe:

- `anon` can read only the intended public projection and safe fields; direct queries to private evidence, research notes, applicant rows, and unverified candidates are denied.
- `authenticated` can read/change only the user’s own permitted profile/save/application/notification fields; it cannot read other users’ data or modify catalogue/editorial state.
- `service_role` operations are server-only and every endpoint applies an explicit user/admin authorization check before using them.
- RLS tests use actual `anon` and `authenticated` JWT roles; table ACL tests inspect direct and inherited grants, default privileges for every migration owner, column ACLs, sequences, views, and RPC execute grants.
- Public views/functions return only allowlisted columns; negative assertions forbid `research_notes`, source excerpts, snapshots, reviewer-private notes, and applicant data.
- Storage bucket access is private; signed URLs are short-lived and never embedded in public catalogue records.
- Logs redact credentials, tokens, applicant fields, raw captures, and private reason details.

## 8. Related documents

- [Governance decision refinement](SCHOLARS_PHASE_2_1_GOVERNANCE_DECISION_REFINEMENT_2026-11-08.md)
- [Authoritative publication policy and gates](SCHOLARS_PHASE_2_1_AUTHORITATIVE_PUBLICATION_POLICY_2026-11-08.md)
- [Application-route acceptance matrix and freshness standard](SCHOLARS_PHASE_2_1_ROUTE_ACCEPTANCE_AND_EVIDENCE_FRESHNESS_POLICY_2026-11-08.md)
- [Technical specification](SCHOLARS_PHASE_2_1_TECHNICAL_SPECIFICATION_AND_FINAL_ERD_2026-11-08.md)
- [Readiness assessment](SCHOLARS_PHASE_2_1_IMPLEMENTATION_READINESS_ASSESSMENT_2026-11-08.md)
