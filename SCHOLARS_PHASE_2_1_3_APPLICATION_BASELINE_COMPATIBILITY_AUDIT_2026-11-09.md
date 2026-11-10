# Scholars Phase 2.1.3 — Application Baseline Compatibility Audit

**Application baseline:** `cf3682ce35912df7b9b9352193630fc404427c7c`
**Investigation date:** 2026-11-09
**Status:** Read-only application inspection; no application code was changed.

## Baseline integrity facts

The stated baseline contains 129 SQL migration files. The current remote application main contains 132 SQL migration files, including three timestamped migrations corresponding to the three production ledger entries added after the earlier Phase 2.1.2 count. The production ledger currently contains 180 entries. This is a migration-state mismatch, not a build failure by itself, but it prevents the baseline from being treated as a complete production source.

No generated Supabase `Database` type definition was found in the baseline, and no `supabase gen types` command was present in `package.json` or the inspected source. The Supabase clients are therefore effectively untyped at the database schema boundary. This increases the risk that a table, column, enum, function-signature, or view change can pass TypeScript compilation while failing at runtime.

The baseline has three distinct client boundaries:

- `lib/supabase/public.ts` creates an anonymous-key client for genuinely public routes.
- `lib/supabase/server.ts` creates an SSR client with the anonymous key and session cookies, so RLS applies to the caller.
- `lib/supabase/service.ts` is marked `server-only` and creates a service-role client that bypasses RLS for trusted jobs.

The application comments and imports identify public scholarship routes, server-session routes, cron/integration workers, and Resource Center reads. These boundaries must remain separate during any future projection or grant change.

## Database-dependent feature compatibility

The baseline directly depends on the following categories of objects:

| Feature | Baseline dependencies | Provenance status |
|---|---|---|
| Public scholarship catalogue and details | `scholarships`, `scholarship_rules`, `cycle_events`, public client and server readers | Tables exist in production; several source migrations are only name matches or unresolved |
| Opportunity catalogue and saves | `opportunities`, `saved_opportunities`, notification opportunity fields | Production ledger has an opportunity-creation entry, but no exact same-name repository source was recovered |
| Applications and drafts | `applications`, profile/application fields, check-in/click routes | `add_applications_table` and several application follow-up entries are not exact source-name matches |
| Matching and eligibility | `scholarships`, `scholarship_rules`, `profiles`, `waec_results`, cycle data | Matching code assumes these objects and columns; generated DB types are absent |
| Notifications and workers | `notifications`, `notification_deliveries`, `workflow_jobs`, claim/complete functions | Worker objects are present in production; provenance and browser-grant remediation remain unresolved |
| WAEC and profile flows | `waec_results`, `profiles`, `replace_waec_results` | Self-service route exists; source mapping for the initial WAEC table is unresolved by name |
| Discovery/editorial operations | discovery candidates, claims, snapshots, review events, publication functions | Discovery migration chain has multiple ambiguous/unresolved source names |
| Resource Center | `resource_public_*` views and editorial admin objects | Timestamped migration source exists in current main after the stated baseline, not in baseline |
| Cron/integration paths | deadline checks, analytics, discovery jobs, reengagement and outbox functions | Service client boundary exists; literal RPC extraction is incomplete and must not substitute for route review |

A baseline literal scan found 44 distinct `.from("...")` table names. It found one literal `.rpc(...)` call (`flag_expired_opportunities`); many function dependencies are likely wrapped, dynamically composed, or present in code versions outside the exact baseline scan, so this count is not a complete RPC inventory. The Phase 2.1.2 live catalog remains the authoritative function inventory.

## Unresolved assumptions in code

The application assumes that catalogue tables can be read through the public/session-aware clients, that owner/admin RLS policies protect private rows, and that service-side jobs can claim worker rows and send notifications. Those assumptions are structurally plausible but cannot be proven compatible with a reconstructed staging database until the missing migrations and role-specific tests exist.

The application also assumes that public Resource Center views exist and return the columns used by public pages and sitemap generation. Those views are introduced by a current-main migration after the stated baseline, so the baseline and the latest production state are not a single reproducible artifact.

The code has no generated DB type safety net. Before remediation, the application owner should generate types from the approved staging schema, compare the generated tables/views/functions with every call site, and add a reproducible type-generation check to CI. This is a recommendation, not an implementation performed in this phase.

## Compatibility decision

The baseline is **partially compatible by observed object names and current application behavior**, but it is not provenance-complete or reproducibly reconstructable. No application code should be changed until the migration ledger is mapped to exact SQL sources or approved replacements. A blanket browser grant revoke would break direct catalogue, matching, save, application, notification, community, admin, and Resource Center reads identified in Phase 2.1.2.

## References

[1]: https://github.com/ImperioKDB/Scholars/commit/cf3682ce35912df7b9b9352193630fc404427c7c "Scholars application baseline"
[2]: https://github.com/ImperioKDB/Scholars/tree/main/app "Scholars application routes"
[3]: https://github.com/ImperioKDB/Scholars/tree/main/lib/supabase "Scholars Supabase client factories"
[4]: https://github.com/ImperioKDB/Updates/commit/67ec2b5d84491607b13a6efcf1d68c1d1d93c931 "Phase 2.1.2 API dependency matrix"
