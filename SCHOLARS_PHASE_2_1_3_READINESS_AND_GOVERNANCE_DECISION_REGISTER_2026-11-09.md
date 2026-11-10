# Scholars Phase 2.1.3 — Readiness and Governance Decision Register

**Investigation date:** 2026-11-09
**Overall verdict:** **BLOCKED — ADDITIONAL INVESTIGATION REQUIRED**
**Change status:** Documentation only; no application, production, or staging changes were made.

## Readiness decision

The staging project remains healthy, but it is not ready for reconstruction. The current production ledger has 180 entries, while the baseline has 129 migration files and current main has 132. Only 106 ledger entries have a single normalized repository source-name match; 35 have ambiguous candidates and 39 have no candidate in reachable Git history. None of the 106 matches has been called an exact SQL-content match because production migration bodies were not retrieved and compared.

Staging still has no Scholars application schema, no migration ledger entries, and no storage buckets in the read-only inventory. Production and staging PostgREST settings remain unavailable through the database settings surface. A supported Management API retrieval method is known, but it requires an authorized scoped PAT/OAuth token or dashboard export that was not available to this investigation.

The project therefore fails the brief's reproducibility acceptance criterion and is **BLOCKED — ADDITIONAL INVESTIGATION REQUIRED**.

## Governance recommendations — not approvals

### 1. Public field allowlist

**Recommended default:** expose only fields needed by public catalogue/detail pages, with explicit column lists and a reviewed public projection.
**Rationale:** direct table grants and `select *` make future columns public by accident.
**Application consequence:** public client and sitemap queries must move to stable projections or reviewed server routes.
**Founder approval required:** final public field list and whether any partner or research metadata may be public.

### 2. Internal research notes

**Recommended default:** private to authorized research/editorial roles and server-side workflows.
**Rationale:** notes can contain source-evaluation reasoning, contact information, or unverified claims.
**Application consequence:** admin/editorial pages need a dedicated capability path rather than public table reads.
**Founder approval required:** whether any summarized research signal may appear in public catalogue responses.

### 3. Cycle-event notes and actor identities

**Recommended default:** public dates and approved status only; keep notes, captured-by identity, and internal verification history private.
**Rationale:** event notes and actor identifiers are operational/editorial data.
**Application consequence:** matching and public calendar views need separate projections.
**Founder approval required:** whether named attribution is a product feature.

### 4. Competitiveness and acceptance-rate information

**Recommended default:** suppress raw estimates and small-sample values; publish only an approved coarse tier if needed.
**Rationale:** estimates can be misleading and may expose private aggregate behavior.
**Application consequence:** dashboard and recommendation copy must handle missing/suppressed values.
**Founder approval required:** product wording, thresholds, and whether estimates are public at all.

### 5. Contributor identity and online presence

**Recommended default:** anonymous or coarse contributor labels by default; presence indicators private unless explicitly consented.
**Rationale:** identity and presence create privacy and safety exposure.
**Application consequence:** discussion projections and contributor RPCs need consent-aware fields.
**Founder approval required:** public display policy and consent language.

### 6. Social-proof thresholds and small cohorts

**Recommended default:** suppress exact counts below five and round or bucket larger counts.
**Rationale:** small cohorts can identify individuals and make metrics unstable.
**Application consequence:** UI copy must support hidden, rounded, and unavailable states.
**Founder approval required:** exact threshold, rounding policy, and whether any cohort exception exists.

### 7. Researcher, reviewer, approver, and auditor capabilities

**Recommended default:** separate capabilities backed by server-controlled membership, with least privilege and immutable audit events.
**Rationale:** discovery publication and editorial changes require separation of duties.
**Application consequence:** admin routes and publication RPCs must carry capability checks.
**Founder approval required:** role definitions, membership owner, and audit retention period.

### 8. Self-review and self-approval

**Recommended default:** prohibit a researcher from reviewing or approving their own submission or source decision.
**Rationale:** prevents a single operator from creating and publishing unreviewed content.
**Application consequence:** the UI and database transition function must reject same-actor transitions.
**Founder approval required:** any documented emergency override and its approver.

### 9. Migration ownership and execution process

**Recommended default:** one project-scoped CI migration identity, with ordered source hashes and a protected approval step.
**Rationale:** production metadata cannot currently prove the historical executor, and defaults differ by creator role.
**Application consequence:** migration logs and source manifests become release artifacts; dashboard ad hoc migrations should be prohibited or recorded.
**Founder approval required:** executor identity, approval workflow, and emergency procedure.

### 10. Staging reconstruction approval

**Recommended default:** reconstruct schema-only in the named staging project using synthetic fixtures and no production data.
**Rationale:** staging is healthy but empty; safe tests require independent role identities and fixtures.
**Application consequence:** a separate setup window, cleanup plan, and rollback proof are required.
**Founder approval required:** authorization to create staging schema, roles/fixtures, storage test objects, and synthetic accounts.

## Remaining blockers and exact next evidence

1. Obtain the complete ordered production migration source set or approved replacement manifest, including SQL content hashes.
2. Recover or formally document the 74 unresolved/ambiguous ledger entries.
3. Obtain sanitized PostgREST configuration for both projects through the supported Management API or dashboard export.
4. Establish the approved historical/future migration executor from CI, Management API audit, or project-admin evidence.
5. Re-inventory staging immediately before setup; current evidence says no application tables, migrations, or storage buckets, but reconstruction is not authorized.
6. Generate database types from the approved staging schema and compare them with all baseline route/query dependencies.
7. Obtain founder decisions for the ten governance recommendations above.

## Final classification

- **Confirmed facts:** current production ledger count is 180; baseline has 129 SQL files; current main has 132; staging is active/healthy and has no inspected Scholars tables, migrations, or buckets; management endpoint and scope requirements are documented.
- **Strongly supported conclusions:** the stated baseline cannot reproduce production; migration executor identity is not present in the migration ledger; direct database settings cannot establish PostgREST configuration.
- **Unverified assumptions:** exact SQL equivalence of normalized filename matches; production/staging API configuration equality; authenticated route/RPC behavior; historical migration executor.
- **Unresolved blockers:** migration source recovery, administrative config read, execution ownership, staging reconstruction approval, and governance decisions.
- **Founder approval required:** all ten governance recommendations and authorization for any staging reconstruction.

## References

[1]: https://github.com/ImperioKDB/Scholars/commit/cf3682ce35912df7b9b9352193630fc404427c7c "Scholars application baseline"
[2]: https://supabase.com/docs/reference/api/v1-get-postgrest-service-config "Supabase Management API — Get PostgREST config"
[3]: https://supabase.com/docs/reference/api/introduction "Supabase Management API authentication"
[4]: https://supabase.com/docs/guides/api/using-custom-schemas "Supabase — Using custom schemas"
[5]: https://github.com/ImperioKDB/Updates/commit/67ec2b5d84491607b13a6efcf1d68c1d1d93c931 "Phase 2.1.2 prior investigation"
