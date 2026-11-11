# Phase 2.1.8.8 — Dollar-Quote Token Boundary Completion Report

## Publication

The complete updated `experiment/run.sh` is published as [`PHASE_2_1_8_8_experiment_run.sh`](./PHASE_2_1_8_8_experiment_run.sh).

- **Source repository:** `ImperioKDB/scholars-schema-extraction`
- **Source path:** `experiment/run.sh`
- **Source commit:** [`44ed6c1dceeb09aad0ec0c82c792a362cdfa381a`](https://github.com/ImperioKDB/scholars-schema-extraction/commit/44ed6c1dceeb09aad0ec0c82c792a362cdfa381a)
- **Exact Git blob SHA:** `4746b410754d5b839c520bf7d40585f2b8eaaa87`
- **Independent blob recomputation:** `PASS`
- **Source byte length:** `30919`

The published runner is byte-for-byte identical to the source file at the stated commit.

## Correction

Dollar-quote openers now require a PostgreSQL token boundary: the preceding character cannot be an unquoted-identifier character, including letters, digits, underscore, or `$`. The existing tag grammar accepts only an optional tag beginning with an ASCII letter or underscore and continuing with ASCII letters, digits, or underscores. Closing tags are matched exactly and case-sensitively. Missing terminators continue to fail closed.

## Required regression fixture

The new fixture contains:

```sql
SELECT identifier$tag$fragment$tag$;
INSERT INTO app.students(display_name, fabricated_email)
VALUES ('Synthetic Student', 'student@example.invalid');
SELECT $tag$valid dollar-quoted text$tag$;
```

Result: **`FAIL`**, because `$tag$` inside `identifier$tag$...` is not treated as a dollar-quote opener, so the later real `INSERT` is detected. The later valid `$tag$...$tag$` construct remains recognized correctly.

## Scanner fixture results

These are scanner-only results. The GitHub Actions workflow and database experiment were not executed.

| Fixture | Expected | Result |
|---|---:|---:|
| Valid definition literals and function bodies, including `$$` and tagged dollar quotes | `PASS` | `PASS` |
| Valid ordinary strings with PostgreSQL 16 default mode | `PASS` | `PASS` |
| Valid `E'...'` escape strings | `PASS` | `PASS` |
| Valid doubled single quotes | `PASS` | `PASS` |
| Valid nested block comments | `PASS` | `PASS` |
| Identifier-containing `$tag$` followed by real `INSERT`, then later valid dollar quote | `FAIL` | `FAIL` |
| Actual `INSERT` row data | `FAIL` | `FAIL` |
| Actual `COPY FROM stdin` row data | `FAIL` | `FAIL` |
| Unterminated single-quoted string | `FAIL` | `FAIL` |
| Unterminated double-quoted identifier | `FAIL` | `FAIL` |
| Unterminated nested block comment | `FAIL` | `FAIL` |
| Unterminated dollar-quoted string | `FAIL` | `FAIL` |
| Empty output | `NOT TESTED` | `NOT TESTED` |

Every fixture remains included in `data_scanner_tests_status`, which is part of the mandatory fail-closed aggregate. Any mismatch fails the entire runner.

## Validation and scope

- Scanner-only fixture verification: PASS.
- `bash -n experiment/run.sh`: PASS.
- YAML formatting check: PASS.
- `git diff --check`: PASS.
- Dispatcher workflow: unchanged.
- No GitHub Actions workflow was executed.
- No merge occurred.
- No Supabase, production, or staging access occurred.
- No Scholars application files were modified.
