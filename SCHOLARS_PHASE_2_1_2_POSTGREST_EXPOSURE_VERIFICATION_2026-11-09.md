# Scholars Phase 2.1.2 — PostgREST Exposure Verification

**Investigation date:** 2026-11-09
**Status:** Read-only production verification; no production or staging changes were made.
**Verdict:** **BLOCKED — ADDITIONAL INVESTIGATION REQUIRED**

## Scope and evidence standard

This report verifies what can be established without production writes, sensitive RPC calls, private-row retrieval, or destructive probing. Database catalog and privilege metadata are authoritative for database state. HTTP results are authoritative only for the exact safe requests that were executed. A database ACL is not treated as proof that a particular HTTP request can read a row.

The application baseline was inspected at Scholars commit `cf3682ce35912df7b9b9352193630fc404427c7c`. Production is Supabase project `cmdglabohpttgfofcmqc` in `eu-west-1`. The production project was healthy at inspection time.

## Production API configuration verdict

The exact deployed PostgREST `db-schemas`, `db-extra-search-path`, `db-anon-role`, and `openapi-mode` settings were not available through the inspected database metadata. Direct `current_setting(..., true)` queries returned `NULL` for each requested `pgrst.*` setting, and the public OpenAPI root returned HTTP 401 with a message that only the service-role key can use that endpoint. No service-role key was requested or used.

Therefore:

- Whether `public` is in the deployed PostgREST exposed-schema list is **not confirmed from configuration metadata**.
- Whether any non-public application schema is exposed is **not confirmed**.
- The observed API behavior proves that some `public` relations are addressable through PostgREST, but it does not prove the complete schema allowlist.
- Staging and production configuration equality is **unverified**.

## Safe HTTP checks actually executed

All requests used the production publishable/legacy anonymous API key, did not include a JWT, requested only `id` or a public view column, used an impossible synthetic slug or UUID, and returned no production rows.

| Request | Result | Evidence level | Interpretation |
|---|---:|---|---|
| `GET /rest/v1/scholarships?select=id&slug=eq.__phase212_no_match__&limit=1` | 200 `[]` | Confirmed API exposure of route | The relation route accepted the request and returned an empty result. No scholarship row was read. |
| `GET /rest/v1/opportunities?select=id&slug=eq.__phase212_no_match__&limit=1` | 200 `[]` | Confirmed API exposure of route | Same safe no-row result. |
| `GET /rest/v1/resource_public_articles?select=id&slug=eq.__phase212_no_match__&limit=1` | 200 `[]` | Confirmed API exposure of route | Public Resource Center view is addressable. |
| `GET /rest/v1/resource_public_categories?select=id&slug=eq.__phase212_no_match__&limit=1` | 200 `[]` | Confirmed API exposure of route | Public Resource Center view is addressable. |
| `GET /rest/v1/applications?select=id&profile_id=eq.00000000-0000-0000-0000-000000000000&limit=1` | 200 `[]` | Conditional exposure | The route is addressable and the impossible-profile query returned no rows. This does not establish access to real student rows. |
| `GET /rest/v1/scholarship_discovery_candidates?select=id&id=eq.00000000-0000-0000-0000-000000000000&limit=1` | 200 `[]` | Conditional exposure | The internal relation route is addressable; no candidate data was returned. |
| `GET /rest/v1/workflow_jobs?select=id&id=eq.00000000-0000-0000-0000-000000000000&limit=1` | 200 `[]` | Conditional exposure | The worker relation route is addressable; no job data was returned. |
| `GET /rest/v1/` | 401 | Configuration endpoint unavailable to anonymous key | The OpenAPI catalogue was not exposed to this key. This was not treated as evidence that relations are absent. |

No RPC was invoked. In particular, `is_admin`, admin analytics functions, discovery publication, achievement checks, trending, social proof, and discussion functions were not called in production.

## Object-level exposure conclusions

| Object group | Database evidence | Safe API evidence | Current conclusion | Recommended disposition |
|---|---|---|---|---|
| `public.scholarships` | RLS enabled, not forced; browser roles have direct `arwdDxtm`; verified-row SELECT policy | 200 empty response to impossible slug | Route exposure confirmed; real-row and column leakage not tested | Replace with explicit public projection; remove broad browser DML and internal columns |
| `public.scholarship_rules` | RLS enabled, not forced; broad browser ACL; verified-parent policy | Not probed because no safe public read was needed | Conditional/unverified | Expose only normalized approved eligibility fields through a projection |
| `public.opportunities` | RLS enabled, not forced; broad browser ACL; verified-row SELECT policy | 200 empty response to impossible slug | Route exposure confirmed; real-row and column leakage not tested | Explicit public projection; remove internal fields and broad browser DML |
| `public.cycle_events` | RLS enabled, not forced; public `USING (true)` policy; broad browser ACL | Not probed to avoid reading cycle data | Database privilege confirmed; HTTP exposure unverified | Project only approved cycle facts; exclude note and actor by default |
| `public.applications` | RLS enabled, not forced; owner/admin policies; broad browser ACL | 200 empty response to impossible profile UUID | Route addressability confirmed; row isolation not tested with JWTs | Keep private; test owner isolation with two synthetic authenticated users |
| `public.saved_scholarships`, `public.saved_opportunities` | Owner/admin policies; broad browser ACL | Not probed | Database privilege confirmed; HTTP exposure unverified | Keep private and owner-scoped; remove unnecessary update rights |
| `public.notifications` | Owner SELECT/UPDATE policy; broad browser ACL | Not probed | Database privilege confirmed; HTTP exposure unverified | Restrict updates to `read_at` or a mark-read function |
| Discovery candidates, claims, snapshots | Admin-only RLS policies; broad browser ACL | Candidate route returned 200 empty for impossible UUID | Route addressability confirmed; policy behavior not tested with JWTs | Keep out of browser API; use scoped editorial/server operations |
| `announcement_log`, `auth_rate_limits`, `broadcast_delivery_log`, `notification_deliveries`, `workflow_jobs` | RLS enabled with no policies; broad browser ACL on each | `workflow_jobs` returned 200 empty for impossible UUID | At least one internal route is addressable; no row exposure demonstrated | Remove browser grants and keep worker functions server-only |
| Resource Center views | Postgres-owned views with anonymous/authenticated SELECT; advisor reports security-definer view posture | Two views returned 200 empty for impossible slug | Public view routes confirmed | Keep only after projection, ownership, and unpublished-row tests pass |

