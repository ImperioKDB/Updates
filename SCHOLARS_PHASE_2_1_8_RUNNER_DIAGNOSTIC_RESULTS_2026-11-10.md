# Scholars Phase 2.1.8 — Runner Diagnostic Results

**Result:** Not run — the dedicated branch workflow cannot be dispatched without default-branch registration.
**Author:** Manus AI

## Verified

Both repositories are public and have GitHub Actions enabled. Updates currently has no workflow files on `main`. Scholars has eight active workflow files; seven use `workflow_dispatch`, but they perform existing application functions and were not run. The requested diagnostic file is absent from both default branches. GitHub requires the workflow file to be present in the default branch before it can receive a manual dispatch. A workflow registered there can then be run using a selected non-default ref. [1]

## Not tested

No runner job ran. Thus there is no observed `ubuntu-24.04` runner identity, Docker daemon result, PostgreSQL 17 client result, disposable container test, synthetic schema dump, synthetic row exclusion check, Supabase CLI `2.122.1` result, SHA-256 execution, or cleanup result. No run URL, job result, diagnostic branch, or diagnostic commit exists.

The billing rule is known: standard hosted runners for public repositories are free. That establishes expected compute price, not the runner’s actual Docker/PostgreSQL capabilities. [2]

## Why no workflow was created

A branch-only `.github/workflows/scholars-runner-preflight.yml` in either repository cannot receive `workflow_dispatch` until the file is on that repository’s default branch. Adding the workflow to `main` solely to register it would violate the requested branch-isolated test approach. Triggering existing Scholars manual workflows would be unrelated and could produce side effects. No changes or runs were made.

## References

[1]: https://docs.github.com/actions/managing-workflow-runs/manually-running-a-workflow "GitHub Manually Running a Workflow"
[2]: https://docs.github.com/billing/managing-billing-for-github-actions/about-billing-for-github-actions "GitHub Actions Billing"
