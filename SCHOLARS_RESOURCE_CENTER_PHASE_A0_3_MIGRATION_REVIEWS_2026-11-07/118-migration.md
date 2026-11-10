# File

`/tmp/scholars-a03-snapshot/scholars-41573f5/supabase/migrations/0099_seed_user_verified_tpac_kapp_snepco_2026.sql`

The file is a 191-line anonymous PL/pgSQL `DO` block named only by the surrounding migration filename. It is explicitly a user-confirmed 2026 opportunity seed for NNPC–SNEPCo, TPA, and KAPP.

# Scope

This audit is strictly read-only and covers only the migration named above. The migration performs conditional data seeding and refreshes existing records; it does not define or alter database structure. It declares three UUID variables, looks up records by canonical application URL or case-insensitive title, inserts missing records, updates a selected existing record, and adds missing scholarship eligibility rules.

# Objects and mutations

## DDL

None. There are no `CREATE`, `ALTER`, `DROP`, `TRUNCATE`, index, constraint, function, trigger, enum, or policy statements.

## DML and procedural operations

The block uses `SELECT ... INTO`, `IF`, `IF NOT EXISTS`, `INSERT`, and `UPDATE`:

1. **`public.scholarships` — one record**
   - Looks up the NNPC–SNEPCo scholarship by exact `application_url` or case-insensitive `title`, ordering by `created_at DESC` and taking one row.
   - If absent, inserts one scholarship with title, provider, narrative description, amount text, `2026-11-30` deadline, canonical Scholastica URL, `undergrad` level, `discipline = null`, `verified = true`, research notes, application instructions, and `last_verified_at = now()`.
   - If present, updates those same substantive fields and refreshes `last_verified_at` with `now()`.

2. **`public.scholarship_rules` — up to three records**
   - For the selected scholarship, checks for and inserts (only when absent) three gating rules:
     - `nationality eq "Nigeria"`
     - `year_of_study eq 200`
     - `gpa gte 3.5`
   - The checks compare `scholarship_id`, `field`, `operator`, and JSONB `value`; each query is limited to one result. Existing matching rules are left unchanged. There is no deletion or replacement of nonmatching rules.

3. **`public.opportunities` — two records**
   - **TPA Colloquium National Essay & Article Competition 2026:** looks up by the supplied Google Forms URL or case-insensitive title. It inserts if absent, otherwise updates the selected row. The mutation sets `type = 'competition'`, title/provider, description, eligibility, duration, location, compensation, discipline, `deadline = 2026-10-30`, `opens_at = 2026-10-01`, application URL, instructions, `verified = true`, and research notes.
   - **Kayode Aderinokun Poetry Prize (KAPP) 2026:** looks up by the supplied Google Forms URL or case-insensitive title. It inserts if absent, otherwise updates the selected row. It sets `type = 'competition'`, title/provider, descriptive and eligibility text, duration, location, compensation, discipline, null deadline and opening date, application URL, instructions, `verified = true`, and research notes.

## Grants and revokes

None. The migration contains no `GRANT`, `REVOKE`, role, ownership, or privilege changes.

# Dependencies

The migration depends on the pre-existing `public` schema and these tables and columns:

- `public.scholarships`: `id`, `application_url`, `title`, `created_at`, plus writable fields `provider_name`, `description`, `amount`, `deadline`, `level`, `discipline`, `verified`, `research_notes`, `how_to_apply`, and `last_verified_at`.
- `public.scholarship_rules`: writable `scholarship_id`, `field`, `operator`, `value` (JSONB-compatible), and `gating`; readable `scholarship_id`, `field`, `operator`, and `value`.
- `public.opportunities`: `id`, `application_url`, `title`, `created_at`, plus all fields written by the two insert/update branches: `type`, `provider_name`, `description`, `eligibility_notes`, `duration`, `location`, `compensation`, `discipline`, `deadline`, `opens_at`, `how_to_apply`, `verified`, and `research_notes`.

