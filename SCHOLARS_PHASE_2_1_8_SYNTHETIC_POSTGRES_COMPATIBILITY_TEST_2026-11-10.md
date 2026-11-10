# Scholars Phase 2.1.8 — Synthetic PostgreSQL Compatibility Test

**Result:** Not run; no GitHub-hosted runner job was started.
**Author:** Manus AI

The proposed test would have used a disposable PostgreSQL 17 container and fabricated schema/table/function/index/RLS policy/rows only. It would then verify schema-only output, absence of fabricated row values, local SHA-256 calculation, and container/temp-file cleanup.

No workflow was created or dispatched. The Updates repository has no existing workflow on `main`, and GitHub requires a `workflow_dispatch` workflow to be present on the default branch before it can be triggered. Registering the diagnostic on `main` was outside the branch-only test approach. Existing Scholars dispatch workflows were not used because they are unrelated and may have application side effects. [1]

Consequently, Docker availability, PostgreSQL 17 image startup, local client installation, dump contents, row exclusion, hashing, and cleanup are **unverified**. No synthetic or production database was created, no dump or hash was generated, and nothing was uploaded. This result makes no claim about production capture readiness.

## References

[1]: https://docs.github.com/actions/managing-workflow-runs/manually-running-a-workflow "GitHub Manually Running a Workflow"
