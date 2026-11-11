# Phase 2.1.8.7 — Unterminated SQL Constructs Completion Report

## Publication

The complete updated `experiment/run.sh` is published as [`PHASE_2_1_8_7_experiment_run.sh`](./PHASE_2_1_8_7_experiment_run.sh).

- **Source repository:** `ImperioKDB/scholars-schema-extraction`
- **Source path:** `experiment/run.sh`
- **Source commit:** [`e486fd2f42fc05cd85f99fcf7ce4aa784a4f2616`](https://github.com/ImperioKDB/scholars-schema-extraction/commit/e486fd2f42fc05cd85f99fcf7ce4aa784a4f2616)
- **Exact Git blob SHA:** `5b07030dbe339e3a7e4233b29ed81cc8c055aef9`
- **Independent blob recomputation:** `PASS`
- **Source byte length:** `30114`

The published runner is byte-for-byte identical to the source file at the stated commit.

## Correction

The scanner now performs explicit end-of-file validation. It fails nonzero when EOF is reached with an open single-quoted string, open double-quoted identifier, nonzero nested block-comment depth, or unterminated dollar-quoted string. An unterminated or malformed lexical construct cannot become `PASS`.

The existing PostgreSQL string-mode behavior remains preserved: ordinary strings use the configured `standard_conforming_strings` mode, `E'...'` strings process backslash escapes, and unsupported or ambiguous settings fail closed. Doubled quotes, dollar-quoted tags, line comments, and nested block comments remain supported.

## Scanner fixture results

These are scanner-only results. The GitHub Actions workflow and database experiment were not executed.

| Fixture | Expected | Result | Purpose |
|---|---:|---:|---|
| Valid definition literals | `PASS` | `PASS` | Valid schema/function literals remain allowed. |
| Valid ordinary string with PostgreSQL 16 default mode | `PASS` | `PASS` | Ordinary strings remain correctly lexed. |
| Valid `E'...'` escape string | `PASS` | `PASS` | Escape-string handling remains correct. |
| Valid doubled single quotes | `PASS` | `PASS` | SQL quote doubling remains supported. |
| Valid nested block comments | `PASS` | `PASS` | Nested comments and fake statements remain ignored. |
| Valid dollar-quoted function body | `PASS` | `PASS` | Dollar-quoted bodies remain masked. |
| Actual `INSERT` row data | `FAIL` | `FAIL` | Real data-loading statements remain rejected. |
| Actual `COPY FROM stdin` row data | `FAIL` | `FAIL` | Real COPY row data remains rejected. |
| Unterminated single-quoted string | `FAIL` | `FAIL` | EOF open-quote check. |
| Unterminated double-quoted identifier | `FAIL` | `FAIL` | EOF open-identifier check. |
| Unterminated nested block comment | `FAIL` | `FAIL` | EOF block-depth check. |
| Unterminated dollar-quoted string | `FAIL` | `FAIL` | Missing dollar-tag terminator check. |
| Empty output | `NOT TESTED` | `NOT TESTED` | Empty output never becomes `PASS`. |

Every fixture result is included in `data_scanner_tests_status`, which remains part of the runner's mandatory fail-closed aggregate. Any fixture mismatch causes the entire runner to exit unsuccessfully.

## Validation and scope

- Scanner-only fixture verification: PASS.
- `bash -n experiment/run.sh`: PASS.
- YAML formatting check: PASS.
- `git diff --check`: PASS.
- Isolation scan: PASS.
- Dispatcher workflow: unchanged.
- No GitHub Actions workflow was executed.
- No merge occurred.
- No Supabase, production, or staging access occurred.
- No Scholars application files were modified.
