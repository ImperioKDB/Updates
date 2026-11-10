# File

`supabase/migrations/0079_enable_push_channel_for_notification_outbox.sql`

# Scope

This is a strictly static, read-only review of the specified migration file only. No SQL was executed, no Supabase instance or hosted service was accessed, and the source snapshot was not modified. Because no other migration was inspected, references to earlier schema objects are identified from this file but their prior definitions cannot be independently verified here.

# Objects and mutations

The migration targets the existing table `public.notification_deliveries`.

1. It executes `ALTER TABLE ... DROP CONSTRAINT IF EXISTS notification_deliveries_channel_check`. This removes the table's existing check constraint if a constraint with that name exists. The `IF EXISTS` clause makes this individual drop operation tolerant of the constraint being absent, but it does not make the migration independent of the table itself.
2. It executes `ALTER TABLE ... ADD CONSTRAINT notification_deliveries_channel_check CHECK (...)`. The replacement check permits exactly the text values `email`, `whatsapp`, and `push` in the `channel` column, using `channel = ANY (ARRAY['email'::text, 'whatsapp'::text, 'push'::text])`.

The file does not create or drop tables, schemas, indexes, sequences, views, policies, triggers, functions, extensions, or roles. It does not grant or revoke privileges. It does not insert, update, or delete rows. The comment states that existing email/WhatsApp rows and delivery history remain unchanged; the SQL itself performs no row-level data mutation.

# Dependencies

The migration depends on:

- The `public` schema being present.
- An existing table named `public.notification_deliveries` being present when both `ALTER TABLE` statements run. `IF EXISTS` applies only to the named constraint, not to the table.
- The table having a `channel` column whose type is compatible with comparison to `text` values and with the stated check expression.
- An earlier or pre-existing check constraint named `notification_deliveries_channel_check` being the constraint intended for replacement. If it is absent, the drop is skipped and the new constraint is still added.
- The executor having sufficient `ALTER TABLE` privilege on `public.notification_deliveries` (normally ownership or an equivalent administrative capability).

No extension, role, user-defined function, foreign key, sequence, or external service is referenced. No dependency on a specific earlier migration number is encoded in the SQL, although the descriptive comment and filename imply that the notification-delivery table and its prior channel validation should already exist.

# Data/external-side-effect assessment

There are no literal data rows, URLs, hostnames, API keys, webhook destinations, or other external references in the file. There are no `INSERT`, `UPDATE`, `DELETE`, `COPY`, or procedural statements. The migration changes metadata and validation behavior only.

The principal possible effect on existing data is validation-related: adding the new constraint requires all existing non-null (or otherwise constraint-evaluated) `channel` values to be among `email`, `whatsapp`, and `push`. If existing rows contain another value, the `ADD CONSTRAINT` statement would fail; it would not silently rewrite those rows. If the statements run in the normal migration transaction context and the second statement fails, the preceding drop would ordinarily roll back with the transaction. Transaction behavior is not explicitly declared in this file, so exact rollback behavior depends on the migration runner and database execution context.

# Security/ordering implications

The change broadens the accepted channel allow-list by adding `push` while preserving `email` and `whatsapp`. Dropping the old constraint before adding the replacement creates a brief constraint-free interval if the statements are run outside a transaction or exposed individually; a transactional migration runner avoids an externally observable gap. The file does not explicitly wrap the statements in `BEGIN`/`COMMIT`, so the runner's transaction policy matters.

The migration must be ordered after creation of `public.notification_deliveries` and its `channel` column, and after any migration that establishes the prior constraint if replacement of that exact constraint is intended. It should be ordered before application code or seed data that inserts `push` delivery records; otherwise such writes may fail under the old constraint. Conversely, adding the constraint can fail if historical data contains unsupported channel values, so the existing data domain should be checked before execution in a real environment.

The migration does not add RLS policies, grants, or application authorization. It therefore does not itself authorize sending push notifications; it only permits the database value `push` in this column. Any downstream workers, status transitions, provider credentials, and access controls remain outside this file's scope.

# Reconstruction recommendation

For a synthetic local schema reconstruction that does not model push delivery, this migration is safe to omit **provided** the reconstructed schema either retains the earlier `email`/`whatsapp`-only behavior intentionally or does not rely on inserting `push` rows. Omitting it would mean the local reconstruction does not reproduce the later accepted value `push`, so it is not behaviorally equivalent for push-channel workflows.

If the reconstruction is intended to represent the final schema or to test push notification outbox/delivery behavior, do not omit it: reproduce the final check constraint (or equivalent validation) after creating `public.notification_deliveries`. Do not emulate the intermediate drop-only state. Since only this file was inspected, the existence, original definition, nullability, and prior data compatibility of the table and column are **not independently verified**.

# Verdict

**PARTIALLY VERIFIED** — The file is internally clear and contains a narrowly scoped, non-external schema mutation that replaces one check constraint to allow `push`. It contains no direct data or external side effects and is generally safe to omit from a deliberately reduced synthetic reconstruction that does not support push rows. However, execution safety and full ordering correctness cannot be verified from this file alone because the prerequisite table/column, prior constraint, existing data domain, and migration-runner transaction behavior were not inspected. In a faithful final-schema reconstruction, the migration should be included or its resulting allow-list constraint represented explicitly.
