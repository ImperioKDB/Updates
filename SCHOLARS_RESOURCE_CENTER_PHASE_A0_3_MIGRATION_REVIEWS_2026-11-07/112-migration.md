# File

`/tmp/scholars-a03-snapshot/scholars-41573f5/supabase/migrations/0093_add_whatsapp_community_invitation_consent.sql`

This audit is based solely on the contents of this migration. No SQL was executed, no Supabase instance or hosted service was accessed, and no other migration was inspected.

# Scope

The migration separates consent for a single manually sent WhatsApp invitation to the Scholars Student Community from the existing reminder consent. It changes the existing `public.profiles` table by adding four consent/audit columns, documents those columns with PostgreSQL comments, and adds a check constraint that validates the affirmative-consent state.

The file is narrowly scoped to schema metadata and row-validity rules. Its comments state that existing reminder opt-ins remain false for this new purpose and that there is no backfill, but the migration itself contains no data-update statement.

# Objects and mutations

## DDL

- `ALTER TABLE public.profiles ... ADD COLUMN IF NOT EXISTS` adds:
  - `whatsapp_community_invite_opt_in boolean NOT NULL DEFAULT false`
  - `whatsapp_community_invite_consented_at timestamptz`
  - `whatsapp_community_invite_withdrawn_at timestamptz`
  - `whatsapp_community_invite_notice_version text`
- A second `ALTER TABLE public.profiles` adds the named check constraint `profiles_community_invite_consent_check`.
- `COMMENT ON COLUMN` adds documentation for each of the four new columns.

The first `ALTER TABLE` uses `IF NOT EXISTS` for each column. The constraint creation does not use an existence guard, so rerunning the migration after the constraint has already been created would ordinarily fail with a duplicate-constraint-name error.

## DML

None. There are no `INSERT`, `UPDATE`, `DELETE`, `MERGE`, or explicit backfill statements. The `DEFAULT false` is a column definition and not an explicit data migration; it establishes the default for new rows and causes existing rows to receive the non-null default as part of adding the column under PostgreSQL's column-addition semantics.

## Grants and revokes

None. The file contains no `GRANT`, `REVOKE`, role changes, RLS changes, policies, triggers, functions, indexes, or row-level data transformations.

# Dependencies

- The table `public.profiles` must already exist.
- The existing `public.profiles.whatsapp_number` column must already exist because the check constraint references it.
- `whatsapp_number` must be usable with the PostgreSQL regular-expression match operator `~`; the intended value format is a Nigerian international number matching `^[+]234[0-9]{10}$`.
- The `public` schema and ordinary PostgreSQL types `boolean`, `timestamptz`, and `text` are required.
- Constraint installation must occur after `profiles` and `whatsapp_number` are present, and after any earlier migration that establishes the table's relevant shape.
- The named constraint occupies the table-level namespace for `profiles`; a prior constraint with the same name would cause this migration's final statement to fail.

# Data/external-side-effect assessment

The migration contains no embedded real user records, phone numbers, tokens, credentials, or other row-level production data. The only data-like values are the boolean default `false`, the consent-state validation condition, descriptive comment text, and the regex literal `^[+]234[0-9]{10}$`.

It contains no external URLs, webhook endpoints, API destinations, network calls, file operations, or service integrations. The reference to WhatsApp and the Scholars Student Community is descriptive domain text only; it does not send or schedule an invitation.

There is no explicit backfill. Existing reminder consent is not copied into the new field. Because the new opt-in column is `NOT NULL DEFAULT false`, existing profiles are represented as not opted in for this new invitation purpose. The nullable timestamp and notice-version columns remain unset unless application logic later records consent.

# Security/ordering implications

The principal security effect is positive consent separation: the new field is independent of reminder opt-in, and the check constraint prevents a row from being affirmative on `whatsapp_community_invite_opt_in` unless it has all of the following: a consent timestamp, no withdrawal timestamp, a non-null notice version, and a WhatsApp number matching the specified Nigerian format.

The check is conditional. It imposes no consistency requirements when `whatsapp_community_invite_opt_in` is false, so a false row could still contain a consent timestamp, withdrawal timestamp, or notice version. The migration also does not enforce temporal ordering between consent and withdrawal timestamps, does not constrain notice-version contents, and does not require the number to be non-null independently of the affirmative state. PostgreSQL check constraints also treat a null result as not-failing; however, `whatsapp_community_invite_opt_in` itself is non-null, and the affirmative branch explicitly requires the other relevant fields to be non-null. The regex condition consequently has to evaluate true for an affirmative row.

No privileges are changed, and no RLS policy is added or modified. Therefore, access to these consent fields is governed by the pre-existing table privileges, RLS policies, and application/server pathways. This migration alone does not prevent an already-authorized role from reading or changing consent data.

Ordering matters: `public.profiles` and its `whatsapp_number` column must precede this migration. The four columns must be added before the constraint is created. If a reconstruction creates the constraint before `whatsapp_number` exists, or omits that column, constraint creation will fail. The `IF NOT EXISTS` column clauses improve rerun tolerance, but they do not verify that an already-existing same-named column has the expected type, nullability, or default; the unguarded named constraint remains non-idempotent.

# Reconstruction recommendation

For a behaviorally faithful synthetic schema reconstruction, retain all four columns, their nullability/default characteristics, the four comments if documentation fidelity matters, and the named check constraint. The constraint is important because it captures the application's affirmative-consent invariant and the dependency on a valid Nigerian WhatsApp number.

For a deliberately minimal synthetic schema whose purpose is only to support unrelated profile queries and that does not model WhatsApp invitation consent, this migration can be omitted, provided no reconstructed application code, queries, fixtures, policies, or later constraints reference these columns or the named constraint. Omitting it would not lose any data backfill or external side effect, but it would lose the consent-specific schema contract and would make behavior differ for any code expecting these fields or validation.

If only structure relevant to downstream behavior is being reconstructed, the strongest compromise is to keep the four columns and check constraint while treating the comments as optional metadata. Do not silently map the new opt-in to the existing reminder opt-in: the migration explicitly defines them as separate purposes.

# Verdict

**Schema-only, consent-invariant migration; no DML, grants, revokes, real-data payload, or external side effect.** It is safe to omit only from a synthetic reconstruction that intentionally excludes the WhatsApp community-invitation consent feature and all references to it. It should be included for a faithful reconstruction because it adds four expected profile attributes and enforces a meaningful affirmative-consent invariant. Apply it only after `public.profiles.whatsapp_number` exists, and account for the unguarded constraint when considering reruns.
