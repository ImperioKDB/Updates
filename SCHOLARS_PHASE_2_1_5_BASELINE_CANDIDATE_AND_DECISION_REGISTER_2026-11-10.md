# Scholars Phase 2.1.5 — Baseline Candidate and Decision Register

**Investigation date:** 2026-11-10
**Scope:** Final decision for controlled schema capture and independent review. No production or staging object, privilege, setting, or data was modified.

## Final verdict

# BLOCKED — AUTHORIZED CAPTURE NOT AVAILABLE

This is the required verdict because the phase could not safely produce the authorized schema-only dump or declarative pg-delta artifact. The environment lacked the approved Supabase CLI, no authorized read-only database URL was available, and the Management API request returned HTTP 401 because no scoped credential was available. The catalog evidence is substantial, but it is not a portable candidate baseline.

## Revalidated facts

| Item | Result |
|---|---|
| Production project | `cmdglabohpttgfofcmqc`, `ACTIVE_HEALTHY` |
| Staging project | `aqhktriwaglvvrchxmtd`, `ACTIVE_HEALTHY` |
| Production migration ledger | 180 rows |
| Staging Scholars application schema | Not present in bounded catalog inventory |
| Production public tables | 45, all RLS-enabled |
| Production public views | 4 Resource Center views |
| Public security-definer functions | 31 |
| Force RLS | 0 public tables |
| Storage buckets | `avatars`, `site` |
| Extensions | Five, matching staging |
| Current main versus stated baseline | 3 additional migration files |
| PostgREST configuration | Not verified; Management API 401 |

## Candidate baseline posture

No candidate baseline artifact is declared in this report. The correct future posture is a **new current-state baseline**, never a recovered historical migration chain. Historical replay remains rejected because prior provenance work found unresolved and ambiguous ledger/file relationships and no authoritative executor manifest.

When access is available, the recommended candidate should contain:

1. A private pg-delta declarative schema tree generated from current production with strict coverage.
2. A private schema-only SQL dump as an independent comparison artifact.
3. A sanitized object inventory and exclusion list.
4. SHA-256 hashes of the unmodified private artifacts.
5. An extension manifest and managed-schema customization list.
6. A reviewed ACL/default-privilege overlay tied to the approved restoration executor.
7. A generated type snapshot from the isolated destination.

## Decision register

| ID | Decision or gate | Status | Owner/approval needed |
|---|---|---|---|
| D-215-01 | Historical migration replay | Rejected | Governance decision already established |
| D-215-02 | Current-state schema-only baseline | Recommended, not captured | Founder/project administrator approval |
| D-215-03 | Primary extraction | Recommend pg-delta declarative generate | Independent reviewer after capture |
| D-215-04 | Secondary extraction | Recommend schema-only dump | Independent reviewer after capture |
| D-215-05 | PostgREST config | Blocked by missing scoped API credential | Project administrator |
| D-215-06 | Destination default privileges | High-risk unresolved restoration control | Database owner and security reviewer |
| D-215-07 | Browser RPC privileges | Requires object-by-object review | Security reviewer; no blanket revoke |
| D-215-08 | Staging restoration | Not authorized and must not occur yet | Separate explicit approval |
| D-215-09 | Production deployment | Not in scope | Separate release authorization |

## Conditions to move to independent baseline review

1. Install or provide a reviewed, pinned Supabase CLI in the controlled execution environment.
2. Provide a properly authorized non-writing database URL for both approved reads, without exposing it in reports or Git.
3. Provide sanitized Management API PostgREST records for both project refs.
4. Generate both extraction artifacts with strict coverage where supported.
5. Scan artifacts for data, storage objects, Vault material, secrets, unexplained roles, and platform-managed internals.
6. Hash and privately retain the original artifacts; publish only sanitized reports.
7. Reconcile artifact inventory to catalog counts and the application dependency matrix.
8. Review security-definer function bodies, view options, RLS combinations, grants, default privileges, managed-schema hooks, and publication membership.
9. Test a synthetic restore in an isolated environment and generate database types.
10. Obtain independent reviewer approval before any staging restoration decision.

## Next phase recommendation

**Phase 2.1.6 — Authorized artifact capture and isolated compatibility review.** It should be evidence-only until the independent reviewer signs the capture package. It must not restore staging, apply migrations, change PostgREST, alter ACLs, or deploy application changes without a separate authorization.

The sequence should be: authorize read-only credentials; pin CLI; generate declarative tree and dump; hash privately; compare coverage; review security; construct a synthetic isolated destination; generate types; run role-specific API/RLS/application smoke tests; then return for an explicit staging decision.

## Safety confirmation

No production or staging tables, functions, triggers, policies, grants, default privileges, roles, buckets, files, PostgREST settings, migration rows, or data were modified. No production table data, student records, storage objects, credentials, JWT secrets, connection strings, or Vault material were retrieved or committed.

## References

- [Supabase CLI reference](https://supabase.com/docs/reference/cli/introduction)
- [Declarative database schemas](https://supabase.com/docs/guides/local-development/declarative-database-schemas)
- [Supabase diff engines](https://supabase.com/docs/guides/local-development/diff-engines)
- [Supabase PostgREST configuration endpoint](https://supabase.com/docs/reference/api/v1-get-postgrest-service-config)
- [Phase 2.1.4 strategy decision](https://github.com/ImperioKDB/Updates/blob/main/SCHOLARS_PHASE_2_1_4_STRATEGY_DECISION_AND_FINAL_ASSESSMENT_2026-11-09.md)
