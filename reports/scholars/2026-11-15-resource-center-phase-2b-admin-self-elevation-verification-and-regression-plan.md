# Scholars Resource Centre — Phase 2B Administrator Self-Elevation Verification and Regression Plan

**Status:** test design only; no test in this plan was executed during this task.
**Environment:** isolated Scholars staging only. Never use production or `serena` as a test substitute.

## Evidence labels

Expected outcomes below are **UNVERIFIED** until executed in staging. Prior production catalog findings are **VERIFIED — DATABASE (PRIOR REPORT)**. Source behavior is **VERIFIED — SOURCE**. No row mutation, exploit attempt, HTTP request, or migration execution is claimed.

## Entry gates

1. A schema-only Scholars staging baseline at the approved source revision is installed and compared with the source manifest.
2. Preview variables point only to `scholars-staging`; no production service-role key is present.
3. Synthetic ordinary, administrator, independent recovery, and anonymous clients exist. No production identities or PII are used.
4. Exact grants, default privileges, policies, triggers, functions, owners, `search_path`, and dependency inventory are captured before and after the proposed change.
5. Owner policy approves bootstrap, two-person approval, last-admin protection, audit retention, and AAL2 requirements.

## Test matrix

### A. Database authority and direct-write denial

| ID | Test | Expected result |
|---|---|---|
| A1 | Anonymous `POST/PATCH` profile write | 401/permission denial; no row or flag change. |
| A2 | Ordinary authenticated own-row update of ordinary field | Succeeds through approved path; row remains own-row only. |
| A3 | Ordinary authenticated own-row `is_admin=false→true` update | Database denies; row unchanged. |
| A4 | Ordinary authenticated own-row `is_admin=true→false` update | Database denies; legitimate revocation requires lifecycle operation. |
| A5 | Ordinary insert/upsert with `is_admin:true` | Denied or trigger-aborted; created profile defaults false. |
| A6 | Ordinary write to another user’s flag | Denied by grants/RLS/trigger. |
| A7 | PostgREST PATCH, POST, and `on_conflict` upsert containing `is_admin` | All fail closed; no policy-only or client-validation assumption. |
| A8 | Reapply broad table DML in a disposable negative fixture | Flag trigger still rejects protected-field changes; never run against production. |
| A9 | Table/column privilege audit | `authenticated` table-level profile INSERT/UPDATE false; protected-column INSERT/UPDATE false; safe-column grants match allowlist. |

### B. Profile lifecycle compatibility

| ID | Test | Expected result |
|---|---|---|
| B1 | Password signup and confirmation | Auth succeeds; profile bootstrap creates false admin state. |
| B2 | OTP signup/login | Auth succeeds; no profile-write regression. |
| B3 | Google OAuth callback | Session succeeds; referral and attribution updates remain limited to the current profile. |
| B4 | Onboarding complete, skip, and resume | Generic profile mutation or replacement endpoint persists safe fields and progress markers. |
| B5 | Profile settings edit | Safe ordinary fields persist; unknown/protected fields cannot be smuggled. |
| B6 | JAMB/institution/academic updates | Persist through approved safe path. |
| B7 | WAEC replace | RPC succeeds for current user; summary triggers update expected derived fields; no admin field change. |
| B8 | Presence heartbeat | Own-row `last_seen_at` update succeeds; another row cannot be targeted. |
| B9 | Community bio edit | Safe bio update succeeds; `community_role` and `is_admin` remain protected. |
| B10 | Community invitation grant/withdraw | Service-side endpoint works; ordinary direct writes to consent columns fail; trigger behavior remains correct. |
| B11 | Referral completion and profile completeness triggers | Expected derived values and XP behavior remain intact. |
| B12 | Profile deletion | Ordinary user can delete own profile; another row cannot be deleted; last-admin policy is enforced. |

### C. Helper, policy, and routine cutover

