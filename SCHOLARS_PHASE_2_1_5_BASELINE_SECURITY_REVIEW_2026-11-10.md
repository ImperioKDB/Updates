# Scholars Phase 2.1.5 — Candidate Baseline Security Review

**Evidence window:** 2026-11-10, 10:25–10:32 CET (UTC+01:00)
**Scope:** Review security-sensitive production schema findings available from the prior bounded catalog inventory and identify what cannot be certified without the schema artifact. No RPC was invoked and no production or staging setting was changed.

## Decision

**No candidate baseline is available for security approval.** Prior Phase 2.1.5 catalog evidence records meaningful ACL, RLS, function, view, storage, and destination-default risks. Those configuration findings are not proof of an exploitable attack path. The underlying SQL artifact and several security details remain unreviewed, so this report does not sign off a restore.

## Evidence standard and methodology

The environments reviewed are production `cmdglabohpttgfofcmqc` and staging `aqhktriwaglvvrchxmtd`. Both project references and active status were re-confirmed through the read-only Supabase connector.

The current review re-confirmed project identity, staging's empty application-table inventory, and the installed-extension list using dedicated read-only Supabase tools. It did not run arbitrary SQL, fetch production rows, retrieve function bodies, invoke RPCs, or generate a dump. The detailed catalog figures below are inherited from the earlier Phase 2.1.5 bounded inventory published at commit `a88ab72fcdddd58fe28315a1c04229a09511ab77`; they are explicitly not fresh DDL-capture results. [1] [2]

## Security-sensitive findings

| Area | Prior catalog evidence | Security meaning and remaining uncertainty |
|---|---|---|
| Tables and RLS | 45 public tables were reported with RLS enabled and zero with `FORCE ROW LEVEL SECURITY`; many browser-role ACLs were reported as broad | RLS and ACL metadata do not prove row exposure. Table owners and bypass roles can bypass RLS. No row access was tested in this review. |
| RLS policy logic | Multiple permissive policy combinations and role-target patterns were reported | PostgreSQL combines permissive policies with OR semantics; each policy set needs table-by-table review. No policy was changed or tested against real data. |
| Browser-executable security-definer functions | 31 public security-definer functions were reported. The prior review flagged browser EXECUTE posture for `is_admin(uuid)`, `get_admin_metrics_summary(timestamptz)`, and `run_achievement_checks(uuid)` | Grants and security mode are configuration risks; they do not alone prove reachable exploitation. Function bodies, dynamic SQL, call paths, and data-bearing results remain unverified here. Do not invoke sensitive production RPCs. |
| Function search paths | Prior metadata recorded a mixture of explicit empty search paths and `search_path=public` | Each privileged function needs body-level qualification and safe search-path review before approval. No blanket function revoke is safe without application regression tests. |
| Resource Center views | Four public views were reported as postgres-owned, with browser SELECT access and `security_barrier=true`; `security_invoker=true` was not established | View owner/RLS semantics and underlying-table access must be tested in an isolated environment. The present evidence does not prove an actual leak. |
| Storage and managed schemas | Prior inventory reported two public buckets, public asset reads, own-avatar management, admin-managed site objects, and a custom `auth.users` trigger | No object bytes or user records were accessed. Bucket configuration, policy expressions, trigger bodies, and platform-managed hooks must be reviewed separately; never replay platform internals blindly. |
| Destination defaults | The prior security report recorded different default privileges for production and staging creators, including broader staging `postgres` defaults | This was not re-queried in this pass. A restore under a different creator can change effective access. Re-check every authorized creator role and apply an approved ACL overlay before any staging restore. |
| Extensions and Vault | Current extension inventories agree on five installed versions; `supabase_vault` is platform-managed | No Vault contents were read. Do not dump or copy Vault secrets or assume extension-created objects are represented in a schema export. |

The project dependency matrix warns that a blanket revoke of `anon` or `authenticated` table grants would break catalogue reads, matching, saves, applications, notifications, profiles, community, Resource Center, admin pages, and server routes using session-aware clients. Make additive replacements, update call sites, and test role boundaries before any narrowly scoped grant change. [3]

## Confirmed facts, inherited evidence, and inference

**Reconfirmed in this pass:** production and staging project refs and health; staging returned no tables in the requested application schemas and no migration entries; both extension inventories report the same five installed versions; no schema artifact or table-row contents were produced.

**Inherited catalog findings, not re-run here:** the object counts and ACL/RLS/function/view/storage/default-privilege details in the table above, as recorded in the prior Phase 2.1.5 report. These remain useful review leads but do not replace inspection of the actual artifact.

**Inference requiring validation:** replaying an artifact under staging defaults or a different migration executor could expose objects or change behavior. This is a restoration risk, not evidence that current production access is exploitable.

## Required review controls

1. Obtain the private, unmodified capture artifacts and their hashes; never publish raw DDL.
2. Compare table ACLs, column ACLs, ownership, RLS/force-RLS state, policies, sequences, and default ACLs against approved least-privilege expectations.
3. Review every browser EXECUTE grant on security-definer functions, including function body, owner, `search_path`, dynamic SQL, and data flow.
4. Verify view security-invoker/definer settings and published-row filters in an isolated synthetic environment.
5. Review `auth.users` and Storage triggers/policies separately from generic schema capture; preserve platform-managed objects.
6. Determine the staging creation role and destination default-privilege overlay before any restore.
7. Run anonymous, Student A/Student B, admin, and worker tests using synthetic identities only.

No blanket revocation, DDL, production RPC, row access, or staging restore is recommended or authorized by this report.

## Limitations and unresolved questions

No portable schema artifact was available for function-body review, complete effective-privilege analysis, managed-schema replay assessment, or artifact-specific coverage review. PostgREST exposed schemas, exact destination creator defaults, view invoker semantics, and exploitability remain unresolved. The inherited catalog observations must not be treated as a restore approval.

## References

[1]: https://github.com/ImperioKDB/Updates/blob/a88ab72fcdddd58fe28315a1c04229a09511ab77/SCHOLARS_PHASE_2_1_5_BASELINE_SECURITY_REVIEW_2026-11-10.md "Prior Phase 2.1.5 Security Catalog Review"
[2]: https://github.com/ImperioKDB/Updates/blob/a88ab72fcdddd58fe28315a1c04229a09511ab77/SCHOLARS_PHASE_2_1_5_SCHEMA_CAPTURE_AND_COVERAGE_REPORT_2026-11-10.md "Prior Phase 2.1.5 Catalog Inventory"
[3]: https://github.com/ImperioKDB/Updates/blob/3d3da285f1b076fbfebb1fdf1adbaadeb178d71f/SCHOLARS_PHASE_2_1_2_API_OBJECT_AND_APPLICATION_DEPENDENCY_MATRIX_2026-11-09.md "Phase 2.1.2 API Object and Application Dependency Matrix"
[4]: https://www.postgresql.org/docs/current/ddl-rowsecurity.html "PostgreSQL Row Security Policies"
