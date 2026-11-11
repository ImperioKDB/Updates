# Phase 2.1.8.6 — Updated Completion Report

## Publication

The complete updated `experiment/run.sh` has been published as [`PHASE_2_1_8_6_experiment_run.sh`](./PHASE_2_1_8_6_experiment_run.sh).

- **Source repository:** `ImperioKDB/scholars-schema-extraction`
- **Source path:** `experiment/run.sh`
- **Source commit:** [`69e11421afdeb7c01765e189fbaeaf75747b19b9`](https://github.com/ImperioKDB/scholars-schema-extraction/commit/69e11421afdeb7c01765e189fbaeaf75747b19b9)
- **Exact Git blob SHA:** `5c187c73f325000d0f22d0e42ae5691154e1690e`
- **Independent blob recomputation:** `PASS`
- **Source byte length:** `28609`

The published runner file is byte-for-byte identical to the source file at the stated commit, including shell logic, comments, fixtures, and trailing newline.

## Scanner fixture results

These are the scanner-only fixture results from the validated Phase 2.1.8.6 correction. The GitHub Actions workflow and database experiment were not executed.

| Fixture | Expected result | Result | Purpose |
|---|---:|---:|---|
| Ordinary string with a backslash immediately before its closing quote, followed by actual `INSERT` | `FAIL` | `PASS` | Confirms PostgreSQL `standard_conforming_strings=on` does not let the backslash conceal the closing quote or subsequent data statement. |
| Ordinary string with a backslash not before its closing quote | `PASS` | `PASS` | Confirms ordinary backslashes are literal under the PostgreSQL 16 default. |
| `E'...'` string with escaped single quotes/backslashes | `PASS` | `PASS` | Confirms escape-string backslash handling. |
| Doubled single quotes | `PASS` | `PASS` | Confirms SQL quote doubling is masked correctly. |
| Dollar-quoted function body | `PASS` | `PASS` | Confirms body literals are not treated as table row data. |
| Nested block comments containing fake `INSERT` | `PASS` | `PASS` | Confirms fake statements inside nested comments are ignored. |
| Actual `INSERT` row data | `FAIL` | `FAIL` | Confirms real data-loading statements are rejected. |
| Actual `COPY FROM stdin` row data | `FAIL` | `FAIL` | Confirms real COPY row data is rejected. |
| Empty output | `NOT TESTED` | `NOT TESTED` | Confirms empty extraction output cannot become a false PASS. |
| Unsupported/ambiguous string-setting cases | `FAIL` | `FAIL` | Confirms unknown or conflicting `standard_conforming_strings` modes fail closed. |

The fixture aggregate remains part of the runner's mandatory fail-closed status list. Existing authentication, role, privilege, default-privilege, RLS, owner-maintenance, extraction, object-inventory, diagnostics, data-exclusion, and forbidden-operation checks remain unchanged and mandatory.

## PostgreSQL string-mode correction

The runner explicitly defaults `SCANNER_STANDARD_CONFORMING_STRINGS` to `on`, matching PostgreSQL 16's default `standard_conforming_strings` behavior. Ordinary strings treat backslashes literally in this mode; `E'...'` strings interpret backslash escapes. If the applicable mode is missing, unsupported, ambiguous, or conflicts with an explicit setting in the scanned text, the scanner fails closed.

No PostgreSQL-aware parser dependency was added. The environment did not provide `pglast`, `pg_query`, or `sqlparse`; this targeted check requires lexical masking rather than AST parsing, and the scanner now handles the required PostgreSQL lexical constructs explicitly.

## Scope confirmation

- No GitHub Actions workflow was executed.
- No merge was performed.
- No Supabase, production, or staging system was accessed.
- No Scholars application files were modified.
