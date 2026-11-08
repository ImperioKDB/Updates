# File

- **Path:** `/tmp/scholars-a03-snapshot/scholars-41573f5/supabase/migrations/0105_seed_unhcr_kectil_unwomen_wit_2026.sql`
- **Migration:** `0105_seed_unhcr_kectil_unwomen_wit_2026.sql`
- **Audit mode:** Static, read-only inspection of this file only. No SQL was executed, no Supabase instance or hosted service was started or accessed, and the snapshot was not modified.

# Scope

This review covers only the contents of migration `0105_seed_unhcr_kectil_unwomen_wit_2026.sql`. The file consists of one anonymous PostgreSQL `DO` block named by the dollar-quoted tag `$migration$`. It performs conditional seed/upsert-like mutations for three rows in `public.opportunities`: the UNHCR Internship Programme, Kectil Program 2027, and the UN Women x Women in Tech Global Programme Registration.

The request calls for special attention to the final two security/Resource Center migrations. Those objects are not present in this file: there is no Resource Center object, security policy, grant/revoke, view, security function, or related DDL here. Because the scope is expressly restricted to this one migration, adjacent or earlier migrations were not inspected, so no claims are made about objects that may exist elsewhere or about the runtime state of any dependency.

# Objects and mutations

## Procedural object

- One anonymous `DO $migration$ ... $migration$;` block is executed when the migration runs.
- The block declares one local variable, `v_id uuid`.
- The block contains three repeated `SELECT ... INTO`, conditional `INSERT`/`UPDATE`, and `IF ... ELSE` sequences.
- It does not create a persisted function or procedure. The anonymous block itself is not a durable database object after execution.

## DDL

No DDL is present. The file does not create, alter, or drop tables, columns, indexes, constraints, views, materialized views, functions, triggers, types, schemas, roles, policies, or extensions.

## DML and row-selection behavior

All database mutations target `public.opportunities`.

1. **UNHCR Internship Programme**
   - Finds at most one existing row where `application_url = 'https://unhcr.wd3.myworkdayjobs.com/External'` or `lower(title) = lower('UNHCR Internship Programme')`.
   - If multiple rows match, selects the one with the latest `created_at`, limited to one row.
   - If no match is found, inserts one row with `type = 'internship'` and populated title, provider, description, eligibility, duration, location, compensation, discipline, application URL, instructions, verification flag, and research notes. `deadline` and `opens_at` are explicitly `NULL`.
   - If a match is found, updates that row with the same content, including resetting `deadline` and `opens_at` to `NULL` and setting `verified = true`.

2. **Kectil Program 2027**
   - Finds at most one existing row where `application_url = 'https://kectil.com/apply'` or `lower(title) = lower('Kectil Program 2027')`.
   - Uses the latest matching `created_at` when more than one row matches.
   - If absent, inserts one row with `type = 'training'`, a deadline of the date literal `'2026-11-15'`, a Kectil application URL, and descriptive, eligibility, compensation, and research-note content. `opens_at` is `NULL`.
   - If present, updates the selected row with the same values, including the deadline and `verified = true`.

3. **UN Women x Women in Tech Global Programme Registration**
   - Finds at most one existing row where `application_url = 'https://women-in-tech.typeform.com/UNWIT'` or `lower(title) = lower('UN Women x Women in Tech Global Programme Registration')`.
   - Uses the latest matching `created_at` when multiple rows match.
   - If absent, inserts one row with `type = 'training'`, a public Typeform URL, qualified/limited programme information, and `verified = true`. `duration`, `location`, `deadline`, and `opens_at` are explicitly `NULL`.
   - If present, updates the selected row with the same values, including the qualification that the public form does not establish complete eligibility, selection, benefits, duration, location, or deadline.

## Grants and revokes

No `GRANT` or `REVOKE` statements are present. No role or privilege is created, changed, or removed by this migration.

## Security, policies, views, functions, and constraints in this file

None are defined or mutated. There are no row-level security statements, policies, security-definer functions, views, privilege changes, or explicit constraint declarations. The only function-like constructs are built-in SQL expressions/functions used by the block (`lower`, `coalesce` is not used, and `order by`/`limit`) and the anonymous procedural block itself; this file does not define them.

# Dependencies

The migration has the following statically visible dependencies:

- The existing schema object `public.opportunities` must exist before execution.
- The table must expose at least the columns read or written here: `id`, `application_url`, `title`, `created_at`, `type`, `provider_name`, `description`, `eligibility_notes`, `duration`, `location`, `compensation`, `discipline`, `deadline`, `opens_at`, `how_to_apply`, `verified`, and `research_notes`.
- `id` must be assignable to the local variable type `uuid`; the selected row ID is returned into `v_id` and later used in `where id = v_id`.
- `created_at` must be orderable for the `order by created_at desc` selection.
- The table’s actual column types and constraints are not verified here. In particular, the date-like literals and null assignments presume compatibility with the target column definitions.
- The block assumes the migration runs with sufficient privileges to select from and insert/update `public.opportunities`; it does not grant those privileges itself.
- The code relies on PostgreSQL procedural SQL support for `DO`, declarations, `IF`, `SELECT ... INTO`, and `RETURNING ... INTO`.

