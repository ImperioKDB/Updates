# Migration-history audit: `0035_add_retention_events.sql`

## File

- **Path:** `/tmp/scholars-a03-snapshot/scholars-41573f5/supabase/migrations/0035_add_retention_events.sql`
- **Review mode:** Strictly read-only static inspection of this file only.
- **Source length:** 35 numbered lines.
- **Observed purpose:** Replace the `public.events` event-name whitelist with an expanded additive whitelist for retention and product-usage events.

## Scope

This review is limited to the pinned file named above. No SQL was executed, no Supabase instance or hosted service was contacted, and no other migration or source file was inspected. Consequently, historical facts about when or how referenced objects were created, and whether the migration has already been applied, cannot be verified from this file alone.

The file has no transaction wrapper, procedural block, comments indicating data backfill, or statements outside the `public.events` constraint replacement.

## Objects and mutations

### DDL operations

1. **Line 3:**
   ```sql
   alter table public.events
     drop constraint if exists events_event_whitelist;
   ```
   This alters the table `public.events` by dropping a constraint named `events_event_whitelist` if it exists. Because of `IF EXISTS`, a missing constraint does not itself cause this statement to fail.

2. **Lines 6–34:**
   ```sql
   alter table public.events
     add constraint events_event_whitelist check (...);
   ```
   This alters the same table by adding a new named `CHECK` constraint, also named `events_event_whitelist`. The check requires the `event` column value to be one of the listed string literals.

### DML operations

- **None observed.** The migration does not `INSERT`, `UPDATE`, `DELETE`, `MERGE`, `SELECT`, or otherwise read or mutate row data directly.
- Adding the check constraint can nevertheless cause an implicit validation scan or fail if existing rows violate the new predicate; that is a schema-enforcement effect rather than a DML statement.

### GRANT/REVOKE operations

- **None observed.** No privileges, ownership, role membership, default privileges, or security labels are changed.

### Created or altered objects

- **Altered:** `public.events`.
- **Dropped conditionally:** the existing constraint `public.events.events_event_whitelist` (constraint namespace is associated with `public.events`).
- **Created:** a replacement `events_event_whitelist` `CHECK` constraint on `public.events`.
- **Not created or altered:** tables, columns, indexes, sequences, views, materialized views, functions, triggers, RLS policies, roles, extensions, schemas, grants, or revokes.

### Effective whitelist

The replacement constraint accepts exactly these 25 literal event names:

`profile_created`, `profile_completed`, `onboarding_step_viewed`, `onboarding_step_completed`, `onboarding_abandoned`, `provisional_matches_viewed`, `match_viewed`, `scholarship_saved`, `scholarship_issue_reported`, `application_started`, `provider_clicked`, `application_status_changed`, `draft_generated`, `draft_confirmed`, `gap_nudge_clicked`, `button_clicked`, `weekly_focus_viewed`, `weekly_focus_actioned`, `outcome_recorded`, `whatsapp_opt_in`, `whatsapp_opt_out`, `page_viewed`, `web_vital`, and `client_error`.

The SQL does not explicitly state how `NULL` is handled. Under ordinary PostgreSQL `CHECK` semantics, a `NULL` result satisfies the check; whether `event` is nullable cannot be determined from this file.

## Dependencies

### Direct object dependencies

- The table `public.events` must exist before execution.
- The table must contain a column named `event`; otherwise the `ADD CONSTRAINT ... CHECK` statement fails.
- The existing constraint may or may not exist. The drop is tolerant of its absence, but the subsequent add is not tolerant of a pre-existing constraint with the same name.

### Earlier tables and columns

- **Earlier table dependency:** `public.events` is required, but the migration does not prove which earlier migration created it.
- **Earlier column dependency:** `public.events.event` is required for the new check expression.
- No other table or column names are referenced.

### Roles and privileges

- No role names or privilege statements appear.
- The executing role must nevertheless have sufficient authority to alter `public.events`, drop the named constraint if present, and add the replacement constraint. The exact required privileges and the identity of the migration runner are not stated here.
- Existing grants and ownership are not changed by the SQL shown.

### Extensions and functions

- No extension names, function calls, operators beyond the ordinary `IN`/equality semantics, or user-defined functions are referenced.
- The check relies on standard PostgreSQL constraint functionality and string comparison. Collation/operator-resolution details are not specified in the file and cannot be fully characterized without database metadata.