The remaining audited relations were not queried against real identifiers. Their HTTP status is therefore **unverified**, even though database ACL metadata is available.

## RPC surface reconciliation

The live production catalog contains 42 `public` functions. The catalog confirms 31 `SECURITY DEFINER` functions, of which 23 have effective EXECUTE for both `anon` and `authenticated`; eight are service-role-only. It also confirms browser-executable non-definer functions, including `replace_waec_results(uuid,jsonb)` for authenticated callers and trigger-returning routines.

The Supabase security advisor independently reports 23 anonymous and 23 authenticated executable `SECURITY DEFINER` functions and names the corresponding `/rest/v1/rpc/...` paths. This is authoritative database/advisor evidence of a published RPC surface, but not an execution result. No sensitive RPC was invoked.

The most important functions remain:

- `is_admin(uuid)`: arbitrary UUID input and browser EXECUTE; potential admin-status oracle confirmed by catalog/body metadata, not by production invocation.
- `get_admin_metrics_summary(timestamptz)`: anonymous/authenticated EXECUTE; prior body review identified an outcome aggregate outside the admin-filtered event query.
- `run_achievement_checks(uuid)`: anonymous/authenticated EXECUTE and arbitrary target UUID; cross-profile side-effect risk identified by body review.
- `get_trending_scholarship_ids(integer,integer)`: browser EXECUTE with caller-controlled threshold/window.
- `get_scholarship_social_proof(uuid)`: exact aggregate output and browser EXECUTE.
- `get_scholarship_discussions(uuid,text,integer)`: public identity/presence fields and browser EXECUTE.
- `publish_discovery_candidate(uuid)`: privileged write RPC with in-body readiness/authorization gates; still requires staging tests and a narrow grant.

Trigger-returning functions were not invoked. Their catalog EXECUTE grants must not be confused with demonstrated ordinary RPC invocability.

## Required questions

1. **Can an anonymous client address underlying catalogue tables?** Yes for `scholarships` and `opportunities`, based on safe 200 empty responses; complete catalogue-table coverage is not tested.
2. **Can an authenticated non-admin client address them?** Unverified. No authenticated test JWT was available or created.
3. **Are internal columns accessible through an exposed route?** Not tested. No real row or internal column was requested.
4. **Can an anonymous client invoke the sensitive RPCs?** Database/advisor metadata confirms anonymous EXECUTE grants for the listed functions, but no function was invoked; HTTP execution is therefore not claimed.
5. **Can a non-admin authenticated client invoke them?** Unverified without a test JWT and staging fixtures.
6. **Are private student records protected by RLS at the API boundary?** RLS policies exist and the safe impossible-profile probe returned no rows, but two-user authenticated negative tests are still required.
7. **Is TRUNCATE reachable through demonstrated HTTP?** No. No destructive or unauthorized probe was made, and no HTTP TRUNCATE route was demonstrated.
8. **Are trigger-only functions invocable through PostgREST?** Not tested. Catalog return type and trigger context suggest ordinary RPC behavior may be rejected, but this remains unverified.
9. **Are Resource Center projections safe under current ownership/RLS semantics?** Not established. They are addressable and allowlisted, but owner-execution/security-definer semantics require staging negative tests.

## Limitations and next evidence

The production API configuration remains unavailable through the inspected metadata. The next safe step is to obtain the deployed API schema configuration from an authoritative Supabase project-settings source or an approved service-admin export, without exposing keys. Staging must then be reconstructed with synthetic fixtures before authenticated, role-specific, RPC, column, view, and trigger tests are run.

## References

[1]: https://github.com/ImperioKDB/Scholars/commit/cf3682ce35912df7b9b9352193630fc404427c7c "Scholars production application baseline"
[2]: https://github.com/ImperioKDB/Updates/commit/7f7eb680562b6e89c0172b5534848f2b576002c0 "Phase 2.1.1 security audit handoff"
[3]: https://supabase.com/docs/guides/database/database-linter "Supabase database security advisors"
