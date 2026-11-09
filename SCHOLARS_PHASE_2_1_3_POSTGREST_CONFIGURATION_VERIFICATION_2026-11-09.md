# Scholars Phase 2.1.3 — PostgREST Configuration Verification

**Investigation date:** 2026-11-09
**Status:** Read-only configuration investigation; no API settings or database configuration were changed.
**Verdict:** Configuration remains **unverified** through the available connector.

## What was attempted

For both production `cmdglabohpttgfofcmqc` and staging `aqhktriwaglvvrchxmtd`, direct read-only SQL checks for `pgrst.db_schemas`, `pgrst.db_extra_search_path`, `pgrst.db_anon_role`, and `pgrst.openapi_mode` returned `NULL`. This means those settings were not exposed through the inspected database `pg_settings` surface; it does not prove that the values are unset.

The anonymous production `GET /rest/v1/` OpenAPI request returned HTTP 401 with a response stating that only a service-role key can use that endpoint. No service-role key was requested or used. This result does not establish the full exposed-schema configuration.

The available Supabase MCP tool inventory had no read-only project PostgREST-config action. It exposed project metadata, migrations, SQL inspection, advisors, and documentation search, but not the Management API configuration endpoint.

## Supported administrative mechanism found

Supabase documents a Management API endpoint:

`GET https://api.supabase.com/v1/projects/{ref}/postgrest`

The documented read operation requires OAuth `rest:read` and a fine-grained token with `data_api_config_read` or `data_api_config_read` plus `data_api_config_secret_read`. The documented response includes `db_schema`, `db_extra_search_path`, pool settings, and related PostgREST service configuration. [1]

Supabase also documents `GET /v1/projects/{ref}/database/openapi` as the Management API replacement for querying `/rest/v1/` directly with an anonymous key. It accepts an optional schema parameter and requires Management API authorization. [2]

The public API settings workflow is also authoritative for custom schemas: Supabase states that custom schemas are added under Dashboard **Project Settings → API → Exposed schemas**, followed by the required schema grants. [3]

## Setting-by-setting status

| Requested setting | Direct SQL result | Supported read path found | Status |
|---|---|---|---|
| `db-schemas` / exposed schemas | `NULL` from `current_setting` | Dashboard API settings export or authorized Management API/OpenAPI inspection | Unverified |
| `db-extra-search-path` | `NULL` from `current_setting` | `GET /v1/projects/{ref}/postgrest` | Unverified |
| `db-anon-role` | `NULL` from `current_setting` | Requires project-admin/platform configuration export; not returned in the public endpoint schema reviewed | Unverified |
| `openapi-mode` | `NULL` from `current_setting` | Requires project-admin/platform configuration export; not returned in the public endpoint schema reviewed | Unverified |

The Management API reference uses `db_schema` singular in its response/body contract, while the product dashboard refers to **Exposed schemas**. The exact serialized value and whether it contains one or multiple schemas must be captured from the authorized response rather than inferred from HTTP route behavior.

## Exact supported access needed next

A project administrator should run the read-only Management API request for both refs using a scoped PAT or OAuth token with only the required read scope, or export the API settings from the Supabase dashboard. The token must not be sent to this session, written to a report, or displayed in logs. If the response omits `db-anon-role` and `openapi-mode`, the administrator must provide the corresponding read-only project configuration export or dashboard evidence.

The next evidence package should contain only sanitized field names and values for both projects, plus the export timestamp and project ref. It should not contain API keys, database credentials, JWTs, or access tokens.

## Conclusion

Phase 2.1.3 resolves the supported retrieval method but does not resolve the values. Production and staging PostgREST configuration equality remains unverified. Route addressability and the anonymous `/rest/v1/` 401 response are not substitutes for an administrative configuration read.

## References

[1]: https://supabase.com/docs/reference/api/v1-get-postgrest-service-config "Supabase Management API — Get project's PostgREST config"
[2]: https://supabase.com/docs/reference/api/v1-get-database-openapi "Supabase Management API — Get PostgREST OpenAPI spec"
[3]: https://supabase.com/docs/guides/api/using-custom-schemas "Supabase — Using custom schemas and exposed schemas"
[4]: https://supabase.com/docs/reference/api/introduction "Supabase Management API authentication and scopes"