| ID | Test | Expected result |
|---|---|---|
| C1 | Anonymous call to legacy/replacement helper | No arbitrary membership disclosure; unauthorized execution denied. |
| C2 | Authenticated call with arbitrary UUID, if shim exists | Non-self UUID is rejected/false; final helper has no UUID argument. |
| C3 | Null `auth.uid()` | Replacement helper fails closed. |
| C4 | Search-path/temp-object spoof | Helper resolves only fully qualified reviewed objects and cannot be influenced by caller-created names. |
| C5 | Function metadata | Dedicated non-login owner, fixed empty search path, no dynamic SQL, exact ACL, no PUBLIC/anon execute. |
| C6 | Complete policy inventory | Every policy referencing legacy helper is replaced; all expected allow/deny outcomes pass for anon, ordinary user, admin, and service role. |
| C7 | Dependent routines | Admin metrics, provider analytics, visitor metrics, confirmation-email analytics, publication, scheduler, and trigger routines retain intended authorization and do not write `is_admin`. |
| C8 | Resource Centre policies | Public projection reads remain available; base-table writes are denied to ordinary users; approved admin/editor workflow behavior remains as designed. |

### D. Administrator lifecycle and MFA

| ID | Test | Expected result |
|---|---|---|
| D1 | Owner bootstrap | Only approved owner procedure can establish first admin; no public/app registration route. |
| D2 | Admin promotion | AAL2 admin can promote another eligible synthetic UID with reason/ticket and approval; self-grant fails. |
| D3 | Demotion/revocation | AAL2 lifecycle operation changes flag and audit record atomically. |
| D4 | Last-admin protection | Final active admin cannot be removed through ordinary lifecycle path. |
| D5 | Emergency recovery | Only independent owner/recovery procedure works; ordinary user and app RPC cannot invoke it. |
| D6 | AAL1 vs AAL2 | High-risk lifecycle, publishing, export, broadcast, and destructive operations reject AAL1 and accept AAL2 when policy requires. |
| D7 | Audit immutability | Ordinary API roles cannot modify/delete lifecycle audit rows; failed and successful attempts are attributable. |
| D8 | Stale session after revocation | Next middleware, route, helper, RLS, and RPC request is denied without waiting for a JWT role refresh. |

### E. Application authorization and side effects

| ID | Test | Expected result |
|---|---|---|
| E1 | Ordinary user calls every admin route family | 401/403; no service-role reads, writes, email, push, or publication side effects. |
| E2 | Synthetic admin calls allowed admin routes | Route guard, RLS, helper, and service-role boundary agree. |
| E3 | Client-state manipulation | Browser storage, hidden UI, payload role fields, and React props cannot grant access. |
| E4 | Service-role isolation | `server-only` boundary holds; no browser bundle or request field supplies a key. |
| E5 | Admin route ordering | Guard executes before protected data access and external side effects; rate limiting is not treated as authorization. |

### F. Public Resource Centre compatibility

| ID | Test | Expected result |
|---|---|---|
| F1 | Anonymous published article/category read | Published, active, time-valid projections are readable only through approved public views. |
| F2 | Anonymous draft/unpublished/archived read | No rows or sensitive base-table fields exposed. |
| F3 | Ordinary authenticated editorial base-table write | Denied until an approved workflow endpoint exists. |
| F4 | Legitimate platform-admin read/write | Works only after helper and policy cutover; no new editorial role authority is implied. |
| F5 | Storage object access | Public reads and admin-only writes follow the approved storage policy; no helper ACL change breaks them. |

## Atomicity and rollback tests

Apply the proposal only in a disposable staging transaction. Inject failures before commit and assert that grants, trigger, helper, policies, and routine changes roll back together. After commit, a forward correction must not restore broad profile DML or PUBLIC execution of the arbitrary-UUID helper. Verify backups and the owner recovery path before any production consideration.

## Exit criteria

The remediation is ready for a separately authorized staging implementation only after every applicable test passes, the exact dependency inventory is reconciled, safe profile upsert behavior is proven, the two-person recovery process is demonstrated, and no production or unrelated project was used. A test plan or source inspection alone is not a PASS.