There is no explicit dependency on a Resource Center table, security policy, view, function, or privilege object in this file. Since no other migration was inspected, ordering dependencies beyond the directly referenced table cannot be established. The referenced table and its columns must precede this migration in the effective schema, while any later security or Resource Center migrations would see the rows only after this block commits.

# Data/external-side-effect assessment

This is real-content seed data rather than synthetic placeholder data. It inserts or overwrites descriptive opportunity records concerning named external organisations and programmes. The content includes eligibility, duration, compensation, deadlines, application instructions, verification flags, and research notes.

The file contains external URLs as stored text, including:

- UNHCR Workday recruitment URL and UNHCR careers/internship research URL.
- Kectil application, homepage, programme, and research URLs.
- Women in Tech Global Typeform registration URL and organisation website.

Those URLs are not fetched by the SQL. The migration has no HTTP client, FDW access, external function call, webhook, or form submission. It therefore has no evident network-side effect during execution. The research notes state that the source material was checked on `2026-11-04`; that claim is content stored in the row and is not runtime verification performed by this audit.

The UN Women record explicitly states that no form response was submitted and no personal data was entered. The migration itself inserts no applicant records and contains no user-submitted personal data. Nevertheless, the `how_to_apply` text points users to an external form that may collect sensitive or personal information; that is an application-content consideration, not a database side effect of this migration.

The data is time-sensitive: Kectil has a `2026-11-15` deadline, while UNHCR is represented as rolling with no deadline and the UN Women registration record intentionally leaves key programme fields unknown. Re-running the migration is not a no-op if an existing matching row has been edited: it may overwrite that row with the file’s values.

# Security/ordering implications

- **No security changes:** There are no grants, revokes, RLS policies, security-definer routines, views, or role changes. The migration does not establish or weaken access control.
- **Privilege prerequisite:** The executing migration identity still needs read and write permissions on `public.opportunities`; absence of explicit grants here means those permissions must come from pre-existing ownership/privilege configuration.
- **Search/update ambiguity:** Matching uses an `OR` between application URL and case-insensitive title, then chooses the newest `created_at`. If duplicate or conflicting rows exist, only one is updated; other duplicates remain. This is application-level deduplication, not a declared unique constraint.
- **Potential overwrite:** Existing matching rows are broadly rewritten, including fields set to `NULL` and `verified = true`. Any local edits, changed deadline, or richer content in the selected row may be lost on rerun.
- **No explicit transaction boundary beyond normal `DO` execution:** The block is one anonymous procedural statement. Static inspection cannot establish the migration runner’s broader transaction behavior or how failures interact with surrounding migrations.
- **Ordering:** `public.opportunities` and all referenced columns must already exist. If later policies, views, or Resource Center projections depend on these rows, they should be applied after the table and this seed are available; however, this file does not define or reference such projections.
- **No runtime verification:** This review does not confirm whether the SQL parses, whether the target table has the expected schema, whether policies would permit the writes, whether rows already exist, or whether any external URL is currently reachable.
- **Final security/Resource Center migrations:** No such objects occur in the inspected file. It is therefore not possible, within the one-file scope, to map or verify the final two migrations’ objects, policies, privileges, views, functions, constraints, or dependencies. Any claim about them would require inspecting prohibited additional files.

# Reconstruction recommendation

For a **synthetic schema reconstruction**, this migration can generally be omitted as application data seeding rather than schema definition. Omitting it does not remove any table, column, constraint, policy, view, function, grant, or revoke defined here because the file defines none of those objects.

If behavioral or fixture fidelity is required, retain a sanitized equivalent seed separately and preserve the three records’ broad shape, nullable date/location fields, external-link fields, and verification metadata. Do not treat this file as sufficient evidence for reconstructing `public.opportunities`: its required table schema and constraints are dependencies supplied elsewhere, and those other migrations were intentionally not inspected.

If reconstructing migration ordering, place the seed only after `public.opportunities` and its referenced columns exist. Treat it as an optional content migration, not as a security or Resource Center migration. Because it contains real organisation/programme content and mutable external URLs/deadlines, a synthetic reconstruction should normally replace the values with clearly synthetic fixtures or omit the rows entirely unless the goal is content-level fidelity.

# Verdict

**Omit from a synthetic schema reconstruction, with caveat.** This file contains no DDL, grants, revokes, persisted functions, views, policies, constraints, or Resource Center/security objects. Its sole substantive effect is conditional insertion or update of up to three real-content rows in the pre-existing `public.opportunities` table. It may be retained only when those seeded opportunity records and their external-link/content behavior are explicitly part of the reconstruction target. No runtime behavior, source reachability, existing-row state, policy outcome, or adjacent migration dependency was verified.