It also relies on PostgreSQL/PL/pgSQL features and types: anonymous `DO` blocks, variables of type `uuid`, `jsonb` casts and equality, `lower()`, `now()`, `ORDER BY ... LIMIT`, `IF`, and `RETURNING`. The referenced tables must already exist with compatible types, and the executing role must have read/write access to them. No other migration was inspected, so the ordering of the table definitions, column definitions, constraints, or RLS policies is not established here; this file must run after the referenced schema objects exist.

The lookup is not a strict unique-key operation: it accepts either URL or title, orders by `created_at DESC`, and updates whichever one row is selected. The rule insertion checks are application-level idempotency checks rather than a stated reliance on a unique constraint.

# Data/external-side-effect assessment

This is real-looking, user-facing seed content rather than synthetic fixture data. It records named 2026 opportunities and contains factual claims about eligibility, awards, dates, instructions, verification, and organizers. It embeds external URLs, including:

- Scholastica campaign and canonical scheme URLs for NNPC–SNEPCo.
- The TPA Colloquium announcement URL and Google Forms submission URL.
- The KAPP Google Form, an independent 2026 listing, and a background page.

The SQL itself does not make HTTP requests, submit forms, send messages, or otherwise contact those URLs. The URLs are stored as text in database rows and could later be rendered or followed by application users. The data is time-sensitive: the NNPC–SNEPCo and competition dates are fixed to 2026, while KAPP deliberately stores null deadline/opening values because the supplied form did not state a final deadline. The migration also stores detailed research notes and application instructions as durable content, including a phone/email-collecting external form reference and warnings about fees, plagiarism, and AI-generated entries.

The mutation can overwrite existing records selected by title or URL, including changing verification status, deadlines, URLs, descriptions, and other editorial fields. It does not delete rows, remove old rules, or clean up duplicate rows. Re-running is generally repeatable for the selected records, but `now()` changes `last_verified_at` on every existing-scholarship update. Concurrent executions could race between lookup and insert, potentially creating duplicates unless database constraints or serialization prevent that.

# Security/ordering implications

No permissions are broadened or narrowed, and no RLS policies are changed. Nevertheless, execution requires write privileges on the three tables and may be subject to their RLS behavior. If run under a privileged migration role, it can update published opportunity content and mark records verified. The stored external links and instructions are untrusted content from a security perspective: downstream presentation should safely handle URLs and text, and users should be warned that following external forms may disclose personal information. The migration itself does not validate URL destinations, verify current page contents, or enforce the truth of the claims it stores.

The block should run only after all referenced tables and columns, compatible JSONB support, and any required defaults/constraints exist. It should be ordered after schema creation and before any dependent process that expects these seeded IDs or records. Because it uses lookup-by-title-or-URL rather than a declared conflict target, schema-level uniqueness is not established by this file. Existing duplicates are not consolidated, and the `created_at DESC` choice makes the mutation target dependent on existing data. A failure in the anonymous block aborts the statement and rolls back its changes as a unit under normal PostgreSQL transaction semantics, but this file itself does not explicitly issue `BEGIN`, `COMMIT`, savepoints, locks, or isolation settings.

# Reconstruction recommendation

For a **synthetic schema reconstruction**, this migration can be omitted. It contributes no schema objects, constraints, policies, grants, or reusable database behavior; it only loads editorial records and rules tied to a particular 2026 data snapshot. Reconstructing the schema should instead reproduce the referenced table shapes and relevant column types from the schema-defining sources, not these opportunity rows.

If the goal is a **data-faithful application reconstruction** or a fixture that must demonstrate recommendation/filtering behavior, retain it as an optional seed fixture after the base schema. Treat the values as dated editorial data, preserve the external URLs as inert strings, and consider replacing live-looking content with clearly synthetic fixtures. If retained in a production seed, add or verify uniqueness/concurrency protections and independently revalidate the time-sensitive claims and destinations before publication.

# Verdict

**Omit from synthetic schema reconstruction; retain only as optional, explicitly labeled editorial/data fixture.** Mutation class: conditional DML seed/upsert with rule inserts; no DDL, grants, or revokes. It has no structural value, but it does carry real-looking data, external links, and publication/security implications if executed against a live database.