### Triggers and policies

- No triggers or RLS policies are created, altered, enabled, or disabled.
- Existing triggers, RLS policies, and application write paths may still be affected indirectly: writes that use an event value outside the replacement whitelist can begin failing once the constraint is installed.

### Privileges and dependency history

- No privilege dependency is declared in the file beyond the executor’s ability to perform the `ALTER TABLE` operations.
- Whether the prior constraint had a different definition, whether another constraint already protects `event`, and whether dependent objects or application code expect additional event names cannot be verified without inspecting the database or other migrations.

## Data/external-side-effect assessment

- **Real-data access:** No `SELECT` or other query is present.
- **Real-data mutation:** No direct row mutation is present. PostgreSQL may validate existing rows while adding the check; this can read/scan table contents internally and can fail if any existing non-`NULL` `event` value is not in the list. The file does not perform a data rewrite or backfill.
- **External URLs/content:** None. There are no URLs, network calls, file references, payloads, secrets, or embedded real-user data.
- **Operational side effects:** The two DDL statements can acquire locks on `public.events`; constraint validation may take time proportional to table size and can contend with concurrent activity. The file does not specify `NOT VALID`, so the new constraint is expected to be validated during addition under normal PostgreSQL behavior.

## Security/ordering implications

1. **Destructive intermediate step:** The migration drops the old whitelist before adding the replacement. If the second statement fails, the table can be left without the old `events_event_whitelist` constraint when the statements are not enclosed in an effective transaction. Many migration runners wrap migrations in a transaction, but this file does not establish that guarantee.
2. **Narrowing or changing accepted values:** Despite the comment calling this an additive whitelist update, the replacement definition is authoritative. Any event value accepted by the old constraint but absent from this list will be rejected after the new constraint is installed. The old definition is not available in this file, so “additive” cannot be independently verified.
3. **Existing-row compatibility:** Addition can fail if existing rows contain a non-`NULL` event value not listed. This is the main data-dependent execution risk.
4. **Concurrent writers:** Writers using newly disallowed or misspelled event names may start receiving constraint violations. The migration can also block or be blocked by concurrent access while altering the table.
5. **Constraint-name collision:** If the old named constraint is absent but another object or constraint with the same applicable name already exists on `public.events`, the `ADD CONSTRAINT` can fail. The `DROP ... IF EXISTS` does not make the add idempotent.
6. **Ordering requirement:** The base `public.events` table and its `event` column must precede this migration. Any application or later migration that writes event names outside the listed set must follow the new contract or be ordered before a compatible constraint change.
7. **No direct privilege escalation:** The file contains no `GRANT`, `REVOKE`, role, RLS, or ownership change. Its security effect is integrity enforcement through the event whitelist, not access-control modification.

## Reconstruction recommendation

For a **synthetic schema reconstruction**, this migration can generally be **omitted as a standalone historical migration** if the reconstruction already creates `public.events` with the desired final `event` check constraint. Replaying the drop-and-add sequence is unnecessary for a final-state schema and introduces avoidable ordering, lock, validation, and partial-failure risks.

It should **not** be omitted when the reconstruction aims to reproduce the exact migration history, intermediate states, or compatibility behavior of the original schema. In that case, retain the semantic effect—preferably by defining the final constraint directly after creating `public.events`—and document that the original file replaced an earlier constraint.

Before applying this migration to a live or data-bearing database, independently verify the existing table definition, current constraint definition, all stored `event` values (including `NULL` policy), migration-runner transaction behavior, and application event vocabulary. Those checks require inspecting the database or other files and were intentionally not performed here.

## Verdict

**PARTIALLY VERIFIED** — The complete set of operations, referenced object names, whitelist literals, absence of DML/GRANT/REVOKE, and absence of URLs or external calls are directly verified from the file. The migration is **not safe to execute blindly** because the file alone cannot establish that `public.events` and `event` exist, that all existing values satisfy the replacement whitelist, that the old constraint has the expected definition, that no name collision exists, or that the drop/add sequence is protected by a transaction. For a final-state synthetic schema, it may be omitted as a historical replay when its final constraint semantics are represented elsewhere.
