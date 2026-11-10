# Scholars Phase 2.1.4 — PostgREST Configuration Access Plan

**Investigation date:** 2026-11-10
**Scope:** Read-only access design. No token, key, password, JWT, or project setting was requested or stored.

## Supported endpoint

Supabase documents the read-only Management API endpoint:

`GET https://api.supabase.com/v1/projects/{ref}/postgrest`

The project reference must be supplied separately for production `cmdglabohpttgfofcmqc` and staging `aqhktriwaglvvrchxmtd`. The endpoint requires OAuth scope `rest:read`. The fine-grained token must include `data_api_config_read`; the documented endpoint also permits the secret-read variant when secret configuration fields are authorized. [1]

The documented response includes `db_schema`, `db_extra_search_path`, pool settings, and related PostgREST service configuration. A response may contain sensitive fields such as JWT-related configuration; those fields must be redacted before evidence is saved or shared. The Management API itself requires an Authorization bearer token, and Supabase recommends scoped PATs or OAuth rather than broad credentials. [2]

## Exact read-only procedure

A project administrator should perform two independent reads, one for each project ref, using a short-lived scoped PAT or OAuth token held only in the administrator's secure environment:

```bash
curl --fail --silent --show-error \
  "https://api.supabase.com/v1/projects/$PROJECT_REF/postgrest" \
  -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN"
```

The administrator should save a sanitized record containing the project ref, UTC timestamp, endpoint, non-secret response fields, and HTTP status. The token must not be pasted into chat, committed to GitHub, placed in a report, or written to terminal output captured for this project. The administrator should destroy the unsanitized response after extracting the approved fields.

The same procedure must be run separately for production and staging. Do not assume that the staging response is equal to production. The current read-only database settings surface returned `NULL` for the inspected `pgrst` settings in both projects, which means SQL catalog inspection did not expose the configured values; it does not establish that the values are unset. [3]

## Fields and limitations

The documented endpoint can establish:

- `db_schema`, which must be reconciled with the Dashboard's **Exposed schemas** setting.
- `db_extra_search_path`.
- Relevant pool and row-limit settings.
- Other non-secret fields returned by the current endpoint contract.

The reviewed endpoint documentation does not expose every requested operational setting. In particular, `db-anon-role` and `openapi-mode` were not present in the documented response/body fields reviewed for this phase. They must be obtained from a supported project-settings export or another project-administrator read path rather than inferred from route behavior.

Supabase separately documents a Management API OpenAPI endpoint, `GET /v1/projects/{ref}/database/openapi`, which can retrieve the PostgREST OpenAPI specification for a selected schema. It is an authorized inspection mechanism, not a substitute for configuration values. [4]

Supabase's custom-schema documentation identifies the Dashboard API Settings **Exposed schemas** control and the required schema grants. The final evidence package should therefore include the sanitized exposed-schema list plus catalog evidence for schema usage and object grants. [5]

## Reconciliation checks

For each project, compare the sanitized Management API record against:

1. The project ref and health metadata.
2. The selected exposed schema list from the Dashboard or authorized project export.
3. `pg_namespace` schema names and owners.
4. Browser-role USAGE and object grants.
5. Public OpenAPI metadata where authorized.
6. Application client configuration and the route dependency matrix.

Differences must be recorded as explicit baseline decisions. Do not “fix” them during this phase.

## Status

Production and staging are both currently reported as `ACTIVE_HEALTHY` through read-only project metadata. Staging has no Scholars application relations or storage buckets in the current catalog checks. PostgREST configuration equality remains unverified because no authorized Management API response or sanitized Dashboard export was available to this session. [3]

## Required approvals

The project administrator must approve the scoped-token read and the sanitized evidence fields. The founder must approve any decision to make the new staging API surface match production or to intentionally change public exposure. No token or setting change is required for this report.

## References

[1]: https://supabase.com/docs/reference/api/v1-get-postgrest-service-config "Supabase Management API — Get PostgREST config"
[2]: https://supabase.com/docs/reference/api/introduction "Supabase Management API authentication"
[3]: https://github.com/ImperioKDB/Updates/blob/main/SCHOLARS_PHASE_2_1_3_POSTGREST_CONFIGURATION_VERIFICATION_2026-11-09.md "Phase 2.1.3 PostgREST verification"
[4]: https://supabase.com/docs/reference/api/v1-get-database-openapi "Supabase Management API — Get PostgREST OpenAPI spec"
[5]: https://supabase.com/docs/guides/api/using-custom-schemas "Supabase custom schemas and exposed schemas"
