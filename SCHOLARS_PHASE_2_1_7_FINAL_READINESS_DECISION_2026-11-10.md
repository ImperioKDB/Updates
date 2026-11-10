# Scholars Phase 2.1.7 — Final Readiness Decision

## **BLOCKED — ADMINISTRATOR ACTION REQUIRED**

The environment is not ready for authorized capture. No restricted non-writing PostgreSQL credential is available, and no verified `rest:read` plus `data_api_config_read` authorization exists for the two PostgREST configuration reads. The current device inventory contains only the Manus Sandbox; it lacks `pg_dump` and Docker, and no already-authorized isolated runner was found. No schema extraction, database query, production RPC, privilege change, project configuration change, staging restore, deployment, or new paid resource was used or created in this phase.

This is an administrator-action blocker because the remaining requirements are human-controlled: approve a dedicated least-privilege database login under separate change authorization; provide scoped PostgREST access and sanitized outputs for both projects; and identify an existing private Docker-enabled runner. The dashboard Read-Only role and experimental Management API query endpoint do not provide a supported `pg_dump` connection. No credentials are requested in chat.

The exact remaining actions are in the [administrator action guide](SCHOLARS_PHASE_2_1_7_ADMINISTRATOR_ACTION_GUIDE_2026-11-10.md). Capture may start only after the access and runner checks in the [preflight checklist](SCHOLARS_PHASE_2_1_7_CAPTURE_PREFLIGHT_CHECKLIST_2026-11-10.md) pass and a separate explicit capture authorization is recorded. Existing staging remains off limits for restoration.

## References

[1]: https://supabase.com/docs/guides/database/connecting-to-postgres "Supabase PostgreSQL Connection Methods"
[2]: https://supabase.com/docs/reference/api/v1-get-postgrest-service-config "Supabase Management API Get PostgREST Configuration"
[3]: https://supabase.com/docs/reference/cli/introduction "Supabase CLI Database Dump"
