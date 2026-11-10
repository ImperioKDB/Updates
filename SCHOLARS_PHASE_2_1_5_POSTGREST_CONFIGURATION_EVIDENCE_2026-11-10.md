# Scholars Phase 2.1.5 — PostgREST Configuration Evidence

**Evidence window:** 2026-11-10, 10:25–10:32 CET (UTC+01:00)
**Scope:** Read-only PostgREST configuration status for production and staging. No configuration was changed.

## Finding

**PostgREST configuration remains unverified for both projects.** This is an authorization-path blocker, not evidence that a setting is absent or unset.

## Method and project identity

The production and staging references were re-confirmed through the Supabase project metadata connector. Production is `cmdglabohpttgfofcmqc` (`scholarship-platform`, `eu-west-1`, `ACTIVE_HEALTHY`, PostgreSQL 17.6.1.155). Staging is `aqhktriwaglvvrchxmtd` (`scholars-staging`, `eu-west-1`, `ACTIVE_HEALTHY`, PostgreSQL 17.11.0.018).

Supabase documents `GET https://api.supabase.com/v1/projects/{ref}/postgrest` as the supported read endpoint. It requires OAuth scope `rest:read` and fine-grained permission `data_api_config_read`. The response can include a `jwt_secret` field, which must not be retained or shared. The secret-read permission is not needed for the requested sanitized fields and must not be added. [1] [2]

The authenticated Supabase MCP session reports that an OAuth token is stored, but it does not disclose that token's scopes. The available MCP tools include project metadata and database inventories, but no PostgREST service-configuration GET operation. This review did not extract or expose a token and did not make a raw Management API request without verified scopes. A prior Phase 2.1.5 note records an unauthenticated request returning HTTP 401; that response proves no configuration value and is not a test of a correctly scoped token. [3]

## Required fields

| Field or question | Production | Staging | Status |
|---|---|---|---|
| `db_schema` / exposed schemas | Not obtained | Not obtained | Requires authorized Management API read or approved settings export |
| `db_extra_search_path` | Not obtained | Not obtained | Requires authorized Management API read or approved settings export |
| `max_rows` and pool settings | Not obtained | Not obtained | Requires authorized Management API read or approved settings export |
| Anonymous role / `db-anon-role` | Unresolved | Unresolved | Not confirmed by the documented response reviewed in prior phases |
| OpenAPI mode | Unresolved | Unresolved | Not confirmed by the documented response reviewed in prior phases |
| JWT-related configuration | Not requested or retained | Not requested or retained | No secret-read permission used |

A previous `current_setting(..., true)` result of `NULL` is not proof that a setting is unset. The production and staging exposed-schema lists therefore cannot be inferred from SQL catalog results or from route addressability. [3] [4]

## Security implications and next evidence

The public API surface cannot be approved until the administrator provides sanitized configuration evidence for both refs. The evidence should contain only project ref, retrieval time, HTTP status, `db_schema`, `db_extra_search_path`, and other approved non-secret fields. Do not include bearer tokens, JWT values, database credentials, or the unsanitized response.

The next safe step is for an authorized project administrator to use a short-lived token whose scopes are verified as `rest:read` and `data_api_config_read`, or to provide an approved sanitized Dashboard export. If neither is available, retain this blocker. Do not substitute the broader alpha project-configuration endpoint or change project settings.

## Limitations

No Management API GET was performed in this review because the only available MCP session did not surface the required scopes or provide the endpoint operation. No PostgREST value is claimed as confirmed. No setting, role, schema, or application object was modified.

## Confirmed facts and inference

- **Confirmed:** The project refs and status are as listed above; MCP reports an authenticated OAuth session but does not expose its scopes; no authorized PostgREST GET was made in this review.
- **Inference:** The configuration cannot be approved without a valid scoped read. This does not imply any particular exposed schema, anonymous role, or OpenAPI setting.

## Unresolved questions

Production and staging `db_schema`, `db_extra_search_path`, anonymous-role behavior, OpenAPI mode, and other non-secret PostgREST fields remain unknown. The scope status of the stored MCP token is also unknown.

## References

[1]: https://supabase.com/docs/reference/api/v1-get-postgrest-service-config "Supabase Management API Get PostgREST Configuration"
[2]: https://supabase.com/docs/guides/platform/personal-access-tokens "Supabase Personal Access Tokens and Permission Scopes"
[3]: https://github.com/ImperioKDB/Updates/blob/a88ab72fcdddd58fe28315a1c04229a09511ab77/SCHOLARS_PHASE_2_1_5_POSTGREST_CONFIGURATION_EVIDENCE_2026-11-10.md "Prior Phase 2.1.5 PostgREST Evidence"
[4]: https://github.com/ImperioKDB/Updates/blob/3d3da285f1b076fbfebb1fdf1adbaadeb178d71f/SCHOLARS_PHASE_2_1_4_POSTGREST_CONFIGURATION_ACCESS_PLAN_2026-11-09.md "Phase 2.1.4 PostgREST Access Plan"
